# T01~T04 SPEC 독립 검증

## 전체 판정

**BLOCK**

- T01: **PASS WITH CHANGES**
- T02: **BLOCK**
- T03: **BLOCK**
- T04: **BLOCK**
- Finding: **P0 0건 / P1 7건 / P2 4건 / P3 3건**
- 구현 허용: **아니오**. P1 7건을 먼저 해소하고 독립 재검토해야 한다.

핵심 차단 사유는 다음과 같다.

1. T02의 `@playwright/test: ^1.50.0`은 현재 1.x 최신 버전까지 허용하지만, 현재 Playwright 공식 요구사항은 Node 22 이상이고 CI는 Node 20으로 고정되어 있다.
2. T03은 T02가 만드는 Vitest 스크립트·설정·CI 구조를 사용하면서 선행 태스크를 T01만 지정했다.
3. T03의 D19 검증은 제시된 스크립트에 기본값 패턴이 3개뿐인데 테스트는 4개 이상을 요구하며, `.env`를 금지하면서 `prisma validate`에 `DATABASE_URL`도 주입하지 않는다.
4. T04는 T02의 테스트 하니스가 필수인데 선행 태스크에서 누락했다.
5. T04의 테스트는 9권·10블록·27과제 표 전체를 대조하지 않아 잘못된 시드도 PASS할 수 있다.
6. T04의 `force` 삭제·재생성에 트랜잭션이 없고 Book upsert의 update 분기가 정해지지 않아 기존 데이터의 부분 삭제·덮어쓰기 위험이 있다.
7. T04 완료 명령은 개발 DB가 비어 있다고 가정하므로 기존 데이터가 있는 안전한 환경에서는 명세된 출력으로 완료할 수 없다.

## 검증 범위

- 저장소: `/Volumes/SSD_1TB/Projects/r-hw`
- 물리 경로로 표시된 동일 작업공간: `/Users/minim4/dev/r-hw`
- 브랜치: `docs/specs-batch1`
- 기준 브랜치: 로컬 `main` (`1deac43`)
- 대상 SPEC:
  - `docs/specs/T01-scaffold.md`
  - `docs/specs/T02-test-harness.md`
  - `docs/specs/T03-prisma-schema.md`
  - `docs/specs/T04-seed.md`
- 검증 관점: 개별 완료 가능성, 선행 관계, 설계·결정 정합성, 파일 범위, 의존성·Node 호환성, 로컬/CI 동등성, 실패 검출력, 데이터 격리·복구·롤백, 순차 Merge 및 충돌 위험
- 제외: 구현, 패키지 설치, SPEC/설계/운영 코드 수정, 브랜치 변경, commit/push/PR/merge/deploy

## 읽은 파일

처음부터 끝까지 읽음:

- `AGENTS.md` (실체는 `CLAUDE.md`를 가리키는 심볼릭 링크)
- `CLAUDE.md`
- `README.md`
- `docs/architecture.md`
- `docs/decisions.md`
- `docs/specs/T01-scaffold.md`
- `docs/specs/T02-test-harness.md`
- `docs/specs/T03-prisma-schema.md`
- `docs/specs/T04-seed.md`
- `.github/workflows/ci.yml`
- `.gitignore`
- `sync-main.sh`

관련 원자료를 직접 확인함:

- `docs/mockups/plan-20days.jpg`
- `docs/mockups/daily-schedule.jpg`

`git ls-files`와 `find docs .github/workflows` 결과, 위 두 설계 문서와 두 mockup 외에 추가 설계 문서는 없다. 추적된 `r-hw` 항목은 `/Volumes/SSD_1TB/projects/r-hw`를 가리키는 심볼릭 링크이며 설계 문서가 아니다.

외부 호환성은 다음 공식 문서로 교차 검증했다.

- [Next.js 15 ESLint](https://nextjs.org/docs/15/pages/api-reference/config/eslint): FlatCompat로 `next/core-web-vitals`, `next/typescript`를 확장하는 구성이 유효하다.
- [Next.js 15 CLI](https://nextjs.org/docs/15/app/api-reference/cli/next): `next typegen` 없이 `tsc --noEmit`만 실행하면 생성 라우트 타입을 검증하지 못한다.
- [Next.js TypeScript](https://nextjs.org/docs/15/app/api-reference/config/typescript): `next-env.d.ts`는 생성물이며 ignore 대상이라는 T01 설명과 일치한다.
- [Tailwind PostCSS 설치](https://tailwindcss.com/docs/installation/using-postcss): `@tailwindcss/postcss`와 `@import "tailwindcss"` 구성은 v4 방식과 일치한다.
- [Playwright 설치·시스템 요구사항](https://playwright.dev/docs/intro): 현재 릴리스는 Node 22/24/26을 지원 대상으로 명시한다.
- [Playwright CI](https://playwright.dev/docs/ci), [브라우저 설치](https://playwright.dev/docs/browsers), [webServer](https://playwright.dev/docs/test-webserver): `install --with-deps chromium`, workers 1, webServer 환경 상속 방식은 유효하다.
- [Prisma DB 기능 표](https://www.prisma.io/docs/orm/reference/database-features): SQLite enum은 Prisma ORM 6.2.0부터 지원된다는 D13 전제와 일치한다.
- [Prisma Schema API](https://www.prisma.io/docs/orm/reference/prisma-schema-reference): `env("DATABASE_URL")`을 쓰는 CLI 실행에는 연결 문자열 주입이 필요하다.
- [Prisma SQLite](https://www.prisma.io/docs/orm/v6/overview/databases/sqlite): SQLite enum은 Prisma 계층에서 구현되며 SQLite DB 자체의 enum 제약은 아니다.
- [Vitest 3 config](https://v3.vitest.dev/config/): `environment`, `env`, `setupFiles` 사용은 유효하다.

## 실행한 읽기 전용 명령

저장소에서 실행:

```text
pwd
git status --short --branch
git log -5 --oneline --decorate
git ls-files
git diff --stat main...docs/specs-batch1
git diff --name-status main...docs/specs-batch1
git diff --find-renames main...docs/specs-batch1 -- docs/architecture.md docs/decisions.md
wc -l <검토 문서들>
sed -n <범위> <검토 문서>
nl -ba <검토 문서> | sed -n <범위>
git ls-files -s AGENTS.md CLAUDE.md r-hw
find docs .github/workflows -maxdepth 3 -type f -print
ls -ld <저장소·심볼릭 링크 경로>
node -v
node -e <Intl Asia/Seoul·UTC 경계 확인>
```

확인된 초기 상태:

```text
## docs/specs-batch1...origin/docs/specs-batch1
13a9c57 (HEAD -> docs/specs-batch1, origin/docs/specs-batch1) docs: T01~T04 구현 스펙 및 D19·D20 결정 추가
1deac43 (origin/main, origin/HEAD, main) Merge pull request #5 from Scott24424/chore/update-claude-md
```

초기 작업 트리는 깨끗했다. `main...docs/specs-batch1` 차이는 `architecture.md`, `decisions.md` 수정과 T01~T04 SPEC 추가, 총 6개 파일이다. 로컬 Node는 `v24.18.0`이었고 Intl 경계 확인은 Seoul `2026-08-02`, UTC `2026-08-01`, `Asia/Seoul` 지원 `true`였다. 이는 Node 20 직접 검증을 대신하지 않는다.

패키지 설치와 구현 명령은 금지되어 실행하지 않았다.

## 태스크 의존관계 검증

필수 순서는 **T01 → T02 → T03 → T04**다.

| 검증 항목 | 판정 | 근거 |
|---|---|---|
| T01 선행 없음 | 타당 | 저장소에 `package.json`과 앱 스캐폴드가 없다. |
| T02가 T01만 의존 | 타당 | 앱, npm 스크립트, lockfile을 전제로 테스트 하니스를 추가한다. Prisma는 필요 없다. |
| T03이 T01만 의존 | 부당 | `src/server/prisma.test.ts`, `npm test`, `vitest.config.ts`의 수집 규약, T02가 교체한 CI 구조를 전제로 한다. |
| T04가 T03만 의존 | 부당 | `tests/integration/*.test.ts`, `createTestDb`, `vitest.config.ts` 수정, `npm test`가 T02를 요구한다. |
| T02와 T03 병렬 구현 | 불가 | `package.json`, `package-lock.json`, `.gitignore`, `.github/workflows/ci.yml`을 동시에 수정하고 T03 테스트가 T02 하니스에 의존한다. |
| T03 테스트를 T02 없이 실행 | 불가 | T01에는 `test` 스크립트, Vitest 의존성, 설정이 없다. |
| T04 통합 테스트 | T02와 T03 모두 필요 | T02가 runner/config를, T03이 Prisma schema/client/migration/WAL 함수를 제공한다. |
| 순차 Merge 안정성 | 현재 불가 | T03 단독 완료 조건과 D19 검증이 자체 모순이고 T04 완료가 개발 DB 상태에 의존한다. |

T02와 T03을 병렬 개발한 뒤 단순 Merge하는 방식도 허용할 수 없다. 네 공통 파일의 의미가 연결되어 있고, T03 CI 패치는 T02가 이미 조건부 CI를 전체 교체했다는 전제에서만 정확히 적용된다.

## T01 판정과 Findings

**판정: PASS WITH CHANGES**

확인된 정합성:

- Next.js 15 + React 19 + Tailwind 4 조합과 App Router 최소 파일은 일관적이다.
- Tailwind v4 PostCSS 구성, Next.js 15 FlatCompat 구성, `next-env.d.ts` ignore 설명은 공식 문서와 일치한다.
- `package.json`의 build/start/serve/lint/typecheck 기본 스크립트와 lockfile 요구는 직접 스캐폴딩에 충분하다.
- `next.config.ts`, 루트 layout/page, global CSS 외에 필수 운영 파일 누락은 확인되지 않았다.

### DR-01

- **심각도:** P2
- **대상 SPEC:** T01
- **정확한 위치:** `package.json` 스크립트 요구사항 2의 `typecheck`(43~49행), `tsconfig.json` include(74~99행), 완료 조건(192~201행)
- **문제:** `typecheck`가 `tsc --noEmit`만 실행한다. `next-env.d.ts`와 `.next/types`는 ignore된 생성물인데, 깨끗한 checkout에서 typecheck가 build보다 먼저 실행되므로 Next.js가 생성하는 라우트 타입을 검사하지 않는다.
- **재현 또는 발생 조건:** T01 구현 후 `.next/`와 `next-env.d.ts`가 없는 깨끗한 checkout에서 `npm ci && npm run typecheck`를 실행한다. 이후 `npm run build`를 한 환경과 typecheck 범위가 달라진다.
- **영향:** CI의 typecheck가 잘못된 typed route/page/layout 계약을 놓칠 수 있고, 로컬에서 build를 한 적이 있는지에 따라 검사 범위가 달라진다. T01의 “참/거짓 판정 가능한 타입 검사”가 완전하지 않다.
- **근거:** Next.js 15 공식 CLI 문서는 생성 라우트 타입을 검사하려면 `next typegen && tsc --noEmit` 순서가 필요하다고 명시한다. T01의 `^15.0.0`은 현재 15.5.x를 선택하며 `next typegen`은 15.5부터 제공된다.
- **권장 수정:** `typecheck`를 `next typegen && tsc --noEmit`으로 바꾸고, 깨끗한 checkout과 build 이후 환경에서 같은 명령을 쓰도록 완료 조건과 T02 CI를 명시한다.
- **수정 후 검증 방법:** `.next/`와 `next-env.d.ts`가 없는 깨끗한 복제본에서 `npm ci && npm run typecheck`; 의도적으로 잘못된 typed route 계약을 넣어 실패 확인 후 원복; 이어서 `npm run build && npm run typecheck`도 같은 결과인지 확인한다.

### DR-02

- **심각도:** P3
- **대상 SPEC:** T01
- **정확한 위치:** 정상 케이스 5 “Tailwind 적용 확인”(167~174행)
- **문제:** HTML에 stylesheet 링크가 있다는 사실은 Tailwind 유틸리티가 실제로 생성·적용됐다는 증거가 아니다. 일반 global CSS만 있어도 이 조건은 PASS한다.
- **재현 또는 발생 조건:** Tailwind에서 소스 탐색이 잘못되어 유틸리티가 하나도 생성되지 않지만 `globals.css` 자체는 빌드되는 구성.
- **영향:** 목표에 포함된 Tailwind 설정이 실질적으로 작동하지 않아도 형식적 PASS가 가능하다.
- **근거:** 현재 page 요구사항은 Tailwind class를 하나도 요구하지 않고 테스트는 CSS 내용이나 계산 스타일을 보지 않는다.
- **권장 수정:** 임시 page에 결정적인 Tailwind class 하나를 지정하고 build 산출 CSS 또는 브라우저 computed style로 그 class의 효과를 확인한다. T14 교체 예정이라는 점은 유지할 수 있다.
- **수정 후 검증 방법:** 정상 구성에서 기대 computed style 확인, PostCSS plugin을 임시 제거했을 때 build 또는 스타일 검증 실패 확인 후 원복한다.

## T02 판정과 Findings

**판정: BLOCK**

확인된 정합성:

- Vitest의 Node 환경과 Playwright의 `e2e/*.spec.ts` 수집 경계는 충돌하지 않는다.
- `webServer.command: npm run serve`는 D16-e의 build+start 요구와 일치한다.
- CI의 Chromium `--with-deps` 설치와 workers 1 설정은 공식 Playwright CI 지침과 일치한다.
- “하나의 SQLite 파일 공유”는 T02 시점의 실제 테스트 전제가 아니라 후속 E2E를 위한 선제적 직렬화 정책이다. Prisma가 아직 없다는 것과 실행상 충돌하지는 않지만 주석은 미래 전제임을 분명히 하는 편이 낫다.

### DR-03

- **심각도:** P1
- **대상 SPEC:** T02
- **정확한 위치:** devDependency 요구사항 1(32~37행), CI Node 설정(168~196행), T01의 `engines.node >=20`
- **문제:** `@playwright/test: ^1.50.0`은 1.x 최신까지 허용한다. package-lock이 아직 없으므로 현재 설치 시 최신 1.x가 선택될 수 있지만, 현재 공식 Playwright 시스템 요구사항은 Node 22/24/26이고 CI는 Node 20으로 고정되어 있다.
- **재현 또는 발생 조건:** 현재 시점에 T01→T02를 새로 구현하여 lockfile을 생성하고 GitHub Actions의 `node-version: "20"`에서 `npm ci`, 브라우저 설치, `npm run e2e`를 실행한다.
- **영향:** unsupported Node 조합으로 설치 경고·실행 실패·향후 무통보 파손 가능성이 있으며 T02의 핵심 완료 조건과 CI가 보장되지 않는다.
- **근거:** semver `^1.50.0`은 `<2.0.0` 전체를 허용하고, 공식 Playwright 설치 문서는 현재 지원 Node를 22/24/26으로 명시한다. lockfile은 잘못 선택된 조합을 재현할 뿐 호환성을 만들지 않는다.
- **권장 수정:** Node 20 지원이 필수면 지원이 확인된 Playwright 버전 상한/정확 버전을 SPEC에 명시하고 CI에서 Node 20으로 검증한다. 최신 1.x를 쓸 것이라면 T01 `engines`, T02 CI와 macOS 검증 기준을 Node 22 이상으로 함께 올린다. 어느 쪽인지 Claude가 결정 문서와 SPEC에 한 번에 고정해야 한다.
- **수정 후 검증 방법:** 깨끗한 lockfile 생성 후 지정 최소 Node 버전에서 `npm ci`, `npx playwright install --with-deps chromium`, `npm run e2e`; `npm ls @playwright/test playwright-core`와 실제 버전을 완료 보고에 포함한다.

### DR-04

- **심각도:** P2
- **대상 SPEC:** T02
- **정확한 위치:** UTC 환경 테스트 요구사항 5~6(72~93행), 비즈니스 규칙(217~225행), 정상 케이스 1~3(229~236행)
- **문제:** 세 테스트는 ICU가 Seoul/UTC를 구분하고 프로세스 TZ가 UTC라는 실행 환경 전제만 확인한다. D8의 핵심인 “앱의 날짜 함수가 프로세스 TZ와 무관하게 Asia/Seoul 날짜를 반환한다”는 검증하지 않는다. 그런데 실패 설명은 D8 전체를 검증하는 것처럼 서술한다.
- **재현 또는 발생 조건:** 후속 `getToday`가 로컬 `Date` getter를 잘못 사용해도 T02의 세 테스트는 모두 PASS한다.
- **영향:** 환경 스모크를 도메인 규칙 검증으로 오인해 D8 결함을 놓칠 수 있다. UTC 한 환경만 고정하므로 “UTC와 KST에서 동일 결과”도 직접 증명하지 않는다.
- **근거:** 테스트 입력과 기대에는 애플리케이션 함수가 없고 `Intl` 및 `process.env.TZ`만 있다. architecture §7.1은 별도로 `getToday(now, tz)` 경계 테스트를 요구한다.
- **권장 수정:** T02 목표를 “D8 실행환경 전제 검증”으로 정확히 한정하고, 실제 D8 검증을 해당 도메인 태스크의 명시적 선행 완료 조건으로 연결한다. 가능하면 별도 프로세스를 `TZ=UTC`, `TZ=Asia/Seoul`로 각각 실행하는 테스트까지 후속 SPEC에 지정한다.
- **수정 후 검증 방법:** 환경 테스트는 그대로 통과시키고, 고의로 로컬 TZ에 의존하는 `getToday` 구현을 넣었을 때 후속 D8 테스트가 두 프로세스 중 하나에서 실패하는지 확인한다.

## T03 판정과 Findings

**판정: BLOCK**

확인된 정합성:

- 제시된 5 enum, 3 model, nullable 필드, 인덱스는 architecture §1.2와 시각 대조상 일치한다.
- Prisma 6.2.0부터 SQLite enum을 지원한다는 D13 전제는 공식 기능 표와 일치한다. 단, SQLite DB 자체 CHECK 제약이 아니라 Prisma 계층의 열거값 강제다.
- 기본 URL `file:./dev.db`가 schema 기준 `prisma/dev.db`를 가리킨다는 D19 경로 설계는 일관적이다.
- WAL을 마이그레이션 뒤 1회 적용하고 client를 disconnect하는 스크립트 구조는 의도와 일치한다.

### DR-05

- **심각도:** P1
- **대상 SPEC:** T03
- **정확한 위치:** 선행 태스크(7~9행), 변경 대상 테스트·CI 파일(20~27행), 테스트 요구사항 12(178~192행), 완료 조건(243~257행)
- **문제:** 선행 태스크를 T01만 지정했지만 T03은 Vitest 테스트 파일, `npm test`, 기존 3건 테스트, 그리고 T02가 전체 교체한 CI 구조를 전제로 한다.
- **재현 또는 발생 조건:** T01까지만 Merge된 브랜치에서 T03을 시작한다. `vitest` 의존성, `test` 스크립트, `vitest.config.ts`, `tests/setup.ts`가 없고 기존 CI는 조건부 shell block 구조다.
- **영향:** `src/server/prisma.test.ts`를 실행할 수 없고 7 passed 완료 조건을 만들 수 없다. CI 두 줄 패치의 적용 위치도 T02 이후 구조와 다르다. T02와 T03의 병렬 구현·독립 PR이 성립하지 않는다.
- **근거:** T01 금지사항은 Vitest/Playwright 추가를 금지하고 T02가 처음으로 test script/config를 만든다.
- **권장 수정:** T03 선행 태스크를 `T01, T02`가 아니라 단순히 `T02`로 고친다(T02가 T01을 전이적으로 포함). T02 Merge 뒤 T03 브랜치를 생성하도록 순서를 명시한다.
- **수정 후 검증 방법:** T02 결과만 checkout한 상태에서 T03 패치를 적용해 공통 파일 충돌이 없는지 확인하고 `npm test`가 기존 3건+신규 4건을 수집하는지 확인한다.

### DR-06

- **심각도:** P1
- **대상 SPEC:** T03
- **정확한 위치:** `prisma validate` 요구사항 4(74행), DB scripts 요구사항 8(150~158행), CI generate(171~176행), D19 테스트(178~192행), 완료 조건(245~252행)
- **문제:** D19 검증이 내부적으로 실행 불가능하다. 제시된 `DATABASE_URL:-` 스크립트는 `db:migrate`, `db:deploy`, `db:wal`의 3개뿐인데 테스트는 4개 이상을 요구한다. 동시에 `.env`를 금지하면서 완료 명령 `npx prisma validate`와 CI의 `npx prisma generate`에는 `DATABASE_URL` 기본값을 주입하지 않는다.
- **재현 또는 발생 조건:** 금지사항대로 `.env`와 셸 `DATABASE_URL`이 없는 깨끗한 환경에서 제시된 package.json을 만든다. 텍스트 테스트는 3개를 추출해 실패하고, datasource의 `env("DATABASE_URL")`을 해석하는 Prisma CLI 검증도 연결 문자열 부재로 실패할 수 있다.
- **영향:** 명세를 그대로 구현해도 T03 완료 조건과 CI를 동시에 만족할 수 없다. 구현자가 임의로 네 번째 위치나 환경 주입 방식을 선택해야 한다.
- **근거:** 요구사항 8의 코드 블록 자체에 패턴이 3개다. D19는 모든 CLI 경로에 기본값을 공급하려는 결정이고 Prisma 공식 schema 문서는 `env("DATABASE_URL")` 기반 CLI 실행에 환경변수가 필요하다고 설명한다.
- **권장 수정:** `db:generate`, `db:validate`에도 같은 기본값을 주입하고 모든 로컬·CI 명령이 npm script를 사용하게 한다. 예: `DATABASE_URL=${DATABASE_URL:-file:./dev.db} prisma generate|validate`. 테스트의 정확한 기대 개수는 실제 정의처 목록과 동일하게 고정하고 “4건 이상” 대신 예상 스크립트 이름 집합을 대조한다.
- **수정 후 검증 방법:** `env -u DATABASE_URL`에 해당하는 깨끗한 환경에서 `npm run db:generate`, `npm run db:validate`, `npm run db:migrate -- --name init`; package scripts 중 DB URL이 필요한 명령의 기본값 집합을 테스트로 정확히 대조한다.

### DR-07

- **심각도:** P2
- **대상 SPEC:** T03
- **정확한 위치:** schema 일치 요구사항 2~3(43~72행), 테스트 요구사항 12~13(178~202행), 경계 테스트 8~9(233~241행)
- **문제:** T03의 핵심 완료 조건인 “architecture §1.2와 정확히 같은 schema”가 눈검사와 index 개수 grep에만 의존한다. `prisma validate`는 유효한 다른 schema도 통과하며, index 개수가 같아도 컬럼이 틀릴 수 있다.
- **재현 또는 발생 조건:** nullable 필드 하나를 non-null로 바꾸거나 index 컬럼 순서를 바꾸되 Prisma 문법과 index 총 개수는 유지한다.
- **영향:** 후속 시드·서비스가 기대하는 null 의미, 진도 체인 조회 또는 목록 질의가 깨져도 T03 자동 검증은 PASS할 수 있다.
- **근거:** 네 Vitest 케이스는 URL 해석만 검사하고 DB schema를 조회하지 않는다. grep은 `CREATE INDEX`와 `CREATE UNIQUE INDEX`의 개수만 센다.
- **권장 수정:** 임시 migrated DB의 `sqlite_master`, `PRAGMA table_info`, `PRAGMA index_list/index_info`, foreign key 정보를 기대 테이블과 대조하는 통합 테스트를 T03 또는 T04에 명시한다. 최소한 생성 migration의 정확한 table/column/null/default/index 구조를 기계적으로 검증한다.
- **수정 후 검증 방법:** 각 핵심 필드 nullable/default/index 컬럼을 하나씩 의도적으로 바꿨을 때 구조 테스트가 실패하고, 원복 후 통과하는지 확인한다.

## T04 판정과 Findings

**판정: BLOCK**

확인된 정합성:

- 원자료와 architecture를 대조한 결과, 판독 불가한 7/29 한글책을 제외한 책 9권, 블록 10건, 과제 27건의 표와 날짜/orderIndex는 일치한다.
- `startUnit` 전부 null, `wimpy kid`만 PAGE, 빈 날짜 6개, 24시간 분 값은 D5/D9/D10/D11/D18과 일치한다.
- 임시 DB는 절대 file URL을 사용하고 복사본별 WAL을 켜므로 개발 DB와 논리적으로 분리할 수 있는 방향이다.

### DR-08

- **심각도:** P1
- **대상 SPEC:** T04
- **정확한 위치:** 선행 태스크(7~9행), 변경 대상 `vitest.config.ts`와 통합 테스트(15~23행), 완료 조건(235~245행)
- **문제:** 선행 태스크가 T03뿐이지만 T04는 T02가 만드는 Vitest 의존성, `test` script, `vitest.config.ts`, 테스트 수집 규약과 기존 3건 테스트를 직접 요구한다.
- **재현 또는 발생 조건:** 문서에 적힌 의존만 따라 T01→T03→T04를 시도한다. T03 자체도 T02 없이 실행되지 않고 T04가 수정할 `vitest.config.ts`가 없다.
- **영향:** 통합 테스트를 작성·수집할 수 없고 28 passed 완료 조건이 불가능하다.
- **근거:** T04의 28건 계산은 T02 3건 + T03 4건 + T04 21건을 명시적으로 합산한다.
- **권장 수정:** T04 선행 태스크를 `T03`으로 유지하려면 T03이 T02에 의존하도록 먼저 고쳐 전이 의존을 명시한다. 더 명확하게는 설명에 “T03을 통해 T02 포함”을 적는다.
- **수정 후 검증 방법:** T01→T02→T03을 순서대로 Merge한 checkout에서 T04 파일 목록이 모두 존재하고 `npm test`가 28건을 수집하는지 확인한다.

### DR-09

- **심각도:** P1
- **대상 SPEC:** T04
- **정확한 위치:** 시드 표 요구사항 2~5(47~118행), 테스트 케이스 1~19(199~231행)
- **문제:** 테스트가 9권·10블록·27과제의 정확한 기대 표를 전체 대조하지 않는다. 총 건수와 일부 표본·일반 불변식만 확인하므로 잘못된 제목, 언어, label, 시간, 과제 type/date/orderIndex/endUnit이 다수 있어도 PASS할 수 있다.
- **재현 또는 발생 조건:** 예를 들어 검사되지 않는 ScheduleBlock label을 바꾸고 start/end를 겹치지 않는 다른 값으로 이동하거나, 검사되지 않는 날짜의 DIARY/WORKSHEET 제목·type을 바꾸면서 총 27건과 날짜 범위를 유지한다.
- **영향:** 실물 자료를 추정 없이 정확히 옮긴다는 T04의 핵심 목표가 자동 검증되지 않는다. 잘못된 초기 데이터가 정상 배포될 수 있다.
- **근거:** 블록 테스트는 marker 수, 비겹침, matchType 개수, 범위만 보고 10개 row 전체를 비교하지 않는다. 과제 테스트도 7/29, 8/1, wimpy kid, 빈 날짜만 표본 확인한다. Book도 9개 전체의 모든 필드를 deep equality로 비교하지 않는다.
- **권장 수정:** ID/timestamp를 제외하고 정렬된 Book 9행, ScheduleBlock 10행, Assignment 27행을 SPEC 표에서 만든 상수와 exact deep equality로 비교한다. 일반 불변식 테스트는 별도로 유지한다.
- **수정 후 검증 방법:** 각 표의 임의 한 셀을 하나씩 바꿨을 때 exact fixture 테스트가 실패하는 mutation 검증을 하고 원복한다.

### DR-10

- **심각도:** P1
- **대상 SPEC:** T04
- **정확한 위치:** Book upsert 요구사항 2(47~61행), 재실행/force 요구사항 7(122~130행), 기존 데이터 보존 규칙(181~193행), 테스트 13~16(216~223행)
- **문제:** 삭제·upsert·재생성을 하나의 transaction으로 수행하라는 요구가 없고 Book upsert의 `update` 분기가 정의되지 않았다. 따라서 `force` 중간 실패 시 Assignment/ScheduleBlock만 삭제된 상태가 남을 수 있고, 기본 실행도 기존 동명 Book의 language/progressUnit/totalUnits/archivedAt을 시드값으로 덮어쓸 수 있다.
- **재현 또는 발생 조건:** 사용자 데이터가 있는 DB에서 `force` 실행 중 deleteMany 뒤 createMany가 실패하거나 프로세스가 종료된다. 또는 기존 `Big Note`의 `totalUnits`/`archivedAt`/단위를 사용자가 수정한 뒤 기본 seed를 재실행하고 구현자가 upsert update에 시드 필드를 넣는다.
- **영향:** 핵심 사용자 데이터의 전량/부분 손실 또는 무통보 변경 가능성이 있다. “기본은 사용자 데이터를 지우지 않는다”는 문구만으로 덮어쓰기와 실패 롤백을 막지 못한다.
- **근거:** 스펙은 동작 순서와 transaction 경계를 지정하지 않으며 upsert create/update payload를 구분하지 않는다. 테스트 13은 Assignment 1건 보존만 확인하고 기존 Book 및 ScheduleBlock 보존, 실패 롤백을 확인하지 않는다.
- **권장 수정:** force의 delete+recreate를 단일 `$transaction`으로 묶고 실패 시 전부 rollback하도록 명시한다. 기존 Book의 update 정책을 명시적으로 `update: {}` 등 비파괴 방식으로 정하고, force가 Book에는 어떤 영향을 주는지 문서화한다. 기본 모드에서 기존 Book·Block·Assignment의 모든 사용자 필드 보존 테스트를 추가한다.
- **수정 후 검증 방법:** 사용자 Book/Block/Assignment fixture를 만든 뒤 기본 seed에서 byte-equivalent 필드 보존 확인; force 중 의도적 실패를 주입해 transaction 전후 데이터가 동일한지 확인; 성공 force의 정확한 결과도 확인한다.

### DR-11

- **심각도:** P1
- **대상 SPEC:** T04
- **정확한 위치:** 비파괴 기본 동작(122~130행), package scripts(170~175행), 완료 조건(235~247행)
- **문제:** 완료 조건의 `npm run db:setup → books=9 blocks=10 assignments=27`은 기본 개발 DB가 비어 있을 때만 성립한다. 기존 블록 또는 과제가 있으면 설계대로 skip되어 0이 출력되며, SPEC은 기존 개발 데이터를 지우지 않고 완료 조건을 재현하는 방법을 제공하지 않는다.
- **재현 또는 발생 조건:** `prisma/dev.db`에 Assignment나 ScheduleBlock이 하나라도 있는 상태에서 T04 완료 검증을 실행한다.
- **영향:** 안전한 비파괴 구현이 오히려 완료 실패로 판정된다. 구현자가 출력 맞추기를 위해 개발 DB 삭제 또는 `SEED_FORCE=1`을 선택하면 사용자 데이터 손실로 이어질 수 있다.
- **근거:** skip 판정은 테이블 count가 0이 아닐 때이며 완료 출력은 skip=false/27·10을 고정한다. 검증용 별도 `DATABASE_URL`이나 사전 상태 조건은 없다.
- **권장 수정:** 완료 검증은 `.tmp/`의 새 절대 DB URL에 migrate/WAL/seed를 실행하고 `try/finally`로 정리하도록 명시한다. 개발 DB에서는 첫 실행과 재실행의 상태별 기대를 분리하고, 완료를 위해 force를 요구하지 않는다.
- **수정 후 검증 방법:** 사용자 데이터가 든 `prisma/dev.db`의 checksum/행을 전후 비교해 불변임을 확인하면서, 별도 임시 DB에서 9/10/27 및 두 번째 skip 출력을 재현한다.

### DR-12

- **심각도:** P2
- **대상 SPEC:** T04
- **정확한 위치:** 테스트 DB helper 요구사항 11~14(155~168행), 테스트 lifecycle(195~197행), 격리 테스트 21(232~233행), 템플릿 정책(262~270행)
- **문제:** cleanup 보장이 정상 반환 뒤 `afterEach`에만 있다. `createTestDb`가 복사 후 WAL 적용에서 실패하면 반환된 cleanup이 없고, 테스트 21에서 직접 만든 추가 DB 두 개의 cleanup도 명시되지 않았다. 템플릿은 migration 변경을 감지하지 않고 존재 여부만 보므로 stale schema를 계속 복사한다. `execFileSync`의 `env`가 기존 `process.env`를 보존해야 한다는 요구도 없다.
- **재현 또는 발생 조건:** migrate/WAL 단계 예외, 테스트 21 assertion 실패, 테스트 프로세스 중단, 또는 새 migration 추가 뒤 `.tmp/test-template.db`를 남긴 채 재실행한다. 구현자가 `env: { DATABASE_URL }`만 넘기면 macOS Homebrew PATH에서 `npx` 탐색도 실패할 수 있다.
- **영향:** 임시 `.db/-wal/-shm` 누적, 잘못된 schema로 인한 후속 테스트의 오진, macOS arm64 환경 종속 실패가 생긴다.
- **근거:** helper 내부 오류 경로의 `try/catch/finally`, 추가 DB cleanup, migration fingerprint, `{ ...process.env, DATABASE_URL }`가 명세에 없다. 수동 `rm -rf .tmp`는 자동 안전장치가 아니다.
- **권장 수정:** 생성 중인 모든 경로를 helper 내부 `try/catch`에서 정리하고, 테스트가 만든 DB 전부를 cleanup registry/`try/finally`로 해제한다. migration 파일 hash를 템플릿 메타데이터에 기록해 불일치 시 원자적으로 재생성한다. child env는 `{ ...process.env, DATABASE_URL: url }`로 명시한다.
- **수정 후 검증 방법:** migrate/WAL 실패를 유도한 뒤 `.tmp/` 잔여 파일이 없는지 확인; 테스트 21 종료 후 두 복사본의 세 sidecar가 모두 없는지 확인; migration hash 변경 후 새 템플릿이 만들어지는지 확인; macOS arm64 PATH에서 helper 실행 확인.

### DR-13

- **심각도:** P3
- **대상 SPEC:** T04
- **정확한 위치:** 비즈니스 규칙의 테스트 번호 참조(181~193행), 실제 테스트 목록(199~233행)
- **문제:** “판독 불가 항목”은 테스트 `10·13`을, “기존 데이터 보존”은 테스트 `12`를 가리키지만 실제 해당 테스트는 각각 `10·14`, `13`이다.
- **재현 또는 발생 조건:** 구현자나 리뷰어가 비즈니스 규칙 표의 번호를 따라 해당 검증을 찾는다.
- **영향:** 추적성이 깨지고 잘못된 테스트를 근거로 규칙이 검증됐다고 판단할 수 있다.
- **근거:** 실제 테스트 12는 wimpy kid 진도, 13은 기존 과제 보존, 14는 `김치` 미포함이다.
- **권장 수정:** 참조를 `10·14`, `13`으로 바로잡고 가능하면 번호 대신 고유 테스트명을 함께 적는다.
- **수정 후 검증 방법:** 모든 “테스트 N” 참조를 실제 목록과 기계적/수동 대조해 누락·중복이 없는지 확인한다.

## 태스크 간 충돌

1. **공통 파일 충돌:** T02와 T03은 `package.json`, `package-lock.json`, `.gitignore`, `.github/workflows/ci.yml` 네 파일을 모두 수정한다. 병렬 PR로 만들면 lockfile과 CI에 의미 충돌이 생긴다.
2. **T04의 누적 수정:** T04는 T03의 `db:setup`을 변경하고 T02의 `vitest.config.ts`를 변경한다. 두 선행 결과가 모두 Merge된 뒤에만 파일 범위가 성립한다.
3. **CI 순서:** T02가 조건부 CI를 전체 교체하고, T03이 그 결과에 Prisma generate/setup을 삽입하며, T04가 `db:setup`의 의미를 seed 포함으로 확장한다. 이 순서를 바꾸면 T03의 “두 곳만 수정” 지시가 적용되지 않는다.
4. **검증 명령 불일치:** T01/T02 CI는 clean checkout에서 typecheck 후 build를 실행해 생성 Next 타입을 놓친다(DR-01). T03은 URL 없는 validate/generate와 기본값 개수 모순으로 자체 완료가 불가능하다(DR-06). T04는 개발 DB 상태에 따라 출력이 달라진다(DR-11).
5. **순차 Merge 결론:** 현재 문서 그대로는 각 PR을 차례로 Merge해도 T03에서 중단된다. 의존성과 명령을 고친 뒤 T01→T02→T03→T04 순서로만 진행해야 한다.

## 구현 전 필수 수정

P1 해소 순서:

1. Node 지원 정책을 하나로 확정하고 T01 engines, T02 Playwright 범위, GitHub Actions Node 버전을 같은 기준으로 맞춘다(DR-03).
2. T03이 T02에 의존하도록 선행 관계와 PR 순서를 수정한다(DR-05).
3. D19 기본값을 validate/generate/migrate/deploy/WAL/seed의 모든 필요한 CLI 경로에 일관되게 공급하고 테스트 기대 개수를 실제 명령 집합과 맞춘다(DR-06).
4. T04가 T02+T03 결과를 필요로 함을 명시한다(DR-08).
5. 9권·10블록·27과제 전체 exact fixture 검증을 추가한다(DR-09).
6. seed/force를 transaction으로 만들고 Book update 및 사용자 데이터 보존 정책을 확정한다(DR-10).
7. T04 완료 검증을 격리된 새 임시 DB에서 수행해 개발 DB 상태·삭제와 분리한다(DR-11).

그 뒤 P2/P3를 반영하고 동일 기준으로 재리뷰한다. SPEC 변경이 D19/D20 또는 Node 지원 결정 자체를 바꾸면 `docs/decisions.md`도 함께 갱신해야 한다.

## 확인하지 못한 항목

- 사용자 지시로 패키지를 설치하지 않았으므로 실제 `package-lock.json` 해석 결과, `npm ci`, lint, typecheck, build, Vitest, Playwright, Prisma CLI 출력은 확인하지 못했다.
- 로컬 Node는 v24.18.0이므로 Node 20 런타임에서 직접 실행하지 않았다. Node 20/Playwright 판단은 공식 현재 지원 범위와 semver 분석에 근거한다.
- 구현 파일과 migration이 아직 없으므로 실제 SQLite 파일 위치, 생성 migration SQL, WAL 결과, PrismaClient 생명주기, CI 실행 로그는 확인하지 못했다.
- GitHub Actions hosted image와 네트워크 다운로드 상태는 실행하지 않았다. 다만 T02의 브라우저 설치 명령 자체는 공식 문서와 일치한다.
- 향후 T05/T09/T14/T17/T19 SPEC은 저장소에 없어 그 번호가 가리키는 실제 파일·범위는 확인할 수 없다. 현재 문서의 미래 참조로만 취급했다.
- `architecture.md` 12행은 “설계 결정 18건”이라고 쓰지만 실제 index와 참조는 D1~D20까지 모두 존재한다. 이는 **P3 공통 문서 정합성 문제(DR-14)** 다.

### DR-14

- **심각도:** P3
- **대상 SPEC:** T01~T04 공통 참조 문서
- **정확한 위치:** `docs/architecture.md` 12행, 같은 문서 308~329행, `docs/decisions.md` 16~39행
- **문제:** architecture 서두는 설계 결정이 18건이라고 쓰지만 현재 branch에는 D19·D20이 추가되어 20건이다.
- **재현 또는 발생 조건:** 서두의 개수를 기준으로 Decision 존재 여부를 검토한다.
- **영향:** 문서 버전과 참조 완전성에 대한 불필요한 의심을 만들고 검토 범위를 18건으로 잘못 제한할 수 있다.
- **근거:** architecture 결정 표와 decisions 색인은 D1~D20을 모두 포함하며 각 anchor도 실제 존재한다.
- **권장 수정:** “설계 결정 20건”으로 갱신하거나 변동 개수를 제거한다.
- **수정 후 검증 방법:** D-number unique count와 서두 표기를 대조하고 모든 architecture link anchor가 decisions에 존재하는지 확인한다.

## 권장 다음 작업

다음 담당자는 **Claude(SPEC 작성자)** 다.

1. 이 리뷰의 P1 7건을 우선 수정한다.
2. P2 4건과 P3 3건도 반영하거나, 반영하지 않는 항목은 문서 근거를 남긴다.
3. T03/T04 의존 순서와 공통 파일 Merge 순서를 명시한다.
4. 수정된 T01~T04 및 변경된 decisions/architecture만 독립 Codex 리뷰에 다시 제출한다.
5. 재리뷰가 PASS 또는 구현 허용 가능한 판정이 되기 전에는 T01 구현을 시작하지 않는다.
