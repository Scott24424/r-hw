# T02 테스트 하니스

## 목표

vitest(단위·통합)와 Playwright(E2E)를 설치·설정하고, 두 프레임워크가 실제로 도는 것을 스모크 테스트와 CI로 증명한다.

## 선행 태스크

T01

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

**이 목록 밖의 파일은 생성·수정하지 않는다.** 특히 `src/` 아래에 아무것도 만들지 않는다.

## 구현 요구사항

1. 아래 devDependency만 추가한다. 다른 패키지를 추가하지 않는다.

```
vitest        ^3.0.0
@playwright/test  ^1.50.0
```

2. `package.json`의 `scripts`에 아래 3개를 **추가**한다. 기존 스크립트는 수정하지 않는다.

```jsonc
"test": "vitest run",
"test:watch": "vitest",
"e2e": "playwright test"
```

3. `vitest.config.ts`를 아래 내용으로 작성한다.

```ts
import { fileURLToPath } from "node:url";
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    environment: "node",
    include: ["src/**/*.test.ts", "tests/**/*.test.ts"],
    exclude: ["node_modules/**", ".next/**", "e2e/**"],
    setupFiles: ["./tests/setup.ts"],
    // D8: 프로세스 TZ가 UTC여도 도메인 함수가 KST 달력 날짜를 정확히 내야 한다.
    // 기본을 UTC로 고정해, 로컬 시각에 의존하는 코드가 곧바로 실패하게 만든다.
    env: { TZ: "UTC" },
    testTimeout: 10_000,
  },
  resolve: {
    alias: { "@": fileURLToPath(new URL("./src", import.meta.url)) },
  },
});
```

4. `include` 패턴이 **`e2e/`를 제외**해야 한다. 제외하지 않으면 vitest가 Playwright 스펙을 실행하려다 실패한다.

5. `tests/setup.ts`는 `process.env.TZ = "UTC";` 한 줄과 그 이유(D8)를 적은 주석을 담는다. 이후 태스크가 전역 셋업을 추가할 자리다.

6. `tests/env.test.ts`는 D8이 의존하는 **실행 환경 능력**을 검증한다. 세 개의 테스트를 아래 이름 그대로 작성한다.

```ts
describe("실행 환경", () => {
  it("같은 순간을 Asia/Seoul과 UTC에서 다른 달력 날짜로 포매팅한다", ...);
  it("Asia/Seoul 타임존을 Intl이 인식한다", ...);
  it("단위 테스트 프로세스의 TZ가 UTC다", ...);
});
```

기준 순간은 `new Date("2026-08-01T15:00:00.000Z")`를 쓴다. 이 순간은 KST로 `2026-08-02 00:00`이다 — D8이 설명하는 "서버가 UTC면 하루가 어긋난다"의 정확한 경계다.

| 검증 | 기대 |
|---|---|
| `Intl.DateTimeFormat("en-CA", { timeZone: "Asia/Seoul", year: "numeric", month: "2-digit", day: "2-digit" }).format(기준 순간)` | `"2026-08-02"` |
| 같은 포매터의 `timeZone: "UTC"` | `"2026-08-01"` |
| `Intl.supportedValuesOf("timeZone").includes("Asia/Seoul")` | `true` |
| `process.env.TZ` | `"UTC"` |

이 테스트가 실패하면 Node의 ICU 데이터가 불완전한 것이며, **D8·§4·§3.4가 전부 틀린 값을 낸다.** 그 경우 진행하지 말고 보고한다.

7. `playwright.config.ts`를 아래 내용으로 작성한다.

```ts
import { defineConfig, devices } from "@playwright/test";

const BASE_URL = "http://127.0.0.1:3000";

export default defineConfig({
  testDir: "./e2e",
  // E2E는 하나의 SQLite 파일을 공유하므로 병렬 실행하지 않는다.
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

8. `workers: 1`과 `fullyParallel: false`를 반드시 유지한다. 후속 태스크의 E2E가 같은 SQLite 파일을 쓰므로 병렬 실행하면 서로의 데이터를 덮어쓴다.

9. `e2e/smoke.spec.ts`는 T01이 만든 임시 화면을 검증한다.

```ts
test("루트 화면이 렌더링된다", async ({ page }) => {
  await page.goto("/");
  await expect(page.getByRole("heading", { level: 1 })).toHaveText("r-hw");
});
```

10. `.gitignore`에 아래를 **추가**한다. 기존 항목은 지우지 않는다.

```
/test-results/
/playwright-report/
/blob-report/
/playwright/.cache/
```

11. `.github/workflows/ci.yml`을 아래 내용으로 **전체 교체**한다. T01에서 `package.json`이 생겼으므로 기존의 "파일이 없으면 건너뜀" 조건 분기는 더 이상 필요 없고, 오히려 스크립트 이름이 잘못돼도 CI가 초록으로 통과하는 위험을 만든다.

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
          node-version: "20"
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
          node-version: "20"
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

12. **프로젝트 전체의 테스트 파일 배치 규약을 이 태스크에서 확정한다.** 후속 태스크는 예외 없이 이 규약을 따른다.

| 종류 | 위치 | 예 |
|---|---|---|
| 단위 테스트 | 대상 파일 옆에 `*.test.ts`로 콜로케이트 | `src/domain/clock.ts` → `src/domain/clock.test.ts` |
| 통합 테스트 (DB 필요) | `tests/integration/*.test.ts` | `tests/integration/seed.test.ts` |
| 공용 테스트 헬퍼 | `tests/helpers/*.ts` | `tests/helpers/db.ts` |
| 환경·전역 셋업 | `tests/setup.ts`, `tests/*.test.ts` | `tests/env.test.ts` |
| E2E | `e2e/*.spec.ts` | `e2e/today.spec.ts` |

E2E만 확장자가 `.spec.ts`다. 이 차이가 vitest와 Playwright의 수집 범위를 갈라놓는다.

## 비즈니스 규칙

| 규칙 | 위반 시 동작 |
|---|---|
| 단위 테스트는 프로세스 TZ가 UTC인 상태에서 돈다 (D8) | `tests/env.test.ts`의 세 번째 테스트가 실패 |
| Node 실행 환경은 완전한 IANA 타임존 데이터를 가져야 한다 (D8) | `tests/env.test.ts`의 첫 두 테스트가 실패. **이 경우 진행하지 말고 보고** |
| E2E는 프로덕션 빌드로 돈다 (D16-e) | `webServer.command`가 `npm run dev`이면 완료 조건 미충족 |
| E2E는 직렬 실행한다 | `workers`가 1이 아니면 완료 조건 미충족 |
| CI는 스크립트 부재를 조용히 넘기지 않는다 | 스크립트 이름이 틀리면 CI가 실패해야 한다 (요구사항 11) |

## 테스트 케이스

### 정상 케이스

| # | 케이스명 | 파일 · 테스트명 | 입력 | 기대 결과 |
|---|---|---|---|---|
| 1 | 타임존별 날짜 분기 | `tests/env.test.ts` › `같은 순간을 Asia/Seoul과 UTC에서 다른 달력 날짜로 포매팅한다` | `2026-08-01T15:00:00.000Z` | Seoul `"2026-08-02"`, UTC `"2026-08-01"` |
| 2 | 타임존 인식 | `tests/env.test.ts` › `Asia/Seoul 타임존을 Intl이 인식한다` | — | `Intl.supportedValuesOf("timeZone")`에 `"Asia/Seoul"` 포함 |
| 3 | 테스트 TZ 기본값 | `tests/env.test.ts` › `단위 테스트 프로세스의 TZ가 UTC다` | — | `process.env.TZ === "UTC"` |
| 4 | E2E 스모크 | `e2e/smoke.spec.ts` › `루트 화면이 렌더링된다` | `GET /` | `<h1>` 텍스트가 `r-hw` |

### 규칙 위반 케이스

| # | 케이스명 | 입력 | 기대 결과 |
|---|---|---|---|
| 5 | 실패하는 테스트가 실제로 CI를 깨는가 | `tests/env.test.ts`에 `expect(1).toBe(2)`를 임시로 추가 | `npm test` 종료 코드 ≠ 0. **확인 후 되돌린다** |
| 6 | E2E 실패가 감지되는가 | `e2e/smoke.spec.ts`의 기대 텍스트를 `r-hw!`로 임시 변경 | `npm run e2e` 종료 코드 ≠ 0. **확인 후 되돌린다** |

5·6번은 하니스가 실패를 실제로 잡는지 확인하는 절차다. **완료 보고에 두 명령의 실제 출력을 포함하고, 코드는 원상 복구된 상태여야 한다.**

### 경계 케이스

| # | 케이스명 | 확인 방법 | 기대 결과 |
|---|---|---|---|
| 7 | vitest가 E2E 파일을 수집하지 않음 | `npm test` 출력 | 실행된 테스트 파일에 `e2e/smoke.spec.ts`가 없음 |
| 8 | Playwright가 단위 테스트를 수집하지 않음 | `npm run e2e` 출력 | 실행된 스펙이 `e2e/smoke.spec.ts` 1개 |
| 9 | 기존 `.gitignore` 항목 보존 | `git diff .gitignore` | 삭제된 줄 0줄 |
| 10 | E2E 서버가 프로덕션 빌드로 뜸 | `npm run e2e` 로그 | `next build` 실행 후 `next start`가 뜬다 |

## 완료 조건

```
npm run typecheck  → 에러 0
npm run lint       → 에러 0
npm test           → 3 passed (tests/env.test.ts)
npm run e2e        → 1 passed (e2e/smoke.spec.ts)
npm run build      → 성공
```

완료 보고에는 `npm test`와 `npm run e2e`의 **실제 출력 전문**을 포함한다.

## 금지 사항

- `src/` 아래에 파일을 만들지 않는다. 이 태스크는 테스트 대상 코드를 추가하지 않는다.
- Prisma, Zod 등 후속 태스크의 의존성을 추가하지 않는다.
- 테스트 유틸 라이브러리(`@testing-library/*`, `jsdom`, `happy-dom`, `msw` 등)를 추가하지 않는다. 필요해지는 태스크의 스펙에서 도입한다.
- 커버리지 도구를 추가하지 않는다.
- `vitest.config.ts`의 `environment`를 `jsdom`으로 바꾸지 않는다. 현재 테스트 대상은 전부 Node 코드다.
- `tests/setup.ts`에 TZ 설정 외의 로직을 넣지 않는다.
- T01이 만든 `src/app/page.tsx`의 문자열을 바꾸지 않는다. E2E 스모크가 의존한다.

## 스펙 미정 사항

| # | 지점 | 결정 |
|---|---|---|
| 1 | E2E 브라우저 | **chromium 하나만.** 아이 기기는 태블릿 1대이고(Q3), 브라우저 호환성은 이 앱의 위험 요소가 아니다 |
| 2 | E2E 뷰포트 | **1024×768 고정** (§6.4의 기준 폭). 세로 768px 검증은 화면 태스크에서 개별 스펙으로 추가한다 |
| 3 | `E2E_TEST_MODE`를 지금 켜두는 것 | **켜둔다.** 값을 읽는 코드는 T09에서 생기며, 그때까지는 아무 효과가 없다. E2E 서버 기동 설정을 한 파일에 모으기 위한 선택이다 (D20) |
| 4 | CI에서 E2E를 별도 job으로 분리 | **분리한다.** `needs: ci`로 순서를 두어, 단위 테스트가 깨진 상태에서 느린 E2E를 돌리지 않는다 |
| 5 | vitest 워커 병렬성 | 기본값을 쓴다. 통합 테스트의 DB 격리는 T04의 `tests/helpers/db.ts`가 파일별 임시 DB로 보장한다 |
| 6 | Playwright 재시도 | CI에서만 1회. 로컬은 0 — 로컬에서 불안정한 테스트를 재시도로 가려서는 안 된다 |
| 7 | 스모크 테스트를 나중에 지울 것인가 | **남긴다.** `tests/env.test.ts`는 D8의 전제를 지키는 영구 테스트다. `e2e/smoke.spec.ts`는 T14에서 오늘 화면 E2E로 대체되므로 그때 삭제한다 |
