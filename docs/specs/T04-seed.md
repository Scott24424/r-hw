# T04 시드 데이터

## 목표

`architecture.md` 부록 C의 시드(책 9권 · 시간표 블록 10건 · 과제 27건)를 **기존 사용자 데이터를 훼손하지 않고** 넣고, 표 전체가 정확히 재현되는지 exact match로 검증한다.

## 요구사항 추적

| 근거 | 내용 |
|---|---|
| MR-01 ~ MR-12 | 과제 27건과 책 9권의 **값 전체**가 `plan-20days.jpg`의 직접 관찰에서 온다 |
| MR-20 ~ MR-29 | 블록 10건의 값 전체가 `daily-schedule.jpg`의 직접 관찰에서 온다 |
| MR-12, NR-02, **UR-24.6** | `7/29`의 판독 불가 항목을 시드하지 않는다. 어떤 이름으로도 채우지 않는다 |
| OR-03 | fixture 중복 전사 + exact match + mutation 확인 |
| **UR-24, UR-24.1** | **이 태스크의 존재 이유.** 사진의 숙제 데이터를 **파일럿·개발·테스트용 초기 시드**로 제공한다 |
| **UR-24.5** | **9 / 10 / 27 데이터 검증을 유지한다** — 이 수가 요구사항으로 고정되어 있다 |
| **UR-24.2, UR-24.3** | `db:setup`은 **파일럿·개발 초기화 명령**이다. 일반 운영 배포에서 사용자 확인 없이 개인 숙제 데이터가 주입되어서는 안 된다 |
| **UR-15.1, UR-15.3** | 과제 27건의 `date`. **연도 `2026`은 mockup에서 읽은 값이 아니라 사용자가 이번 파일럿에 지정한 값이다** (MR-02에는 월·일만 있다) |
| **UR-16** | **블록 10건이 `date`를 갖는다.** 요구사항 9 참조 |
| **UR-26, UR-26.1~26.6** | 그 `date` 값이 `2026-07-29`인 것. **사용자가 파일럿 기간 첫날을 대표 일일 시간표 날짜로 지정했다** (2026-08-01 `OPEN-01` 결정) |
| UR-17 | 모든 과제를 `status = PLANNED`, `completedAt = null`로 시드하는 것 |

**설계 가정 12건(AP-01~AP-12)은 2026-08-01에 전부 처리되었다.** 이 태스크에 영향을 준 것은 **AP-11 조건부 승인**(파일럿 한정)과 **AP-03 거절**(블록에 날짜가 생김)이다.

## 선행 태스크

T03

T03은 T02를, T02는 T01을 선행으로 갖는다. 따라서 T04는 **T01·T02·T03을 전이적으로 포함한다** (DR-08). 구체적으로 T04는 아래를 전제한다.

| 전제 | 제공 태스크 |
|---|---|
| `vitest` 의존성, `test` 스크립트, `vitest.config.ts`, `tests/` 배치 규약 | T02 |
| `prisma/schema.prisma`, 마이그레이션, `createPrismaClient`, `enableWal` | T03 |
| `tests/helpers/db.ts`의 `createTestDb` / `cleanupAllTestDbs` | T03 |
| `db:deploy` / `db:wal` / `db:setup` 스크립트, `EXPECTED_DB_URL_SCRIPTS` | T03 |

## 구현 순서상의 위치

**T01 → T02 → T03 → T04.** T04 브랜치는 **T03이 `main`에 Merge된 뒤에** 만든다. T04는 T03의 `db:setup`과 T03의 `src/server/prisma.test.ts`를 수정하므로, 두 선행 결과가 모두 Merge된 뒤에만 파일 범위가 성립한다.

## 변경 대상 파일

생성:

- `prisma/seed.ts`
- `tests/fixtures/seed-expected.ts`
- `tests/integration/seed.test.ts`

수정:

- `package.json`
- `src/server/prisma.test.ts` — **T03 소유 파일에 대한 의도된 소유권 예외** (아래 참조)

5개 파일이다. **이 목록 밖의 파일은 생성·수정하지 않는다.** 새 의존성을 추가하지 않으므로 `package-lock.json`은 바뀌지 않는다.

**소유권 예외 — `src/server/prisma.test.ts` (RR-03).** 이 파일은 T03이 만들고 소유한다. T04가 수정하는 것은 **의도된 예외**이며 근거는 다음과 같다.

- T04가 `package.json`의 `db:*` 스크립트를 바꾸므로(`db:seed` 추가, `db:setup` 확장), **그 스크립트 문자열을 검증하는 테스트도 같은 커밋에서 함께 움직여야 한다.** 갈라지면 T03의 exact match 테스트가 실패하는데, 그것이 그 테스트의 설계 목적이다 (T03 요구사항 17).
- 허용 범위는 **요구사항 19·20에 적힌 정확한 변경 두 가지뿐이다.** `EXPECTED_DB_URL_SCRIPTS` 배열에 `"db:seed"` 추가, 그리고 `db:setup` 구성 검증 테스트 추가. 그 밖의 기존 테스트를 고치거나 지우지 않는다.
- **역방향은 허용하지 않는다.** `tests/helpers/db.ts`는 **사용만 하고 수정하지 않는다** (T03 소관). T04가 헬퍼의 동작이 바뀌어야 한다고 판단하면 고치지 말고 **멈추고 보고한다.**

## 구현 요구사항

### A. 시드 함수 (`prisma/seed.ts`)

1. 파일은 함수를 export 하고, 그 함수를 부르는 `main()`을 함께 둔다. 통합 테스트가 프로세스를 띄우지 않고 함수를 직접 부를 수 있어야 한다.

```ts
export interface SeedResult {
  books: number;        // upsert된 책 수 (항상 9)
  blocks: number;       // 생성된 블록 수 (건너뛰었으면 0)
  assignments: number;  // 생성된 과제 수 (건너뛰었으면 0)
  skipped: { blocks: boolean; assignments: boolean };
}

export interface SeedOptions {
  force?: boolean;
  /**
   * 트랜잭션 안에서 삭제 직후·생성 직전에 호출된다.
   * 롤백을 결정적으로 검증하기 위한 테스트 전용 seam이며 프로덕션 경로는 넘기지 않는다.
   */
  beforeCreateHook?: () => Promise<void> | void;
  /**
   * 트랜잭션 안에서 ScheduleBlock 생성 단계 직후·Assignment 생성 단계 직전에 호출된다.
   * "일부만 생성된 뒤 실패"를 검증하기 위한 테스트 전용 seam (R2-04).
   */
  afterBlocksHook?: () => Promise<void> | void;
  /**
   * 트랜잭션 안에서 Assignment 생성 단계 직후·커밋 직전에 호출된다.
   * "마지막 생성 단계까지 끝난 뒤 실패"를 검증하기 위한 테스트 전용 seam (R2-04).
   */
  afterAssignmentsHook?: () => Promise<void> | void;
}

export async function seed(client: PrismaClient, options?: SeedOptions): Promise<SeedResult>;
```

2. **전체를 하나의 `$transaction`으로 감싼다** (DR-10). 중간에 실패하면 아무 변경도 남지 않아야 한다. 트랜잭션 안의 순서는 정확히 아래와 같다.

```
$transaction(async (tx) => {
  1. Book 9권을 title 기준 upsert         (create: 시드값, update: {})
  2. force면  tx.assignment.deleteMany()  →  tx.scheduleBlock.deleteMany()
  3. beforeCreateHook?.()                 (있으면 호출)
  4. tx.scheduleBlock.count() === 0 이면 블록 10건 생성, 아니면 skipped.blocks = true
  5. afterBlocksHook?.()                  (있으면 호출 — R2-04)
  6. tx.assignment.count() === 0  이면 과제 27건 생성, 아니면 skipped.assignments = true
  7. afterAssignmentsHook?.()             (있으면 호출 — R2-04)
}, { maxWait: 10_000, timeout: 30_000 })
```

**1~7단계는 전부 같은 `tx` 위에서 실행된다.** 어느 단계도 `tx`가 아닌 클라이언트(`client`, 전역 `prisma`)를 쓰지 않는다 — 트랜잭션 밖에서 쓰면 롤백되지 않는다.

**2-A. 생성 도중 실패의 롤백 계약 (R2-04).** 위 순서에서 **4단계(블록 생성)와 6단계(과제 생성)는 서로 다른 실패 지점**이다. `beforeCreateHook`(3단계)만으로는 "삭제가 롤백되는가"만 증명되고, **"블록을 만든 뒤 과제 생성에서 실패하면 그 블록도 사라지는가"는 증명되지 않는다.** 그래서 seam이 셋이다.

| seam | 어디서 실패하는가 | 반증하는 잘못된 구현 | 검증 테스트 |
|---|---|---|---|
| `beforeCreateHook` | 삭제 직후, 생성 전 | `deleteMany`가 트랜잭션 밖에 있음, **또는 Book upsert(1단계)가 트랜잭션 밖에 있음** | 위반 케이스 18 · 18c (Book 경계는 mutation 29b) |
| `afterBlocksHook` | **블록 10건이 이미 만들어진 뒤** | **ScheduleBlock 생성이 트랜잭션 밖에 있음** | 위반 케이스 18b·18c |
| `afterAssignmentsHook` | **과제 27건까지 만들어진 뒤** | **Assignment 생성이 트랜잭션 밖에 있음** | 위반 케이스 18d |

- **hook은 실제 구현 경로 안에 있어야 한다.** 위 순서의 지정된 위치에서 `await`로 호출하며, 테스트를 위해 별도의 "테스트용 시드 함수"를 만들어 우회하지 않는다. 우회하면 실제 트랜잭션 경계를 검증하지 못한다.
- **롤백 판정은 fixture와 비교하지 않는다.** 시드 표(`tests/fixtures/seed-expected.ts`)와 비교하면 시드와 fixture가 같은 잘못된 값을 공유할 때 거짓 양성이 된다. 판정 기준은 **`seed()` 호출 직전에 테스트가 직접 찍은 스냅샷**이며, 호출 후 상태가 그 스냅샷과 deep equal이어야 한다 (요구사항 2-B).
- 이 테스트들은 전부 `createTestDb()`가 만든 임시 DB에서 돈다. **개발 DB(`prisma/dev.db`)를 대상으로 실행하지 않는다** (T03 13-11, 금지 사항).

**2-B. 롤백 스냅샷의 정의 — 전체 DB 상태 (R2-04 Round 3 잔여 1).**

Round 3이 지적한 문제는 **부분 스냅샷**이었다. `id`·`createdAt`·`updatedAt`·`completedAt`·`bookId`를 제외하면, 예컨대 **Book upsert를 트랜잭션 밖으로 옮긴 잘못된 구현**이 기존 Book의 `updatedAt`만 커밋하고도 롤백 테스트를 통과한다. 그래서 스냅샷은 **선택 필드가 아니라 사용자 테이블의 전체 행·전체 컬럼**을 결정적으로 캡처한다.

**캡처 대상은 아래로 고정한다. 구현자가 고르지 않는다.**

| 대상 | 캡처 방식 | 이유 |
|---|---|---|
| `Book` 전체 행 | `SELECT * FROM "Book" ORDER BY "id"` | 사용자 테이블 |
| `ScheduleBlock` 전체 행 | `SELECT * FROM "ScheduleBlock" ORDER BY "id"` | 사용자 테이블 |
| `Assignment` 전체 행 | `SELECT * FROM "Assignment" ORDER BY "id"` | 사용자 테이블 |
| `sqlite_sequence` | `SELECT name, seq FROM sqlite_sequence ORDER BY name` — **테이블이 없으면 빈 배열**로 둔다 | 이후 ID 생성에 영향을 주는 DB 상태. 현재 스키마는 `AUTOINCREMENT`를 쓰지 않아 이 테이블이 없을 수 있으나, 생겼는데도 비교하지 않는 상태를 만들지 않는다 |
| `_prisma_migrations` | **캡처하지 않는다** | 시드가 건드리지 않는 Prisma 내부 테이블이며, 마이그레이션 시각이 들어가 결정성을 해친다 |

```ts
/**
 * 롤백 판정용 전체 DB 스냅샷.
 * 컬럼을 고르지 않는다 — SELECT * 로 모든 컬럼을 그대로 가져온다.
 * id · createdAt · updatedAt · completedAt · bookId를 포함하며, 그것이 이 스냅샷의 요점이다.
 */
async function snapshotDb(client: PrismaClient) {
  const rows = async (sql: string) =>
    (await client.$queryRawUnsafe<Record<string, unknown>[]>(sql)).map(normalizeRow);

  const hasSeq = (
    await client.$queryRawUnsafe<{ n: bigint }[]>(
      `SELECT COUNT(*) AS n FROM sqlite_master WHERE type='table' AND name='sqlite_sequence'`,
    )
  )[0].n > 0n;

  return {
    books:       await rows(`SELECT * FROM "Book" ORDER BY "id"`),
    blocks:      await rows(`SELECT * FROM "ScheduleBlock" ORDER BY "id"`),
    assignments: await rows(`SELECT * FROM "Assignment" ORDER BY "id"`),
    sqliteSequence: hasSeq ? await rows(`SELECT name, seq FROM sqlite_sequence ORDER BY name`) : [],
  };
}
```

**`normalizeRow`의 계약.** 비교를 결정적으로 만들기 위한 **표현 정규화만** 한다. 값을 버리지 않는다.

| 규칙 | 내용 |
|---|---|
| 컬럼 | 행에 존재하는 **모든 키**를 유지한다. 화이트리스트·블랙리스트를 두지 않는다 |
| 정렬 | 행은 SQL의 `ORDER BY "id"`(코드 유닛 비교)로, 각 행의 키는 이름 오름차순으로 정렬해 직렬화한다 |
| `null` | `null`을 그대로 남긴다. `undefined`나 빈 문자열로 바꾸지 않는다 — nullable 값의 차이가 반드시 드러나야 한다 |
| timestamp | `Date`는 `toISOString()`, 정수 epoch는 그대로 둔다. **값을 버리거나 반올림하지 않는다** — `updatedAt` 한 컬럼의 차이가 29b mutation의 유일한 검출 신호다 |
| `BigInt` | `Number`가 아니라 문자열로 직렬화해 정밀도 손실을 막는다 |
| `Buffer` | `toString("hex")` |

**독립 연결에서 다시 읽는다 (R2-04 Round 3 잔여, 요구 9·10).** 실패 후 스냅샷은 `seed()`에 넘긴 클라이언트가 아니라 **같은 파일을 가리키는 새 `PrismaClient`**로 읽고, 읽은 뒤 `$disconnect()` 한다.

```ts
async function snapshotFresh(filePath: string) {
  const fresh = new PrismaClient({ datasources: { db: { url: `file:${filePath}` } } });
  try { return await snapshotDb(fresh); } finally { await fresh.$disconnect(); }
}
```

- **잠금이나 파일 존재 여부로 롤백을 판정하지 않는다.** 판정은 오직 두 스냅샷의 deep equality다. "파일이 있다", "연결이 살아 있다", "예외가 났다"만으로 통과시키지 않는다.
- **fixture를 공유하지 않는다.** 기대값은 `tests/fixtures/seed-expected.ts`도, `seed()`를 다시 부른 결과도 아니다. **`seed()` 호출 직전에 테스트가 직접 찍은 스냅샷**이 유일한 기대값이다. 시드 구현과 기대값이 같은 잘못된 값을 공유할 수 없는 형태다.
- **단정 형태는 언제나 `expect(after).toEqual(before)`다.** "건수가 1이다" 같은 부분 단정만 두지 않는다 — 건수만 보면 값이 바뀐 롤백 실패를 놓친다.
- 롤백 테스트는 **빈 DB**(18b), **기존 사용자 데이터 DB**(18), **`force` 경로**(18c·18d)를 모두 포함한다. 실패 seam은 블록 생성 후(18b·18c)와 과제 생성 후(18d)로 유지된다.

**정상 구현에서 이 스냅샷이 실패하지 않는 이유.** 전체 롤백이 일어나면 `id`·`createdAt`·`updatedAt`을 포함한 모든 컬럼이 트랜잭션 시작 시점 값으로 돌아간다. 전체 컬럼 비교가 통과하지 못하는 경우는 **실제로 커밋된 변경이 남았을 때뿐이다.**

3. **`update: {}`가 Book 정책의 핵심이다** (DR-10). 이미 있는 책의 `language`·`progressUnit`·`totalUnits`·`archivedAt`을 시드값으로 **덮어쓰지 않는다.** 부모가 관리 화면(§6.2-5)에서 단위를 고치거나 책을 보관해 둔 상태에서 시드를 다시 돌려도 그 편집이 살아 있어야 한다.

   - `@updatedAt` 컬럼은 빈 update로도 갱신될 수 있다. 이는 사용자 필드가 아니므로 허용하며, 보존 검증 대상에서 제외한다.

4. **`force`는 `Book`에 아무 영향을 주지 않는다.** 삭제 대상은 `Assignment`와 `ScheduleBlock`뿐이다. 책을 지우면 지난 계획의 표시가 깨지고(D17), 진도 체인(F1)이 끊긴다.

5. **재실행 정책.** 시드는 사용자 데이터를 지우지 않는 것이 기본이다.

| 대상 | 기본 동작 | `force: true` |
|---|---|---|
| `Book` | 항상 title 기준 upsert (`update: {}`) | **동일. 삭제하지 않는다** |
| `ScheduleBlock` | 기존 건수가 0일 때만 생성. 아니면 `skipped.blocks = true` | 전체 삭제 후 재생성 |
| `Assignment` | 기존 건수가 0일 때만 생성. 아니면 `skipped.assignments = true` | 전체 삭제 후 재생성 |

`force`는 환경변수 `SEED_FORCE === "1"`로도 켤 수 있다. `main()`이 이 값을 읽어 `seed(client, { force })`에 넘긴다.

6. `main()`은 `createPrismaClient()`로 클라이언트를 만들고, 결과를 한 줄로 출력한 뒤 `$disconnect()` 한다. 예외가 나면 `process.exitCode = 1`.

   **`main()`이 `seed()`에 넘기는 옵션은 정확히 `{ force }` 하나다.** 세 테스트 seam(`beforeCreateHook`·`afterBlocksHook`·`afterAssignmentsHook`) 중 어느 것도 여기서 만들지 않으며, 환경변수나 CLI 인자로 켤 수 있게 하지 않는다 (요구사항 2-A, 금지 사항).

```
seeded books=9 blocks=10 assignments=27 (skipped: blocks=false assignments=false)
```

7. 과제 생성 시 **책 제목 → id 매핑을 미리 만들어 둔다.** 과제마다 `findUnique`를 호출하지 않는다.

### B. 시드 데이터

8. **책(`Book`) 9권.** 항상 `title` 기준 upsert (D4의 find-or-create). 같은 책이 여러 날에 나오므로 제목당 정확히 1건이어야 진도 체인(F1)이 이어진다. `totalUnits`와 `archivedAt`은 전부 `null`이다.

| # | title | language | progressUnit | 근거 |
|---|---|---|---|---|
| 1 | `Big Note` | `EN` | `CHAPTER` | `ch.6`, `ch.12` |
| 2 | `Kid Spy` | `EN` | `CHAPTER` | `ch.10`, `ch.16` |
| 3 | `13 Tree House` | `EN` | `CHAPTER` | `ch.7`, `ch.13` |
| 4 | `Andrew Lost` | `EN` | `CHAPTER` | 진도 표기 없음 |
| 5 | `wimpy kid` | `EN` | **`PAGE`** | `~p.102`, `~p.217` (F3 — 유일한 페이지 단위 책) |
| 6 | `Jake Drake Bully Buster` | `EN` | `CHAPTER` | 진도 표기 없음 |
| 7 | `엄마 5분만` | `KO` | `CHAPTER` | 진도 표기 없음 |
| 8 | `무지개 물고기` | `KO` | `CHAPTER` | 진도 표기 없음 |
| 9 | `김방구 3` | `KO` | `CHAPTER` | **`3`은 제목의 일부다. 챕터로 파싱하지 말 것** |

9. **시간표 블록(`ScheduleBlock`) 10건.** D11의 표 그대로다. `label`의 가운뎃점은 `·`(U+00B7)이고 앰퍼샌드 앞뒤에 공백이 있다.

   **10건 전부 `date = "2026-07-29"`다** (UR-16, UR-26.1). 블록은 이제 날짜에 속한다.

| # | date | startMinute | endMinute | label | kind | matchType |
|---|---|---|---|---|---|---|
| 1 | `2026-07-29` | 450 | `null` | `기상` | `MARKER` | `null` |
| 2 | `2026-07-29` | 480 | `null` | `아침식사 끝내기` | `MARKER` | `null` |
| 3 | `2026-07-29` | 480 | 600 | `원리셈 · 플라토 · 따플 · 디딤돌` | `STUDY` | `null` |
| 4 | `2026-07-29` | 600 | 660 | `영어책 읽기` | `STUDY` | `ENGLISH_READING` |
| 5 | `2026-07-29` | 660 | 690 | `일기쓰기` | `STUDY` | `DIARY` |
| 6 | `2026-07-29` | 690 | 750 | `점심 & 자유시간` | `MEAL` | `null` |
| 7 | `2026-07-29` | 750 | 765 | `뿌리깊은 국어` | `STUDY` | `null` |
| 8 | `2026-07-29` | 765 | 840 | `영어책 읽기` | `STUDY` | `ENGLISH_READING` |
| 9 | `2026-07-29` | 840 | 900 | `한글책 읽기` | `STUDY` | `KOREAN_READING` |
| 10 | `2026-07-29` | 900 | 1020 | `영어숙제 끝내기` | `STUDY` | `WORKSHEET` |

**9-A. 블록의 날짜에 대하여 (UR-16, UR-26) — 읽고 넘어갈 것.**

- `daily-schedule.jpg`에는 **날짜가 적혀 있지 않다** (MR-20). 그럼에도 블록이 날짜를 갖는 이유는 사용자 요구가 "**특정 하루**의 계획표"이고(UR-07), "날짜 없이 매일 반복" 모델이 2026-08-01에 **명시적으로 거절**되었기 때문이다 (UR-16).
- **왜 하루분 10건인가:** UR-24.5가 블록 수를 **10건**으로 고정한다. 파일럿 기간 20일 전체에 넣으면 200건이 되어 그 조건과 충돌한다.
- **왜 `2026-07-29`인가:** **사용자가 지정했다** (UR-26, 2026-08-01). 파일럿 기간의 첫 날짜를 **대표 일일 시간표 날짜**로 정한 것이다. **이미지에서 판독한 날짜가 아니다** — `2026`이라는 연도에 대한 UR-15.3과 같은 성질이며, 완료 보고에서 "사진에서 읽었다"고 쓰지 않는다.
- **`2026-07-29`는 제품 전체에 하드코딩되는 불변값이 아니다** (UR-26.6). 파일럿 시드용 값이다. `prisma/seed.ts`의 시드 표 밖에서 이 문자열을 참조하는 로직을 만들지 않는다.
- **다른 19일에 시간표를 자동 복제하지 않는다** (UR-26.2). 20일치를 만들어 넣는 구현은 UR-24.5(10건)와도 충돌한다.
- **결과: 시드 직후 `2026-07-29` 외의 19일은 시간표가 비어 있다. 이것은 의도된 동작이다** (UR-26.2, UR-26.4). 결함이 아니며 **완료 보고에서 실패로 보고하지 않는다.** 시간표 템플릿·반복은 MVP 밖이므로(UR-26.3, NR-03) 사용자가 날짜별로 입력한다 (UR-26.5). 화면은 그 상태를 "이 날짜의 시간표가 없음"으로 표시한다 (UR-26.4, `architecture.md` §6.2-2 — 담당은 후속 화면 태스크다).
- 이 날짜를 바꾸라는 지시를 받으면 **요구사항 9의 표와 fixture의 값만** 바꾼다. 다른 로직은 날짜 값에 의존하지 않아야 한다.

10. **과제(`Assignment`) 27건.** §0.1의 실물 계획표에서 판독 가능한 항목 전부다. **모든 행의 `startUnit`은 `null`, `status`는 `PLANNED`, `completedAt`은 `null`이다.**

| # | date | orderIndex | type | title | book | endUnit |
|---|---|---|---|---|---|---|
| 1 | 2026-07-29 | 0 | `ENGLISH_READING` | `null` | Big Note | 6 |
| 2 | 2026-07-29 | 1 | `DIARY` | `일기` | `null` | `null` |
| 3 | 2026-07-30 | 0 | `ENGLISH_READING` | `null` | Big Note | 12 |
| 4 | 2026-07-30 | 1 | `WORKSHEET` | `work sheet` | `null` | `null` |
| 5 | 2026-07-31 | 0 | `KOREAN_READING` | `null` | 엄마 5분만 | `null` |
| 6 | 2026-07-31 | 1 | `KOREAN_READING` | `null` | 무지개 물고기 | `null` |
| 7 | 2026-08-01 | 0 | `ENGLISH_READING` | `null` | Kid Spy | 10 |
| 8 | 2026-08-01 | 1 | `DIARY` | `일기` | `null` | `null` |
| 9 | 2026-08-01 | 2 | `KOREAN_READING` | `null` | 김방구 3 | `null` |
| 10 | 2026-08-02 | 0 | `ENGLISH_READING` | `null` | Kid Spy | 16 |
| 11 | 2026-08-02 | 1 | `WORKSHEET` | `work sheet` | `null` | `null` |
| 12 | 2026-08-04 | 0 | `ENGLISH_READING` | `null` | 13 Tree House | 7 |
| 13 | 2026-08-04 | 1 | `DIARY` | `일기` | `null` | `null` |
| 14 | 2026-08-05 | 0 | `ENGLISH_READING` | `null` | 13 Tree House | 13 |
| 15 | 2026-08-05 | 1 | `WORKSHEET` | `work sheet` | `null` | `null` |
| 16 | 2026-08-06 | 0 | `ENGLISH_READING` | `null` | Andrew Lost | `null` |
| 17 | 2026-08-06 | 1 | `WORKSHEET` | `work sheet` | `null` | `null` |
| 18 | 2026-08-07 | 0 | `DIARY` | `일기` | `null` | `null` |
| 19 | 2026-08-08 | 0 | `ENGLISH_READING` | `null` | wimpy kid | 102 |
| 20 | 2026-08-08 | 1 | `DIARY` | `일기` | `null` | `null` |
| 21 | 2026-08-09 | 0 | `ENGLISH_READING` | `null` | wimpy kid | 217 |
| 22 | 2026-08-09 | 1 | `WORKSHEET` | `work sheet` | `null` | `null` |
| 23 | 2026-08-11 | 0 | `ENGLISH_READING` | `null` | Jake Drake Bully Buster | `null` |
| 24 | 2026-08-11 | 1 | `DIARY` | `일기` | `null` | `null` |
| 25 | 2026-08-12 | 0 | `ENGLISH_READING` | `null` | Jake Drake Bully Buster | `null` |
| 26 | 2026-08-12 | 1 | `PROJECT` | `reading project` | `null` | `null` |
| 27 | 2026-08-13 | 0 | `PROJECT` | `reading project` | `null` | `null` |

**2026-08-03, 08-10, 08-14 ~ 08-17에는 과제를 만들지 않는다.** 실물이 빈칸이다 (F7).

11. 필드 규칙 요약:
    - **읽기 유형**(`ENGLISH_READING` / `KOREAN_READING`): `bookId`는 해당 책, `title`은 `null` (§1.3 — 비면 책 제목을 쓴다).
    - **비읽기 유형**(`DIARY` / `WORKSHEET` / `PROJECT`): `title`은 표의 문자열, `bookId`·`startUnit`·`endUnit`은 전부 `null` (I2).
    - **`startUnit`은 27건 전부 `null`** (D5 — 시작점은 실물에 없으므로 파생되게 둔다).

12. **7/29의 한글책(`김치찌…`)은 시드하지 않는다.** 사진에서 판독되지 않는다 (부록 C.2-1, Q2). 제목을 추측해 채우지 않는다 (CLAUDE.md). 그 결과 7/29의 `orderIndex`는 빈 자리 없이 `0, 1`이다.

### C. 기대 fixture (`tests/fixtures/seed-expected.ts`)

13. **`prisma/seed.ts`와 `tests/fixtures/seed-expected.ts`는 서로 import 하지 않는다** (DR-09). 위 세 표를 **두 번 독립적으로 옮겨 적는 것이 의도다.** 시드가 fixture를 import 하거나 그 반대가 되면 비교 테스트가 아무것도 증명하지 않는다.

14. fixture는 세 개의 정렬된 상수 배열을 export 한다. ID와 timestamp처럼 비결정적인 필드는 포함하지 않는다.

```ts
export interface ExpectedBook {
  title: string;
  language: "EN" | "KO";
  progressUnit: "CHAPTER" | "PAGE";
  totalUnits: number | null;
  archivedAt: Date | null;
}

export interface ExpectedBlock {
  date: string;              // UR-16 — 블록이 속한 날짜. 10건 전부 "2026-07-29" (UR-26.1)
  startMinute: number;
  endMinute: number | null;
  label: string;
  kind: "STUDY" | "MEAL" | "FREE" | "MARKER";
  matchType: string | null;
}

export interface ExpectedAssignment {
  date: string;
  orderIndex: number;
  type: string;
  title: string | null;
  bookTitle: string | null;   // bookId는 cuid라 비결정적 → 제목으로 대조한다
  startUnit: number | null;
  endUnit: number | null;
  status: string;
  completedAt: Date | null;
}

export const EXPECTED_BOOKS: readonly ExpectedBook[] = [ /* 9건, title 오름차순 */ ];
export const EXPECTED_BLOCKS: readonly ExpectedBlock[] = [ /* 10건 */ ];
export const EXPECTED_ASSIGNMENTS: readonly ExpectedAssignment[] = [ /* 27건 */ ];
```

15. **정렬 규칙.** 조회 결과와 fixture 양쪽에 같은 규칙을 적용한다.

| 배열 | 정렬 키 |
|---|---|
| `EXPECTED_BOOKS` | `title` 오름차순 |
| `EXPECTED_BLOCKS` | **`date`** → `startMinute` → `endMinute ?? -1` → `label` 오름차순 (UR-16) |
| `EXPECTED_ASSIGNMENTS` | `date` → `orderIndex` 오름차순 |

16. **문자열 정렬은 비교 연산자(코드 유닛 순서)로 한다. `localeCompare`를 쓰지 않는다** — ICU 버전과 로케일에 따라 한글·숫자 혼합 정렬 결과가 달라져 테스트가 환경에 의존하게 된다. 코드 유닛 순서에서 `EXPECTED_BOOKS`의 순서는 아래와 같다.

```
13 Tree House, Andrew Lost, Big Note, Jake Drake Bully Buster,
Kid Spy, wimpy kid, 김방구 3, 무지개 물고기, 엄마 5분만
```

(숫자 < 대문자 < 소문자 < 한글 순이므로 `wimpy kid`가 `Kid Spy` 뒤, 한글 앞에 온다.)

17. `EXPECTED_BLOCKS`의 정렬 결과는 요구사항 9의 표 순서와 같다. 10건의 `date`가 전부 같으므로 첫 정렬 키는 동점이고, 480분에 두 건이 있으나 `endMinute ?? -1`이 `아침식사 끝내기`(-1)를 `원리셈 · 플라토 · 따플 · 디딤돌`(600)보다 앞에 둔다. **`date`를 첫 키로 두는 이유는 시드가 한 날짜분이라서가 아니라, 여러 날짜가 생겼을 때도 같은 규칙이 성립해야 하기 때문이다** (UR-16).

### D. 설정 변경

18. `package.json`:
    - `scripts`에 `"db:seed": "DATABASE_URL=${DATABASE_URL:-file:./dev.db} tsx prisma/seed.ts"` 추가
    - 기존 `db:setup`을 아래 문자열로 **정확히** 수정한다.

```
npm run db:deploy && npm run db:wal && npm run db:seed
```

19. `src/server/prisma.test.ts`의 `EXPECTED_DB_URL_SCRIPTS`에 `"db:seed"`를 추가해 정렬을 유지한다 (T03 요구사항 17). 갱신하지 않으면 T03의 exact match 테스트가 실패한다 — 그것이 그 테스트의 목적이다.

```ts
const EXPECTED_DB_URL_SCRIPTS = [
  "db:deploy",
  "db:diff",
  "db:generate",
  "db:migrate",
  "db:seed",
  "db:validate",
  "db:wal",
] as const;
```

20. **`db:setup`의 구성과 순서를 자동으로 검사한다 (RR-03).** `src/server/prisma.test.ts`의 `describe("D19 기본값 일관성")` 안에 아래 테스트를 **추가**한다. 기존 테스트는 고치지 않는다.

```ts
const EXPECTED_DB_SETUP = "npm run db:deploy && npm run db:wal && npm run db:seed";

it("db:setup이 db:deploy → db:wal → db:seed 순서로 조합된다", ...);
```

    - `package.json`을 읽어 `scripts["db:setup"]`을 `EXPECTED_DB_SETUP`과 **문자열 exact match**로 비교한다.
    - 부분 문자열 포함(`includes`), 정규식 느슨한 매칭, 하위 명령 집합 비교를 쓰지 않는다. **순서가 검증 대상이므로 exact match여야 한다.**
    - 이 테스트가 필요한 이유: 기존 `기본값 리터럴을 갖는 스크립트 집합이 기대와 정확히 일치한다`는 **`DATABASE_URL=` 리터럴을 갖는 스크립트의 이름 집합**만 본다. `db:setup`은 리터럴이 없으므로 그 검사의 대상이 아니고, 따라서 `db:seed`를 빼먹거나 순서를 바꿔도 그 테스트는 초록이다. RR-03이 지적한 구멍이 정확히 이 지점이다.
    - `db:setup`에 `DATABASE_URL=` 리터럴이 없다는 기존 테스트(`db:setup은 기본값 리터럴을 갖지 않는다`)는 그대로 유지한다. 두 테스트는 서로 다른 것을 본다.

## 비즈니스 규칙

**테스트는 번호가 아니라 이름으로 참조한다** (DR-13).

| 규칙 | 위반 시 동작 (검증 테스트명) |
|---|---|
| 책·블록·과제의 모든 값이 표와 정확히 일치 (부록 C) | `Book 9건이 기대 fixture와 정확히 일치한다` / `ScheduleBlock 10건이 기대 fixture와 정확히 일치한다` / `Assignment 27건이 기대 fixture와 정확히 일치한다` |
| 책은 제목당 1건 (D4, F1) | `같은 책이 여러 날에 나와도 Book은 제목당 1건이다` |
| `startUnit`은 전부 `null` (D5) | `모든 과제의 startUnit이 null이고 status가 PLANNED다` |
| 읽기 유형 ⟺ `bookId != null` (I1), 비읽기는 진도 필드 없음 (I2) | `읽기 과제와 비읽기 과제의 필드 조건이 I1·I2를 만족한다` |
| `endMinute == null` ⟺ `kind == MARKER` (I8) | `마커 블록 2건만 endMinute이 null이고 kind가 MARKER다` |
| **같은 날짜 안에서** 범위 블록끼리 겹치지 않는다 (I9, D15, UR-16) | `같은 날짜의 범위 블록끼리 시간이 겹치지 않는다` |
| 블록은 날짜에 속한다 (UR-16) | `모든 블록이 같은 날짜에 속한다` / `ScheduleBlock 10건이 기대 fixture와 정확히 일치한다` |
| 판독 불가 항목을 추측해 채우지 않는다 (부록 C.2-1) | `2026-07-29에는 과제가 2건이고 한글책 과제가 없다` / `판독 불가 항목을 임의로 채우지 않는다` |
| 기본 시드는 기존 데이터를 덮어쓰거나 지우지 않는다 (DR-10) | `기존 과제가 있으면 다시 만들지 않는다` / `기본 시드는 기존 Book의 사용자 필드를 보존한다` / `기본 시드는 기존 블록과 과제를 보존한다` |
| force 중 실패하면 전부 롤백된다 (DR-10) | `force 중 실패하면 삭제가 롤백된다` |
| **생성 단계 도중 실패해도 전부 롤백된다 — 블록 생성 후, 과제 생성 후 모두** (R2-04) | `블록 생성 도중 실패하면 새 DB에 아무 행도 남지 않는다` / `블록 생성 후 실패하면 force가 지운 사용자 데이터가 복원된다` / `과제 생성 후 실패하면 블록과 과제가 모두 롤백된다` |
| **롤백 판정은 fixture가 아니라 호출 전 전체 DB 스냅샷과 비교한다** (R2-04, 요구사항 2-B) | 위 네 테스트(18·18b·18c·18d)가 `expect(after).toEqual(before)`가 아니거나 `snapshotDb`가 전체 컬럼을 담지 않으면 요구사항 2-B 미충족 |
| force는 Book을 지우지 않는다 (DR-10) | `force는 Book을 삭제하지 않는다` |
| `김방구 3`의 `3`을 챕터로 파싱하지 않는다 | `김방구 3의 제목이 그대로 저장되고 진도가 파싱되지 않는다` |
| `db:setup`은 `db:deploy → db:wal → db:seed` 순서로 조합된다 (RR-03) | `db:setup이 db:deploy → db:wal → db:seed 순서로 조합된다` |
| 개발 DB(`prisma/dev.db`와 `-wal`·`-shm`·`-journal`)는 완료 검증으로 변하지 않는다 (DR-11, T03 16e와 같은 4파일) | 완료 조건 2의 불변 검사가 종료 코드 `2`로 실패 |

## 테스트 케이스

**케이스 1~29는 `tests/integration/seed.test.ts`에, 케이스 30~32는 `src/server/prisma.test.ts`에 작성한다.** 후자는 DB에 붙지 않는 `package.json` 텍스트 검사이며, T03이 만든 파일에 대한 의도된 소유권 예외다 (RR-03 — "변경 대상 파일" 참조).

`tests/integration/seed.test.ts`는 `beforeEach`에서 `createTestDb()`, `afterEach`에서 `cleanup()`, `afterAll`에서 `cleanupAllTestDbs()`를 부른다 (T03 헬퍼).

### 정상 케이스 — exact match (DR-09의 핵심)

| # | 테스트명 | 입력 | 기대 결과 |
|---|---|---|---|
| 1 | `Book 9건이 기대 fixture와 정확히 일치한다` | 시드 후 전체 조회 → 요구사항 14의 필드만 추출 → 요구사항 15로 정렬 | `EXPECTED_BOOKS`와 deep equal |
| 2 | `ScheduleBlock 10건이 기대 fixture와 정확히 일치한다` | 같은 방식 | `EXPECTED_BLOCKS`와 deep equal |
| 3 | `Assignment 27건이 기대 fixture와 정확히 일치한다` | 같은 방식. `bookId`는 `bookTitle`로 변환 | `EXPECTED_ASSIGNMENTS`와 deep equal |
| 4 | `시드 결과 건수가 9·10·27이다` | `seed(prisma)` | `books=9`, `blocks=10`, `assignments=27`, `skipped` 둘 다 `false` |

1~3번이 통과하면 총 건수·제목·언어·단위·label·시각·type·date·orderIndex·endUnit이 **전부** 대조된다. 아래 일반 불변식 테스트는 그와 별개로 유지한다 — 불변식은 "표가 맞다"와 다른 것을 증명하며, 후속 태스크가 시드를 바꿀 때 규칙 위반을 잡는다.

### 정상 케이스 — 일반 불변식

| # | 테스트명 | 입력 | 기대 결과 |
|---|---|---|---|
| 5 | `같은 책이 여러 날에 나와도 Book은 제목당 1건이다` | 시드 후 조회 | `Big Note`, `Kid Spy`, `13 Tree House`, `wimpy kid`, `Jake Drake Bully Buster` 각각 1건 |
| 6 | `wimpy kid만 PAGE 단위이고 나머지 8권은 CHAPTER다` | 시드 후 조회 | `progressUnit === "PAGE"`인 책이 1건 |
| 7 | `모든 과제의 startUnit이 null이고 status가 PLANNED다` | 시드 후 조회 | `startUnit != null` 0건, `status != "PLANNED"` 0건 |
| 8 | `읽기 과제와 비읽기 과제의 필드 조건이 I1·I2를 만족한다` | 시드 후 조회 | 읽기는 `bookId != null && title == null`, 비읽기는 `bookId == null && title != null && startUnit == null && endUnit == null` |
| 9 | `마커 블록 2건만 endMinute이 null이고 kind가 MARKER다` | 시드 후 조회 | `endMinute == null` 2건, 그 2건의 `kind`가 `MARKER`, 나머지 8건은 `endMinute != null && kind != "MARKER"` |
| 10 | `같은 날짜의 범위 블록끼리 시간이 겹치지 않는다` | 시드 후 조회 | **`date`로 묶은 뒤** 각 그룹 안에서 `endMinute != null`을 `startMinute` 오름차순 정렬 시 모든 인접 쌍이 `prev.endMinute <= next.startMinute` (I9, UR-16). **다른 날짜끼리는 비교하지 않는다** |
| 10b | `모든 블록이 같은 날짜에 속한다` | 시드 후 조회 | 10건의 `date`가 전부 `"2026-07-29"` (요구사항 9, UR-26.1). **다른 날짜의 블록은 0건** — 자동 복제 금지(UR-26.2)를 함께 고정한다 |
| 11 | `matchType이 지정된 블록은 5건이다` | 시드 후 조회 | `ENGLISH_READING` 2건, `DIARY` 1건, `KOREAN_READING` 1건, `WORKSHEET` 1건 |
| 12 | `김방구 3의 제목이 그대로 저장되고 진도가 파싱되지 않는다` | 시드 후 조회 | `title === "김방구 3"`, `language === "KO"`, 그 책의 과제 1건의 `endUnit === null` |
| 13 | `2026-07-29에는 과제가 2건이고 한글책 과제가 없다` | 시드 후 조회 | 2건, `type` 집합이 `{ENGLISH_READING, DIARY}`, `orderIndex`가 `[0, 1]` |
| 14 | `wimpy kid의 진도 체인 근거가 저장된다` | 시드 후 조회 | `2026-08-08`의 `endUnit === 102`, `2026-08-09`의 `endUnit === 217` |

### 규칙 위반 케이스 — 데이터 보존과 롤백 (DR-10)

아래 테스트들은 **사용자 데이터 fixture를 먼저 만든 뒤** 시드를 돌린다. fixture는 시드 표에 없는 값이어야 한다. **예외는 케이스 18b 하나로, 그것은 fixture 없이 빈 DB에서 돈다** — 새 DB에서의 생성 도중 실패를 보기 위함이다 (R2-04, 요구사항 2-A).

사용자 fixture 정의: `Big Note`를 `progressUnit=PAGE`, `totalUnits=99`, `archivedAt=2026-07-30T00:00:00Z`로 생성 / `date="2026-08-20", startMinute=1200, endMinute=1260, label="사용자 블록", kind=FREE`인 블록 1건 — **시드 블록의 날짜(`2026-07-29`)와 다른 날짜를 쓴다.** 같은 날짜를 쓰면 보존 검증이 겹침 규칙과 얽힌다 / `date="2026-08-20", orderIndex=0, type=DIARY, title="사용자 과제"`인 과제 1건.

| # | 테스트명 | 입력 | 기대 결과 |
|---|---|---|---|
| 15 | `기존 과제가 있으면 다시 만들지 않는다` | fixture 생성 후 `seed(prisma)` | 과제 1건 유지, `result.assignments === 0`, `result.skipped.assignments === true` |
| 16 | `기본 시드는 기존 Book의 사용자 필드를 보존한다` | 같은 조건 | `Big Note`의 `progressUnit === "PAGE"`, `totalUnits === 99`, `archivedAt`이 그대로. **`updatedAt`은 검사하지 않는다** (요구사항 3) |
| 17 | `기본 시드는 기존 블록과 과제를 보존한다` | 같은 조건 | `사용자 블록`과 `사용자 과제`가 그대로 존재하고 블록·과제 총 건수가 각각 1 |
| 18 | `force 중 실패하면 삭제가 롤백된다` | fixture 생성 후 `snapshotFresh(filePath)` → `seed(prisma, { force: true, beforeCreateHook: () => { throw new Error("boom"); } })` | 호출이 reject되고, 호출 후 `snapshotFresh(filePath)`가 **호출 전 스냅샷과 deep equal**이다 (`사용자 블록`·`사용자 과제`가 그대로, 블록·과제 각각 1건) |
| 18b | `블록 생성 도중 실패하면 새 DB에 아무 행도 남지 않는다` | **빈 DB**(fixture 없음)에서 `snapshotFresh(filePath)`(= 네 배열 모두 빈 상태) → `seed(prisma, { afterBlocksHook: () => { throw new Error("blocks boom"); } })` | 호출이 reject되고 호출 후 `snapshotFresh(filePath)`가 **호출 전 스냅샷과 deep equal**이다 — 즉 `Book` 0건, `ScheduleBlock` **0건**, `Assignment` 0건. **블록 10건이 이미 만들어진 뒤 실패했는데도 하나도 남지 않는다** — 블록 생성이 트랜잭션 밖이면 10건이 남아 실패한다 (R2-04) |
| 18c | `블록 생성 후 실패하면 force가 지운 사용자 데이터가 복원된다` | fixture 생성 후 `snapshotFresh(filePath)` → `seed(prisma, { force: true, afterBlocksHook: () => { throw new Error("blocks boom"); } })` | 호출이 reject되고 호출 후 `snapshotFresh(filePath)`가 **호출 전 스냅샷과 deep equal**이다. 즉 삭제된 `사용자 블록`·`사용자 과제`가 돌아오고, 시드 블록은 **0건**이며, `Big Note`의 사용자 필드(`PAGE`/`99`/`archivedAt`)도 그대로다 |
| 18d | `과제 생성 후 실패하면 블록과 과제가 모두 롤백된다` | fixture 생성 후 `snapshotFresh(filePath)` → `seed(prisma, { force: true, afterAssignmentsHook: () => { throw new Error("assignments boom"); } })` | 호출이 reject되고 호출 후 `snapshotFresh(filePath)`가 **호출 전 스냅샷과 deep equal**이다. 블록 총 1건(`사용자 블록`)·과제 총 1건(`사용자 과제`)이며 시드 27건은 **0건**이다 — 과제 생성이 트랜잭션 밖이면 27건이 남아 실패한다 (R2-04) |
| 19 | `force는 Book을 삭제하지 않는다` | fixture 생성 후 `seed(prisma, { force: true })` | `Big Note`가 존재하고 `totalUnits === 99` 유지. 책 총 9권 |
| 20 | `판독 불가 항목을 임의로 채우지 않는다` | 시드 후 전체 과제·책 조회 | `title`과 책 제목 어디에도 `김치`가 포함된 건이 0건 |

### 경계 케이스

| # | 테스트명 | 입력 | 기대 결과 |
|---|---|---|---|
| 21 | `시드를 두 번 실행해도 과제가 늘지 않는다` | `seed` → `seed` | 과제 27건 유지, 두 번째 `skipped.assignments === true` |
| 22 | `force로 재실행해도 중복이 생기지 않는다` | `seed` → `seed(prisma, { force: true })` | 과제 27건, 블록 10건, 책 9권. **케이스 3의 exact match를 다시 통과한다** |
| 23 | `계획이 없는 날에는 과제가 0건이다` | 시드 후 조회 | `2026-08-03`, `08-10`, `08-14`, `08-15`, `08-16`, `08-17` 전부 0건 |
| 24 | `모든 과제 날짜가 방학 기간 안이다` | 시드 후 조회 | 모든 `date`가 `"2026-07-29" <= date <= "2026-08-17"` (D18, 문자열 비교 — D9) |
| 25 | `블록의 시각이 0 이상 1440 이하다` | 시드 후 조회 | `startMinute`이 `0..1439`, `endMinute`이 있으면 `startMinute < endMinute <= 1440` (I7) |
| 26 | `블록만 있고 과제가 없는 DB에서는 과제만 채운다` | 블록 1건만 만든 뒤 `seed(prisma)` | `skipped.blocks === true`, `skipped.assignments === false`, 과제 27건 생성 |

### 규칙 위반 케이스 — 검증이 실제로 작동하는지 (mutation 확인)

DR-09가 요구한 절차다. **`prisma/seed.ts`를 임시로 고쳐** exact match 테스트가 실패하는지 확인하고 되돌린다. fixture가 아니라 구현을 고치는 것이 요점이다 — fixture를 고치면 "비교가 살아 있다"만 알 수 있고 "시드가 표와 같다"는 증명되지 않는다.

| # | 케이스명 | 임시 변경 | 기대 결과 |
|---|---|---|---|
| 27 | 책 표의 셀 변경이 잡히는가 | `Andrew Lost`의 `progressUnit`을 `PAGE`로 | `Book 9건이 기대 fixture와 정확히 일치한다`가 실패 |
| 28 | 블록 표의 셀 변경이 잡히는가 | `뿌리깊은 국어`의 `label`을 `뿌리깊은국어`로 (공백 제거) | `ScheduleBlock 10건이 기대 fixture와 정확히 일치한다`가 실패 |
| 28b | 블록 날짜 변경이 잡히는가 (UR-16) | 블록 1건의 `date`를 `2026-07-30`으로 | `ScheduleBlock 10건이 기대 fixture와 정확히 일치한다`와 `모든 블록이 같은 날짜에 속한다`가 **둘 다** 실패 |
| 29 | 과제 표의 셀 변경이 잡히는가 | `2026-08-09`의 `endUnit`을 `217` → `218`로 | `Assignment 27건이 기대 fixture와 정확히 일치한다`가 실패 |
| 29b | **Book upsert가 트랜잭션 안에 있는가** (R2-04 Round 3) | 요구사항 2의 **1단계(Book 9권 upsert)** 를 `$transaction(...)` **호출 이전**으로 끌어올려 `client`로 수행하고, 트랜잭션 안에서는 1단계를 건너뛰도록 임시 변경 | `force 중 실패하면 삭제가 롤백된다`(18)와 `블록 생성 후 실패하면 force가 지운 사용자 데이터가 복원된다`(18c)가 **실패한다.** 트랜잭션 밖에서 커밋된 Book 9권의 신규 행과 기존 `Big Note`의 `updatedAt` 변화가 전체 컬럼 스냅샷에서 드러난다 (요구사항 2-B). **확인 후 되돌린다** |
| 29c | **블록 생성이 트랜잭션 안에 있는가** (R2-04) | 요구사항 2의 **4단계(블록 10건 생성)** 를 `$transaction(...)` **호출 이전**으로 끌어올려 `client`로 수행하고, 트랜잭션 안에서는 4단계를 건너뛰도록 임시 변경 | `블록 생성 도중 실패하면 새 DB에 아무 행도 남지 않는다`(18b)와 `블록 생성 후 실패하면 force가 지운 사용자 데이터가 복원된다`(18c)가 **둘 다** 실패한다. 커밋된 블록 10건이 스냅샷에 남는다. **확인 후 되돌린다** |
| 29d | **과제 생성이 트랜잭션 안에 있는가** (R2-04) | 요구사항 2의 **6단계(과제 27건 생성)** 를 `$transaction(...)` **호출 이전**으로 끌어올려 `client`로 수행하고, 트랜잭션 안에서는 6단계를 건너뛰도록 임시 변경 | `과제 생성 후 실패하면 블록과 과제가 모두 롤백된다`(18d)가 실패한다. 커밋된 과제 27건이 스냅샷에 남는다. **확인 후 되돌린다** |
| 29e | **트랜잭션 경계 자체가 있는가** (R2-04) | `$transaction(async (tx) => { ... })` 래퍼를 제거하고 1~7단계를 `client` 위에서 **순차 실행**하도록 임시 변경 (hook 호출 위치는 그대로) | 롤백 테스트 **4건 전부**(18·18b·18c·18d)가 실패한다. **확인 후 되돌린다** |

**아홉 명령(27·28·28b·29·29b·29c·29d·29e·30 계열)의 실제 출력을 완료 보고에 포함하고, 코드는 원상 복구된 상태여야 한다.** 원복 후 `git diff prisma/seed.ts`가 비어 있어야 한다.

**29b~29e가 R2-04의 핵심이다.** 이 mutation들이 없으면 "전체 시드가 하나의 트랜잭션"이라는 요구는 문서상의 주장일 뿐이고, 어떤 단계를 트랜잭션 밖으로 뺀 구현도 exact match 테스트와 기존 rollback 테스트를 전부 통과한다.

**왜 "두 번째 writer 연결"이 아니라 "트랜잭션 시작 전으로 끌어올리기"인가 (R2-04 Round 3 잔여 2).** Round 2까지의 mutation은 트랜잭션이 **열려 있는 동안** 별도 클라이언트로 같은 SQLite 파일에 쓰게 했다. SQLite는 writer를 하나만 허용하므로 그 쓰기는 `SQLITE_BUSY`/timeout으로 거절될 수 있고, 그러면 **행이 하나도 남지 않은 채** 호출이 reject되어 잘못된 구현이 롤백 테스트를 통과한다 — mutation의 실패 이유가 "부분 저장"이 아니라 "잠금"이 되는 거짓 양성이다. 위 네 mutation은 전부 **트랜잭션이 시작되기 전**에 단일 연결로 쓰기를 끝내므로 동시 writer도 `SQLITE_BUSY`도 발생하지 않는다.

| 성질 | Round 2 mutation (제거됨) | 현재 mutation 29b~29e |
|---|---|---|
| 두 번째 writer 연결 | 필요 | **없음** — 시종일관 `client` 하나 |
| `SQLITE_BUSY` 가능성 | 있음 | **없음** — 트랜잭션 열림 구간과 겹치지 않는다 |
| 실패 seam이 던질 때의 DB 상태 | 불확정 (쓰기가 거절됐을 수 있음) | **최소 한 건의 write가 이미 커밋됨** |
| 테스트가 실패하는 이유 | 잠금 오류일 수도, 부분 저장일 수도 | **부분 저장 하나뿐** — 전체 컬럼 스냅샷의 deep equality 불일치 |
| 존재하지 않는 ID 사용 | — | **없음** |

**seam의 타입·기본값·호출 위치와 운영 경로 비노출.**

| 항목 | 값 |
|---|---|
| 타입 | `beforeCreateHook`·`afterBlocksHook`·`afterAssignmentsHook` 모두 `(() => Promise<void> \| void) \| undefined` |
| 기본값 | `undefined`. 세 hook 모두 **선택 필드**이며 `SeedOptions`를 생략하면 하나도 주입되지 않는다 |
| 호출 위치 | 요구사항 2의 3·5·7단계. **트랜잭션 콜백 안에서 `await`로** 부른다 (`await options?.xxxHook?.()`) |
| 호출 횟수 | 주입된 경우 요청당 정확히 1회 |
| 주입 주체 | **통합 테스트뿐이다.** `prisma/seed.ts`의 `main()`은 `{ force }`만 넘기며 세 hook을 절대 넘기지 않는다 |
| 운영 API 노출 | 없음. `main()`·`db:seed`·`db:setup` 어느 경로에서도 hook을 읽거나 환경변수로 주입할 수 없다. 환경변수로 hook을 켜는 스위치를 만들지 않는다 |

**production 호출 경로에서 seam이 주입되지 않는다는 조건.** `npm run db:seed`와 `npm run db:setup`은 `main()`만 실행하고, `main()`은 `seed(prisma, { force: <SEED_FORCE 해석값> })` 형태로만 호출한다. 따라서 운영 경로에서 세 hook은 항상 `undefined`이며 시드 동작은 hook이 없는 것과 동일하다.

### 정상 케이스 — 스크립트 구성 (`src/server/prisma.test.ts`, RR-03)

| # | 테스트명 | 입력 | 기대 결과 |
|---|---|---|---|
| 30 | `db:setup이 db:deploy → db:wal → db:seed 순서로 조합된다` | `package.json`의 `scripts["db:setup"]` | 문자열이 정확히 `npm run db:deploy && npm run db:wal && npm run db:seed` |

### 규칙 위반 케이스 — `db:setup` mutation (RR-03)

`package.json`을 임시로 고쳐 케이스 30이 실제로 살아 있는지 확인하고 되돌린다.

| # | 케이스명 | 임시 변경 | 기대 결과 |
|---|---|---|---|
| 31 | `db:seed` 누락이 잡히는가 | `db:setup`을 `"npm run db:deploy && npm run db:wal"`로 | 케이스 30이 실패. 완료 검증 스크립트(완료 조건 2)의 `assignments=27` 단정도 실패 |
| 32 | 순서 변경이 잡히는가 | `db:setup`을 `"npm run db:deploy && npm run db:seed && npm run db:wal"`로 | 케이스 30이 실패 |

**두 명령의 실제 출력을 완료 보고에 포함하고, `package.json`은 원상 복구된 상태여야 한다.** 원복 후 `git diff package.json`이 요구사항 18의 변경만 보여야 한다.

31번이 두 곳에서 잡히는 것이 요점이다 — **문자열 검사(케이스 30)와 실제 실행(완료 조건 2)이 서로를 대신하지 않는다.** 문자열만 보면 스크립트가 실제로 도는지 모르고, 실행만 보면 순서 실수를 놓칠 수 있다.

## 완료 조건

### 1. 테스트

```
npm run typecheck                → 에러 0
npm run lint                     → 에러 0
npm test -- --reporter=verbose   → 실패 0건. 정상 케이스 1~14(10b 포함)·30,
                                   위반 15~20(**18b·18c·18d 포함**),
                                   경계 21~26의 테스트명이 모두 출력에 나타난다
npm run build                    → 성공
npm run e2e                      → 실패 0건
```

**누적 테스트 개수를 완료 조건으로 쓰지 않는다.** 명명된 테스트 이름이 `--reporter=verbose` 출력에 나타나는 것으로 판정한다.

**아래 네 롤백 테스트의 이름이 출력에 없으면 완료 조건 미충족이다** (R2-04). 이름을 바꾸거나 합치지 않는다.

```
force 중 실패하면 삭제가 롤백된다
블록 생성 도중 실패하면 새 DB에 아무 행도 남지 않는다
블록 생성 후 실패하면 force가 지운 사용자 데이터가 복원된다
과제 생성 후 실패하면 블록과 과제가 모두 롤백된다
```

### 2. `db:setup` 실행 검증 — 격리된 임시 DB에서만 (DR-11, RR-03)

**검증 대상은 `npm run db:setup` 자체다.** T04가 바꾸는 핵심 운영 경로가 그것이고, CI의 e2e job도 그 스크립트를 부른다 (T03 요구사항 25). **하위 script(`db:deploy`/`db:wal`/`db:seed`)를 따로 실행하고 `db:setup`을 검증했다고 하지 않는다** — 그렇게 하면 `db:seed` 누락이나 순서 실수가 그대로 통과한다.

**개발 DB(`prisma/dev.db`)를 비우거나 `SEED_FORCE`로 덮어쓰지 않는다.** 완료 출력(9/10/27)은 빈 DB에서만 나오므로, 개발 DB에 데이터가 있으면 설계대로 skip되어 0이 출력된다. 그것은 정상 동작이며 완료 실패가 아니다. 따라서 검증은 새 임시 DB에서 수행한다.

#### 2-1. 개발 DB 불변 검사의 범위 (DR-11)

**본체 하나가 아니라 아래 네 파일 전부**를 검증 전후로 비교한다. 개발 DB는 WAL 모드이므로(T03), 오작동한 명령의 쓰기가 `-wal`에만 남아 **본체 checksum이 같을 수 있다.** 본체만 보면 그 변경을 놓친다.

**보호 대상 집합은 T03 정상 케이스 16e와 정확히 같은 네 파일이다.** 두 태스크가 같은 개발 DB를 다른 범위로 보호하면, 한쪽이 놓치는 파일이 생긴다 (T03 13-11).

| 파일 | 없을 때 |
|---|---|
| `prisma/dev.db` | 존재 여부 자체를 `absent`로 **기록한다** (검사 생략이 아니다) |
| `prisma/dev.db-wal` | 같음 |
| `prisma/dev.db-shm` | 같음 |
| `prisma/dev.db-journal` | 같음 |

- 존재하는 파일은 `shasum -a 256`의 해시를 기록한다.
- **존재하지 않던 파일이 생기거나, 있던 파일이 사라지는 것도 변경이다.** 그래서 존재 여부를 상태의 일부로 기록한다.
- 네 파일이 모두 없는 깨끗한 저장소에서도 전후 스냅샷이 같으므로 검사는 그대로 성립한다.
- **이 검사는 개발 DB 파일을 만들거나 지우거나 고치지 않는다.** `prisma/dev.db-journal`이 존재하면 해시를 기록해 전후를 비교하고, 존재하지 않으면 `absent` 상태가 전후 동일한지만 확인한다. 없는 파일을 만들어 두고 검사하지 않는다.

#### 2-2. 검증 스크립트

**정상 경로와 실패 경로 모두에서 불변 검사가 실행되어야 한다.** 그래서 `set -e`로 중간에 빠져나가지 않고, `EXIT` trap 하나가 cleanup과 불변 검사를 모두 책임진다.

```bash
#!/usr/bin/env bash
# 저장소 루트에서 실행한다. bash로 실행한다(배열을 쓴다).
set -u          # -e를 쓰지 않는다 — 원래 종료 코드를 직접 다뤄야 하기 때문이다.

VERIFY_DB="$PWD/.tmp/verify-setup-$$.db"
mkdir -p "$PWD/.tmp"

DEV_DB_FILES=("prisma/dev.db" "prisma/dev.db-wal" "prisma/dev.db-shm" "prisma/dev.db-journal")

snapshot_dev_db() {
  local f
  for f in "${DEV_DB_FILES[@]}"; do
    if [ -e "$f" ]; then
      printf '%s present %s\n' "$f" "$(shasum -a 256 "$f" | awk '{print $1}')"
    else
      printf '%s absent -\n' "$f"
    fi
  done
}

BEFORE="$(snapshot_dev_db)"
printf '개발 DB 사전 상태:\n%s\n' "$BEFORE"

CLEANUP_FAILED=0
CHECK_FAILED=0

finish() {
  ORIGINAL_STATUS=$?          # trap 진입 시점의 종료 코드를 가장 먼저 저장한다
  trap - EXIT                 # 재진입 방지

  # (1) cleanup — 임시 DB와 sidecar
  rm -f "$VERIFY_DB" "$VERIFY_DB-wal" "$VERIFY_DB-shm" "$VERIFY_DB-journal" || CLEANUP_FAILED=1

  # (2) 개발 DB 불변 검사 — 정상 경로와 실패 경로 모두에서 실행된다
  AFTER="$(snapshot_dev_db)"
  if [ "$BEFORE" = "$AFTER" ]; then
    printf '개발 DB 불변 확인:\n%s\n' "$AFTER"
  else
    printf '개발 DB가 변경되었다.\n--- BEFORE ---\n%s\n--- AFTER ---\n%s\n' \
      "$BEFORE" "$AFTER" >&2
    CHECK_FAILED=1
  fi

  # (3) 종료 코드 우선순위 — 아래 순서로 판정한다
  #     2: 개발 DB 불변 검사 실패  (가장 심각 — 사용자 데이터가 변했다)
  #     3: cleanup 실패            (임시 파일이 남았다)
  #     그 외: 원래 검증 명령의 종료 코드를 그대로 보존한다
  if [ "$CHECK_FAILED" -ne 0 ]; then exit 2; fi
  if [ "$CLEANUP_FAILED" -ne 0 ]; then exit 3; fi
  exit "$ORIGINAL_STATUS"
}
trap finish EXIT

# --- 검증 본문 ---------------------------------------------------------
# SEED_FORCE는 반드시 명시적으로 unset 한다. 셸에 남아 있던 값을 상속하면
# 의도치 않게 force 경로가 돌아 검증의 의미가 사라진다 (DR-11).

# (A) db:setup 한 번으로 migration · WAL · seed가 모두 수행된다
env -u SEED_FORCE DATABASE_URL="file:$VERIFY_DB" npm run db:setup || exit $?

# (B) 단일 db:setup 실행 결과를 한 번에 확인한다
env -u SEED_FORCE DATABASE_URL="file:$VERIFY_DB" node -e '
const { PrismaClient } = require("@prisma/client");
const c = new PrismaClient({ datasourceUrl: process.env.DATABASE_URL });
(async () => {
  const mode = (await c.$queryRawUnsafe("PRAGMA journal_mode;"))[0].journal_mode;
  const applied = Number(
    (await c.$queryRawUnsafe(
      "SELECT COUNT(*) AS n FROM _prisma_migrations WHERE finished_at IS NOT NULL"
    ))[0].n
  );
  const books = await c.book.count();
  const blocks = await c.scheduleBlock.count();
  const assignments = await c.assignment.count();
  await c.$disconnect();
  console.log(
    `migrations=${applied} journal_mode=${mode} ` +
    `books=${books} blocks=${blocks} assignments=${assignments}`
  );
  const ok = applied >= 1 && mode === "wal" &&
             books === 9 && blocks === 10 && assignments === 27;
  process.exit(ok ? 0 : 1);
})().catch((e) => { console.error(e); process.exit(1); });
' || exit $?

# (C) 재실행 멱등성 — db:seed는 건너뛴다
env -u SEED_FORCE DATABASE_URL="file:$VERIFY_DB" npm run db:seed || exit $?

exit 0
```

#### 2-3. 실행 순서와 기대

trap 설치부터 종료까지의 순서는 **모호함 없이 아래 하나뿐이다.**

```
1. BEFORE 스냅샷 (존재 여부 + 해시, 4파일)
2. trap finish EXIT 설치
3. 검증 본문 (A) → (B) → (C) 실행
4. (어떤 경로로 끝나든) trap 진입
5.   ORIGINAL_STATUS 저장
6.   cleanup: 임시 .db / -wal / -shm / -journal 삭제
7.   AFTER 스냅샷 + BEFORE와 비교
8.   종료 코드 판정: 불변 검사 실패(2) > cleanup 실패(3) > ORIGINAL_STATUS
```

| 단계 | 기대 |
|---|---|
| (A) `db:setup` | `journal_mode=wal`과 `seeded books=9 blocks=10 assignments=27 (skipped: blocks=false assignments=false)`가 **한 번의 실행**으로 나온다 |
| (B) 단일 실행 결과 확인 | `migrations=1 journal_mode=wal books=9 blocks=10 assignments=27`, 종료 코드 0 |
| (C) 2회차 `db:seed` | `skipped: blocks=true assignments=true`, 종료 코드 0 |
| 개발 DB 4파일 | 존재 여부와 해시가 전후 동일 (`prisma/dev.db`·`-wal`·`-shm`·`-journal`) |
| cleanup | 임시 `.db`·`-wal`·`-shm`·`-journal` 전부 삭제 |
| 최종 종료 코드 | 위 전부 만족 시 `0` |

`migrations`가 `0`이면 마이그레이션이 적용되지 않은 것이다. 값이 `1`이 아니라 그 이상이면 마이그레이션이 추가된 것이므로 `>= 1`로 판정한다.

완료 보고에 위 스크립트의 **실제 출력 전문**과, mutation 케이스 27~29·31·32의 출력을 포함한다.

## 금지 사항

- **완료 검증을 위해 `prisma/dev.db`를 지우거나 `SEED_FORCE=1`로 실행하지 않는다** (DR-11). 개발 DB를 대상으로 `db:setup`·`db:deploy`·`db:seed`·`prisma migrate`·`prisma migrate reset` 중 어느 것도 완료 검증의 일부로 실행하지 않는다.
- **완료 검증에서 `SEED_FORCE`를 상속하지 않는다.** 모든 검증 명령을 `env -u SEED_FORCE`로 실행한다 (DR-11).
- **개발 DB 불변 검사를 `prisma/dev.db` 본체 하나로 줄이지 않는다.** `-wal`·`-shm`·`-journal`을 함께 본다 (DR-11의 2-1). **보호 대상 4파일은 T03 정상 케이스 16e와 같은 집합이며, 한쪽만 줄이지 않는다.**
- **하위 script만 따로 실행하고 `db:setup`을 검증했다고 보고하지 않는다** (RR-03). 완료 조건 2의 (A)는 `npm run db:setup` 한 줄이어야 한다.
- 완료 검증의 `DATABASE_URL`을 상대 경로나 개발 DB 경로로 두지 않는다. `.tmp/` 아래의 **절대 경로**를 쓴다 (D19의 상대 경로 함정).
- `prisma/seed.ts`가 `tests/fixtures/seed-expected.ts`를 import 하지 않는다. 그 반대도 금지 (DR-09).
- `update: {}` 대신 시드값을 넣어 기존 Book을 덮어쓰지 않는다 (DR-10).
- `force`에서 `Book`을 `deleteMany` 하지 않는다.
- **삭제·생성을 트랜잭션 밖에서 수행하지 않는다.** Book upsert·삭제·블록 생성·과제 생성이 **전부** 같은 `tx` 위에서 일어난다 (요구사항 2). 위반 케이스 29b·29c·29d·29e는 검증용 임시 변경이며 반드시 원복한다.
- **롤백 검증에 두 번째 writer 연결이나 `SQLITE_BUSY`를 쓰지 않는다.** 존재하지 않는 Assignment ID로 실패를 만드는 방법도 쓰지 않는다 (R2-04 Round 3).
- **`beforeCreateHook`·`afterBlocksHook`·`afterAssignmentsHook`을 `main()`이나 프로덕션 경로에서 넘기지 않는다.** `main()`이 만드는 옵션 객체는 정확히 `{ force }`이며 hook 키를 포함하지 않는다. 세 hook은 `seed()`의 **선택적 인자로만** 존재하고, 환경변수·CLI 인자·HTTP 요청 등 어떤 외부 입력으로도 켤 수 없다 (T03 스펙 미정 7과 같은 원칙).
- 테스트를 위해 시드 로직을 복제한 **별도의 "테스트용 시드 함수"를 만들지 않는다.** 롤백 테스트는 실제 `seed()`를 그대로 호출해야 한다 (요구사항 2-A).
- **롤백 테스트의 판정을 `tests/fixtures/seed-expected.ts`와의 비교로 바꾸지 않는다.** 호출 전 스냅샷과 비교한다 (요구사항 2-B).
- `package.json`에 `"prisma": { "seed": ... }` 설정을 추가하지 않는다. `prisma db seed` 경로는 D19의 기본값 주입을 거치지 않아 `.env` 없는 환경에서 실패한다. 시드 실행은 `npm run db:seed`만 쓴다.
- `김치찌…`를 포함해 판독 불가 항목을 어떤 이름으로도 시드하지 않는다.
- `startUnit`에 값을 넣지 않는다. 계산해서 채우는 것도 금지다 (D5가 기각한 A안).
- 진도 표기가 없는 책에 `endUnit`을 추정해 넣지 않는다 (F4).
- `Book.totalUnits`를 채우지 않는다. 실물에 없는 정보다.
- 과제 상태를 `DONE`으로 시드하지 않는다. 지난 날짜 정리는 T17의 일괄 완료 기능이 담당한다 (부록 C.3).
- `tests/helpers/db.ts`를 **어떤 이유로도 수정하지 않는다** (T03 소관). 헬퍼 변경이 필요하다고 판단되면 멈추고 보고한다.
- `src/server/prisma.test.ts`에서 **요구사항 19·20이 지정한 두 변경 외의 것을 하지 않는다.** 기존 테스트를 고치거나 지우지 않는다.
- `db:setup` 검증을 부분 문자열 포함이나 하위 명령 집합 비교로 바꾸지 않는다. exact match여야 순서가 검증된다 (RR-03).
- `src/server/prisma.ts`, `prisma/schema.prisma`, `vitest.config.ts`, `.github/workflows/ci.yml`을 수정하지 않는다. T03이 이미 필요한 상태로 만들어 두었다.
- 새 npm 의존성을 추가하지 않는다.

## 스펙 미정 사항

| # | 지점 | 결정 |
|---|---|---|
| 1 | 7/29 한글책 제외로 생기는 `orderIndex` 빈자리 | **빈자리를 남기지 않는다.** `0, 1`로 연속시킨다. 실물의 세로 위치를 보존할 이유가 없고, T17에서 사용자가 추가하면 끝에 붙는다 |
| 2 | 시드의 기본 파괴성 | **비파괴가 기본.** `force`는 명시적으로 켜야 한다 |
| 3 | Book upsert의 update 분기 | **`update: {}`.** 기존 사용자 편집을 보존한다. `@updatedAt` 갱신은 허용하고 검증 대상에서 제외한다 (DR-10) |
| 4 | `force`가 Book에 미치는 영향 | **없다.** 삭제 대상은 `Assignment`·`ScheduleBlock`뿐이다 |
| 5 | 트랜잭션 경계 | 책 upsert부터 과제 생성까지 **전부 하나의 `$transaction`** (요구사항 2). `timeout: 30_000` |
| 6 | 테스트 seam 3종 (`beforeCreateHook`, `afterBlocksHook`, `afterAssignmentsHook`) | 롤백을 결정적으로 검증할 다른 방법이 없다. 세 위치가 각각 **삭제 단계 / 블록 생성 이후 / 과제 생성 이후**의 실패를 만든다 (요구사항 2-A, R2-04). T03의 `afterCopyHook` 계열과 같은 패턴이며 `main()`·프로덕션 경로에는 넘기지 않는다 |
| 6b | 롤백 판정 기준 | **호출 전 스냅샷과의 deep equal** (요구사항 2-B). fixture와 비교하면 시드와 fixture가 같은 잘못된 값을 공유할 때 거짓 양성이 된다. 건수만 보는 부분 단정도 쓰지 않는다 |
| 7 | fixture 중복 전사 | **의도된 중복이다** (DR-09). 두 파일이 서로를 참조하면 비교가 무의미해진다. 표가 바뀌면 두 곳을 함께 고치고, 그 사실을 PR 본문에 적는다 |
| 8 | 문자열 정렬 방식 | 코드 유닛 비교. `localeCompare` 금지 (요구사항 16) |
| 9 | `bookId` 비교 방법 | cuid는 비결정적이므로 `bookTitle`로 변환해 비교한다 (요구사항 14) |
| 10 | 완료 검증 DB의 위치 | `.tmp/verify-setup-$$.db` 절대 경로. `.gitignore`의 `/.tmp/`가 T03에서 이미 추가되어 있다 |
| 11 | 시드를 CI에서 돌릴 것인가 | 돌린다. T03이 e2e job에 `db:setup`을 넣어두었고 `db:setup`이 이제 `db:seed`를 포함한다. E2E 시나리오는 시드 데이터를 전제로 한다. **CI를 다시 고치지 않으므로 `db:setup` 조합 자체가 T04의 검증 대상이다** (RR-03) |
| 12 | `SeedResult.books`의 의미 | 신규 생성이 아니라 **upsert된 총 건수**(항상 9). 책은 건너뛰기 대상이 아니다 |
| 13 | 블록과 과제의 건너뛰기 판정 | 각각 독립적으로 자기 테이블의 건수만 본다. 한쪽만 비어 있어도 그쪽만 채운다 (경계 케이스 26) |
| 14 | `.tmp/` 정리 | `cleanup()`이 개별 DB를 지우고 템플릿만 남는다. 스키마가 바뀌면 T03의 지문 검사가 템플릿을 자동 재생성하므로 수동 `rm -rf .tmp`는 필요하지 않다 |
| 15 | `db:setup`을 두 곳에서 검증하는 이유 | 문자열 검사(케이스 30)는 **순서와 구성**을, 실행 검사(완료 조건 2)는 **실제로 동작하는지**를 본다. 어느 한쪽도 다른 쪽을 대신하지 못한다 (RR-03) |
| 16 | 완료 검증의 종료 코드 우선순위 | **불변 검사 실패(2) > cleanup 실패(3) > 원래 명령의 종료 코드.** 개발 데이터 변경이 가장 심각하므로 다른 실패를 덮어쓴다. 반대로 하면 검증 명령이 실패한 실행에서 데이터 변경 사실이 묻힌다 (DR-11) |
| 17 | `set -e`를 쓰지 않는 이유 | 원래 명령의 종료 코드를 보존하고 실패 경로에서도 불변 검사를 돌려야 하기 때문이다. `set -e`는 중간 실패 시 즉시 빠져나가 `ORIGINAL_STATUS` 판정을 어렵게 만든다. 대신 각 명령에 `\|\| exit $?`를 붙이고 `EXIT` trap 하나가 정리·검사를 책임진다 (DR-11) |
| 18 | 개발 DB 불변 검사에 sidecar를 포함하는 이유 | 개발 DB는 WAL 모드(T03)이므로 쓰기가 `-wal`에만 남아 **본체 해시가 그대로일 수 있다.** 본체만 보면 변경을 놓친다. 존재 여부까지 상태로 기록하는 이유는 파일이 새로 생기거나 사라지는 것도 변경이기 때문이다 (DR-11). `-journal`을 포함하는 이유는 WAL 적용 전 구간이나 비정상 종료 후에 rollback journal이 남을 수 있고, **T03 16e가 보호하는 집합과 범위를 하나로 맞춰야 하기 때문이다** |
| 19 | `SEED_FORCE` unset을 명시하는 이유 | 셸에 남아 있던 값을 상속하면 완료 검증이 조용히 force 경로를 타고, 그 결과 "비파괴가 기본"이라는 성질이 검증되지 않는다. 모든 검증 명령에 `env -u SEED_FORCE`를 붙인다 (DR-11) |
