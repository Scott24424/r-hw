# T04 시드 데이터 · 테스트 DB 헬퍼

## 목표

`architecture.md` 부록 C의 시드(책 9권 · 시간표 블록 10개 · 과제 27건)를 넣고, 이후 모든 통합 테스트가 쓸 격리된 임시 DB 헬퍼를 만든다.

## 선행 태스크

T03

## 변경 대상 파일

생성:

- `prisma/seed.ts`
- `tests/helpers/db.ts`
- `tests/integration/seed.test.ts`

수정:

- `package.json`
- `vitest.config.ts`
- `.gitignore`

**이 목록 밖의 파일은 생성·수정하지 않는다.** 새 의존성을 추가하지 않으므로 `package-lock.json`은 바뀌지 않는다.

## 구현 요구사항

### A. 시드 (`prisma/seed.ts`)

1. 파일은 **함수를 export 하고**, 그 함수를 부르는 `main()`을 함께 둔다. 통합 테스트가 프로세스를 띄우지 않고 함수를 직접 부를 수 있어야 한다.

```ts
export interface SeedResult {
  books: number;        // upsert된 책 수
  blocks: number;       // 생성된 블록 수 (건너뛰었으면 0)
  assignments: number;  // 생성된 과제 수 (건너뛰었으면 0)
  skipped: { blocks: boolean; assignments: boolean };
}

export async function seed(
  client: PrismaClient,
  options: { force?: boolean } = {},
): Promise<SeedResult>;
```

2. **책(`Book`)은 항상 `title` 기준 upsert 한다** (D4의 find-or-create). 같은 책이 여러 날에 나오므로 제목당 정확히 1건이어야 진도 체인(F1)이 이어진다.

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

`totalUnits`와 `archivedAt`은 전부 `null`이다.

3. **시간표 블록(`ScheduleBlock`) 10건**을 D11의 표 그대로 넣는다. 순서도 이 표와 같게 한다.

| # | startMinute | endMinute | label | kind | matchType |
|---|---|---|---|---|---|
| 1 | 450 | `null` | `기상` | `MARKER` | `null` |
| 2 | 480 | `null` | `아침식사 끝내기` | `MARKER` | `null` |
| 3 | 480 | 600 | `원리셈 · 플라토 · 따플 · 디딤돌` | `STUDY` | `null` |
| 4 | 600 | 660 | `영어책 읽기` | `STUDY` | `ENGLISH_READING` |
| 5 | 660 | 690 | `일기쓰기` | `STUDY` | `DIARY` |
| 6 | 690 | 750 | `점심 & 자유시간` | `MEAL` | `null` |
| 7 | 750 | 765 | `뿌리깊은 국어` | `STUDY` | `null` |
| 8 | 765 | 840 | `영어책 읽기` | `STUDY` | `ENGLISH_READING` |
| 9 | 840 | 900 | `한글책 읽기` | `STUDY` | `KOREAN_READING` |
| 10 | 900 | 1020 | `영어숙제 끝내기` | `STUDY` | `WORKSHEET` |

`label`의 가운뎃점은 `·`(U+00B7)이고 앰퍼샌드 앞뒤에 공백이 있다. 문자열을 그대로 옮긴다.

4. **과제(`Assignment`) 27건**을 아래 표 그대로 넣는다. §0.1의 실물 계획표에서 판독 가능한 항목만이다.

| date | orderIndex | type | book / title | endUnit |
|---|---|---|---|---|
| 2026-07-29 | 0 | `ENGLISH_READING` | Big Note | 6 |
| 2026-07-29 | 1 | `DIARY` | `일기` | — |
| 2026-07-30 | 0 | `ENGLISH_READING` | Big Note | 12 |
| 2026-07-30 | 1 | `WORKSHEET` | `work sheet` | — |
| 2026-07-31 | 0 | `KOREAN_READING` | 엄마 5분만 | `null` |
| 2026-07-31 | 1 | `KOREAN_READING` | 무지개 물고기 | `null` |
| 2026-08-01 | 0 | `ENGLISH_READING` | Kid Spy | 10 |
| 2026-08-01 | 1 | `DIARY` | `일기` | — |
| 2026-08-01 | 2 | `KOREAN_READING` | 김방구 3 | `null` |
| 2026-08-02 | 0 | `ENGLISH_READING` | Kid Spy | 16 |
| 2026-08-02 | 1 | `WORKSHEET` | `work sheet` | — |
| 2026-08-04 | 0 | `ENGLISH_READING` | 13 Tree House | 7 |
| 2026-08-04 | 1 | `DIARY` | `일기` | — |
| 2026-08-05 | 0 | `ENGLISH_READING` | 13 Tree House | 13 |
| 2026-08-05 | 1 | `WORKSHEET` | `work sheet` | — |
| 2026-08-06 | 0 | `ENGLISH_READING` | Andrew Lost | `null` |
| 2026-08-06 | 1 | `WORKSHEET` | `work sheet` | — |
| 2026-08-07 | 0 | `DIARY` | `일기` | — |
| 2026-08-08 | 0 | `ENGLISH_READING` | wimpy kid | 102 |
| 2026-08-08 | 1 | `DIARY` | `일기` | — |
| 2026-08-09 | 0 | `ENGLISH_READING` | wimpy kid | 217 |
| 2026-08-09 | 1 | `WORKSHEET` | `work sheet` | — |
| 2026-08-11 | 0 | `ENGLISH_READING` | Jake Drake Bully Buster | `null` |
| 2026-08-11 | 1 | `DIARY` | `일기` | — |
| 2026-08-12 | 0 | `ENGLISH_READING` | Jake Drake Bully Buster | `null` |
| 2026-08-12 | 1 | `PROJECT` | `reading project` | — |
| 2026-08-13 | 0 | `PROJECT` | `reading project` | — |

**2026-08-03, 08-10, 08-14 ~ 08-17에는 과제를 만들지 않는다.** 실물이 빈칸이다 (F7).

5. 과제 필드 규칙:
   - **읽기 유형**(`ENGLISH_READING` / `KOREAN_READING`): `bookId`는 해당 책, `title`은 `null` (§1.3 — 비면 책 제목을 쓴다), `endUnit`은 표의 값.
   - **비읽기 유형**(`DIARY` / `WORKSHEET` / `PROJECT`): `title`은 표의 문자열, `bookId`·`startUnit`·`endUnit`은 전부 `null` (I2).
   - **`startUnit`은 27건 전부 `null`** (D5 — 시작점은 실물에 없으므로 파생되게 둔다).
   - `status`는 전부 `PLANNED`, `completedAt`은 `null`.

6. **7/29의 한글책(`김치찌…`)은 시드하지 않는다.** 사진에서 판독되지 않는다 (부록 C.2-1, Q2). 제목을 추측해 채우지 않는다 (CLAUDE.md). 그 결과 7/29의 `orderIndex`는 빈 자리 없이 `0, 1`이다.

7. **재실행 안전성.** 시드는 사용자 데이터를 지우지 않는 것이 기본이다.

| 대상 | 기본 동작 | `force: true` |
|---|---|---|
| `Book` | 항상 `title` 기준 upsert | 동일 |
| `ScheduleBlock` | 기존 건수가 0일 때만 생성. 아니면 건너뛰고 `skipped.blocks = true` | 전체 삭제 후 재생성 |
| `Assignment` | 기존 건수가 0일 때만 생성. 아니면 건너뛰고 `skipped.assignments = true` | 전체 삭제 후 재생성 |

`force`는 환경변수 `SEED_FORCE === "1"`로도 켤 수 있다. `main()`이 이 값을 읽어 `seed(client, { force })`에 넘긴다.

8. `main()`은 `createPrismaClient()`로 클라이언트를 만들고, 결과를 한 줄로 출력한 뒤 `$disconnect()` 한다. 예외가 나면 `process.exitCode = 1`.

```
seeded books=9 blocks=10 assignments=27 (skipped: blocks=false assignments=false)
```

9. 과제 생성 시 **책 제목 → id 매핑을 미리 만들어 둔다.** 과제마다 `findUnique`를 호출하지 않는다.

### B. 테스트 DB 헬퍼 (`tests/helpers/db.ts`)

10. 아래 API를 export 한다.

```ts
export interface TestDb {
  prisma: PrismaClient;
  url: string;       // file:/절대경로 형태
  filePath: string;  // 절대 경로
  cleanup: () => Promise<void>;
}

export async function createTestDb(): Promise<TestDb>;
```

11. 동작 순서:
    1. 저장소 루트의 `.tmp/` 디렉터리를 보장한다 (`fileURLToPath(new URL("../../", import.meta.url))`로 루트를 구한다).
    2. 템플릿 DB `.tmp/test-template.db`가 없으면 만든다.
       - `.tmp/test-template.<pid>-<랜덤>.db`에 `npx prisma migrate deploy`를 실행한다. `execFileSync`의 `env`에 `DATABASE_URL`을 **절대 경로**로 주고, `cwd`는 저장소 루트로 한다.
       - 완료 후 `fs.renameSync`로 `.tmp/test-template.db`에 옮긴다. rename은 원자적이므로 vitest 워커가 동시에 들어와도 안전하다.
    3. 템플릿을 `.tmp/test-<랜덤>.db`로 복사한다.
    4. 복사본에 `createPrismaClient(url)`로 붙고 `enableWal(client)`를 적용한다.
    5. `cleanup`은 `$disconnect()` 후 `.db` / `.db-wal` / `.db-shm` 세 파일을 지운다 (없으면 무시).

12. **템플릿에는 WAL을 적용하지 않는다.** WAL 상태의 DB를 `-wal` 파일 없이 복사하면 해석이 애매해진다. WAL은 복사본마다 4번 단계에서 적용한다.

13. 경로는 **전부 절대 경로**로 다룬다. 상대 경로는 `schema.prisma` 기준으로 해석되므로(D19) 테스트에서 쓰면 위치를 예측하기 어렵다.

14. `createTestDb()`는 시드를 실행하지 않는다. 시드가 필요한 테스트가 직접 `seed(db.prisma)`를 부른다. **빈 DB가 기본값이다** — 후속 태스크의 통합 테스트는 대부분 자기 픽스처를 만든다.

### C. 설정 변경

15. `package.json`:
    - `scripts`에 `"db:seed": "DATABASE_URL=${DATABASE_URL:-file:./dev.db} tsx prisma/seed.ts"` 추가
    - 기존 `db:setup`을 `"npm run db:deploy && npm run db:wal && npm run db:seed"`로 수정
    - 최상위에 `"prisma": { "seed": "tsx prisma/seed.ts" }` 추가 (`prisma db seed` 지원)

16. `vitest.config.ts`: `testTimeout`을 `30_000`으로 올리고 `hookTimeout: 30_000`을 추가한다. 첫 통합 테스트가 템플릿 DB 마이그레이션을 수행하므로 10초로는 부족하다.

17. `.gitignore`에 `/.tmp/`를 추가한다. 기존 항목은 지우지 않는다.

## 비즈니스 규칙

| 규칙 | 위반 시 동작 |
|---|---|
| 책은 제목당 1건 (D4, F1) | 같은 제목이 2건 생기면 테스트 2 실패. 진도 체인이 끊긴다 |
| `startUnit`은 전부 `null` (D5) | 테스트 4 실패. 시작점을 저장하면 D5가 기각한 A안이 된다 |
| 읽기 유형 ⟺ `bookId != null` (I1) | 테스트 5 실패 |
| 비읽기 유형은 `startUnit`·`endUnit`이 `null` (I2) | 테스트 5 실패 |
| `endMinute == null` ⟺ `kind == MARKER` (I8) | 테스트 6 실패 |
| 범위 블록끼리 겹치지 않는다 (I9, D15) | 테스트 7 실패 |
| 판독 불가 항목을 추측해 채우지 않는다 (부록 C.2-1) | 테스트 10·13 실패 |
| 기존 데이터가 있으면 덮어쓰지 않는다 | 테스트 12 실패. 부모가 입력한 계획이 시드 재실행으로 사라진다 |
| `김방구 3`의 `3`을 챕터로 파싱하지 않는다 | 테스트 9 실패 |

## 테스트 케이스

전부 `tests/integration/seed.test.ts`에 작성한다. 각 테스트는 `beforeEach`에서 `createTestDb()`, `afterEach`에서 `cleanup()`을 부른다.

### 정상 케이스

| # | 테스트명 | 입력 | 기대 결과 |
|---|---|---|---|
| 1 | `빈 DB에 시드하면 책 9권·블록 10건·과제 27건이 생긴다` | `seed(prisma)` | `books=9`, `blocks=10`, `assignments=27`, `skipped` 둘 다 `false` |
| 2 | `같은 책이 여러 날에 나와도 Book은 제목당 1건이다` | 시드 후 조회 | `Big Note`, `Kid Spy`, `13 Tree House`, `wimpy kid`, `Jake Drake Bully Buster` 각각 정확히 1건 |
| 3 | `wimpy kid만 PAGE 단위이고 나머지 8권은 CHAPTER다` | 시드 후 조회 | `progressUnit === "PAGE"`인 책이 `wimpy kid` 1건 |
| 4 | `모든 과제의 startUnit이 null이고 status가 PLANNED다` | 시드 후 조회 | `startUnit != null`인 과제 0건, `status != "PLANNED"`인 과제 0건 |
| 5 | `읽기 과제와 비읽기 과제의 필드 조건이 I1·I2를 만족한다` | 시드 후 조회 | 읽기 유형은 전부 `bookId != null && title == null`, 비읽기 유형은 전부 `bookId == null && title != null && startUnit == null && endUnit == null` |
| 6 | `마커 블록 2건만 endMinute이 null이고 kind가 MARKER다` | 시드 후 조회 | `endMinute == null`인 블록 2건, 그 2건의 `kind`가 모두 `MARKER`, 나머지 8건은 `endMinute != null && kind != "MARKER"` |
| 7 | `범위 블록끼리 시간이 겹치지 않는다` | 시드 후 조회 | `endMinute != null`인 블록을 `startMinute` 오름차순 정렬했을 때 모든 인접 쌍이 `prev.endMinute <= next.startMinute` |
| 8 | `matchType이 지정된 블록은 5건이다` | 시드 후 조회 | `ENGLISH_READING` 2건, `DIARY` 1건, `KOREAN_READING` 1건, `WORKSHEET` 1건 |
| 9 | `김방구 3의 제목이 그대로 저장되고 진도가 파싱되지 않는다` | 시드 후 조회 | `title === "김방구 3"`, `language === "KO"`, 그 책의 과제 1건의 `endUnit === null` |
| 10 | `2026-07-29에는 과제가 2건이고 한글책 과제가 없다` | 시드 후 조회 | 2건, `type` 집합이 `{ENGLISH_READING, DIARY}`, `orderIndex`가 `[0, 1]` |
| 11 | `2026-08-01의 orderIndex가 0,1,2로 연속이다` | 시드 후 조회 | 3건, `orderIndex` 오름차순이 `[0, 1, 2]` |
| 12 | `wimpy kid의 진도 체인 근거가 저장된다` | 시드 후 조회 | `2026-08-08`의 `endUnit === 102`, `2026-08-09`의 `endUnit === 217` |

### 규칙 위반 케이스

| # | 테스트명 | 입력 | 기대 결과 |
|---|---|---|---|
| 13 | `기존 과제가 있으면 다시 만들지 않는다` | 과제 1건을 직접 생성 후 `seed(prisma)` | 과제 총 1건 유지, `result.assignments === 0`, `result.skipped.assignments === true` |
| 14 | `판독 불가 항목을 임의로 채우지 않는다` | 시드 후 전체 과제·책 조회 | `title`과 책 제목 어디에도 `김치`가 포함된 건이 0건 |
| 15 | `시드를 두 번 실행해도 과제가 늘지 않는다` | `seed` → `seed` | 과제 27건 유지, 두 번째 `result.skipped.assignments === true` |
| 16 | `force로 재실행해도 중복이 생기지 않는다` | `seed` → `seed(prisma, { force: true })` | 과제 27건, 블록 10건, 책 9권 유지 |

### 경계 케이스

| # | 테스트명 | 입력 | 기대 결과 |
|---|---|---|---|
| 17 | `계획이 없는 날에는 과제가 0건이다` | 시드 후 조회 | `2026-08-03`, `2026-08-10`, `2026-08-14`, `2026-08-15`, `2026-08-16`, `2026-08-17` 전부 0건 |
| 18 | `모든 과제 날짜가 방학 기간 안이다` | 시드 후 조회 | 모든 `date`가 `"2026-07-29" <= date <= "2026-08-17"` (D18. 문자열 비교로 판정 — D9) |
| 19 | `블록의 시각이 0 이상 1440 이하다` | 시드 후 조회 | 모든 `startMinute`이 `0..1439`, `endMinute`이 있으면 `startMinute < endMinute <= 1440` (I7) |
| 20 | `테스트 DB에 WAL이 적용된다` | `createTestDb()` 후 `getJournalMode` | `"wal"` |
| 21 | `테스트 DB는 서로 격리된다` | `createTestDb()` 2회 후 한쪽에만 책 1건 생성 | 다른 쪽의 책 수가 0, 두 `filePath`가 서로 다름 |

## 완료 조건

```
npm test        → 기존 7건 + 신규 21건 = 28 passed
npm run db:setup → "seeded books=9 blocks=10 assignments=27" 출력, 종료 코드 0
npm run db:seed  → 2회째 실행 시 skipped=true로 표시되고 종료 코드 0
npm run typecheck → 에러 0
npm run lint      → 에러 0
npm run build     → 성공
npm run e2e       → 1 passed
```

완료 보고에 `npm test`와 `npm run db:setup`의 **실제 출력**을 포함한다.

## 금지 사항

- `김치찌…`를 포함해 판독 불가 항목을 어떤 이름으로도 시드하지 않는다.
- `startUnit`에 값을 넣지 않는다. 계산해서 채우는 것도 금지다 (D5가 기각한 A안).
- 진도 표기가 없는 책에 `endUnit`을 추정해 넣지 않는다 (F4).
- `Book.totalUnits`를 채우지 않는다. 실물에 없는 정보다.
- 과제 상태를 `DONE`으로 시드하지 않는다. 지난 날짜 정리는 T17의 일괄 완료 기능이 담당한다 (부록 C.3).
- `src/` 아래 파일을 만들거나 고치지 않는다. 특히 `src/domain/`은 T05다.
- `src/server/prisma.ts`를 수정하지 않는다. 필요한 함수는 T03에서 이미 export되어 있다.
- 시드에서 `deleteMany`를 무조건 호출하지 않는다. `force`일 때만이다.
- `.github/workflows/ci.yml`을 수정하지 않는다. T03이 `db:setup`을 이미 호출하도록 해두었다.
- 새 npm 의존성을 추가하지 않는다.

## 스펙 미정 사항

| # | 지점 | 결정 |
|---|---|---|
| 1 | 7/29 한글책 제외로 생기는 `orderIndex` 빈자리 | **빈자리를 남기지 않는다.** `0, 1`로 연속시킨다. 실물의 세로 위치를 보존할 이유가 없고, T17에서 사용자가 추가하면 끝에 붙는다 |
| 2 | 시드의 기본 파괴성 | **비파괴가 기본.** `force`는 명시적으로 켜야 한다. 시드는 개발·초기화용이지만 `db:setup`이 실수로 재실행될 수 있다 |
| 3 | 통합 테스트의 DB 격리 | 파일별 임시 DB 복사본. 인메모리 SQLite(`file::memory:`)는 쓰지 않는다 — WAL 검증(테스트 20)과 실제 파일 동작이 달라진다 |
| 4 | 템플릿 DB 재사용 | 재사용한다. 매 테스트마다 `migrate deploy`를 돌리면 통합 테스트가 늘수록 선형으로 느려진다 |
| 5 | `.tmp/` 정리 | 자동 정리하지 않는다. `cleanup()`이 개별 DB를 지우고 템플릿만 남는다. 스키마가 바뀌면 `rm -rf .tmp`로 수동 폐기 — **T05 이후 스키마 변경 태스크의 스펙에 이 절차를 명시할 것** |
| 6 | 시드를 CI에서 돌릴 것인가 | 돌린다. T03이 e2e job에 `db:setup`을 넣어두었고, E2E 시나리오는 시드 데이터를 전제로 한다 |
| 7 | `SeedResult.books`의 의미 | 신규 생성이 아니라 **upsert된 총 건수**(항상 9). 책은 건너뛰기 대상이 아니다 |
| 8 | 블록과 과제의 건너뛰기 판정 | 각각 독립적으로 자기 테이블의 건수만 본다. 한쪽만 비어 있어도 그쪽만 채운다 |
