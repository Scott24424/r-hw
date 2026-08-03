# T02 테스트 하니스

## 목표

vitest(단위·통합)와 Playwright(E2E)를 설치·설정하고, 두 프레임워크가 실제로 도는 것을 스모크 테스트와 CI로 증명한다. 또한 D21의 Node 정책이 한 곳에서만 정의되는지 대조한다.

**이 태스크는 애플리케이션의 도메인 규칙을 검증하지 않는다.** 검증 대상은 (a) 하니스가 실제로 돌고 실패를 잡는가, (b) 실행 환경이 후속 태스크의 전제를 만족하는가, 두 가지뿐이다.

## 요구사항 추적

| 근거 | 내용 |
|---|---|
| **OR-03** | 이 태스크의 **존재 이유**다. "테스트와 교차 검증을 통해 결과 품질을 최대화한다"가 하니스·CI·실패 검출 확인의 근거다 |
| OR-02 | 커버리지 도구·테스트 유틸 라이브러리를 도입하지 않고 chromium 1종만 설치한다 — 비용 최소화 |
| **UR-14** | vitest·Playwright 선택과 Node 정책(D21)이 여기 걸린다 |
| **UR-20, UR-20.1** | `playwright.config.ts`의 viewport `1024×768`. **태블릿 가로는 주요 인수 테스트 기준이며 제품을 그 폭으로 제한하지 않는다** — E2E가 이 폭에서 도는 것과 제품이 데스크톱에서 동작해야 하는 것(UR-20.2)은 양립한다 |
| **UR-21** | `webServer.env`의 `E2E_TEST_MODE: "1"`은 상시 실행·시각 주입(D16·D20)에서 왔다. **이 태스크에서는 값을 읽는 코드가 없어 실행상 효과가 없다** |
| **UR-22, UR-22.3** | `tests/env.test.ts`의 `Asia/Seoul` ICU 전제 검사. 이 파일은 **환경 능력만** 보고 도메인 규칙을 보지 않는다. 타임존의 **단일 정의처 검증(UR-22.1)은 T05**의 몫이다 |
| NR-06 | WebSocket·SSE를 쓰지 않으므로 E2E에 실시간 연결 검증이 없다 |

**제품 기능 요구(UR-04~UR-13)에 직접 대응하는 항목은 없다.**

**설계 가정 12건(AP-01~AP-12)은 2026-08-01에 전부 처리되었다.** 이 태스크에 영향을 준 것은 AP-01·AP-07·AP-08·AP-09의 승인이며, AP-07과 AP-09는 **조건부**다 — 위 표의 UR-20.1·UR-20.2와 UR-22.1이 그 조건이다.

## 선행 태스크

T01

## 구현 순서상의 위치

**T01 → T02 → T03 → T04.** T02는 T01이 `main`에 Merge된 뒤 브랜치를 만든다. T02와 T03을 병렬로 구현하지 않는다 — 두 태스크가 `package.json`, `package-lock.json`, `.gitignore`, `.github/workflows/ci.yml`을 모두 건드리고, T03의 CI 패치는 **T02가 조건부 CI를 이미 전체 교체했다는 전제에서만** 정확히 적용된다 (DR-05).

## 변경 대상 파일

생성:

- `vitest.config.ts`
- `playwright.config.ts`
- `tests/setup.ts`
- `tests/env.test.ts`
- `e2e/smoke.spec.ts`

수정:

- `package.json`
- `package-lock.json`
- `.gitignore`
- `.github/workflows/ci.yml`

**이 목록 밖의 파일은 생성·수정하지 않는다.** 특히 `src/` 아래에 아무것도 만들지 않고, T01이 만든 파일을 고치지 않는다.

## 구현 요구사항

1. 아래 devDependency만 추가한다. 다른 패키지를 추가하지 않는다.

```
vitest            ^3.0.0
@playwright/test  ^1.50.0
```

2. **Playwright 버전과 Node 정책 (D21, DR-03).** `^1.50.0`은 `<2.0.0` 전체를 허용하므로 현재 최신 1.x가 설치된다. 현행 Playwright의 시스템 요구사항은 **"Node.js: latest 22.x, 24.x or 26.x."** — **하한이 아니라 집합 {22, 24, 26}이다.** 공식 근거: [Playwright — Installation / System requirements](https://playwright.dev/docs/intro), 확인일 **2026-08-01**.

   T01이 `.nvmrc = 22`(CI 기준선)와 `engines.node = "22 || 24 || 26"`(허용 집합)을 고정했으므로 이 조합은 지원 범위 안에 있다. 아래 네 가지를 지킨다.

   - 범위는 `^1.50.0`으로 두고 **정확한 버전은 `package-lock.json`이 고정한다.**
   - 설치 후 `npm ls @playwright/test playwright-core`와 `npx playwright --version`의 출력을 **완료 보고에 그대로 포함한다.**
   - **허용 메이저 집합은 `>=` 비교가 아니라 열거로 검사한다** (요구사항 9). `>= 22`로 검사하면 지원 목록에 없는 23·25·27이 통과한다 — 그것이 DR-03의 잔여 지적이다.
   - 설치된 Playwright가 **Node 22를 지원 대상에서 제외**한다면(향후 릴리스에서 목록이 바뀌는 경우) **진행하지 말고 보고한다.** `.nvmrc`·`engines.node`·`SUPPORTED_NODE_MAJORS`를 임의로 올리지 않는다 — D21을 갱신하는 것은 설계자의 일이다. 목록에 새 메이저가 추가되거나 26이 빠지는 경우도 같다.

3. `package.json`의 `scripts`에 아래 3개를 **추가**한다. 기존 스크립트는 수정하지 않는다.

```jsonc
"test": "vitest run",
"test:watch": "vitest",
"e2e": "playwright test"
```

4. `vitest.config.ts`를 아래 내용으로 작성한다.

```ts
import { fileURLToPath } from "node:url";
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    environment: "node",
    include: ["src/**/*.test.ts", "tests/**/*.test.ts"],
    exclude: ["node_modules/**", ".next/**", "e2e/**"],
    setupFiles: ["./tests/setup.ts"],
    // 프로세스 TZ 기본값을 UTC로 고정한다. 로컬 시각에 암묵적으로 의존하는
    // 코드가 들어오면 곧바로 드러난다. (D8의 전제 조건 — 검증 자체는 T05)
    env: { TZ: "UTC" },
    testTimeout: 10_000,
  },
  resolve: {
    alias: { "@": fileURLToPath(new URL("./src", import.meta.url)) },
  },
});
```

5. `include` 패턴이 **`e2e/`를 제외**해야 한다. 제외하지 않으면 vitest가 Playwright 스펙을 실행하려다 실패한다.

6. `tests/setup.ts`는 `process.env.TZ = "UTC";` 한 줄과 그 이유를 적은 주석을 담는다. 이후 태스크가 전역 셋업을 추가할 자리다.

7. `tests/env.test.ts`는 **실행 환경이 후속 태스크의 전제를 만족하는지**만 검증한다. 두 개의 describe로 나눈다.

```ts
describe("실행 환경 — ICU·타임존 전제", () => {
  it("같은 순간을 Asia/Seoul과 UTC에서 다른 달력 날짜로 포매팅한다", ...);
  it("Asia/Seoul 타임존을 Intl이 인식한다", ...);
  it("단위 테스트 프로세스의 TZ 기본값이 UTC다", ...);
});

describe("실행 환경 — Node 버전 정책", () => {
  it(".nvmrc가 22이다", ...);
  it("package.json engines.node가 22 || 24 || 26이다", ...);
  it("engines.node가 선언하는 메이저 집합이 지원 목록과 일치한다", ...);
  it("실행 중인 Node의 메이저가 지원 목록에 있다", ...);
  it("지원 목록에 없는 메이저는 거부된다", ...);
});
```

8. ICU 전제 검증의 기준 순간은 `new Date("2026-08-01T15:00:00.000Z")`를 쓴다. 이 순간은 KST로 `2026-08-02 00:00`이다.

| 검증 | 기대 |
|---|---|
| `Intl.DateTimeFormat("en-CA", { timeZone: "Asia/Seoul", year: "numeric", month: "2-digit", day: "2-digit" }).format(기준 순간)` | `"2026-08-02"` |
| 같은 포매터의 `timeZone: "UTC"` | `"2026-08-01"` |
| `Intl.supportedValuesOf("timeZone").includes("Asia/Seoul")` | `true` |
| `process.env.TZ` | `"UTC"` |

이 테스트가 실패하면 Node의 ICU 데이터가 불완전한 것이며, **후속 태스크의 날짜 계산이 성립할 수 없다.** 그 경우 진행하지 말고 보고한다.

9. **Node 정책 검증 (D21, DR-03).** 허용 메이저는 **하한이 아니라 집합**이다. 파일 상단에 아래 상수를 두고, 이 배열이 테스트 안에서의 유일한 기준이 된다.

```ts
/** D21: 현행 Playwright가 지원하는 Node 메이저. 하한이 아니라 열거다. */
const SUPPORTED_NODE_MAJORS = [22, 24, 26] as const;

/** CI 기준선. .nvmrc의 값이자 SUPPORTED_NODE_MAJORS의 원소여야 한다. */
const CI_BASELINE_MAJOR = 22;

/** `"22 || 24 || 26"` → `[22, 24, 26]`. engines.node를 기계적으로 해석한다. */
function parseEnginesMajors(engines: string): number[] {
  return engines.split("||").map((part) => Number(part.trim()));
}
```

검증 항목:

| # | 테스트명 | 검증 | 기대 |
|---|---|---|---|
| 9-1 | `.nvmrc가 22이다` | `.nvmrc` 파일 내용을 trim한 값 | 문자열 `"22"`. 그리고 `Number(값) === CI_BASELINE_MAJOR`이며 `SUPPORTED_NODE_MAJORS`에 포함된다 |
| 9-2 | `package.json engines.node가 22 \|\| 24 \|\| 26이다` | `package.json`의 `engines.node` | 문자열 exact match `"22 \|\| 24 \|\| 26"` |
| 9-3 | `engines.node가 선언하는 메이저 집합이 지원 목록과 일치한다` | `parseEnginesMajors(engines.node)` | `[...SUPPORTED_NODE_MAJORS]`와 **deep equal** (순서 포함) |
| 9-4 | `실행 중인 Node의 메이저가 지원 목록에 있다` | `Number(process.versions.node.split(".")[0])` | `SUPPORTED_NODE_MAJORS.includes(major) === true` |
| 9-5 | `지원 목록에 없는 메이저는 거부된다` | `SUPPORTED_NODE_MAJORS.includes(m)` — `m ∈ {20, 21, 23, 25, 27}` | 다섯 값 전부 `false` |

**규칙:**

- **9-4에 `>=` 비교를 쓰지 않는다.** `major >= 22`는 지원 목록에 없는 23·25·27을 통과시킨다 — DR-03이 남긴 잔여 결함이 정확히 이것이다.
- 9-3이 있으므로 `engines.node` 문자열과 `SUPPORTED_NODE_MAJORS`가 갈라질 수 없다. 9-1이 `.nvmrc`를 그 집합에 묶는다. **세 값이 한 집합을 말한다는 것이 이 describe의 목적이다.**
- 9-5는 실제로 Node 23을 설치해 돌릴 수 없으므로 **판정 함수를 직접 검사**한다. 이 테스트가 있어야 "미지원 메이저는 거부된다"가 반증 가능한 명제가 된다.
- 로컬 Node **24.18.0에서 9-4는 통과한다** — 24가 집합 안에 있다. `.nvmrc`의 22는 CI 기준선이지 로컬 강제값이 아니다 (D21).
- `engines`는 npm에서 기본적으로 경고에 그치므로 **지원되지 않는 메이저에서 완료 검증을 실패시키는 장치는 9-4다.** `.npmrc`나 `engine-strict`를 추가하지 않는다.

10. `playwright.config.ts`를 아래 내용으로 작성한다.

```ts
import { defineConfig, devices } from "@playwright/test";

const BASE_URL = "http://127.0.0.1:3000";

export default defineConfig({
  testDir: "./e2e",
  // 후속 태스크의 E2E가 하나의 SQLite 파일을 공유할 예정이므로 선제적으로
  // 직렬화한다. T02 시점에는 DB가 아직 없으므로 실행상 제약은 없다.
  fullyParallel: false,
  workers: 1,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  reporter: process.env.CI
    ? [["list"], ["html", { open: "never" }]]
    : [["list"]],
  use: {
    baseURL: BASE_URL,
    trace: "on-first-retry",
  },
  projects: [
    {
      // §6.4: 아이의 기기는 태블릿, 가로 1024px가 기준 폭이다.
      name: "tablet-chromium",
      use: { ...devices["Desktop Chrome"], viewport: { width: 1024, height: 768 } },
    },
  ],
  webServer: {
    // D16-e: 상시 실행은 next dev가 아니라 build + start다.
    command: "npm run serve",
    url: BASE_URL,
    reuseExistingServer: !process.env.CI,
    timeout: 180_000,
    // D20: 서버의 "지금"을 x-e2e-now 헤더로 주입할 수 있게 하는 플래그.
    // 이 값을 읽는 코드는 T09에서 추가된다. 여기서 켜두는 이유는 E2E 서버
    // 기동 설정이 한 곳에만 있게 하기 위함이다.
    env: { E2E_TEST_MODE: "1" },
  },
});
```

11. `workers: 1`과 `fullyParallel: false`를 반드시 유지한다. 후속 태스크의 E2E가 같은 SQLite 파일을 쓰므로 병렬 실행하면 서로의 데이터를 덮어쓴다.

12. `webServer.env`가 `process.env`를 대체해 `npm run serve`가 `PATH`를 잃는다면, `env: { ...process.env, E2E_TEST_MODE: "1" }`로 바꾼다. **그 경우 바꾼 사실과 이유를 완료 보고에 적는다.** 다른 해결책(셸 래퍼 추가 등)을 쓰지 않는다.

13. `e2e/smoke.spec.ts`는 T01이 만든 임시 화면을 검증한다. **두 번째 단정이 DR-02의 브라우저 측 절반이다** — T01은 유틸리티가 CSS에 생성되는 것까지, T02는 실제로 적용되는 것까지 본다.

```ts
test("루트 화면이 렌더링된다", async ({ page }) => {
  await page.goto("/");
  await expect(page.getByRole("heading", { level: 1 })).toHaveText("r-hw");
});

test("Tailwind 유틸리티가 브라우저에서 실제로 적용된다", async ({ page }) => {
  await page.goto("/");
  // T01이 <h1>에 text-[42px]를 넣었다. Tailwind가 동작하지 않으면
  // 이 계산값은 42px이 아니다 (일반 CSS만으로는 이 값이 나오지 않는다).
  await expect(page.getByRole("heading", { level: 1 })).toHaveCSS("font-size", "42px");
});
```

14. `.gitignore`에 아래를 **추가**한다. 기존 항목은 지우지 않는다.

```
/test-results/
/playwright-report/
/blob-report/
/playwright/.cache/
```

15. `.github/workflows/ci.yml`을 아래 내용으로 **전체 교체**한다. T01에서 `package.json`이 생겼으므로 기존의 "파일이 없으면 건너뜀" 조건 분기는 더 이상 필요 없고, 오히려 스크립트 이름이 잘못돼도 CI가 초록으로 통과하는 위험을 만든다.

**Node 버전은 `node-version-file: ".nvmrc"`로 읽는다** (D21). CI에 버전을 하드코딩하지 않는다 — 두 job과 로컬이 같은 파일을 본다.

```yaml
name: CI

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  ci:
    name: ci
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version-file: ".nvmrc"
          cache: npm
      - run: npm ci
      - run: npm run typecheck
      - run: npm run lint
      - run: npm test
      - run: npm run build

  e2e:
    name: e2e
    runs-on: ubuntu-latest
    needs: ci
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version-file: ".nvmrc"
          cache: npm
      - run: npm ci
      - run: npx playwright install --with-deps chromium
      - run: npm run e2e
      - uses: actions/upload-artifact@v4
        if: ${{ !cancelled() }}
        with:
          name: playwright-report
          path: playwright-report/
          retention-days: 7
```

16. CI는 `npm run typecheck`를 호출한다. T01이 이 스크립트를 `next typegen && tsc --noEmit`으로 정의했으므로 **로컬과 CI가 문자 그대로 같은 명령을 실행한다** (DR-01). CI에서 `tsc`나 `next typegen`을 따로 부르지 않는다.

17. **프로젝트 전체의 테스트 파일 배치 규약을 이 태스크에서 확정한다.** 후속 태스크는 예외 없이 이 규약을 따른다.

| 종류 | 위치 | 예 |
|---|---|---|
| 단위 테스트 | 대상 파일 옆에 `*.test.ts`로 콜로케이트 | `src/domain/clock.ts` → `src/domain/clock.test.ts` |
| 통합 테스트 (DB 필요) | `tests/integration/*.test.ts` | `tests/integration/db-foundation.test.ts` |
| 공용 테스트 헬퍼 | `tests/helpers/*.ts` | `tests/helpers/db.ts` |
| 테스트용 기대 데이터 | `tests/fixtures/*.ts` | `tests/fixtures/seed-expected.ts` |
| 환경·전역 셋업 | `tests/setup.ts`, `tests/*.test.ts` | `tests/env.test.ts` |
| E2E | `e2e/*.spec.ts` | `e2e/today.spec.ts` |

E2E만 확장자가 `.spec.ts`다. 이 차이가 vitest와 Playwright의 수집 범위를 갈라놓는다.

## 비즈니스 규칙

| 규칙 | 위반 시 동작 |
|---|---|
| Node 실행 환경은 완전한 IANA 타임존 데이터를 가져야 한다 | `같은 순간을 Asia/Seoul과 UTC에서 다른 달력 날짜로 포매팅한다`가 실패. **진행 중단 후 보고** |
| 단위 테스트는 프로세스 TZ가 UTC인 상태에서 돈다 | `단위 테스트 프로세스의 TZ 기본값이 UTC다`가 실패 |
| CI 기준선의 정의처는 `.nvmrc` 하나다 (D21) | `.nvmrc가 22이다`가 실패 |
| 허용 Node 집합은 `.nvmrc`·`engines.node`·`SUPPORTED_NODE_MAJORS`에서 동일하다 (D21, DR-03) | `package.json engines.node가 22 \|\| 24 \|\| 26이다` 또는 `engines.node가 선언하는 메이저 집합이 지원 목록과 일치한다`가 실패 |
| Playwright는 Node 22 · 24 · 26에서만 돈다 (D21) | `실행 중인 Node의 메이저가 지원 목록에 있다`가 실패, 또는 `npm run e2e`가 unsupported Node 경고·오류 |
| 지원 목록에 없는 메이저(20·21·23·25·27)를 통과시키지 않는다 (DR-03) | `지원 목록에 없는 메이저는 거부된다`가 실패 |
| Tailwind 유틸리티가 브라우저에서 적용된다 (DR-02) | `Tailwind 유틸리티가 브라우저에서 실제로 적용된다`가 실패 |
| E2E는 프로덕션 빌드로 돈다 (D16-e) | `webServer.command`가 `npm run dev`이면 완료 조건 미충족 |
| E2E는 직렬 실행한다 | `workers`가 1이 아니면 완료 조건 미충족 |
| CI는 스크립트 부재를 조용히 넘기지 않는다 | 스크립트 이름이 틀리면 CI가 실패해야 한다 (요구사항 15) |
| 로컬과 CI의 typecheck 명령이 같다 (DR-01) | CI가 `npm run typecheck` 외의 방법으로 타입 검사하면 완료 조건 미충족 |

## 테스트 케이스

### 정상 케이스

| # | 테스트명 | 파일 | 입력 | 기대 결과 |
|---|---|---|---|---|
| 1 | `같은 순간을 Asia/Seoul과 UTC에서 다른 달력 날짜로 포매팅한다` | `tests/env.test.ts` | `2026-08-01T15:00:00.000Z` | Seoul `"2026-08-02"`, UTC `"2026-08-01"` |
| 2 | `Asia/Seoul 타임존을 Intl이 인식한다` | `tests/env.test.ts` | — | `Intl.supportedValuesOf("timeZone")`에 `"Asia/Seoul"` 포함 |
| 3 | `단위 테스트 프로세스의 TZ 기본값이 UTC다` | `tests/env.test.ts` | — | `process.env.TZ === "UTC"` |
| 4 | `.nvmrc가 22이다` | `tests/env.test.ts` | `.nvmrc` 내용 | trim 결과가 `"22"`이고 `SUPPORTED_NODE_MAJORS`에 포함 |
| 5 | `package.json engines.node가 22 \|\| 24 \|\| 26이다` | `tests/env.test.ts` | `package.json` | `engines.node === "22 \|\| 24 \|\| 26"` |
| 5b | `engines.node가 선언하는 메이저 집합이 지원 목록과 일치한다` | `tests/env.test.ts` | `parseEnginesMajors(engines.node)` | `[22, 24, 26]`과 deep equal |
| 6 | `실행 중인 Node의 메이저가 지원 목록에 있다` | `tests/env.test.ts` | `process.versions.node` | 메이저가 `SUPPORTED_NODE_MAJORS`에 **포함**. `>=` 비교 금지 |
| 6b | `지원 목록에 없는 메이저는 거부된다` | `tests/env.test.ts` | `20, 21, 23, 25, 27` | 다섯 값 전부 미포함 판정 |
| 7 | `루트 화면이 렌더링된다` | `e2e/smoke.spec.ts` | `GET /` | `<h1>` 텍스트가 `r-hw` |
| 8 | `Tailwind 유틸리티가 브라우저에서 실제로 적용된다` | `e2e/smoke.spec.ts` | `GET /` | `<h1>`의 computed `font-size`가 `42px` |

### 규칙 위반 케이스

| # | 케이스명 | 입력 | 기대 결과 |
|---|---|---|---|
| 9 | 실패하는 단위 테스트가 CI를 깨는가 | `tests/env.test.ts`에 `expect(1).toBe(2)`를 임시 추가 | `npm test` 종료 코드 ≠ 0 |
| 10 | 실패하는 E2E가 감지되는가 | `e2e/smoke.spec.ts`의 기대 텍스트를 `r-hw!`로 임시 변경 | `npm run e2e` 종료 코드 ≠ 0 |
| 11 | Node 정책 불일치가 감지되는가 | `.nvmrc`를 `20`으로 임시 변경 | `.nvmrc가 22이다`가 실패 |
| 11b | 하한 선언으로의 회귀가 감지되는가 | `package.json`의 `engines.node`를 `">=22"`로 임시 변경 | `package.json engines.node가 22 \|\| 24 \|\| 26이다`와 `engines.node가 선언하는 메이저 집합이 지원 목록과 일치한다`가 **둘 다** 실패 (DR-03) |
| 11c | 미지원 메이저 추가가 감지되는가 | `SUPPORTED_NODE_MAJORS`에 `23`을 임시 추가 | `engines.node가 선언하는 메이저 집합이 지원 목록과 일치한다`와 `지원 목록에 없는 메이저는 거부된다`가 **둘 다** 실패 |
| 12 | Tailwind 미적용이 감지되는가 | `src/app/page.tsx`의 `text-[42px]`를 임시 제거하고 `npm run e2e` | `Tailwind 유틸리티가 브라우저에서 실제로 적용된다`가 실패 |

9~12번(11b·11c 포함)은 하니스가 실패를 실제로 잡는지 확인하는 절차다. **여섯 명령의 실제 출력을 완료 보고에 포함하고, 코드는 원상 복구된 상태여야 한다.** 11·11b는 T01 파일(`.nvmrc`, `package.json`)을, 12번은 T01의 `src/app/page.tsx`를 임시 수정하므로 특히 원복을 확인한다 — 원복 후 `git diff .nvmrc package.json src/app/page.tsx`가 비어 있어야 하고, 그 출력을 보고에 포함한다.

### 경계 케이스

| # | 케이스명 | 확인 방법 | 기대 결과 |
|---|---|---|---|
| 13 | vitest가 E2E 파일을 수집하지 않음 | `npm test` 출력 | 실행된 파일에 `e2e/smoke.spec.ts`가 없음 |
| 14 | Playwright가 단위 테스트를 수집하지 않음 | `npm run e2e` 출력 | 실행된 스펙이 `e2e/smoke.spec.ts` 1개 |
| 15 | 기존 `.gitignore` 항목 보존 | `git diff .gitignore` | 삭제된 줄 0줄 |
| 16 | E2E 서버가 프로덕션 빌드로 뜸 | `npm run e2e` 로그 | `next build` 실행 후 `next start`가 뜬다 |
| 17 | 설치된 Playwright 버전 기록 | `npm ls @playwright/test playwright-core`, `npx playwright --version` | 출력을 완료 보고에 포함 (D21) |

### 이 태스크가 검증하지 않는 것 (후속 태스크로 이관한 책임)

DR-04에 대한 응답이다. **`tests/env.test.ts`는 실행 환경의 전제만 본다.** 입력과 기대에 애플리케이션 함수가 하나도 없으므로, 이 파일이 통과한다는 사실은 앱의 날짜 계산이 옳다는 증거가 **아니다.**

| 미검증 항목 | 담당 태스크 | 그 태스크의 필수 완료 조건 |
|---|---|---|
| `getToday(now, tz)`가 프로세스 TZ와 무관하게 `Asia/Seoul` 달력 날짜를 반환하는가 (D8) | **T05** (도메인 기반) | **별도 프로세스 두 개**를 `TZ=UTC`와 `TZ=Asia/Seoul`로 각각 실행해 같은 결과가 나오는지 확인한다. 한 프로세스 안에서 `process.env.TZ`를 바꾸는 방식으로 대체하지 않는다 |
| `deriveDisplayStatus`, `getWeekRange`의 날짜 경계 | T05 | §3.3의 6케이스, 월요일 시작·월 넘김 (§7.1) |
| 실제 `today` 확정 경로 (요청 단위 단일 `today`) | T12 (대시보드 API) | §5.1의 단일 집계 응답 |

`tests/env.test.ts`가 통과하고도 `getToday`가 로컬 `Date` getter를 잘못 쓰면 T02는 전부 초록이다. **그 결함은 T05가 잡는다.** T05 스펙을 쓸 때 위 표의 첫 줄을 그 태스크의 완료 조건으로 반드시 포함해야 한다.

## 완료 조건

```
node -v                                        → 메이저가 22 · 24 · 26 중 하나 (D21)
npm ci                                         → 종료 코드 0
npm run typecheck                              → 에러 0
npm run lint                                   → 에러 0
npm test -- --reporter=verbose                 → 실패 0건. 위 정상 케이스 1~6
                                                 (5b·6b 포함)의 테스트명이 모두
                                                 출력에 나타난다
npm run e2e                                    → 실패 0건. 정상 케이스 7~8 통과
npm run build                                  → 성공
npm ls @playwright/test playwright-core        → 출력을 보고에 포함
npx playwright --version                       → 출력을 보고에 포함
```

**누적 테스트 개수를 완료 조건으로 쓰지 않는다.** 대신 이 스펙에 명명된 테스트 이름이 `--reporter=verbose` 출력에 모두 나타나는 것으로 판정한다. 개수 합산은 후속 태스크가 테스트를 추가할 때마다 어긋나며, 그 어긋남은 실제 결함이 아니다.

완료 보고에는 `npm test`, `npm run e2e`, 위반 케이스 9~12(11b·11c 포함)의 **실제 출력 전문**을 포함한다.

## 금지 사항

- `src/` 아래에 파일을 만들지 않는다. 이 태스크는 테스트 대상 코드를 추가하지 않는다.
- **T01이 만든 파일(`.nvmrc`, `package.json`의 T01 항목, `src/app/**`)을 영구 수정하지 않는다.** 위반 케이스 11·11b·12는 검증을 위한 임시 수정이며 **반드시 원복하고, 원복 후 `git diff`로 확인한다.** `.nvmrc`와 `src/app/**`은 `변경 대상 파일` 목록에 없으므로 최종 커밋에 나타나서는 안 된다 (`package.json`은 스크립트·devDependency 추가만 허용하며 `engines.node`는 건드리지 않는다).
- `.nvmrc`나 `engines.node`의 값을 **영구적으로** 바꾸지 않는다. `.nvmrc = 22` 또는 허용 집합 {22, 24, 26}이 맞지 않다고 판단되면 멈추고 보고한다 — D21을 갱신하는 것은 설계자의 일이다.
- `SUPPORTED_NODE_MAJORS`를 `>=` 비교로 바꾸거나 목록에 없는 메이저를 추가하지 않는다 (DR-03).
- `.npmrc`를 만들거나 `engine-strict`를 설정하지 않는다. 지원 목록 강제는 요구사항 9의 테스트가 담당한다 (D21).
- CI에 Node 버전을 하드코딩하지 않는다. `node-version-file`만 쓴다.
- Prisma, Zod 등 후속 태스크의 의존성을 추가하지 않는다.
- 테스트 유틸 라이브러리(`@testing-library/*`, `jsdom`, `happy-dom`, `msw` 등)를 추가하지 않는다.
- 커버리지 도구를 추가하지 않는다.
- `vitest.config.ts`의 `environment`를 `jsdom`으로 바꾸지 않는다. 현재 테스트 대상은 전부 Node 코드다.
- `tests/setup.ts`에 TZ 설정 외의 로직을 넣지 않는다.
- `tests/env.test.ts`에 애플리케이션 함수를 import 하지 않는다. 이 파일의 범위는 실행 환경이다 (DR-04).

## 스펙 미정 사항

| # | 지점 | 결정 |
|---|---|---|
| 1 | Node 버전 | **허용 집합 {22, 24, 26}, CI 기준선 22, 기준선의 정의처는 `.nvmrc`** (D21). CI는 `node-version-file`로 읽는다. 허용 집합은 `engines.node`와 `SUPPORTED_NODE_MAJORS`가 함께 선언하고 요구사항 9의 테스트가 대조한다 |
| 2 | Playwright 버전 | 범위 `^1.50.0`, 정확한 버전은 lockfile. 설치 버전을 보고에 기록한다. 향후 릴리스가 지원 목록을 바꾸면(특히 Node 22 제외) 중단 후 보고 |
| 3 | E2E 브라우저 | **chromium 하나만.** 아이 기기는 태블릿 1대이고(UR-20) 단일 가족용 시스템이므로(UR-14) 브라우저 호환성은 이 앱의 위험 요소가 아니다. 데스크톱 지원(UR-20.2)은 같은 chromium 엔진 위에서 폭만 달라지는 문제다 |
| 4 | E2E 뷰포트 | **1024×768 고정** (§6.4의 기준 폭). 세로 768px 검증은 화면 태스크에서 개별 스펙으로 추가한다 |
| 5 | `E2E_TEST_MODE`를 지금 켜두는 것 | **켜둔다.** 값을 읽는 코드는 T09에서 생기며 그때까지 효과가 없다. E2E 서버 기동 설정을 한 파일에 모으기 위한 선택이다 (D20) |
| 6 | `webServer.env`의 병합 여부 | 병합되지 않아 `PATH`를 잃으면 요구사항 12의 방식으로만 해결한다 |
| 7 | CI에서 E2E를 별도 job으로 분리 | **분리한다.** `needs: ci`로 순서를 두어 단위 테스트가 깨진 상태에서 느린 E2E를 돌리지 않는다 |
| 8 | vitest 워커 병렬성 | 기본값을 쓴다. 통합 테스트의 DB 격리는 T03의 `tests/helpers/db.ts`가 파일별 임시 DB로 보장한다 |
| 9 | Playwright 재시도 | CI에서만 1회. 로컬은 0 — 로컬에서 불안정한 테스트를 재시도로 가려서는 안 된다 |
| 10 | 스모크 테스트의 수명 | `tests/env.test.ts`는 **영구 유지**한다. `e2e/smoke.spec.ts`는 T14에서 오늘 화면 E2E로 대체되므로 그때 삭제한다 |
| 11 | D8 도메인 검증의 위치 | **T05.** 이 태스크의 "이 태스크가 검증하지 않는 것" 표가 이관 내용을 정의한다 (DR-04) |
