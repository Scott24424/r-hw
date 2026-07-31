# T03 Prisma 스키마 · 마이그레이션 · 클라이언트(WAL) · 구조 검증

## 목표

`architecture.md` §1.2의 스키마를 Prisma로 옮기고, 초기 마이그레이션과 WAL 클라이언트를 만들고, **생성된 DB 구조가 설계와 일치함을 기계적으로 검증한다.**

## 선행 태스크

T02

T02는 T01을 선행으로 갖는다. 따라서 T03은 **T01·T02를 전이적으로 포함한다** (DR-05).

## 구현 순서상의 위치

**T01 → T02 → T03 → T04.**

- T03 브랜치는 **T02가 `main`에 Merge된 뒤에** 만든다.
- **T02와 T03을 병렬로 구현하지 않는다.** 두 태스크가 `package.json`, `package-lock.json`, `.gitignore`, `.github/workflows/ci.yml`을 모두 수정하고, 아래 요구사항 14의 CI 패치는 **T02가 조건부 CI를 이미 전체 교체했다는 전제에서만** 적용된다.
- T03은 T02가 만든 `vitest` 의존성, `test` 스크립트, `vitest.config.ts`, `tests/` 배치 규약을 그대로 사용한다. T01까지만 Merge된 상태에서는 이 태스크의 어떤 테스트도 실행할 수 없다.

## 변경 대상 파일

생성:

- `prisma/schema.prisma`
- `prisma/migrations/<timestamp>_init/migration.sql` — **`prisma migrate dev`가 생성한다. 손으로 쓰거나 고치지 않는다** (CLAUDE.md)
- `prisma/migrations/migration_lock.toml` — 생성물
- `prisma/wal.ts`
- `src/server/prisma.ts`
- `src/server/prisma.test.ts`
- `tests/helpers/db.ts`
- `tests/integration/db-foundation.test.ts`

수정:

- `vitest.config.ts`
- `package.json`
- `package-lock.json`
- `.gitignore`
- `.github/workflows/ci.yml`

13개 파일이며 그중 2개(`migration.sql`, `migration_lock.toml`)는 생성물이다. "태스크당 10개 이내" 목표를 초과하는 이유는 **DR-07 때문에 구조 검증을 이 태스크로 가져왔기 때문**이다. 검증을 T04로 미루면 T03이 눈검사로만 완료되고, 스키마 결함이 한 태스크 뒤에 발견된다. 자기 검증 가능성을 파일 수보다 우선했다.

**이 목록 밖의 파일은 생성·수정하지 않는다.** 시드(`prisma/seed.ts`)는 T04다.

## 구현 요구사항

### A. 의존성과 스키마

1. 아래 의존성만 추가한다.

| 패키지 | 위치 | 버전 |
|---|---|---|
| `@prisma/client` | dependencies | `^6.2.0` |
| `prisma` | devDependencies | `^6.2.0` |
| `tsx` | devDependencies | `^4.0.0` |

**`^6.2.0` 미만이면 SQLite에서 `enum`을 쓸 수 없다 (D13).** 설치 후 `npx prisma --version` 출력을 완료 보고에 포함한다.

2. `prisma/schema.prisma`를 아래로 시작한다. **모델·필드·인덱스는 `architecture.md` §1.2와 한 글자도 다르면 안 된다.**

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

3. **SQLite의 enum은 Prisma 계층에서만 강제된다.** DB에는 `TEXT` 컬럼으로 생성되고 `CHECK` 제약이 붙지 않는다. 따라서 구조 검증(요구사항 D)은 `CHECK` 제약을 기대하지 않으며, 값 범위 보장은 Prisma Client의 타입과 Zod(T07)가 담당한다. 이것이 D13이 남긴 대가이며 새로운 문제가 아니다.

4. `npm run db:validate`가 통과해야 한다. **enum 때문에 실패하면 진행하지 말고 즉시 보고한다** — D13의 버전 전제가 깨진 것이며 설계 결정 재검토가 필요하다.

### B. 연결 문자열 (D19) — 모든 Prisma CLI 경로

5. `src/server/prisma.ts`를 아래 내용으로 작성한다. 이 파일이 **연결 문자열 기본값의 정의처**다.

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
> 이 동작은 요구사항 16의 검사로 못 박는다. 검사가 실패하면 전제가 다른 것이므로 **진행하지 말고 보고한다.**

6. 개발 중 핫 리로드로 커넥션이 누적되지 않도록 `globalThis` 캐시를 둔다 (요구사항 5의 코드에 포함). `any`를 쓰지 않고 `as unknown as { prisma?: PrismaClient }`로 좁힌다.

7. **`DATABASE_URL`이 필요한 Prisma CLI 경로를 전부 npm 스크립트로 감싼다** (DR-06). `datasource`가 `env("DATABASE_URL")`을 쓰므로, 이 값을 해석해야 하는 모든 CLI 명령은 기본값 주입 없이는 `.env`가 없는 환경에서 실패한다. `package.json`의 `scripts`에 아래 7개를 **추가**한다.

```jsonc
"db:generate": "DATABASE_URL=${DATABASE_URL:-file:./dev.db} prisma generate",
"db:validate": "DATABASE_URL=${DATABASE_URL:-file:./dev.db} prisma validate",
"db:migrate":  "DATABASE_URL=${DATABASE_URL:-file:./dev.db} prisma migrate dev",
"db:deploy":   "DATABASE_URL=${DATABASE_URL:-file:./dev.db} prisma migrate deploy",
"db:diff":     "DATABASE_URL=${DATABASE_URL:-file:./dev.db} prisma migrate diff --from-migrations ./prisma/migrations --to-schema-datamodel ./prisma/schema.prisma --shadow-database-url file:./.tmp-shadow.db --exit-code",
"db:wal":      "DATABASE_URL=${DATABASE_URL:-file:./dev.db} tsx prisma/wal.ts",
"db:setup":    "npm run db:deploy && npm run db:wal"
```

8. **기본값 리터럴을 갖는 스크립트의 집합은 정확히 아래 6개다.** `db:setup`은 다른 스크립트를 `npm run`으로 조합할 뿐이므로 리터럴을 갖지 않는다. 이 집합이 요구사항 17의 exact match 테스트 기대값이다.

```
db:generate, db:validate, db:migrate, db:deploy, db:diff, db:wal
```

9. **어떤 로컬 명령도 `npx prisma ...`를 직접 부르지 않는다.** 항상 npm 스크립트를 거친다. 예외는 버전 확인(`npx prisma --version`)뿐이며 이 명령은 연결 문자열을 필요로 하지 않는다.

10. `prisma/wal.ts`는 WAL을 적용하고 결과를 표준 출력에 찍는다. `wal`이 아니면 **종료 코드 1**로 끝난다.

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

11. 마이그레이션은 `npm run db:migrate -- --name init`으로 생성한다. 생성된 `migration.sql`을 **읽는 것은 되지만 수정하지 않는다** (CLAUDE.md).

### C. 테스트 DB 헬퍼 (`tests/helpers/db.ts`)

12. 아래 API를 export 한다. 이 헬퍼는 T04 이후 모든 통합 테스트가 쓴다.

```ts
export interface TestDb {
  prisma: PrismaClient;
  url: string;       // file:/절대경로
  filePath: string;  // 절대 경로
  cleanup: () => Promise<void>;
}

export interface CreateTestDbOptions {
  /** 복사 직후·WAL 적용 전에 호출된다. 실패 경로 정리를 검증하기 위한 테스트 전용 seam. */
  afterCopyHook?: () => void | Promise<void>;
}

export async function createTestDb(options?: CreateTestDbOptions): Promise<TestDb>;

/** 아직 해제되지 않은 모든 테스트 DB를 정리한다. afterAll에서 부른다. */
export async function cleanupAllTestDbs(): Promise<void>;

/** prisma/migrations의 내용 지문. 파일 순서에 무관하고 내용이 바뀌면 값이 바뀐다. */
export function computeMigrationsFingerprint(migrationsDir: string): string;
```

13. 동작 규칙 (DR-12에 대한 응답이다. 각 항목이 리뷰가 지적한 구멍을 하나씩 막는다).

| # | 규칙 | 막는 구멍 |
|---|---|---|
| 13-1 | 저장소 루트는 `fileURLToPath(new URL("../../", import.meta.url))`로 구한다. 모든 경로는 **절대 경로**로 다룬다 | 상대 경로가 `schema.prisma` 기준으로 해석되는 함정 (D19) |
| 13-2 | 템플릿은 `.tmp/test-template.db`, 지문은 `.tmp/test-template.meta.json`(`{ "fingerprint": "..." }`)에 둔다 | — |
| 13-3 | 템플릿을 쓰기 전에 `computeMigrationsFingerprint(<root>/prisma/migrations)`와 meta의 값을 비교한다. **다르거나 meta가 없으면 템플릿을 다시 만든다** | 새 마이그레이션 추가 후 stale schema를 계속 복사하는 문제 |
| 13-4 | 템플릿 생성은 유일한 임시 이름(`test-template.<pid>-<랜덤>.db`)에 `prisma migrate deploy`를 실행한 뒤 `fs.renameSync`로 최종 경로에 옮긴다. meta도 같은 방식으로 원자적으로 쓴다 | 워커 동시 진입 시 반쯤 만들어진 템플릿을 읽는 문제 |
| 13-5 | 자식 프로세스 환경은 **반드시 `{ ...process.env, DATABASE_URL: url }`** 로 넘긴다 | `env: { DATABASE_URL }`만 넘기면 `PATH`가 사라져 macOS arm64 Homebrew 환경에서 `npx` 탐색이 실패한다 |
| 13-6 | 템플릿에는 WAL을 적용하지 않는다. 복사본마다 `enableWal`을 적용한다 | WAL 상태 DB를 `-wal` 없이 복사할 때의 애매함 |
| 13-7 | 복사 이후의 모든 단계를 `try/catch`로 감싸고, **실패 시 그때까지 만든 `.db`/`.db-wal`/`.db-shm`을 지우고 다시 throw 한다** | 반환 전에 실패하면 cleanup 핸들이 없어 파일이 누적되는 문제 |
| 13-8 | 만들어진 모든 DB를 모듈 수준 registry에 등록하고, `cleanup()`이 성공하면 registry에서 제거한다. `cleanupAllTestDbs()`는 남은 전부를 정리한다 | 테스트가 직접 만든 추가 DB의 누락, assertion 실패로 인한 누수 |
| 13-9 | `cleanup()`은 `$disconnect()` 후 `.db`, `.db-wal`, `.db-shm` 세 파일을 지운다. 없으면 무시하고, 두 번 불려도 오류가 없다 | sidecar 파일 누적 |

14. `createTestDb()`는 **시드를 실행하지 않는다.** 빈 DB가 기본값이며, 시드가 필요한 테스트가 직접 시드 함수를 부른다 (T04).

15. `computeMigrationsFingerprint`는 순수 함수여야 한다. 인자로 받은 디렉터리만 읽고, `prisma/migrations`를 하드코딩하지 않는다. 그래야 테스트가 **가짜 디렉터리로 지문 동작을 검증할 수 있다** — 실제 마이그레이션 파일을 건드리지 않고. 구현: 디렉터리 아래 모든 `migration.sql`과 `migration_lock.toml`을 **경로 기준 정렬** 후 내용을 이어붙여 sha256을 낸다.

### D. 구조 검증과 설정

16. 마이그레이션 실행 후 **DB 파일이 만들어진 위치를 확인한다.**

```
ls -la prisma/dev.db     → 존재해야 한다
ls -la dev.db            → 존재하면 안 된다 (No such file)
ls -la prisma/prisma     → 존재하면 안 된다
```

셋 중 하나라도 어긋나면 상대 경로 해석 기준이 이 스펙의 전제와 다른 것이다. **임의로 경로를 고쳐 맞추지 말고, 관찰된 실제 위치를 그대로 보고한다.** D19를 갱신해야 한다.

17. `src/server/prisma.test.ts`에 아래 테스트를 작성한다. **DB에 붙지 않는다** — 순수 함수와 `package.json` 텍스트만 검사한다.

```ts
describe("resolveDatabaseUrl", () => {
  it("DATABASE_URL이 없으면 기본값을 쓴다", ...);
  it("DATABASE_URL이 있으면 그 값을 쓴다", ...);
  it("DATABASE_URL이 빈 문자열이면 기본값을 쓴다", ...);
});

describe("D19 기본값 일관성", () => {
  it("기본값 리터럴을 갖는 스크립트 집합이 기대와 정확히 일치한다", ...);
  it("추출된 모든 기본값이 DEFAULT_DATABASE_URL과 같다", ...);
  it("db:setup은 기본값 리터럴을 갖지 않는다", ...);
});
```

**"4개 이상" 같은 하한 비교를 쓰지 않는다** (DR-06). `package.json`을 읽어 명령 문자열에 `DATABASE_URL=${DATABASE_URL:-`가 포함된 스크립트 **이름의 집합**을 만들고, 정렬해서 아래 상수와 deep equality로 비교한다.

```ts
const EXPECTED_DB_URL_SCRIPTS = [
  "db:deploy",
  "db:diff",
  "db:generate",
  "db:migrate",
  "db:validate",
  "db:wal",
] as const;
```

스크립트를 추가하면서 이 배열을 갱신하지 않으면 테스트가 실패한다 — 그것이 목적이다. **T04는 `db:seed`를 추가하면서 이 배열도 갱신한다.**

18. `tests/integration/db-foundation.test.ts`에 두 개의 describe를 작성한다. 스키마 구조 검증(DR-07)과 헬퍼 동작 검증(DR-12)이다.

```ts
describe("스키마 구조", () => {
  it("테이블 집합이 기대와 일치한다", ...);
  it("Book의 컬럼 이름·순서·nullable이 기대와 일치한다", ...);
  it("Assignment의 컬럼 이름·순서·nullable이 기대와 일치한다", ...);
  it("ScheduleBlock의 컬럼 이름·순서·nullable이 기대와 일치한다", ...);
  it("orderIndex의 기본값이 0이고 status의 기본값이 PLANNED다", ...);
  it("인덱스 이름·유니크 여부·컬럼 순서가 기대와 일치한다", ...);
  it("Assignment.bookId가 Book.id를 참조하는 외래키를 갖는다", ...);
  it("enum 컬럼에는 CHECK 제약이 없다", ...);
});

describe("테스트 DB 헬퍼", () => {
  it("서로 격리된 DB를 만든다", ...);
  it("만들어진 DB에 WAL이 적용된다", ...);
  it("cleanup이 db·wal·shm 세 파일을 모두 지운다", ...);
  it("생성 중 실패하면 부분 생성 파일을 남기지 않는다", ...);
  it("지문은 내용이 바뀌면 달라진다", ...);
  it("지문은 파일 나열 순서에 무관하다", ...);
  it("템플릿 지문이 다르면 템플릿을 다시 만든다", ...);
});
```

19. 구조 검증은 `createTestDb()`가 만든 **마이그레이션이 적용된 임시 DB**에 대해 아래 SQLite 내부 정보를 조회해 수행한다. 눈검사나 `grep` 개수 세기로 대체하지 않는다 (DR-07).

| 조회 | 용도 |
|---|---|
| `SELECT name, sql FROM sqlite_master WHERE type='table'` | 테이블 집합, `CHECK` 제약 부재 |
| `PRAGMA table_info(<table>)` | 컬럼 이름·순서·타입·notnull·기본값·PK |
| `PRAGMA index_list(<table>)` | 인덱스 이름·유니크 여부 |
| `PRAGMA index_info(<index>)` | 인덱스의 컬럼과 순서 |
| `PRAGMA foreign_key_list(<table>)` | 외래키 |

20. 기대 구조는 아래와 같다. `_prisma_migrations`는 Prisma가 관리하는 테이블이므로 집합에는 포함하되 컬럼은 검사하지 않는다.

**테이블 집합:** `{ Assignment, Book, ScheduleBlock, _prisma_migrations }`

**`Book`** — 컬럼 순서와 nullable:

| 순서 | 컬럼 | 타입 | notnull | 비고 |
|---|---|---|---|---|
| 0 | `id` | TEXT | Y | PK |
| 1 | `title` | TEXT | Y | 유니크 인덱스 대상 |
| 2 | `language` | TEXT | Y | enum |
| 3 | `progressUnit` | TEXT | Y | enum |
| 4 | `totalUnits` | INTEGER | **N** | §1.3 — 없어도 어떤 기능도 막히지 않는다 |
| 5 | `archivedAt` | DATETIME | **N** | D17 |
| 6 | `createdAt` | DATETIME | Y | 기본값 있음 |
| 7 | `updatedAt` | DATETIME | Y | 클라이언트가 관리 |

**`Assignment`**:

| 순서 | 컬럼 | 타입 | notnull | 비고 |
|---|---|---|---|---|
| 0 | `id` | TEXT | Y | PK |
| 1 | `date` | TEXT | Y | **D9 — DATETIME이 아니다** |
| 2 | `orderIndex` | INTEGER | Y | 기본값 `0` |
| 3 | `type` | TEXT | Y | enum |
| 4 | `title` | TEXT | **N** | 읽기 유형이면 null (§1.3) |
| 5 | `bookId` | TEXT | **N** | FK → `Book.id` |
| 6 | `startUnit` | INTEGER | **N** | **D5 — NULL이 "이어서"를 의미한다** |
| 7 | `endUnit` | INTEGER | **N** | F4 |
| 8 | `status` | TEXT | Y | 기본값 `PLANNED` |
| 9 | `completedAt` | DATETIME | **N** | I10 |
| 10 | `createdAt` | DATETIME | Y | |
| 11 | `updatedAt` | DATETIME | Y | |

**`ScheduleBlock`**:

| 순서 | 컬럼 | 타입 | notnull | 비고 |
|---|---|---|---|---|
| 0 | `id` | TEXT | Y | PK |
| 1 | `startMinute` | INTEGER | Y | D10 |
| 2 | `endMinute` | INTEGER | **N** | **F11 — NULL이 시점 마커를 의미한다** |
| 3 | `label` | TEXT | Y | |
| 4 | `kind` | TEXT | Y | 기본값 `STUDY` |
| 5 | `matchType` | TEXT | **N** | F15 — NULL이 순수 루틴 블록 |
| 6 | `createdAt` | DATETIME | Y | |
| 7 | `updatedAt` | DATETIME | Y | |

**인덱스** — 이름, 유니크 여부, 컬럼 순서:

| 인덱스 이름 | 테이블 | 유니크 | 컬럼 순서 |
|---|---|---|---|
| `Book_title_key` | Book | **예** | `title` |
| `Assignment_date_status_idx` | Assignment | 아니오 | `date`, `status` |
| `Assignment_bookId_date_idx` | Assignment | 아니오 | `bookId`, `date` |
| `ScheduleBlock_startMinute_idx` | ScheduleBlock | 아니오 | `startMinute` |

**외래키:** `Assignment.bookId` → `Book.id` 1건. `ScheduleBlock`에는 외래키가 없다 (D11 — 조인 테이블 없는 파생 매칭).

21. **기본값 단정의 범위를 제한한다.** `orderIndex`의 기본값이 `0`이고 `status`의 기본값 문자열에 `PLANNED`가 포함되는지만 확인한다. 이 둘은 설계상 의미가 있다(D15-b, §1.2). `createdAt`류는 "기본값이 존재한다"까지만 확인하고 정확한 DDL 문자열을 비교하지 않는다 — Prisma 패치 버전에 따라 표기가 달라질 수 있고, 그 차이는 설계와 무관하다.

22. **불일치가 나왔을 때의 처리를 구분한다.**

| 불일치 항목 | 판단 | 조치 |
|---|---|---|
| 컬럼 집합·순서, nullable, PK, 인덱스 이름·컬럼·유니크, 외래키 | **스키마가 틀렸다** | `schema.prisma`를 §1.2에 맞춰 고치고 마이그레이션을 다시 만든다 |
| 타입 문자열(TEXT/INTEGER/DATETIME), 기본값 DDL 표기 | **스펙의 전제가 틀렸을 수 있다** | 기대값을 임의로 바꾸지 말고 `PRAGMA table_info` 출력 전문과 함께 **보고한다** |

23. `vitest.config.ts`를 수정한다. `testTimeout`을 `30_000`으로 올리고 `hookTimeout: 30_000`을 추가한다. 첫 통합 테스트가 템플릿 DB 마이그레이션을 수행하므로 10초로는 부족하다. 그 외 설정은 바꾸지 않는다.

24. `.gitignore`에 아래를 **추가**한다. 기존 항목은 지우지 않는다.

```
/prisma/*.db
/prisma/*.db-journal
/prisma/*.db-shm
/prisma/*.db-wal
/.tmp/
```

`db:diff`의 shadow DB는 `prisma/.tmp-shadow.db`에 만들어지며 위 `/prisma/*.db` 규칙이 덮는다 — gitignore의 `*`는 선행 점(`.`)도 매치한다. 별도 규칙을 추가하지 않는다.

25. `.github/workflows/ci.yml`을 아래 세 곳만 수정한다. 그 외 줄은 건드리지 않는다. **CI도 npm 스크립트를 쓴다** (DR-06 — `npx prisma`를 직접 부르지 않는다).

- `ci` job: `- run: npm ci` 다음 줄에 `- run: npm run db:generate` 추가
- `e2e` job: `- run: npm ci` 다음에 `- run: npm run db:generate` 추가
- `e2e` job: 위 줄 다음에 `- run: npm run db:setup` 추가

`db:setup`은 E2E 서버가 뜨기 전에 DB 파일과 스키마를 만든다. T04가 여기에 시드를 붙이면 CI를 다시 고치지 않아도 된다.

## 비즈니스 규칙

| 규칙 | 위반 시 동작 |
|---|---|
| Prisma 버전 ≥ 6.2.0 (D13) | `npm run db:validate`가 SQLite enum을 거부 → **진행 중단 후 보고** |
| `AssignmentStatus`에 `OVERDUE`를 만들지 않는다 (D7) | `테이블 집합이 기대와 일치한다`는 통과하지만 §1.2 대조에서 드러난다. enum 값은 DB에 남지 않으므로 **스키마 텍스트로 확인한다** |
| `Assignment.date`는 `String` (D9) | `Assignment의 컬럼 이름·순서·nullable이 기대와 일치한다`가 실패 (타입 TEXT 기대) |
| `startUnit`·`endUnit`·`title`·`bookId`는 nullable (D5, F4) | 같은 테스트가 실패 |
| `endMinute`은 nullable (F11) | `ScheduleBlock의 컬럼 이름·순서·nullable이 기대와 일치한다`가 실패 |
| `orderIndex`에 유니크 제약을 걸지 않는다 (D15-b) | `인덱스 이름·유니크 여부·컬럼 순서가 기대와 일치한다`가 실패 |
| 진도 체인·목록 질의용 인덱스 2개 (D5, D7) | 같은 테스트가 실패 |
| 연결 문자열은 `.env`가 아니라 코드·스크립트 기본값 (D19) | `.env`를 만들면 CLAUDE.md 위반. `env -u DATABASE_URL` 완료 조건이 실패 |
| 기본값 리터럴을 갖는 스크립트 집합이 고정된다 (D19) | `기본값 리터럴을 갖는 스크립트 집합이 기대와 정확히 일치한다`가 실패 |
| 마이그레이션 SQL 직접 수정 금지 (CLAUDE.md) | `git diff`에 손으로 고친 흔적이 있으면 완료 조건 미충족 |
| 스키마와 마이그레이션이 일치한다 | `npm run db:diff`가 종료 코드 2 (drift 감지) |
| WAL 적용 (D16-e) | `npm run db:wal` 종료 코드 1 |
| 테스트 DB는 생성 실패 시에도 파일을 남기지 않는다 (DR-12) | `생성 중 실패하면 부분 생성 파일을 남기지 않는다`가 실패 |

## 테스트 케이스

### 정상 케이스

| # | 테스트명 | 파일 | 입력 | 기대 결과 |
|---|---|---|---|---|
| 1 | `DATABASE_URL이 없으면 기본값을 쓴다` | `src/server/prisma.test.ts` | `resolveDatabaseUrl({})` | `"file:./dev.db"` |
| 2 | `DATABASE_URL이 있으면 그 값을 쓴다` | 같은 파일 | `resolveDatabaseUrl({ DATABASE_URL: "file:/tmp/x.db" })` | `"file:/tmp/x.db"` |
| 3 | `기본값 리터럴을 갖는 스크립트 집합이 기대와 정확히 일치한다` | 같은 파일 | `package.json` | 정렬된 이름 집합이 `EXPECTED_DB_URL_SCRIPTS`와 deep equal |
| 4 | `추출된 모든 기본값이 DEFAULT_DATABASE_URL과 같다` | 같은 파일 | `package.json` | 6건 전부 `"file:./dev.db"` |
| 5 | `db:setup은 기본값 리터럴을 갖지 않는다` | 같은 파일 | `package.json` | `db:setup` 명령에 `DATABASE_URL=` 없음 |
| 6 | `테이블 집합이 기대와 일치한다` | `tests/integration/db-foundation.test.ts` | 마이그레이션된 임시 DB | `{Assignment, Book, ScheduleBlock, _prisma_migrations}` |
| 7 | `Book의 컬럼 이름·순서·nullable이 기대와 일치한다` | 같은 파일 | `PRAGMA table_info(Book)` | 요구사항 20의 Book 표와 일치 |
| 8 | `Assignment의 컬럼 이름·순서·nullable이 기대와 일치한다` | 같은 파일 | `PRAGMA table_info(Assignment)` | 요구사항 20의 Assignment 표와 일치 |
| 9 | `ScheduleBlock의 컬럼 이름·순서·nullable이 기대와 일치한다` | 같은 파일 | `PRAGMA table_info(ScheduleBlock)` | 요구사항 20의 ScheduleBlock 표와 일치 |
| 10 | `orderIndex의 기본값이 0이고 status의 기본값이 PLANNED다` | 같은 파일 | `PRAGMA table_info(Assignment)` | `orderIndex`의 `dflt_value`가 `0`, `status`의 `dflt_value`에 `PLANNED` 포함 |
| 11 | `인덱스 이름·유니크 여부·컬럼 순서가 기대와 일치한다` | 같은 파일 | `PRAGMA index_list` / `index_info` | 요구사항 20의 인덱스 표와 일치 |
| 12 | `Assignment.bookId가 Book.id를 참조하는 외래키를 갖는다` | 같은 파일 | `PRAGMA foreign_key_list(Assignment)` | 1건, `from=bookId`, `table=Book`, `to=id` |
| 13 | `enum 컬럼에는 CHECK 제약이 없다` | 같은 파일 | `sqlite_master.sql` | 세 테이블의 DDL에 `CHECK`가 없다 (요구사항 3) |
| 14 | `서로 격리된 DB를 만든다` | 같은 파일 | `createTestDb()` 2회, 한쪽에만 Book 1건 생성 | 다른 쪽의 Book 수가 0, 두 `filePath`가 다름 |
| 15 | `만들어진 DB에 WAL이 적용된다` | 같은 파일 | `getJournalMode` | `"wal"` |
| 16 | `cleanup이 db·wal·shm 세 파일을 모두 지운다` | 같은 파일 | `cleanup()` 후 파일 확인 | 세 경로 모두 부재 |
| 17 | `지문은 내용이 바뀌면 달라진다` | 같은 파일 | 임시 디렉터리에 가짜 `migration.sql` 2종 | 두 지문이 다르다 |
| 18 | `지문은 파일 나열 순서에 무관하다` | 같은 파일 | 같은 내용, 생성 순서만 다른 임시 디렉터리 2개 | 두 지문이 같다 |
| 19 | `템플릿 지문이 다르면 템플릿을 다시 만든다` | 같은 파일 | `.tmp/test-template.meta.json`에 잘못된 지문을 쓴 뒤 `createTestDb()` | meta의 지문이 `computeMigrationsFingerprint(prisma/migrations)` 값으로 갱신됨 |

17·18·19번은 **실제 `prisma/migrations` 파일을 건드리지 않는다.** 지문 함수에 임시 디렉터리를 넘기고, 19번은 meta 파일만 조작한다. 마이그레이션 파일 수정 금지(CLAUDE.md)를 지키면서 지문 로직을 검증하는 방법이다.

### 규칙 위반 케이스

| # | 케이스명 | 입력 | 기대 결과 |
|---|---|---|---|
| 20 | 구조 단정이 살아 있는가 | 테스트 파일의 기대 구조 상수에서 `Assignment.startUnit`의 notnull 기대를 `Y`로 임시 변경 | 케이스 8이 실패. **확인 후 되돌린다** |
| 21 | 스키마 변경이 감지되는가 | `schema.prisma`의 `startUnit Int?`를 `startUnit Int`로 임시 변경하고 `npm run db:validate && npm run db:diff` | `db:diff`가 종료 코드 2(drift). **마이그레이션을 새로 만들지 않고 즉시 되돌린다** |
| 22 | 기본값이 갈라지면 잡히는가 | `package.json`의 `db:wal` 기본값을 `file:./other.db`로 임시 변경 | 케이스 4가 실패. **확인 후 되돌린다** |
| 23 | 스크립트 집합 변화가 잡히는가 | `db:wal`에서 `DATABASE_URL=${DATABASE_URL:-file:./dev.db} ` 접두를 임시 제거 | 케이스 3이 실패. **확인 후 되돌린다** |
| 24 | 생성 실패 시 정리되는가 | `createTestDb({ afterCopyHook: () => { throw new Error("boom"); } })` | throw 되고 `.tmp/`에 해당 `.db`/`-wal`/`-shm`이 남지 않는다 (케이스 `생성 중 실패하면 부분 생성 파일을 남기지 않는다`) |
| 25 | enum 지원 확인 | `npm run db:validate` | 통과. 실패하면 **중단 후 보고** (D13 전제 붕괴) |

20~23번은 검증이 실제로 작동하는지 확인하는 절차다. **네 명령의 실제 출력을 완료 보고에 포함하고, 코드는 원상 복구된 상태여야 한다.** 21번은 특히 마이그레이션을 재생성하지 않도록 주의한다.

### 경계 케이스

| # | 케이스명 | 입력 | 기대 결과 |
|---|---|---|---|
| 26 | 빈 문자열 환경변수 | `resolveDatabaseUrl({ DATABASE_URL: "" })` | 기본값 반환 (빈 문자열은 "설정되지 않음"으로 취급) |
| 27 | WAL 재적용 | `npm run db:wal`을 연속 2회 | 두 번 모두 `journal_mode=wal`, 종료 코드 0 (멱등) |
| 28 | `.env` 없는 환경 | `env -u DATABASE_URL npm run db:validate` | 종료 코드 0 (D19) |
| 29 | DB 파일 위치 | 요구사항 16의 세 명령 | `prisma/dev.db`만 존재. 루트 `dev.db`와 `prisma/prisma/`는 없음 |
| 30 | cleanup 멱등성 | `cleanup()`을 두 번 호출 | 두 번째도 오류 없이 종료 |

## 완료 조건

`.env`가 없고 셸에 `DATABASE_URL`도 없는 상태를 `env -u DATABASE_URL`로 강제해 검증한다 (DR-06).

```
npx prisma --version                                → prisma 6.2.0 이상
env -u DATABASE_URL npm run db:validate             → valid, 종료 코드 0
env -u DATABASE_URL npm run db:generate             → 종료 코드 0
env -u DATABASE_URL npm run db:migrate -- --name init → 마이그레이션 생성 성공
ls prisma/dev.db                                    → 존재 / ls dev.db → 없음 (요구사항 16)
env -u DATABASE_URL npm run db:diff                 → 종료 코드 0 (drift 없음)
env -u DATABASE_URL npm run db:wal                  → "journal_mode=wal", 종료 코드 0
env -u DATABASE_URL npm run db:wal                  → 2회째도 종료 코드 0 (멱등)
npm run typecheck                                   → 에러 0
npm run lint                                        → 에러 0
npm test -- --reporter=verbose                      → 실패 0건. 정상 케이스 1~19의
                                                      테스트명이 모두 출력에 나타난다
npm run build                                       → 성공
npm run e2e                                         → 실패 0건
```

**누적 테스트 개수를 완료 조건으로 쓰지 않는다.** 이 스펙에 명명된 테스트 이름이 `--reporter=verbose` 출력에 모두 나타나는 것으로 판정한다.

완료 보고에 `prisma --version`, `db:validate`, `db:diff`, `db:wal`, `npm test`, 그리고 위반 케이스 20~23의 **실제 출력**을 포함한다.

## 금지 사항

- `.env`, `.env.local`, `prisma/.env`를 만들지 않는다. **어떤 경우에도** (CLAUDE.md, D19).
- 생성된 `migration.sql`을 수정하지 않는다. 위반 케이스 21에서 스키마를 임시 변경한 뒤 **마이그레이션을 재생성하지 않고** 되돌린다.
- 로컬·CI 어디서도 `npx prisma generate|validate|migrate`를 직접 부르지 않는다. npm 스크립트를 쓴다 (DR-06).
- `EXPECTED_DB_URL_SCRIPTS`를 "N개 이상" 같은 하한 비교로 바꾸지 않는다.
- `prisma/seed.ts`를 만들지 않는다 (T04).
- `src/domain/` 아래에 파일을 만들지 않는다 (T05). 특히 enum 재수출 파일을 미리 만들지 않는다.
- 스키마에 §1.2에 없는 모델·필드·관계를 추가하지 않는다. 필요하다고 판단되면 **멈추고 질문한다**.
- 구조 검증의 기대값을 관찰값에 맞춰 고치지 않는다. 요구사항 22의 구분을 따른다.
- `prisma migrate reset`을 스크립트나 CI에 넣지 않는다.
- Zod, 서비스 계층, Route Handler를 만들지 않는다.
- `tests/setup.ts`, `playwright.config.ts`를 수정하지 않는다 (T02 소관).

## 스펙 미정 사항

| # | 지점 | 결정 |
|---|---|---|
| 1 | Prisma 클라이언트 생성기 | 기본 `prisma-client-js`, `output` 미지정. 새 `prisma-client` 생성기는 쓰지 않는다 — §1.4가 `@prisma/client`에서의 import를 전제한다 |
| 2 | DB 파일 위치 | `prisma/dev.db`. `.gitignore`로 제외한다 |
| 3 | WAL 적용 시점 | 마이그레이션 직후 `db:setup`에서 1회. 애플리케이션 기동 시에는 적용하지 않는다 — WAL은 DB 파일에 남는 영구 설정이고, 모듈 로드 시 비동기 작업을 넣으면 초기화 순서가 복잡해진다 |
| 4 | `datasourceUrl` vs `datasources` | `datasourceUrl`(문자열 1개). Prisma 6에서 권장되는 형태이고 중첩 객체보다 단순하다 |
| 5 | 구조 검증을 T03에 두는 이유 | T04로 미루면 T03이 눈검사로 완료된다. 파일 수 초과를 감수하고 자기 검증을 택했다 (DR-07) |
| 6 | 테스트 DB 헬퍼를 T03에 두는 이유 | 구조 검증이 마이그레이션된 임시 DB를 필요로 하므로 같은 태스크에 있어야 한다. T04는 이 헬퍼를 **사용만** 한다 |
| 7 | `afterCopyHook` 테스트 seam | 실패 경로 정리를 결정적으로 검증할 다른 방법이 없다. 프로덕션 경로는 이 옵션을 넘기지 않으며, 헬퍼는 테스트 전용 파일(`tests/`)이다 |
| 8 | 기본값 DDL 문자열 검증 범위 | `orderIndex`와 `status`만. 그 외는 "기본값 존재" 수준 (요구사항 21) |
| 9 | enum의 DB 레벨 강제 | 없다. Prisma 계층 강제이며 `CHECK` 제약을 기대하지 않는다 (요구사항 3). 값 검증은 T07의 Zod가 담당한다 |
| 10 | `db:diff`의 shadow DB | `file:./.tmp-shadow.db` (schema 기준 → `prisma/.tmp-shadow.db`). `.gitignore`에 추가한다 |
| 11 | 커넥션 풀·타임아웃 | 설정하지 않는다. 기기 2~3대 규모(D16)에서 기본값으로 충분하다 |
| 12 | 마이그레이션 이름 | `init` 하나. 이 태스크에서 스키마 전체가 한 번에 들어간다 |
| 13 | 시드 데이터 | 이 태스크에서 넣지 않는다. `db:setup`은 T04에서 `db:seed`를 이어붙인다 |
