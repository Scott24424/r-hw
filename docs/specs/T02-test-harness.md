# T02 테스트 하니스

## 목표

vitest(단위·통합)와 Playwright(E2E)를 설치·설정하고, 두 프레임워크가 실제로 도는 것을 스모크 테스트와 CI로 증명한다. 또한 D21의 Node 정책이 한 곳에서만 정의되는지 대조한다.

**이 태스크는 애플리케이션의 도메인 규칙을 검증하지 않는다.** 검증 대상은 (a) 하니스가 실제로 돌고 실패를 잡는가, (b) 실행 환경이 후속 태스크의 전제를 만족하는가, 두 가지뿐이다.

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

2. **Playwright 버전과 Node 정책 (D21, DR-03).** `^1.50.0`은 `<2.0.0` 전체를 허용하므로 현재 최신 1.x가 설치되고, 현행 Playwright의 시스템 요구사항은 **Node 22 / 24 / 26**이다. T01이 이미 `.nvmrc = 22`와 `engines.node = ">=22"`를 고정했으므로 이 조합은 지원 범위 안에 있다. 아래 세 가지를 지킨다.

   - 범위는 `^1.50.0`으로 두고 **정확한 버전은 `package-lock.json`이 고정한다.**
   - 설치 후 `npm ls @playwright/test playwright-core`와 `npx playwright --version`의 출력을 **완료 보고에 그대로 포함한다.**
   - 설치된 Playwright가 Node 22를 지원 대상에서 제외한다면(향후 릴리스에서 하한이 올라가는 경우) **진행하지 말고 보고한다.** `.nvmrc`를 임의로 올리지 않는다 — D21을 갱신하는 것은 설계자의 일이다.

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
  it("package.json engines.node가 >=22이다", ...);
  it("실행 중인 Node의 메이저 버전이 22 이상이다", ...);
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

9. Node 정책 검증은 D21의 "정의처는 하나"를 지킨다. 세 값을 exact match로 대조한다.

| 검증 | 기대 |
|---|---|
| `.nvmrc` 파일 내용을 trim한 값 | `"22"` |
| `package.json`의 `engines.node` | `">=22"` |
| `process.versions.node`의 메이저 정수 | `>= 22` |

앞의 두 값은 문자열 exact match다. 하나만 바뀌면 실패해야 한다 — 그것이 이 테스트의 목적이다 (D21의 대가 완화 장치).

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
| Node 버전 정의처는 `.nvmrc` 하나다 (D21) | `.nvmrc가 22이다` 또는 `package.json engines.node가 >=22이다`가 실패 |
| Playwright는 Node 22 이상에서 돈다 (D21) | `실행 중인 Node의 메이저 버전이 22 이상이다`가 실패, 또는 `npm run e2e`가 unsupported Node 경고·오류 |
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
| 4 | `.nvmrc가 22이다` | `tests/env.test.ts` | `.nvmrc` 내용 | trim 결과가 `"22"` |
| 5 | `package.json engines.node가 >=22이다` | `tests/env.test.ts` | `package.json` | `engines.node === ">=22"` |
| 6 | `실행 중인 Node의 메이저 버전이 22 이상이다` | `tests/env.test.ts` | `process.versions.node` | 메이저 `>= 22` |
| 7 | `루트 화면이 렌더링된다` | `e2e/smoke.spec.ts` | `GET /` | `<h1>` 텍스트가 `r-hw` |
| 8 | `Tailwind 유틸리티가 브라우저에서 실제로 적용된다` | `e2e/smoke.spec.ts` | `GET /` | `<h1>`의 computed `font-size`가 `42px` |

### 규칙 위반 케이스

| # | 케이스명 | 입력 | 기대 결과 |
|---|---|---|---|
| 9 | 실패하는 단위 테스트가 CI를 깨는가 | `tests/env.test.ts`에 `expect(1).toBe(2)`를 임시 추가 | `npm test` 종료 코드 ≠ 0 |
| 10 | 실패하는 E2E가 감지되는가 | `e2e/smoke.spec.ts`의 기대 텍스트를 `r-hw!`로 임시 변경 | `npm run e2e` 종료 코드 ≠ 0 |
| 11 | Node 정책 불일치가 감지되는가 | `.nvmrc`를 `20`으로 임시 변경 | `.nvmrc가 22이다`가 실패 |
| 12 | Tailwind 미적용이 감지되는가 | `src/app/page.tsx`의 `text-[42px]`를 임시 제거하고 `npm run e2e` | `Tailwind 유틸리티가 브라우저에서 실제로 적용된다`가 실패 |

9~12번은 하니스가 실패를 실제로 잡는지 확인하는 절차다. **네 명령의 실제 출력을 완료 보고에 포함하고, 코드는 원상 복구된 상태여야 한다.** 12번은 T01 파일을 임시 수정하므로 특히 원복을 확인한다.

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
node -v                                        → v22 이상
npm ci                                         → 종료 코드 0
npm run typecheck                              → 에러 0
npm run lint                                   → 에러 0
npm test -- --reporter=verbose                 → 실패 0건. 위 정상 케이스 1~6의
                                                 테스트명이 모두 출력에 나타난다
npm run e2e                                    → 실패 0건. 정상 케이스 7~8 통과
npm run build                                  → 성공
npm ls @playwright/test playwright-core        → 출력을 보고에 포함
npx playwright --version                       → 출력을 보고에 포함
```

**누적 테스트 개수를 완료 조건으로 쓰지 않는다.** 대신 이 스펙에 명명된 테스트 이름이 `--reporter=verbose` 출력에 모두 나타나는 것으로 판정한다. 개수 합산은 후속 태스크가 테스트를 추가할 때마다 어긋나며, 그 어긋남은 실제 결함이 아니다.

완료 보고에는 `npm test`, `npm run e2e`, 위반 케이스 9~12의 **실제 출력 전문**을 포함한다.

## 금지 사항

- `src/` 아래에 파일을 만들지 않는다. 이 태스크는 테스트 대상 코드를 추가하지 않는다.
- **T01이 만든 파일(`.nvmrc`, `package.json`의 T01 항목, `src/app/**`)을 영구 수정하지 않는다.** 위반 케이스 11·12는 검증을 위한 임시 수정이며 **반드시 원복하고, 원복 후 `git diff`로 확인한다.** 이 두 파일은 `변경 대상 파일` 목록에 없으므로 최종 커밋에 나타나서는 안 된다 (`package.json`은 스크립트·devDependency 추가만 허용).
- `.nvmrc`의 값을 **영구적으로** 바꾸지 않는다. 22가 맞지 않다고 판단되면 멈추고 보고한다 — D21을 갱신하는 것은 설계자의 일이다.
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
| 1 | Node 버전 | **22, 정의처는 `.nvmrc`** (D21). CI는 `node-version-file`로 읽는다 |
| 2 | Playwright 버전 | 범위 `^1.50.0`, 정확한 버전은 lockfile. 설치 버전을 보고에 기록한다. 향후 릴리스가 Node 22를 제외하면 중단 후 보고 |
| 3 | E2E 브라우저 | **chromium 하나만.** 아이 기기는 태블릿 1대이고(Q3) 브라우저 호환성은 이 앱의 위험 요소가 아니다 |
| 4 | E2E 뷰포트 | **1024×768 고정** (§6.4의 기준 폭). 세로 768px 검증은 화면 태스크에서 개별 스펙으로 추가한다 |
| 5 | `E2E_TEST_MODE`를 지금 켜두는 것 | **켜둔다.** 값을 읽는 코드는 T09에서 생기며 그때까지 효과가 없다. E2E 서버 기동 설정을 한 파일에 모으기 위한 선택이다 (D20) |
| 6 | `webServer.env`의 병합 여부 | 병합되지 않아 `PATH`를 잃으면 요구사항 12의 방식으로만 해결한다 |
| 7 | CI에서 E2E를 별도 job으로 분리 | **분리한다.** `needs: ci`로 순서를 두어 단위 테스트가 깨진 상태에서 느린 E2E를 돌리지 않는다 |
| 8 | vitest 워커 병렬성 | 기본값을 쓴다. 통합 테스트의 DB 격리는 T03의 `tests/helpers/db.ts`가 파일별 임시 DB로 보장한다 |
| 9 | Playwright 재시도 | CI에서만 1회. 로컬은 0 — 로컬에서 불안정한 테스트를 재시도로 가려서는 안 된다 |
| 10 | 스모크 테스트의 수명 | `tests/env.test.ts`는 **영구 유지**한다. `e2e/smoke.spec.ts`는 T14에서 오늘 화면 E2E로 대체되므로 그때 삭제한다 |
| 11 | D8 도메인 검증의 위치 | **T05.** 이 태스크의 "이 태스크가 검증하지 않는 것" 표가 이관 내용을 정의한다 (DR-04) |
