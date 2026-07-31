# T03 Prisma 스키마 · 마이그레이션 · 클라이언트(WAL)

## 목표

`architecture.md` §1.2의 스키마를 그대로 Prisma로 옮기고, 초기 마이그레이션과 WAL 모드가 적용된 Prisma 클라이언트를 만든다.

## 선행 태스크

T01

## 변경 대상 파일

생성:

- `prisma/schema.prisma`
- `prisma/migrations/<timestamp>_init/migration.sql` — **`prisma migrate dev`가 생성한다. 손으로 쓰거나 고치지 않는다** (CLAUDE.md)
- `prisma/migrations/migration_lock.toml` — 생성물
- `prisma/wal.ts`
- `src/server/prisma.ts`
- `src/server/prisma.test.ts`

수정:

- `package.json`
- `package-lock.json`
- `.gitignore`
- `.github/workflows/ci.yml`

**이 목록 밖의 파일은 생성·수정하지 않는다.** 시드(`prisma/seed.ts`)와 테스트 DB 헬퍼는 T04다.

## 구현 요구사항

1. 아래 의존성만 추가한다.

| 패키지 | 위치 | 버전 |
|---|---|---|
| `@prisma/client` | dependencies | `^6.2.0` |
| `prisma` | devDependencies | `^6.2.0` |
| `tsx` | devDependencies | `^4.0.0` |

**`^6.2.0` 미만이면 SQLite에서 `enum`을 쓸 수 없다 (D13).** 설치 후 `npx prisma --version`으로 6.2.0 이상임을 확인하고, 그 출력을 완료 보고에 포함한다.

2. `prisma/schema.prisma`를 아래 순서로 작성한다. **모델·필드·인덱스는 `architecture.md` §1.2와 한 글자도 다르면 안 된다.**

```prisma
generator client {
  provider = "prisma-client-js"
}

// D19: 값의 정의처는 src/server/prisma.ts의 DEFAULT_DATABASE_URL이다.
// Prisma CLI는 코드를 거치지 않으므로 package.json 스크립트가 같은 값을 주입한다.
datasource db {
  provider = "sqlite"
  url      = env("DATABASE_URL")
}
```

이어서 §1.2의 `enum` 5개(`AssignmentType`, `AssignmentStatus`, `ProgressUnit`, `BookLanguage`, `BlockKind`)와 `model` 3개(`Book`, `Assignment`, `ScheduleBlock`)를 그대로 옮긴다. 주석도 함께 옮긴다 — 필드의 NULL 의미(D5)가 주석에 담겨 있다.

3. 스키마 작성 후 아래를 만족하는지 눈으로 확인한다. 하나라도 빠지면 후속 태스크의 질의가 깨진다.

| # | 확인 항목 | 근거 |
|---|---|---|
| 3-1 | `Book.title`에 `@unique` | D4 — find-or-create로 진도 체인을 잇는다 |
| 3-2 | `Book.archivedAt`이 `DateTime?` | D17 |
| 3-3 | `Assignment.date`가 `String` (`DateTime` 아님) | D9 |
| 3-4 | `Assignment.startUnit` / `endUnit` / `title` / `bookId`가 전부 nullable | D5, F4, §1.3 |
| 3-5 | `Assignment.orderIndex`에 `@default(0)`, **유니크 제약 없음** | D15-b |
| 3-6 | `@@index([date, status])`, `@@index([bookId, date])` | D7, D5 |
| 3-7 | `ScheduleBlock.endMinute`이 `Int?`, `matchType`이 `AssignmentType?` | F11, F15 |
| 3-8 | `@@index([startMinute])` | §1.2 |
| 3-9 | `AssignmentStatus`에 `OVERDUE`가 **없다** | D7 |

4. `npx prisma validate`가 통과해야 한다. **enum 때문에 실패하면 진행하지 말고 즉시 보고한다** — D13의 버전 전제가 깨진 것이며, 설계 결정 재검토가 필요하다 (CLAUDE.md: 확신이 없을 때 추측으로 진행하지 않는다).

5. `src/server/prisma.ts`를 아래 내용으로 작성한다. 이 파일이 **연결 문자열 기본값의 정의처**다 (D19).

```ts
import { PrismaClient } from "@prisma/client";

/**
 * D19: 연결 문자열 기본값의 정의처.
 * package.json의 db:* 스크립트도 같은 문자열을 쓴다 — 갈라지면 prisma.test.ts가 잡는다.
 */
export const DEFAULT_DATABASE_URL = "file:./dev.db";

export function resolveDatabaseUrl(env: NodeJS.ProcessEnv = process.env): string {
  const url = env.DATABASE_URL;
  return url === undefined || url === "" ? DEFAULT_DATABASE_URL : url;
}

export function createPrismaClient(url: string = resolveDatabaseUrl()): PrismaClient {
  return new PrismaClient({ datasourceUrl: url });
}

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };

export const prisma: PrismaClient = globalForPrisma.prisma ?? createPrismaClient();

if (process.env.NODE_ENV !== "production") {
  globalForPrisma.prisma = prisma;
}

/**
 * D16-e: 기본 저널 모드에서는 쓰기가 읽기를 막아, 폴링 중인 기기가
 * 다른 기기의 체크 동작과 부딪히면 SQLITE_BUSY가 난다.
 * WAL은 DB 파일에 기록되는 영구 설정이므로 1회 적용으로 충분하다.
 */
export async function enableWal(client: PrismaClient): Promise<string> {
  await client.$queryRawUnsafe("PRAGMA journal_mode=WAL;");
  return getJournalMode(client);
}

export async function getJournalMode(client: PrismaClient): Promise<string> {
  const rows =
    await client.$queryRawUnsafe<Array<{ journal_mode: string }>>("PRAGMA journal_mode;");
  return rows[0]?.journal_mode ?? "unknown";
}
```

> **상대 경로의 기준점 (D19):** SQLite의 상대 경로는 **`schema.prisma`가 있는 디렉터리** 기준으로 해석된다. 따라서 `file:./dev.db`가 가리키는 실제 파일은 **`prisma/dev.db`** 다. `file:./prisma/dev.db`로 적으면 `prisma/prisma/dev.db`가 만들어진다 — 값을 바꾸지 말 것.
>
> 이 동작은 요구사항 13의 검사로 못 박는다. 검사가 실패하면 전제가 다른 것이므로 **진행하지 말고 보고한다.**

6. 개발 중 핫 리로드로 커넥션이 누적되지 않도록 `globalThis` 캐시를 둔다 (요구사항 5의 코드에 포함). `any`를 쓰지 않고 `as unknown as { prisma?: PrismaClient }`로 좁힌다.

7. `prisma/wal.ts`는 WAL을 적용하고 결과를 표준 출력에 찍는다. `wal`이 아니면 **종료 코드 1**로 끝난다. 이것이 완료 조건의 기계적 판정 근거다.

```ts
import { createPrismaClient, enableWal, resolveDatabaseUrl } from "../src/server/prisma";

async function main(): Promise<void> {
  const url = resolveDatabaseUrl();
  const client = createPrismaClient(url);
  try {
    const mode = await enableWal(client);
    console.log(`database=${url} journal_mode=${mode}`);
    if (mode !== "wal") {
      console.error(`WAL 적용 실패: journal_mode=${mode}`);
      process.exitCode = 1;
    }
  } finally {
    await client.$disconnect();
  }
}

void main();
```

8. `package.json`의 `scripts`에 아래 5개를 **추가**한다. 셸의 `${VAR:-기본값}` 확장을 쓰므로 `DATABASE_URL`이 설정돼 있으면 그 값이 우선한다 (D19).

```jsonc
"db:generate": "prisma generate",
"db:migrate": "DATABASE_URL=${DATABASE_URL:-file:./dev.db} prisma migrate dev",
"db:deploy": "DATABASE_URL=${DATABASE_URL:-file:./dev.db} prisma migrate deploy",
"db:wal": "DATABASE_URL=${DATABASE_URL:-file:./dev.db} tsx prisma/wal.ts",
"db:setup": "npm run db:deploy && npm run db:wal"
```

9. 마이그레이션은 `npm run db:migrate -- --name init`으로 생성한다. 생성된 `migration.sql`을 **읽는 것은 되지만 수정하지 않는다** (CLAUDE.md 금지 사항).

10. `.gitignore`에 아래를 **추가**한다. 기존 항목은 지우지 않는다.

```
/prisma/*.db
/prisma/*.db-journal
/prisma/*.db-shm
/prisma/*.db-wal
```

11. `.github/workflows/ci.yml`을 아래 두 곳만 수정한다. 그 외 줄은 건드리지 않는다.

- `ci` job: `- run: npm ci` 다음 줄에 `- run: npx prisma generate` 추가
- `e2e` job: `- run: npm ci` 다음에 `- run: npx prisma generate`와 `- run: npm run db:setup`을 이 순서로 추가

`db:setup`은 E2E 서버가 뜨기 전에 DB 파일과 스키마를 만든다. T04가 여기에 시드를 붙이면 CI를 다시 고치지 않아도 된다.

12. `src/server/prisma.test.ts`에 아래 4개 테스트를 작성한다. **DB에 붙지 않는다** — 순수 함수와 `package.json` 텍스트만 검사한다.

```ts
describe("resolveDatabaseUrl", () => {
  it("DATABASE_URL이 없으면 기본값을 쓴다", ...);
  it("DATABASE_URL이 있으면 그 값을 쓴다", ...);
  it("DATABASE_URL이 빈 문자열이면 기본값을 쓴다", ...);
});

describe("D19 기본값 일관성", () => {
  it("package.json 스크립트의 DATABASE_URL 기본값이 DEFAULT_DATABASE_URL과 같다", ...);
});
```

마지막 테스트는 `package.json`을 읽어 `DATABASE_URL:-` 뒤의 값을 모두 뽑아, **4건 이상 존재하고 전부 `DEFAULT_DATABASE_URL`과 같은지** 확인한다. D19가 남긴 "기본값이 두 곳에 존재한다"는 대가를 여기서 막는다.

13. 마이그레이션 실행 후 **DB 파일이 만들어진 위치를 확인한다.**

```
ls -la prisma/dev.db     → 존재해야 한다
ls -la dev.db            → 존재하면 안 된다 (No such file)
ls -la prisma/prisma     → 존재하면 안 된다
```

셋 중 하나라도 어긋나면 상대 경로 해석 기준이 이 스펙의 전제와 다른 것이다. **임의로 경로를 고쳐 맞추지 말고, 관찰된 실제 위치를 그대로 보고한다** (CLAUDE.md: 추측으로 진행하지 않는다). D19를 갱신해야 한다.

## 비즈니스 규칙

| 규칙 | 위반 시 동작 |
|---|---|
| Prisma 버전 ≥ 6.2.0 (D13) | `prisma validate`가 SQLite enum을 거부 → **진행 중단 후 보고** |
| `AssignmentStatus`에 `OVERDUE`를 만들지 않는다 (D7) | 스키마 검토 3-9 실패 |
| `Assignment.date`는 `String` (D9) | 스키마 검토 3-3 실패 |
| `orderIndex`에 유니크 제약을 걸지 않는다 (D15-b) | 스키마 검토 3-5 실패 |
| 연결 문자열은 `.env`가 아니라 코드·스크립트 기본값 (D19) | `.env`를 만들면 CLAUDE.md 위반 |
| 마이그레이션 SQL 직접 수정 금지 (CLAUDE.md) | `git diff`에 손으로 고친 흔적이 있으면 완료 조건 미충족 |
| WAL 적용 (D16-e) | `npm run db:wal` 종료 코드 1 |

## 테스트 케이스

### 정상 케이스

| # | 케이스명 | 파일 · 테스트명 | 입력 | 기대 결과 |
|---|---|---|---|---|
| 1 | 기본값 사용 | `src/server/prisma.test.ts` › `DATABASE_URL이 없으면 기본값을 쓴다` | `resolveDatabaseUrl({})` | `"file:./dev.db"` |
| 2 | 오버라이드 | 같은 파일 › `DATABASE_URL이 있으면 그 값을 쓴다` | `resolveDatabaseUrl({ DATABASE_URL: "file:/tmp/x.db" })` | `"file:/tmp/x.db"` |
| 3 | 기본값 단일화 | 같은 파일 › `package.json 스크립트의 DATABASE_URL 기본값이 DEFAULT_DATABASE_URL과 같다` | `package.json` 텍스트 | 추출된 기본값 4건 이상, 전부 `DEFAULT_DATABASE_URL`과 일치 |

### 규칙 위반 케이스

| # | 케이스명 | 입력 | 기대 결과 |
|---|---|---|---|
| 4 | 기본값이 갈라지면 잡히는가 | `package.json`의 `db:wal` 스크립트 기본값을 `file:./prisma/other.db`로 임시 변경 | 테스트 3이 실패. **확인 후 되돌린다** |
| 5 | enum 지원 확인 | `npx prisma validate` | 통과. 실패하면 **중단 후 보고** (D13 전제 붕괴) |

### 경계 케이스

| # | 케이스명 | 입력 | 기대 결과 |
|---|---|---|---|
| 6 | 빈 문자열 환경변수 | `resolveDatabaseUrl({ DATABASE_URL: "" })` | 기본값 반환 (빈 문자열은 "설정되지 않음"으로 취급) |
| 7 | WAL 재적용 | `npm run db:wal`을 연속 2회 실행 | 두 번 모두 `journal_mode=wal`, 종료 코드 0 (멱등) |
| 8 | 인덱스 생성 확인 | `grep -c "CREATE INDEX" prisma/migrations/*/migration.sql` | `3` (date+status, bookId+date, startMinute) |
| 9 | 유니크 인덱스 확인 | `grep -c "CREATE UNIQUE INDEX" prisma/migrations/*/migration.sql` | `1` (`Book.title`) |
| 10 | DB 파일 위치 | 요구사항 13의 세 명령 | `prisma/dev.db`만 존재. 루트 `dev.db`와 `prisma/prisma/`는 없음 |

## 완료 조건

```
npx prisma --version              → prisma 6.2.0 이상
npx prisma validate               → The schema at prisma/schema.prisma is valid
npm run db:migrate -- --name init → 마이그레이션 생성 성공
ls prisma/dev.db                  → 존재 / ls dev.db → 없음 (요구사항 13)
npm run db:wal                    → "journal_mode=wal" 출력, 종료 코드 0
npm run db:wal                    → 2회째도 종료 코드 0 (멱등)
npm test                          → 기존 3건 + 신규 4건 = 7 passed
npm run typecheck                 → 에러 0
npm run lint                      → 에러 0
npm run build                     → 성공
npm run e2e                       → 1 passed
```

완료 보고에 `prisma --version`, `prisma validate`, `db:wal`, `npm test`의 **실제 출력**을 포함한다.

## 금지 사항

- `.env`, `.env.local`, `prisma/.env`를 만들지 않는다. **어떤 경우에도** (CLAUDE.md, D19).
- 생성된 `migration.sql`을 수정하지 않는다.
- `prisma/seed.ts`를 만들지 않는다 (T04).
- `tests/helpers/db.ts`를 만들지 않는다 (T04).
- `src/domain/` 아래에 파일을 만들지 않는다 (T05). 특히 enum 재수출 파일을 미리 만들지 않는다.
- 스키마에 §1.2에 없는 모델·필드·관계를 추가하지 않는다. 필요하다고 판단되면 **멈추고 질문한다** (CLAUDE.md).
- `prisma migrate reset`을 CI 스크립트에 넣지 않는다.
- Zod, 서비스 계층, Route Handler를 만들지 않는다.

## 스펙 미정 사항

| # | 지점 | 결정 |
|---|---|---|
| 1 | Prisma 클라이언트 생성기 | 기본 `prisma-client-js`를 쓰고 `output`을 지정하지 않는다. 새 `prisma-client` 생성기는 쓰지 않는다 — §1.4가 `@prisma/client`에서의 import를 전제한다 |
| 2 | DB 파일 위치 | `prisma/dev.db`. `.gitignore`로 제외한다 |
| 3 | WAL 적용 시점 | 마이그레이션 직후 `db:setup`에서 1회. 애플리케이션 기동 시에는 적용하지 않는다 — WAL은 DB 파일에 남는 영구 설정이라 매번 켤 필요가 없고, 모듈 로드 시 비동기 작업을 넣으면 초기화 순서가 복잡해진다 |
| 4 | `datasourceUrl` vs `datasources` | `datasourceUrl`(문자열 1개)을 쓴다. Prisma 6에서 권장되는 형태이고 중첩 객체보다 단순하다 |
| 5 | 커넥션 풀·타임아웃 | 설정하지 않는다. 기기 2~3대 규모(D16)에서 기본값으로 충분하다 |
| 6 | `prisma generate`를 postinstall로 걸 것인가 | 걸지 않는다. `@prisma/client` 설치 시 자체 postinstall이 돌고, CI는 요구사항 11에서 명시적으로 호출한다 |
| 7 | 마이그레이션 이름 | `init` 하나. 이 태스크에서 스키마 전체가 한 번에 들어간다 |
| 8 | 시드 데이터 | 이 태스크에서 넣지 않는다. `db:setup`은 T04에서 `db:seed`를 이어붙인다 |
