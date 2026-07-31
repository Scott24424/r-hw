# T01 프로젝트 스캐폴딩

## 목표

Next.js App Router + TypeScript + Tailwind + ESLint로 빈 저장소를 빌드·실행 가능한 상태로 만들고, 프로젝트의 Node 기준 버전을 고정한다.

## 선행 태스크

없음

## 구현 순서상의 위치

**T01 → T02 → T03 → T04.** T01은 이 순서의 첫 번째이며 선행이 없다. T02는 T01이 `main`에 Merge된 뒤에 브랜치를 만든다.

## 변경 대상 파일

생성:

- `.nvmrc`
- `package.json`
- `package-lock.json`
- `tsconfig.json`
- `next.config.ts`
- `postcss.config.mjs`
- `eslint.config.mjs`
- `src/app/layout.tsx`
- `src/app/page.tsx`
- `src/app/globals.css`

수정:

- `.gitignore`

11개 파일이다. "태스크당 10개 이내" 목표를 1개 초과하며, 초과분은 `.nvmrc`(한 줄 파일, D21의 정의처)다. 스캐폴딩은 파일을 나눌 수 없는 성질의 작업이므로 그대로 진행한다.

**이 목록 밖의 파일은 생성·수정하지 않는다.** `next-env.d.ts`와 `.next/`는 Next가 생성하며 `.gitignore`에 들어가므로 커밋 대상이 아니다.

## 구현 요구사항

1. `create-next-app`을 실행하지 않는다. 저장소에 이미 `docs/`, `CLAUDE.md`, `AGENTS.md`(심볼릭 링크), `README.md`, `.github/`, `sync-main.sh`가 있어 생성기가 이들을 덮어쓰거나 거부할 수 있다. 아래 파일들을 직접 작성한 뒤 `npm install`로 의존성을 설치한다.

2. `.nvmrc`는 아래 한 줄이다 (D21). **이 파일이 Node 버전의 정의처다.**

```
22
```

3. `package.json`은 다음과 정확히 같은 필드를 갖는다. 버전은 캐럿 범위로 두고, 정확한 버전 고정은 `package-lock.json`이 담당한다.

```json
{
  "name": "r-hw",
  "version": "0.1.0",
  "private": true,
  "engines": { "node": ">=22" },
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "serve": "next build && next start",
    "lint": "eslint .",
    "typecheck": "next typegen && tsc --noEmit"
  },
  "dependencies": {
    "next": "^15.5.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  },
  "devDependencies": {
    "@eslint/eslintrc": "^3.0.0",
    "@tailwindcss/postcss": "^4.0.0",
    "@types/node": "^22.0.0",
    "@types/react": "^19.0.0",
    "@types/react-dom": "^19.0.0",
    "eslint": "^9.0.0",
    "eslint-config-next": "^15.5.0",
    "tailwindcss": "^4.0.0",
    "typescript": "^5.0.0"
  }
}
```

4. **`engines.node`는 정확히 `">=22"`여야 한다.** `.nvmrc`의 `22`와 이 값을 T02의 테스트가 exact match로 대조한다 (D21). 둘 중 하나만 바꾸면 T02가 실패한다.

5. **`typecheck`는 반드시 `next typegen && tsc --noEmit`이다** (DR-01). `tsc --noEmit`만 실행하면 `next-env.d.ts`와 `.next/types/`가 없는 깨끗한 checkout에서 Next가 생성하는 라우트·페이지 타입 계약을 검사하지 못하고, **build를 한 적이 있는지에 따라 검사 범위가 달라진다.** `next typegen`이 생성물을 먼저 만들어 두므로 어느 환경에서도 같은 범위를 검사한다.

   - `next` 범위를 `^15.5.0`으로 올린 이유가 이것이다. `next typegen`은 15.5부터 제공된다.
   - `npm install` 후 `npx next typegen --help`가 종료 코드 0이 아니면 **진행하지 말고 설치된 Next 버전(`npm ls next` 출력)과 함께 보고한다.**
   - **로컬과 CI가 같은 명령을 쓴다.** T02의 CI는 `npm run typecheck`를 호출하며, 어느 쪽에서도 `tsc`를 직접 부르지 않는다.

6. `serve` 스크립트를 반드시 포함한다. D16-e가 상시 실행을 `next dev`가 아니라 `next build` + `next start`로 요구한다.

7. `package-lock.json`을 커밋한다. CI가 `npm ci`를 쓰므로 없으면 설치가 실패한다.

8. `tsconfig.json`은 아래와 같이 작성한다. `strict: true`와 `@/*` 경로 별칭은 필수다.

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": false,
    "skipLibCheck": true,
    "strict": true,
    "forceConsistentCasingInFileNames": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": { "@/*": ["./src/*"] }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
```

9. `next.config.ts`는 `reactStrictMode: true`만 설정하고 타입은 `NextConfig`를 쓴다.

10. Tailwind는 **v4 방식**으로 설정한다. `tailwind.config.js` / `tailwind.config.ts`를 만들지 않는다.
    - `postcss.config.mjs`의 plugins에 `"@tailwindcss/postcss": {}` 하나만 둔다.
    - `src/app/globals.css`는 아래 한 줄이다.

```css
@import "tailwindcss";
```

11. `src/app/layout.tsx`는 아래 조건을 모두 만족한다.
    - `<html lang="ko">`
    - `./globals.css`를 import
    - `metadata.title === "r-hw"`
    - `viewport`를 `{ width: "device-width", initialScale: 1 }`로 export (§6.4 태블릿 기준)
    - `children` 타입은 `react`에서 `import type { ReactNode }`로 가져온다

12. `src/app/page.tsx`는 임시 화면이며 **T14에서 오늘 화면으로 전면 교체된다.** 아래 세 조건을 정확히 만족한다. T02의 E2E 스모크 테스트가 이 값들에 의존한다.

    | 요소 | 조건 |
    |---|---|
    | `<h1>` | 텍스트가 정확히 `r-hw`, class에 **`text-[42px]`** 포함 |
    | `<p>` | 텍스트가 정확히 `남은 방학숙제 관리` |

13. **`text-[42px]`는 Tailwind가 실제로 동작하는지 판정하기 위한 결정적 표지다** (DR-02). 스타일시트가 HTML에 링크되어 있다는 사실은 Tailwind 유틸리티가 생성됐다는 증거가 아니다 — 일반 CSS만 있어도 링크는 존재한다. 임의값 유틸리티를 쓰는 이유는 두 가지다.

    - `font-size: 42px`는 Tailwind 없이는 이 프로젝트의 어떤 CSS도 만들지 않는 값이므로, 나타났다면 Tailwind가 클래스를 스캔해 생성한 것이다.
    - 표준 유틸리티(`text-3xl` 등)의 계산값은 버전에 따라 바뀔 수 있지만 임의값은 바뀌지 않는다.

14. **Tailwind 검증 책임의 분담** (DR-02). T01에는 Playwright가 없으므로 브라우저 계산 스타일을 볼 수 없다. 두 태스크가 서로 다른 층을 본다.

    | 태스크 | 검증 대상 | 방법 |
    |---|---|---|
    | **T01** | 빌드 산출 CSS에 유틸리티가 **생성**되는가 | `npm run build` 후 산출 CSS에서 `42px` 문자열을 찾는다 (테스트 케이스 5) |
    | **T02** | 브라우저에서 실제로 **적용**되는가 | `e2e/smoke.spec.ts`에서 `<h1>`의 computed `font-size`가 `42px`인지 확인한다 |

    T01은 "생성"까지만 책임진다. "적용"은 T02의 완료 조건이다.

15. `next/font`를 사용하지 않는다. 빌드 시 외부 폰트를 내려받으므로 네트워크가 없는 CI에서 빌드가 실패한다. 폰트는 시스템 폰트 스택으로 둔다.

16. `.gitignore`에 아래 세 줄을 **추가**한다. 기존 항목(`node_modules/`, `.env`, `.env.*`, `.next/`, `dist/`, `*.log`, `.DS_Store`, `backups/`, `.claude/settings.local.json`)은 하나도 지우지 않는다.

```
next-env.d.ts
*.tsbuildinfo
/out/
```

## 비즈니스 규칙

이 태스크에는 도메인 규칙이 없다. 대신 아래 프로젝트 규칙이 이 태스크에서 처음 강제된다.

| 규칙 | 위반 시 동작 |
|---|---|
| `any` 타입 사용 금지 (CLAUDE.md) | `npm run lint`가 `@typescript-eslint/no-explicit-any` 에러로 실패 |
| TypeScript strict 모드 | `npm run typecheck`가 에러로 실패 |
| typecheck는 생성 타입을 포함한다 (DR-01) | `typecheck`가 `tsc --noEmit` 단독이면 완료 조건 미충족 |
| Node 하한은 `>=22`, 정의처는 `.nvmrc` (D21) | `.nvmrc`와 `engines.node`가 어긋나면 T02의 대조 테스트가 실패 |
| Tailwind 유틸리티가 실제로 생성된다 (DR-02) | 빌드 산출 CSS에 `42px`가 없으면 완료 조건 미충족 |
| `.env` 파일 생성·수정 금지 (CLAUDE.md) | 이 태스크는 환경변수를 전혀 쓰지 않는다. `.env`를 만들면 규칙 위반 |
| 상시 실행은 `next dev`가 아니다 (D16-e) | `serve` 스크립트가 없으면 완료 조건 미충족 |

## 테스트 케이스

**이 태스크에는 자동화 테스트 프레임워크가 아직 없다** (vitest·Playwright는 T02에서 도입). 따라서 검증은 아래 명령의 종료 코드와 출력으로 한다. 각 항목은 참/거짓 판정이 가능하다. **완료 보고에는 아래 모든 명령의 실제 출력을 포함한다.**

### 정상 케이스

| # | 케이스명 | 명령 | 기대 결과 |
|---|---|---|---|
| 1 | Node 버전 충족 | `node -v` | `v22.0.0` 이상 (D21) |
| 2 | 깨끗한 checkout에서 타입 검사 | `rm -rf .next next-env.d.ts && npm run typecheck` | 종료 코드 0. 실행 후 `next-env.d.ts`와 `.next/types/`가 **생성되어 있다** |
| 3 | build 이후 타입 검사가 동일 결과 | `npm run build && npm run typecheck` | 종료 코드 0. 2번과 같은 결과 (DR-01의 "환경에 따라 범위가 달라지지 않는다") |
| 4 | lint 통과 | `npm run lint` | 종료 코드 0, 에러 0건 |
| 5 | Tailwind 유틸리티 생성 | `npm run build` 후 `grep -rl "42px" .next/static/css/` | 최소 1개 파일이 매치. **매치가 없으면 완료 조건 미충족** |
| 6 | 프로덕션 서버 기동 | `npm run start` 후 `curl -s http://localhost:3000` | HTML에 `r-hw`와 `남은 방학숙제 관리`가 모두 포함 |

3번에서 `npm run typecheck`를 두 번 실행하는 것이 요점이다. 두 환경에서 결과가 다르면 DR-01이 지적한 문제가 남아 있는 것이다.

5번에서 `.next/static/css/`에 CSS가 없으면 **경로를 추측해 바꾸지 말고** `.next/` 아래에서 실제 산출 CSS 위치를 찾아 보고한다. 설치된 Next 버전의 출력 구조가 스펙의 전제와 다르다는 뜻이다.

### 규칙 위반 케이스

| # | 케이스명 | 입력 | 기대 결과 |
|---|---|---|---|
| 7 | `any` 차단 확인 | `src/app/page.tsx`에 `const x: any = 1;`을 임시 추가 | `npm run lint`가 `no-explicit-any` 에러로 실패 |
| 8 | strict 위반 차단 확인 | `src/app/page.tsx`에 `const s: string = undefined;`을 임시 추가 | `npm run typecheck`가 실패 |
| 9 | Tailwind 미동작 감지 | `postcss.config.mjs`에서 `@tailwindcss/postcss` 플러그인을 임시 제거하고 `rm -rf .next && npm run build` | 케이스 5의 `grep`이 매치 0건이거나 build가 실패 |

7·8·9번은 설정이 실제로 동작하는지 확인하는 절차다. **세 명령의 실제 출력을 완료 보고에 포함하고, 코드는 원상 복구된 상태여야 한다.** 9번 후에는 `rm -rf .next && npm run build`로 정상 산출물을 다시 만든다.

### 경계 케이스

| # | 케이스명 | 확인 방법 | 기대 결과 |
|---|---|---|---|
| 10 | `.nvmrc`와 engines 일치 | `cat .nvmrc` / `node -e "console.log(require('./package.json').engines.node)"` | `22` / `>=22` (D21) |
| 11 | 기존 `.gitignore` 항목 보존 | `git diff .gitignore` | 삭제된 줄 0줄, 추가만 3줄 |
| 12 | 기존 파일 미훼손 | `git status --porcelain` | `docs/`, `CLAUDE.md`, `README.md`, `.github/`, `sync-main.sh`에 변경 없음 |
| 13 | 네트워크 없는 빌드 | `npm run build` 로그 | 외부 폰트/CDN 요청 없음 (`next/font` 미사용) |

## 완료 조건

```
node -v                                   → v22 이상
npm ci                                    → 종료 코드 0
rm -rf .next next-env.d.ts
npm run typecheck                         → 에러 0 (깨끗한 checkout)
npm run lint                              → 에러 0
npm run build                             → 성공
npm run typecheck                         → 에러 0 (build 이후, 위와 동일 결과)
grep -rl "42px" .next/static/css/         → 최소 1건
npm run start                             → HTTP 응답 HTML에 "r-hw" 포함
cat .nvmrc                                → 22
git status --porcelain                    → 변경 파일이 "변경 대상 파일" 목록과 정확히 일치
```

완료 보고에는 위 명령들과 위반 케이스 7·8·9의 **실제 출력**을 포함한다 (CLAUDE.md).

## 금지 사항

- `create-next-app` 실행 금지. 기존 파일을 덮어쓸 위험이 있다.
- `typecheck`를 `tsc --noEmit` 단독으로 두지 않는다 (DR-01).
- `.nvmrc` 또는 `engines.node` 중 하나만 바꾸지 않는다. 둘은 함께 움직인다 (D21).
- Prisma, vitest, Playwright, Zod 등 후속 태스크의 의존성을 추가하지 않는다. `package.json`에는 위 목록의 패키지만 있어야 한다.
- `src/domain/`, `src/server/`, `prisma/`, `tests/`, `e2e/` 디렉터리를 만들지 않는다.
- `.env`, `.env.local` 등 어떤 환경변수 파일도 만들지 않는다.
- `.github/workflows/ci.yml`을 수정하지 않는다 (T02 담당).
- `tailwind.config.*`를 만들지 않는다 (v4는 설정 파일이 필요 없다).
- `README.md`를 수정하지 않는다 (T19 담당).
- `next/font`, 외부 폰트, 외부 CDN 자원을 쓰지 않는다.
- `src/app/page.tsx`의 `text-[42px]`를 다른 클래스로 바꾸지 않는다. T02의 E2E가 이 값을 본다.

## 스펙 미정 사항

| # | 지점 | 결정 |
|---|---|---|
| 1 | Node 최소 버전 | **22.** `.nvmrc`가 정의처, `engines`는 하한 선언 (D21) |
| 2 | Next.js 버전 | **`^15.5.0`.** `next typegen`이 15.5부터 제공되므로 하한을 15.5로 올렸다 (DR-01). 16 이상이 설치되면 진행하지 말고 보고 |
| 3 | Tailwind 메이저 버전 | **v4로 고정.** 설정 파일이 없어 변경 파일이 줄고 PostCSS 플러그인 한 줄로 끝난다 |
| 4 | Tailwind가 유틸리티를 못 찾는 경우 | v4의 자동 소스 탐색이 `src/app/page.tsx`를 잡지 못해 케이스 5가 실패하면, `globals.css`에 `@source "../**/*.{ts,tsx}";` **한 줄만** 추가한다. 그 외의 설정은 추가하지 않고, 추가했다면 이유를 완료 보고에 적는다 |
| 5 | 패키지 버전 고정 방식 | `package.json`은 캐럿 범위, 재현성은 `package-lock.json` + `npm ci`. 정확 버전 고정(캐럿 제거)은 하지 않는다 |
| 6 | `src/app/page.tsx`의 내용 | 임시 화면이다. 디자인에 시간을 쓰지 않는다. 요구사항 12의 세 조건만 정확하면 된다 |
| 7 | 다크 모드 | v1에서 도입하지 않는다. `globals.css`에 `prefers-color-scheme` 분기를 넣지 않는다 |
| 8 | 폰트 | 시스템 폰트 스택만 사용한다 (요구사항 15) |
| 9 | `package.json`의 `"type"` 필드 | 설정하지 않는다(기본 CommonJS). T03이 `tsx`로 스크립트를 실행할 때 설정이 단순해진다 |
| 10 | `@types/node` 메이저 | `^22.0.0`. 런타임 Node 22와 맞춘다 |
