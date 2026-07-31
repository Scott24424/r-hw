# T01 프로젝트 스캐폴딩

## 목표

Next.js App Router + TypeScript + Tailwind + ESLint로 빈 저장소를 빌드·실행 가능한 상태로 만든다.

## 선행 태스크

없음

## 변경 대상 파일

생성:

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

**이 목록 밖의 파일은 생성·수정하지 않는다.** `next-env.d.ts`는 Next가 자동 생성하며 `.gitignore`에 들어가므로 커밋 대상이 아니다.

## 구현 요구사항

1. `create-next-app`을 실행하지 않는다. 저장소에 이미 `docs/`, `CLAUDE.md`, `AGENTS.md`(심볼릭 링크), `README.md`, `.github/`, `sync-main.sh`가 있어 생성기가 이들을 덮어쓰거나 거부할 수 있다. 아래 파일들을 직접 작성한 뒤 `npm install`로 의존성을 설치한다.

2. `package.json`은 다음과 정확히 같은 필드를 갖는다. 버전은 캐럿 범위로 두고, 정확한 버전 고정은 `package-lock.json`이 담당한다.

```json
{
  "name": "r-hw",
  "version": "0.1.0",
  "private": true,
  "engines": { "node": ">=20" },
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "serve": "next build && next start",
    "lint": "eslint .",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "next": "^15.0.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  },
  "devDependencies": {
    "@eslint/eslintrc": "^3.0.0",
    "@tailwindcss/postcss": "^4.0.0",
    "@types/node": "^20.0.0",
    "@types/react": "^19.0.0",
    "@types/react-dom": "^19.0.0",
    "eslint": "^9.0.0",
    "eslint-config-next": "^15.0.0",
    "tailwindcss": "^4.0.0",
    "typescript": "^5.0.0"
  }
}
```

3. `serve` 스크립트를 반드시 포함한다. D16-e가 상시 실행을 `next dev`가 아니라 `next build` + `next start`로 요구한다.

4. `package-lock.json`을 커밋한다. CI가 `npm ci`를 쓰므로 없으면 CI가 설치 단계를 건너뛴다.

5. `tsconfig.json`은 아래와 같이 작성한다. `strict: true`와 `@/*` 경로 별칭은 필수다.

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

6. `next.config.ts`는 `reactStrictMode: true`만 설정하고 타입은 `NextConfig`를 쓴다.

7. Tailwind는 **v4 방식**으로 설정한다. `tailwind.config.js` / `tailwind.config.ts`를 만들지 않는다.
   - `postcss.config.mjs`의 plugins에 `"@tailwindcss/postcss": {}` 하나만 둔다.
   - `src/app/globals.css`의 첫 줄은 `@import "tailwindcss";`다.

8. `eslint.config.mjs`는 flat config이며 `next/core-web-vitals`와 `next/typescript`를 확장하고, **`@typescript-eslint/no-explicit-any`를 `error`로 설정한다** (CLAUDE.md의 `any` 금지를 lint로 강제).

```js
import { dirname } from "path";
import { fileURLToPath } from "url";
import { FlatCompat } from "@eslint/eslintrc";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const compat = new FlatCompat({ baseDirectory: __dirname });

export default [
  { ignores: [".next/**", "node_modules/**", "next-env.d.ts"] },
  ...compat.extends("next/core-web-vitals", "next/typescript"),
  {
    rules: {
      "@typescript-eslint/no-explicit-any": "error",
    },
  },
];
```

9. `src/app/layout.tsx`는 아래 조건을 모두 만족한다.
   - `<html lang="ko">`
   - `./globals.css`를 import
   - `metadata.title === "r-hw"`
   - `viewport`를 `{ width: "device-width", initialScale: 1 }`로 export (§6.4 태블릿 기준)
   - `children` 타입은 `react`에서 `import type { ReactNode }`로 가져온다

10. `src/app/page.tsx`는 임시 화면이며 **T14에서 오늘 화면으로 전면 교체된다.** 다음 두 요소를 정확한 문자열로 포함한다. T02의 E2E 스모크 테스트가 이 문자열에 의존한다.
    - `<h1>` 텍스트: `r-hw`
    - `<p>` 텍스트: `남은 방학숙제 관리`

11. `next/font`를 사용하지 않는다. 빌드 시 외부 폰트를 내려받으므로 네트워크가 없는 CI에서 빌드가 실패한다. 폰트는 CSS의 시스템 폰트 스택으로 둔다.

12. `.gitignore`에 아래 세 줄을 **추가**한다. 기존 항목(`node_modules/`, `.env`, `.env.*`, `.next/`, `dist/`, `*.log`, `.DS_Store`, `backups/`, `.claude/settings.local.json`)은 하나도 지우지 않는다.

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
| `.env` 파일 생성·수정 금지 (CLAUDE.md) | 이 태스크는 환경변수를 전혀 쓰지 않는다. `.env`를 만들면 규칙 위반 |
| 상시 실행은 `next dev`가 아니다 (D16-e) | `serve` 스크립트가 없으면 완료 조건 미충족 |

## 테스트 케이스

**이 태스크에는 자동화 테스트 프레임워크가 아직 없다** (vitest·Playwright는 T02에서 도입). 따라서 검증은 아래 명령의 종료 코드와 출력으로 한다. 각 항목은 참/거짓 판정이 가능하다.

### 정상 케이스

| # | 케이스명 | 명령 | 기대 결과 |
|---|---|---|---|
| 1 | 타입 검사 통과 | `npm run typecheck` | 종료 코드 0, 에러 0건 |
| 2 | lint 통과 | `npm run lint` | 종료 코드 0, 에러 0건 |
| 3 | 프로덕션 빌드 성공 | `npm run build` | 종료 코드 0 |
| 4 | 프로덕션 서버 기동 | `npm run start` 후 `curl -s http://localhost:3000` | HTML에 `r-hw`와 `남은 방학숙제 관리`가 모두 포함 |
| 5 | Tailwind 적용 확인 | 4번 응답 HTML | `<link>` 또는 인라인으로 스타일시트가 포함되어 있고, 빌드 로그에 Tailwind 관련 에러 없음 |

### 규칙 위반 케이스

| # | 케이스명 | 입력 | 기대 결과 |
|---|---|---|---|
| 6 | `any` 차단 확인 | `src/app/page.tsx`에 `const x: any = 1;`을 임시로 추가 | `npm run lint`가 `no-explicit-any` 에러로 실패. **확인 후 반드시 되돌린다** |
| 7 | strict 위반 차단 확인 | `src/app/page.tsx`에 `const s: string = undefined;`을 임시로 추가 | `npm run typecheck`가 실패. **확인 후 반드시 되돌린다** |

6·7번은 설정이 실제로 동작하는지 확인하는 절차다. **완료 보고에 이 두 명령의 실제 출력을 포함하고, 코드는 원상 복구된 상태여야 한다.**

### 경계 케이스

| # | 케이스명 | 확인 방법 | 기대 결과 |
|---|---|---|---|
| 8 | 기존 `.gitignore` 항목 보존 | `git diff .gitignore` | 삭제된 줄이 0줄, 추가만 3줄 |
| 9 | 기존 파일 미훼손 | `git status --porcelain` | `docs/`, `CLAUDE.md`, `README.md`, `.github/`, `sync-main.sh`에 변경 없음 |
| 10 | 네트워크 없는 빌드 | `npm run build` 로그 | 외부 폰트/CDN 요청 없음 (`next/font` 미사용) |

## 완료 조건

```
npm ci                → 종료 코드 0
npm run typecheck     → 에러 0
npm run lint          → 에러 0
npm run build         → 성공
npm run start         → http://localhost:3000 응답 HTML에 "r-hw" 포함
git status --porcelain → 변경 파일이 "변경 대상 파일" 목록과 정확히 일치
```

완료 보고에는 위 명령들의 **실제 출력**을 포함한다 (CLAUDE.md).

## 금지 사항

- `create-next-app` 실행 금지. 기존 파일을 덮어쓸 위험이 있다.
- Prisma, vitest, Playwright, Zod 등 후속 태스크의 의존성을 추가하지 않는다. T01의 `package.json`에는 위 목록의 패키지만 있어야 한다.
- `src/domain/`, `src/server/`, `prisma/`, `tests/`, `e2e/` 디렉터리를 만들지 않는다.
- `.env`, `.env.local` 등 어떤 환경변수 파일도 만들지 않는다.
- `.github/workflows/ci.yml`을 수정하지 않는다 (T02 담당).
- `tailwind.config.*`를 만들지 않는다 (v4는 설정 파일이 필요 없다).
- `README.md`를 수정하지 않는다 (T19 담당).
- `next/font`, 외부 폰트, 외부 CDN 자원을 쓰지 않는다.

## 스펙 미정 사항

| # | 지점 | 결정 |
|---|---|---|
| 1 | Next.js 메이저 버전 | **15.x로 고정한다.** App Router의 동적 라우트 `params`가 Promise인 규약(Next 15+)을 전제로 후속 태스크 스펙이 작성된다. `npm install` 결과 16 이상이 설치되면 진행하지 말고 보고할 것 |
| 2 | Tailwind 메이저 버전 | **v4로 고정한다.** 설정 파일이 없어 변경 파일이 줄고, PostCSS 플러그인 한 줄로 끝난다 |
| 3 | 패키지 버전 고정 방식 | `package.json`은 캐럿 범위, 재현성은 `package-lock.json` + CI의 `npm ci`가 담당한다. 정확 버전 고정(캐럿 제거)은 하지 않는다 |
| 4 | `src/app/page.tsx`의 내용 | 임시 화면이다. 디자인·레이아웃에 시간을 쓰지 않는다. 요구사항 10의 두 문자열만 정확하면 된다 |
| 5 | 다크 모드 | v1에서 도입하지 않는다. `globals.css`에 `prefers-color-scheme` 분기를 넣지 않는다 |
| 6 | 폰트 | 시스템 폰트 스택만 사용한다 (요구사항 11) |
| 7 | `package.json`의 `"type"` 필드 | 설정하지 않는다(기본 CommonJS). T03이 `tsx`로 `prisma/seed.ts`를 실행할 때 설정이 단순해진다 |
