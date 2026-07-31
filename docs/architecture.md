# r-hw 아키텍처 설계 (초안)

> **이 문서의 독자는 구현 에이전트(Codex)다.**
> Codex는 이 문서와 여기서 파생된 `docs/specs/T##-*.md`만 보고 구현한다.
> 따라서 이 문서는 "무엇을 저장하는가"뿐 아니라 **"왜 그렇게 정했고, 무엇을 기각했는가"**를 남긴다.
> 판단이 필요한 지점에서 이 문서에 답이 없다면, 그것은 설계 누락이다 — 임의로 진행하지 말고 질문할 것.

- 스택(고정): Next.js App Router + TypeScript + Prisma + SQLite / vitest(단위) + Playwright(E2E)
- 근거 자료: `docs/mockups/plan-20days.jpg`, `docs/mockups/daily-schedule.jpg`

---

## 0. 실물 자료에서 읽어낸 사실

설계 판단의 근거이므로 먼저 기록한다. **추측이 아니라 사진에서 직접 관찰된 내용만** 적었다.

### 0.1 `plan-20days.jpg` — 날짜별 과제 계획표

5칸 × 4줄 = 20칸 그리드. 7/29 ~ 8/17.

| 날짜 | 내용 |
|---|---|
| 7/29 | Big Note ch.6 / 김치찌… / 일기 |
| 30 | Big Note ch.12 / work sheet |
| 31 | 엄마 5분만 / 무지개 물고기 |
| 8/1 | Kid Spy ch.10 / 일기 / 김방구 3 |
| 2 | Kid Spy ch.16 / work sheet |
| 3 | *(빈칸, `-` 표시만)* |
| 4 | 13 Tree House ch.7 / 일기 |
| 5 | 13 Tree House ch.13 / work sheet |
| 6 | Andrew Lost / work sheet |
| 7 | 일기 |
| 8 | wimpy kid ~p.102 / 일기 |
| 9 | wimpy kid ~p.217 / work sheet |
| 10 | *(빈칸)* |
| 11 | Jake Drake Bully Buster / 일기 |
| 12 | Jake Drake Bully Buster / reading project |
| 13 | reading project |
| 14~17 | *(빈칸)* |

관찰 사실과 그 함의:

| # | 관찰 | 설계 함의 |
|---|---|---|
| F1 | 같은 책이 연속/근접한 날짜에 반복 등장하고 숫자가 증가한다 (Big Note ch.6 → ch.12, Kid Spy ch.10 → ch.16, wimpy kid ~p.102 → ~p.217) | 진도의 "시작점"은 **같은 책의 직전 계획**에서만 도출된다. 날짜순 직전 과제가 아니다 → 책이 1급 엔티티여야 한다 (**D4**) |
| F2 | 영어책과 한글책이 번갈아 등장한다 (Big Note ↔ 김치찌…, Kid Spy ↔ 김방구 3) | 진도 체인은 **책 단위로 스코프**되어야 한다. 날짜만으로 이어붙이면 다른 책의 챕터를 물려받는다 |
| F3 | 단위가 책마다 다르다: `ch.` (Big Note, Kid Spy, 13 Tree House) vs `p.` (wimpy kid) | 단위(chapter/page)는 **과제가 아니라 책**의 속성이다. 한 책 안에서 단위가 섞이지 않는다 (**D4**) |
| F4 | 진도 표기가 아예 없는 책도 있다 (Andrew Lost, Jake Drake Bully Buster, 엄마 5분만, 무지개 물고기) | 목표 지점(endUnit)은 **nullable**이어야 한다. "오늘은 이 책 읽기"만으로 유효한 과제다 |
| F5 | 시작점은 **어디에도 적혀 있지 않다**. `~p.102`처럼 끝 목표만 적힌다 | 시작점의 부재는 데이터 누락이 아니라 **도메인의 실제 상태**다 → NULL이 의미론적으로 정직한 표현 (**D5**) |
| F6 | 줄마다 펜 색이 다르다 (검정 → 분홍 → 주황 → 빨강) | 계획은 한 번에 다 쓰이지 않고 **5일치씩 점진적으로** 작성됐다. 즉 "지난번 다음"은 *읽은 실적*이 아니라 *직전 계획*을 의미한다 (**D6**) — 8/9를 쓰는 시점에 8/8은 아직 읽지 않았다 |
| F7 | 빈칸에도 `-` 불릿이 미리 그어져 있다 | 칸은 있으나 내용 미정인 상태. 데이터로는 "과제 0건"이지만, **UI는 "계획 없음"을 명시적으로 보여줘야** 한다 |
| F8 | 한 칸에 1~3개가 세로로 순서대로 적힌다 | 날짜 안의 **표시 순서**가 존재한다 → `orderIndex` 필요 |
| F9 | 그리드가 5칸 폭이다 (요일 정렬 아님) | 부모의 멘탈 모델은 "방학 20일"이지 "주"가 아니다. 다만 요구사항의 "이번 주 남은 것"은 주 단위 → 두 모델이 공존한다 (**§8**) |
| F10 | `reading project`가 8/12, 8/13 이틀에 걸쳐 있다 | 다일 과제는 **날짜별 독립 레코드 2건**으로 표현된다. 부모-자식 관계로 모델링할 근거는 사진에 없다 → 과도한 모델링 회피 |

### 0.2 `daily-schedule.jpg` — 매일 반복되는 시간표

```
7:30            기상
8:00            아침식사 끝내기
8:00 ~ 10:00    원리셈 · 플라토 · 따플 · 디딤돌
10:00 ~ 11:00   영어책 읽기
11:00 ~ 11:30   일기쓰기
11:30 ~ 12:30   점심 & 자유시간
12:30 ~ 12:45   뿌리깊은 국어
12:45 ~ 2:00    영어책 읽기
2:00 ~ 3:00     한글책 읽기
3:00 ~ 5:00     영어숙제 끝내기
```

| # | 관찰 | 설계 함의 |
|---|---|---|
| F11 | `7:30 기상`, `8:00 아침식사 끝내기`는 **범위가 아니라 시점**이다. 나머지는 범위다 | `endMinute`을 nullable로 두어 시점 마커를 표현 (**D10**) |
| F12 | `2:00`, `3:00`, `5:00`은 명백히 오후다 (12:45 다음에 2:00이 온다) | 저장은 24시간 기준으로 정규화해야 한다. 문자열 그대로 저장하면 정렬이 깨진다 (**D10**) |
| F13 | `8:00~10:00` 한 블록에 항목이 4개(원리셈/플라토/따플/디딤돌) 들어 있다 | 블록 라벨은 **여러 항목을 담는 자유 텍스트**다. 항목별 체크 요구는 사진에 없다 (**D11-b**) |
| F14 | `영어책 읽기`가 두 블록(10:00~11:00, 12:45~2:00)에 **중복 등장**한다 | 블록 ↔ 과제는 **1:1이 아니다**. 같은 과제가 여러 블록에 걸린다 (**D11**) |
| F15 | 수학(원리셈/플라토/따플/디딤돌)과 뿌리깊은 국어는 **시간표에만 있고 계획표에는 없다** | 모든 시간 블록이 과제와 연결되지는 않는다. 순수 루틴 블록이 존재한다 → 연결은 **optional** |
| F16 | `점심 & 자유시간`처럼 숙제가 아닌 블록도 있다 | 위와 동일. 블록의 성격 구분이 필요 |
| F17 | `8:00 아침식사 끝내기`(시점)와 `8:00~10:00`(범위)이 같은 시각에 공존한다 | 겹침 검증은 **범위끼리만** 적용하고 시점 마커는 제외해야 한다 (**D15**) |
| F18 | 범위 블록끼리는 서로 겹치지 않는다 | 겹침 금지를 불변식으로 세울 수 있다 → "지금 뭐 할 시간?" 질의가 항상 단일 결과 (**D15**) |

### 0.3 두 자료의 관계

시간표의 블록은 **활동 카테고리**이고, 계획표의 항목은 그 카테고리의 **그날의 구체적 인스턴스**다.

```
시간표(매일 반복)                계획표(날짜별)
10:00~11:00 영어책 읽기  ←────  8/2: Kid Spy ch.16
11:00~11:30 일기쓰기     ←────  8/2: (일기 없음 — 8/1에 있음)
2:00~3:00   한글책 읽기  ←────  8/1: 김방구 3
8:00~10:00  원리셈 등     ←────  (대응 없음 — 순수 루틴)
```

이 대응 관계를 **저장할 것인가 파생할 것인가**가 D11의 쟁점이다.

---

## 1. 데이터 모델 (ERD)

### 1.1 개요

```mermaid
erDiagram
    Book ||--o{ Assignment : "읽기 과제의 대상 (nullable)"

    Book {
        string id PK
        string title "책 제목 (표시명 겸 식별용)"
        string language "EN | KO — 책 선택 UI 필터용"
        string progressUnit "CHAPTER | PAGE — 이 책의 진도 단위"
        int totalUnits "총 챕터/페이지 수 (nullable, 실물에 없음)"
        datetime createdAt
        datetime updatedAt
    }

    Assignment {
        string id PK
        string date "YYYY-MM-DD — 계획된 날짜"
        int orderIndex "같은 날짜 안의 표시 순서"
        string type "AssignmentType"
        string title "표시명 (읽기 과제는 nullable)"
        string bookId FK "읽기 과제일 때만 non-null"
        int startUnit "시작 지점 (nullable = 이어서 읽기)"
        int endUnit "목표 지점 (nullable = 목표 미지정)"
        string status "PLANNED | IN_PROGRESS | DONE | SKIPPED"
        datetime completedAt "DONE 진입 시각 (nullable)"
        datetime createdAt
        datetime updatedAt
    }

    ScheduleBlock {
        string id PK
        int startMinute "자정 기준 분 (0~1439)"
        int endMinute "자정 기준 분 (nullable = 시점 마커)"
        string label "블록 이름 (여러 항목 포함 가능)"
        string kind "STUDY | MEAL | FREE | MARKER"
        string matchType "연결할 AssignmentType (nullable = 연결 없음)"
        datetime createdAt
        datetime updatedAt
    }
```

**`ScheduleBlock`과 `Assignment` 사이에 FK가 없다는 점에 주의.** 연결은 `matchType`을 통한 파생 관계다 → **D11** 참조.

### 1.2 Prisma 스키마 (설계 표기 — 이 문서 단계에서 파일로 만들지 않는다)

```prisma
// enum은 Prisma 6.2.0 이상에서만 SQLite에 쓸 수 있다 → D13 참조.
// package.json의 prisma / @prisma/client를 ^6.2.0 이상으로 고정할 것.

enum AssignmentType {
  ENGLISH_READING   // 영어책 읽기 — Big Note, Kid Spy, 13 Tree House, wimpy kid ...
  KOREAN_READING    // 한글책 읽기 — 김방구 3, 엄마 5분만, 무지개 물고기 ...
  WORKSHEET         // work sheet
  DIARY             // 일기
  PROJECT           // reading project
  ETC
}

enum AssignmentStatus {
  PLANNED
  IN_PROGRESS
  DONE
  SKIPPED
}

enum ProgressUnit  { CHAPTER  PAGE }
enum BookLanguage  { EN  KO }
enum BlockKind     { STUDY  MEAL  FREE  MARKER }

model Book {
  id           String       @id @default(cuid())
  title        String       @unique
  language     BookLanguage
  progressUnit ProgressUnit
  totalUnits   Int?
  archivedAt   DateTime?    // non-null = 보관됨. 책 선택 목록에서 숨김 (D17)
  assignments  Assignment[]
  createdAt    DateTime     @default(now())
  updatedAt    DateTime     @updatedAt
}

model Assignment {
  id          String           @id @default(cuid())
  date        String           // "YYYY-MM-DD" — D9 참조 (의도적으로 DateTime이 아님)
  orderIndex  Int              @default(0)
  type        AssignmentType
  title       String?
  bookId      String?
  book        Book?            @relation(fields: [bookId], references: [id])
  startUnit   Int?
  endUnit     Int?
  status      AssignmentStatus @default(PLANNED)
  completedAt DateTime?
  createdAt   DateTime         @default(now())
  updatedAt   DateTime         @updatedAt

  @@index([date, status])   // 오늘 목록 + 밀린 목록 둘 다 커버 (D7)
  @@index([bookId, date])   // 진도 체인 역추적 (D5)
}

model ScheduleBlock {
  id          String          @id @default(cuid())
  startMinute Int
  endMinute   Int?
  label       String
  kind        BlockKind       @default(STUDY)
  matchType   AssignmentType?
  createdAt   DateTime        @default(now())
  updatedAt   DateTime        @updatedAt

  @@index([startMinute])
}
```

### 1.3 필드별 의미 — 모호함 제거

#### `Book`

| 필드 | 의미 | 비고 |
|---|---|---|
| `title` | 책 제목. 사용자가 입력한 문자열 그대로. "김방구 3"처럼 권수가 붙어도 **파싱하지 않는다** | `@unique` — 같은 제목 재입력 시 find-or-create로 재사용해 진도 체인이 끊기지 않게 한다 (F1) |
| `language` | `"EN"` \| `"KO"`. **책 선택 UI의 필터 용도로만 쓴다.** 시간표 매칭에는 쓰지 않는다 | 매칭은 `Assignment.type`으로 한다 → D3 |
| `progressUnit` | `"CHAPTER"` \| `"PAGE"`. 이 책의 진도를 세는 단위 | 과제가 아니라 책에 둔다 (F3). 한 책 안에서 `ch.6 → p.217` 같은 혼용이 원천 차단된다 |
| `totalUnits` | 총 챕터/페이지 수. **nullable** | 실물에는 없는 정보다. 진행률 표시용 선택 항목이며, **없다고 해서 어떤 기능도 막히면 안 된다** |
| `archivedAt` | 보관 시각. non-null이면 **책 선택 목록에서 숨긴다.** 과제 표시·진도 체인에는 계속 참여한다 | D17. 다 읽은 책을 목록에서 치우되 지난 계획 기록은 보존하기 위한 필드 |

#### `Assignment`

| 필드 | 의미 | 비고 |
|---|---|---|
| `date` | 이 과제를 하기로 계획된 날짜. `"YYYY-MM-DD"` 문자열 | D9 참조. 마감일 개념과 동일하다 — 별도 `dueDate`를 두지 않는다 |
| `orderIndex` | 같은 `date` 안에서의 표시 순서. 0부터 | F8. 유니크 제약을 걸지 않는다 → D15-b |
| `type` | `AssignmentType` 중 하나 (§1.4) | |
| `title` | 표시명. **읽기 유형이면 nullable**(비면 책 제목 사용), 비읽기 유형이면 필수 | §1.5 불변식 참조 |
| `bookId` | 읽기 유형일 때 대상 책. **읽기 유형이면 필수, 아니면 반드시 null** | §1.5 불변식 |
| `startUnit` | 시작 지점. **NULL = "직전 계획에 이어서"**, 값 있음 = "명시적으로 지정됨" | D5 — 이 필드의 NULL은 "모름"이 아니라 **"이어서"라는 의미를 갖는다** |
| `endUnit` | 목표 지점 (`~p.102`의 102). **nullable** = 목표 미지정, 그냥 그 책 읽기 | F4 |
| `status` | 저장되는 4개 상태 중 하나 (§3). **`OVERDUE`는 여기 들어가지 않는다** | D7 |
| `completedAt` | `DONE`으로 전이한 시각. `DONE`을 벗어나면 `null`로 되돌린다 | "오늘 몇 개 했나" 집계용 |

#### `ScheduleBlock`

| 필드 | 의미 | 비고 |
|---|---|---|
| `startMinute` | 자정 기준 분. `13:00` → `780` | D10 |
| `endMinute` | 자정 기준 분. **NULL = 시점 마커**(기상, 아침식사 끝내기) | F11 |
| `label` | 블록 이름. `"원리셈 · 플라토 · 따플 · 디딤돌"`처럼 여러 항목이 한 문자열에 들어갈 수 있다 | F13 |
| `kind` | `"STUDY"` \| `"MEAL"` \| `"FREE"` \| `"MARKER"`. **표시 스타일 결정에만 쓴다.** 로직 분기에 쓰지 않는다 | `endMinute == null`이면 `kind`는 `MARKER`여야 한다 (§1.5) |
| `matchType` | 이 블록이 보여줄 `AssignmentType`. **NULL = 연결 없는 순수 루틴 블록** | F15, D11 |

### 1.4 열거값 정의 (단일 출처)

**Prisma 스키마(§1.2)가 유일한 정의처다** (D13). Prisma Client가 값과 타입을 생성하므로 값 목록을 손으로 다시 적지 않는다.

도메인 코드는 `src/domain/enums.ts`에서 **재수출만** 하여 import 경로를 하나로 유지한다. 여기에 손으로 쓴 값 배열을 두지 말 것 — Prisma 스키마와 갈라진다.

```ts
// src/domain/enums.ts — 정의가 아니라 재수출 + 도메인 헬퍼
export { AssignmentType, AssignmentStatus, ProgressUnit, BookLanguage, BlockKind }
  from '@prisma/client';
import { AssignmentType } from '@prisma/client';

/** 읽기 유형 판별. D3에서 영어/한글을 별도 type 값으로 나눈 대가를 여기 한 곳으로 모은다. */
export const READING_TYPES = [
  AssignmentType.ENGLISH_READING,
  AssignmentType.KOREAN_READING,
] as const;

export const isReadingType = (t: AssignmentType): boolean =>
  READING_TYPES.includes(t as (typeof READING_TYPES)[number]);
```

Zod 검증은 `z.nativeEnum(AssignmentType)`을 쓴다. 값 목록을 Zod에 다시 적지 않는다.

> **참고 — `@prisma/client` import에 대하여:** D14는 도메인 계층이 Prisma에 의존하지 않게 하라고 요구하지만, 그 규칙의 대상은 **`PrismaClient` 인스턴스와 I/O**다. 생성된 enum 값·타입을 import 하는 것은 DB 연결을 만들지 않으므로 허용된다. 도메인 함수가 `prisma.assignment.findMany()`를 부르는 것만 금지된다.

### 1.5 불변식 (Invariants) — 반드시 테스트로 고정할 것

Prisma enum 덕분에 **개별 필드의 값 범위는 DB/엔진이 강제한다** (D13). 그러나 아래는 **여러 컬럼에 걸친 조건**이라 Prisma 스키마로 표현할 수 없다. **애플리케이션 계층의 Zod discriminated union + vitest**로 강제한다. 각 항목마다 통과 케이스와 위반 케이스를 모두 작성한다.

| # | 불변식 | 위반 시 |
|---|---|---|
| I1 | `isReadingType(type)` ⟺ `bookId != null` | 400 |
| I2 | `!isReadingType(type)` ⟹ `startUnit == null && endUnit == null` | 400 |
| I3 | 비읽기 유형은 `title`이 공백 아닌 문자열 | 400 |
| I4 | `startUnit != null && endUnit != null` ⟹ `startUnit <= endUnit` | 400 |
| I5 | `startUnit`, `endUnit`은 `>= 1` | 400 |
| I6 | `date`는 유효한 `YYYY-MM-DD` (`2026-02-30` 같은 값 거부) | 400 |
| I7 | `0 <= startMinute <= 1439`, `endMinute`이 있으면 `startMinute < endMinute <= 1440` | 400 |
| I8 | `endMinute == null` ⟺ `kind == 'MARKER'` | 400 |
| I9 | 범위 블록끼리 시간 겹침 금지. 마커는 검증 대상 제외 | 409 |
| I10 | `completedAt != null` ⟺ `status == 'DONE'` | 서비스 계층이 자동 유지 (사용자 입력 아님) |
| I11 | `Book` **하드 삭제** 시 참조하는 `Assignment`가 있으면 거부. 참조가 0건이면 허용 (D17) | 409 + 참조 건수 |
| I12 | 보관된 책(`archivedAt != null`)은 **새 과제 생성 시 선택할 수 없다.** 기존 과제는 그대로 유효 | 400 |

---

## 2. 설계 결정 기록

각 결정은 **선택 / 기각한 대안 / 이유 / 대가**를 남긴다.

---

### D1 — 날짜별 과제와 반복 시간표를 별도 엔티티로 분리한다

**선택:** `Assignment`(날짜 있음)와 `ScheduleBlock`(날짜 없음, 매일 반복)은 완전히 다른 테이블.

**기각한 대안:** 하나의 "할 일" 테이블에 `date` nullable + `recurring` 플래그.

**이유:** 두 개념은 **생명주기가 다르다.** 시간표는 방학 내내 거의 바뀌지 않는 설정값이고, 과제는 매일 생성·완료되는 트랜잭션 데이터다. 또 시간표에는 상태(완료/미완료)가 없고 과제에는 있다. 한 테이블에 합치면 절반의 컬럼이 항상 NULL이고 "이 행은 어느 쪽인가" 분기가 모든 질의에 들어간다.

**대가:** 두 개념을 한 화면(오늘 화면)에 합쳐 보여줄 때 조인이 아니라 애플리케이션 레벨 조합이 필요하다 → D11에서 처리.

---

### D2 — 과제 유형: 단일 테이블 + `type` 컬럼 (Single Table Inheritance)

이 프로젝트에서 가장 자주 재논의될 지점이므로 상세히 남긴다.

**후보:**

| 안 | 구조 |
|---|---|
| **A. 단일 테이블 + type** | `Assignment` 하나. 읽기 전용 필드는 nullable |
| B. 단일 테이블 + JSON payload | `Assignment` + `payload Json` |
| C. 베이스 + 유형별 상세 테이블 | `Assignment` + `ReadingDetail` 등 (Class Table Inheritance) |
| D. 유형별 완전 분리 | `ReadingAssignment`, `WorksheetAssignment`, ... |

**결정적 사실 두 가지:**

1. **유형별 고유 필드를 가진 유형이 사실상 하나뿐이다.** 읽기 유형만 `bookId / startUnit / endUnit` 3개를 갖고, 워크시트·일기·프로젝트·기타는 고유 필드가 **0개**다. 즉 "유형마다 스키마가 다른" 전형적 상황이 아니다 — nullable 컬럼 3개가 전부다.
2. **핵심 질의가 전부 유형 횡단이다.** "오늘 남은 숙제", "밀린 숙제", "이번 주 남은 것", 달력 요약 — 전부 유형과 무관하게 한 날짜의 모든 과제를 `orderIndex` 순으로 가져와야 한다 (F8). 유형별 분리의 이득은 유형별 질의가 지배적일 때 생기는데, 여기선 그 반대다.

**비교:**

| 기준 | A (선택) | B (JSON) | C (CTI) | D (완전 분리) |
|---|---|---|---|---|
| 유형 횡단 질의 | 단일 SELECT | 단일 SELECT | 매 질의마다 `include` 3~4개 | UNION 또는 N회 질의 + 앱 병합 |
| `orderIndex` 정렬 | DB가 처리 | DB가 처리 | DB가 처리 | **앱에서 병합 정렬** — 페이지네이션 불가능해짐 |
| 타입 안전성 | Zod discriminated union으로 확보 | **불가** — `any` 유발, CLAUDE.md 금지 사항 위반 | 확보 | 확보 |
| Book으로의 FK | 가능 | **불가** (JSON 안에서 FK 못 걸음) | 가능 | 가능 |
| 새 유형 추가 비용 | 상수 배열에 값 추가 | 값 추가 | 테이블 추가 + 마이그레이션 | 테이블 추가 + 모든 집계 질의 수정 |
| NULL 컬럼 | 3개 | 0개 | 0개 | 0개 |

**선택: A.** B는 CLAUDE.md의 `any` 금지와 정면 충돌하고 FK를 걸 수 없어 F1(진도 체인)을 구현할 수 없다. C와 D는 유형별 필드가 3개뿐인 대가로 모든 핵심 질의를 복잡하게 만든다 — 비용이 이득을 초과한다. 특히 D는 `orderIndex` 정렬이 앱 계층으로 넘어가면서 F8을 다루기 어렵게 만든다.

**대가와 그 완화:** nullable 컬럼 3개와, DB가 강제해주지 않는 불변식 I1·I2가 생긴다. 완화책은 **모든 쓰기 경로가 반드시 통과하는 Zod discriminated union 하나**를 두고, I1·I2를 위반 케이스 테스트로 고정하는 것이다. 라우트 핸들러가 Prisma를 직접 부르지 않게 하는 D14가 이 완화의 전제 조건이다.

**재검토 트리거:** 어떤 유형이 고유 필드를 3개 이상 갖게 되면 그 유형만 C 방식(상세 테이블 분리)으로 승격하는 것을 재검토한다.

---

### D3 — 영어책/한글책을 `type`의 별도 값으로 둔다 (`language` 필드로 분리하지 않는다)

**선택:** `ENGLISH_READING`, `KOREAN_READING`을 `AssignmentType`의 독립된 값으로.

**기각한 대안:** `type = 'READING'` + `Assignment.language = 'EN' | 'KO'`.

**이유:** 이 도메인에서 둘은 **다른 활동**이다. 시간표가 증거다 — `10:00~11:00 영어책 읽기`와 `2:00~3:00 한글책 읽기`는 별개의 시간 블록이다 (F14, 0.3절). 별도 값으로 두면 시간표 매칭 규칙이 **`block.matchType === assignment.type` 단일 등식**으로 끝난다. 대안을 택하면 `(type, language)` 복합 매칭 + "READING이면 language 필수"라는 불변식이 하나 더 늘어난다.

**대가:** "모든 읽기 과제"를 다룰 때 `isReadingType()` 헬퍼가 필요하다. 값이 두 개뿐이라 비용이 낮고, 헬퍼가 §1.4에 단일 정의로 존재한다.

**주의:** `Book.language`는 남긴다. 다만 **책 선택 UI 필터 전용**이며 매칭 로직에 쓰지 않는다. 이론적으로 `Book.language`와 `Assignment.type`이 어긋날 수 있으나(한글책에 `ENGLISH_READING`), 이는 입력 UI가 언어에 맞는 책만 보여주는 것으로 방지한다. DB 제약으로는 막지 않는다 — 막으려면 D2에서 기각한 복잡도가 돌아온다.

---

### D4 — `Book`을 별도 테이블로 둔다

**선택:** `Book` 테이블 + `Assignment.bookId` nullable FK.

**기각한 대안:** `Assignment.bookTitle` 문자열만 두고 제목 문자열 매칭으로 진도를 이어붙인다.

**이유:** F1이 요구하는 "같은 책의 직전 계획 찾기"를 문자열 매칭으로 하면 오타 한 글자(`Jake Drake Bully Buster` vs `Jake Drake Bully buster`)에 진도 체인이 조용히 끊긴다 — 실물에서 8/11과 8/12에 손으로 두 번 쓰인 제목이다. 또 F3의 `progressUnit`을 놓을 자리가 없어져 한 책에 `ch.`과 `p.`이 섞이는 것을 막을 수 없다.

**대가:** 과제 입력 시 책을 먼저 만들어야 하는 마찰. **완화: `title`에 `@unique`를 걸고 입력은 find-or-create + 자동완성으로 처리한다.** 부모 입장에서는 제목을 타이핑하는 동작 하나로 끝나고, 이미 있는 책이면 자동으로 재사용된다.

---

### D5 — 진도 시작점: `startUnit`을 nullable로 두고, NULL이면 조회 시 파생한다

**사용자가 명시적으로 비교를 요청한 지점이다.**

**후보:**

| 안 | 방식 |
|---|---|
| A. 생성 시점 확정 저장 | 생성할 때 직전 계획을 조회해 `startUnit = 직전 endUnit + 1`을 계산해 저장. 이후 고정 |
| B. 매번 계산 | `startUnit`을 저장하지 않고 조회 시마다 직전 계획에서 도출 |
| **C. nullable + 파생 (선택)** | 기본은 NULL(= 이어서). 사용자가 명시하면 그 값을 저장하고 그것이 우선 |

**시나리오별 비교:**

| 시나리오 | A | B | C |
|---|---|---|---|
| 정상: 8/8 `~p.102` → 8/9 `~p.217` | 8/9에 `start=103` 저장. 정상 | 조회 시 103 도출. 정상 | NULL 저장, 조회 시 103. 정상 |
| **부모가 8/8을 `~p.120`으로 수정** | 8/9는 `start=103`인 채로 **조용히 틀림** | 자동으로 121로 갱신 | 자동으로 121로 갱신 |
| **8/8과 8/9 사이에 새 날짜 삽입** | 8/9의 `start`가 **조용히 틀림** | 자동 반영 | 자동 반영 |
| **부모가 "이번엔 p.150부터"로 지정** | 저장값 수정으로 표현 가능 | **표현 불가** — 저장할 자리가 없음 | 그 과제만 `startUnit=150` 저장 |
| 조회 비용 | 0 | 책마다 역추적 1회 | NULL인 것만 역추적 |

**선택: C.** 근거는 두 가지다.

첫째, **F5** — 시작점은 실물 어디에도 적혀 있지 않다. 이는 데이터 누락이 아니라 도메인의 실제 모습이다. "적혀 있지 않다 = 이어서 읽는다"라는 의미를 NULL이 정확히 담는다. A는 도메인에 없는 정보를 만들어 저장하는 것이고, 만들어 저장한 값은 원본이 바뀌어도 따라가지 않으므로 **조용히 틀리는 데이터**가 된다. F6이 보여주듯 계획은 점진적으로 작성·수정되므로 이 수정 시나리오는 예외가 아니라 일상이다.

둘째, B는 정확하지만 **"이번엔 여기서부터"를 표현할 방법이 없다.** 책을 다시 읽거나 일부를 건너뛰는 상황에서 막힌다.

C는 두 방식의 이점을 모두 취한다. 대가는 "이 필드는 NULL일 때 특별한 의미를 갖는다"는 규칙을 코드 전체가 일관되게 지켜야 한다는 점이다. **완화: 해석 함수를 단 하나만 두고(§4), 표시 경로가 원본 `startUnit`을 직접 읽는 것을 금지한다.**

**성능 주의:** 달력 월 뷰처럼 여러 과제를 한 번에 표시할 때 책마다 역추적하면 N+1이 된다. 규정된 처리 방식은 §4.2에 있다. (데이터 규모는 20일 × 3건 ≈ 60행이므로 성능이 이 결정의 판단 기준은 아니다. 다만 N+1 패턴 자체를 코드에 남기지 않는다.)

---

### D6 — 진도 체인은 **계획 기반**이며 **상태와 무관**하다

**선택:** 직전 계획을 찾을 때 `status`를 조건에 넣지 않는다. `DONE`이든 `SKIPPED`든 `PLANNED`든 동일하게 체인에 포함된다.

**기각한 대안:** 완료된 과제만 체인에 포함 (= 실제로 읽은 만큼만 이어짐).

**이유 (두 가지):**

1. **실물이 그렇다.** F6에서 확인했듯 계획은 5일치씩 미리 작성된다. 8/9의 `~p.217`을 쓰는 시점에 8/8은 아직 읽히지 않았다. 즉 실물에서의 "지난번 다음"은 **직전 *계획*의 다음**이지 실적의 다음이 아니다.
2. **상태 의존 체인은 아이의 체크 동작이 다른 날의 표시를 조용히 바꾸게 만든다.** 8/8을 실수로 체크 해제하면 8/9의 범위가 `103~217`에서 `1~217`로 튄다. 아이가 원인을 이해할 수 없는 변화이고, D5에서 피하려던 "조용한 변경"을 다른 형태로 되살린다.

**대가:** 계획대로 읽지 못했을 때 다음 날 범위가 실제 진도와 어긋난다. 이는 **의도된 동작**이다 — 계획표는 계획을 보여주는 물건이다. 실적 추적이 필요해지면 `actualEndUnit` 필드를 추가하는 것이 확장 경로이며, 그때도 계획 체인은 계획끼리 유지한다 (§9).

---

### D7 — `OVERDUE`(밀림)를 상태로 저장하지 않고 조회 시 계산한다

**v-hw에서 "서버 시각 기준 단일 소스로 계산"을 택했다고 했다. 재검토 결과 같은 결론이지만, 한 가지 중요한 조건을 추가한다 (D8).**

**후보:**

| 안 | 방식 |
|---|---|
| A. `status = 'OVERDUE'` 저장 | 마감이 지나면 상태를 변경 |
| **B. 파생 계산 (선택)** | `date < today && status ∈ {PLANNED, IN_PROGRESS}` |

**A의 결정적 문제 — 전이를 일으킬 주체가 없다.** 세 가지 방법이 있는데 모두 실패한다.

| 트리거 | 실패 모드 |
|---|---|
| 자정 크론 | 앱이 상시 실행되므로 **대체로는 돈다.** 다만 재시작·배포·기기 절전 중 자정을 넘기면 조용히 건너뛴다 |
| 조회 시 일괄 갱신(lazy sweep) | 어차피 조회 시점에 계산하면서 **쓰기까지 추가로 한다.** B보다 순수하게 나쁘다 |
| 쓰기 시 갱신 | 아무도 아무것도 쓰지 않을 때가 정확히 밀린 상황이다. **원리적으로 발동하지 않는다** |

> **전제 수정 이력 (2026-07-31):** 이 문서 초안은 "앱이 상시 실행되지 않는다"를 가정하고 크론을 기각했다. 사용자 확인 결과 **앱은 하루 종일 켜져 있다**(Q4). 따라서 크론 항목의 근거는 **위와 같이 약해졌다.** 그럼에도 결론은 바뀌지 않는데, 이유는 아래 두 논거가 상시 실행 여부와 무관하게 성립하기 때문이다. 근거가 하나 사라졌다는 사실을 남겨두어, 나중에 이 결정을 재검토할 때 오해가 없게 한다.

**A의 통상적 이점(인덱싱)이 여기서는 성립하지 않는다.** "밀림"은 `date`와 `status`의 순수 함수이고 둘 다 저장·인덱싱된 컬럼이다. `@@index([date, status])` 하나로 밀린 목록 질의(`date < ? AND status IN (...)`)와 오늘 목록 질의(`date = ?`)가 모두 커버된다. 파생 계산 때문에 인덱스를 못 쓰는 상황이 아니다. 데이터 규모는 20일 × 3건 ≈ 60행이므로 성능은 애초에 판단 기준이 아니다.

**A는 상태 공간을 오염시킨다.** `OVERDUE`를 상태로 두면 `OVERDUE → DONE` 전이가 필요하고, 완료 후 날짜를 미래로 수정하면 `DONE → PLANNED`인지 `→ OVERDUE`인지 판단이 필요해진다. B에서는 이런 질문이 아예 생기지 않는다 — 저장 상태는 그대로고 파생값만 바뀐다.

**B는 자기 치유적이다.** 파생 계산은 멱등이며 "언제 마지막으로 갱신됐는가"라는 상태를 갖지 않는다. A는 크론이 한 번이라도 건너뛰면 **누군가 알아채고 고쳐줄 때까지 틀린 채로 표시된다.** 상시 실행이라 해도 그 확률이 0이 되지는 않으며, 이 앱에서 밀린 숙제 표시는 부모가 신뢰해야 하는 정보다.

**선택: B.** v-hw와 동일한 결론이다. 단, 근거 3개 중 1개(크론 미실행)는 이 프로젝트에서 약하다.

**대가:** "밀림"을 표시하는 모든 경로가 동일한 `today`를 써야 한다. 서로 다른 시점의 `today`를 쓰면 화면 안에서 분류가 어긋난다. → **완화: `today`를 요청 단위로 한 번만 확정하고 아래로 주입한다. 대시보드를 3개 API가 아니라 1개 집계 API로 만드는 이유가 이것이다 (§5).**

---

### D8 — "오늘"은 서버에서 **고정 타임존(Asia/Seoul)** 으로 확정한다

**v-hw 결론에 추가하는 조건이다. 이것이 없으면 D7은 실제로 틀린 결과를 낸다.**

**문제:** `new Date()`의 날짜 부분은 프로세스의 주변 타임존(TZ 환경변수, 컨테이너 기본값)에 좌우된다. 서버가 UTC로 도는데 가족은 KST에 있으면, **KST 8월 2일 오전 8시에 서버는 아직 8월 1일**이다. 그 결과:

- 8/2 과제가 "오늘"에 나타나지 않는다.
- 8/1의 미완료 과제가 "밀림"으로 잡히지 않는다.

아침에 앱을 여는 시간대(KST 07:00~09:00 = UTC 22:00~00:00 전날)가 정확히 이 구간이므로, **가장 자주 쓰는 시간에 가장 확실하게 틀린다.**

**선택:** 타임존을 코드에서 명시적으로 고정한다. 주변 환경에서 읽지 않는다.

```ts
// src/domain/clock.ts — 날짜 경계를 다루는 유일한 장소
export const APP_TIMEZONE = process.env.APP_TIMEZONE ?? 'Asia/Seoul';

/** 주어진 순간을 APP_TIMEZONE 기준 달력 날짜 "YYYY-MM-DD"로 변환 */
export function toLocalDate(instant: Date, tz = APP_TIMEZONE): string { /* ... */ }

/** 지금의 달력 날짜. 테스트에서 now를 주입할 수 있어야 한다 */
export function getToday(now: Date = new Date(), tz = APP_TIMEZONE): string {
  return toLocalDate(now, tz);
}
```

**기각한 대안:**
- *클라이언트가 자기 날짜를 보내기* — 기기 시계가 틀리면 밀린 숙제가 사라진다. 아이가 시계를 바꿔 밀린 숙제를 지울 수 있다는 뜻이기도 하다.
- *`.env`에 필수값으로 두기* — CLAUDE.md가 `.env` 조작을 금지한다. **코드 기본값 `'Asia/Seoul'`을 두어 `.env` 없이도 정상 동작하게 한다.** 환경변수는 선택적 오버라이드일 뿐이다.

**Codex 주의:** `getToday()`는 `now`를 인자로 받아야 한다. Playwright/vitest에서 자정 경계를 테스트하려면 주입이 필요하다. 도메인 코드 안에서 `new Date()`를 직접 호출하는 곳이 `clock.ts` 밖에 있으면 안 된다.

**필수 테스트 케이스:** KST `2026-08-02 00:01` / KST `2026-08-01 23:59` / 서버 프로세스 TZ가 `UTC`일 때와 `Asia/Seoul`일 때 결과가 동일할 것.

---

### D9 — `Assignment.date`는 `DateTime`이 아니라 `String("YYYY-MM-DD")`

**선택:** 문자열.

**기각한 대안:** Prisma `DateTime`(UTC 자정으로 저장).

**이유:**

| 기준 | String YYYY-MM-DD | DateTime |
|---|---|---|
| 정렬 | 사전순 = 시간순 (ISO 형식의 성질) | 정상 |
| 범위 질의 | `date >= '2026-08-01' AND date <= '2026-08-07'` — 정상 | 정상 |
| 타임존 함정 | **없음.** 달력 날짜 외의 의미를 갖지 않는다 | UTC 자정으로 저장된 값을 다른 타임존에서 포매팅하면 **하루 밀린다.** D8의 실수를 표시 계층에서 반복하게 된다 |
| DB 내용 가독성 | `2026-08-02` | `1785628800000` |
| 유효성 | DB가 보장 안 함 → Zod로 I6 검증 | DB가 형식은 보장 |

`Assignment.date`는 **시각이 아니라 달력 날짜**다. 시각 타입으로 저장하면 존재하지 않는 정밀도(시/분/초/타임존)가 생기고, 그 정밀도는 반드시 언젠가 잘못 해석된다. **정보가 없는 필드를 만들지 않는다**는 원칙이다.

**주의:** `createdAt` / `updatedAt` / `completedAt`은 진짜 *순간*이므로 `DateTime`을 그대로 쓴다. 둘을 혼동하지 말 것.

---

### D10 — 시간표의 시각은 **자정 기준 분(Int)** 으로 저장한다

**선택:** `startMinute`, `endMinute`을 `0..1440` 정수로. `13:00` → `780`.

**기각한 대안:**
- *`"HH:mm"` 문자열* — `"9:00"`과 `"09:00"`이 다르게 정렬된다. F12의 `2:00`(오후)을 정규화하지 않으면 정렬이 무너진다.
- *`DateTime`* — 날짜가 없는 값에 가짜 날짜를 붙여야 하고, D9와 같은 타임존 문제가 붙는다.

**이유:** 정렬·겹침 검증·"지금 이 블록인가" 판정이 전부 정수 비교로 끝난다.

**시점 마커(F11):** `endMinute = null`. *길이 0 블록(`end == start`)* 은 기각했다 — "지속 시간 > 0" 불변식이 깨지고 겹침 판정에서 경계 사례가 생긴다. NULL이 "끝이 없다"를 정확히 표현한다.

**입력 UI 주의:** 실물이 `2:00`(=14:00)처럼 12시간제로 적혀 있다 (F12). 입력 컴포넌트는 `<input type="time">`(24시간, `"14:00"` 형식 반환)을 쓰고 저장 직전에 분으로 변환한다. 사용자가 `2:00`을 입력해 오전 2시로 저장되는 일이 없도록, 입력값은 항상 24시간 표기로만 받는다.

---

### D11 — 시간 블록 ↔ 과제 연결은 **조인 테이블 없이 `matchType`으로 파생**한다

**후보:**

| 안 | 방식 |
|---|---|
| A. 명시적 조인 테이블 | `BlockAssignmentLink(date, blockId, assignmentId)` |
| **B. 파생 매칭 (선택)** | `ScheduleBlock.matchType` ↔ `Assignment.type` 등식 |

**비교:**

| 기준 | A | B |
|---|---|---|
| 입력 부담 | 매일, 과제마다 "어느 블록?"을 지정해야 함 | **0** |
| 아무도 연결하지 않았을 때 | 시간표가 빈 껍데기가 된다 | 항상 채워진다 |
| 과제를 수정/삭제했을 때 | 링크 정리 필요 | 자동 반영 |
| 같은 과제가 여러 블록에 (F14: 영어책 읽기 ×2) | 링크 2개 필요 | 자동으로 두 블록 모두에 표시 |
| 특정 블록에 특정 과제를 못박기 | 가능 | 불가 |

**선택: B.** 결정 근거는 **시간표가 아이의 주 화면**이라는 점이다. 아이는 달력을 보지 않고 "지금 뭐 할 시간이지"를 본다. A는 부모가 매일 연결 작업을 해야만 시간표가 쓸모 있어지는데, 그 작업은 실제로는 안 하게 되고 결국 시간표가 빈 화면이 된다 — 도구가 버려지는 가장 흔한 경로다. B는 부모가 계획만 넣으면 시간표가 자동으로 채워진다.

F14가 이 선택을 뒷받침한다. 영어책 읽기가 두 시간대에 있는데, 실물의 의도는 "두 시간대 모두 그 책을 읽는다"이다. A에서는 링크 2개를 만들어야 표현되고, B에서는 그냥 그렇게 동작한다.

**매칭 규칙 (Codex: 이대로 구현할 것):**

```
블록 B가 날짜 D에 표시할 과제 =
  B.matchType == null  →  [] (빈 배열, 순수 루틴 블록)
  그 외                →  Assignment 중 date == D && type == B.matchType,
                          orderIndex ASC, id ASC 정렬
```

**초기 시간표 시드 데이터** (실물 그대로, `prisma/seed.ts`):

| start | end | label | kind | matchType |
|---|---|---|---|---|
| 450 (7:30) | null | 기상 | MARKER | null |
| 480 (8:00) | null | 아침식사 끝내기 | MARKER | null |
| 480 (8:00) | 600 (10:00) | 원리셈 · 플라토 · 따플 · 디딤돌 | STUDY | null |
| 600 (10:00) | 660 (11:00) | 영어책 읽기 | STUDY | ENGLISH_READING |
| 660 (11:00) | 690 (11:30) | 일기쓰기 | STUDY | DIARY |
| 690 (11:30) | 750 (12:30) | 점심 & 자유시간 | MEAL | null |
| 750 (12:30) | 765 (12:45) | 뿌리깊은 국어 | STUDY | null |
| 765 (12:45) | 840 (14:00) | 영어책 읽기 | STUDY | ENGLISH_READING |
| 840 (14:00) | 900 (15:00) | 한글책 읽기 | STUDY | KOREAN_READING |
| 900 (15:00) | 1020 (17:00) | 영어숙제 끝내기 | STUDY | WORKSHEET |

**대가:** 특정 과제를 특정 블록에 못박을 수 없다. **확장 경로:** `Assignment.pinnedBlockId nullable FK`를 추가하고, 매칭 규칙을 "핀이 있으면 핀 우선, 없으면 `matchType`"으로 확장한다. 조인 테이블 없이 가능하며 기존 데이터 마이그레이션이 필요 없다.

**부수 결정 (D11-b):** 블록의 여러 항목(F13: 원리셈/플라토/따플/디딤돌)은 `label` 한 문자열로 둔다. 항목별 체크 요구가 실물에 없고(계획표에 수학이 안 나온다, F15), 자식 테이블로 쪼개면 시간표 편집 UI가 과제 CRUD만큼 복잡해진다. 항목별 체크가 필요해지면 그때 자식 테이블로 승격한다.

---

### D12 — `SKIPPED`를 종료 상태로 둔다

**선택:** `PLANNED / IN_PROGRESS / DONE / SKIPPED` 4개.

**기각한 대안:** `SKIPPED` 없이 3개 + 필요하면 삭제.

**이유:** 계획이 바뀌어 안 하기로 한 과제를 `PLANNED`로 두면 **영원히 밀린 목록에 남는다.** 초등학생 사용자에게 줄지 않는 실패 목록을 보여주는 것은 도구를 그만 쓰게 만드는 직접적인 원인이다. 삭제로 처리하면 "계획했다가 안 함"과 "애초에 계획 없음"이 구분되지 않는다. `SKIPPED`는 **거짓말(완료 처리) 없이 밀린 목록에서 빼는 유일한 방법**이다.

**대가:** 상태가 하나 늘어 전이 행렬이 커진다. §3에 전체를 명시했으므로 모호함은 없다.

---

### D13 — Prisma `enum`을 쓴다 (Prisma ≥ 6.2.0 필요)

**버전 제약이 있으므로 Codex가 반드시 확인해야 한다.**

Prisma의 SQLite 커넥터는 **오랫동안 `enum`을 지원하지 않았고, 6.2.0(2025-01)에서 지원이 추가됐다.** SQLite에 네이티브 enum 타입이 없어 폴리필로 구현된다 ([prisma#2219](https://github.com/prisma/prisma/issues/2219)).

**선택:** Prisma 스키마에 `enum` 블록을 정의한다 (§1.2).

- 값의 정의처: **Prisma 스키마.** `src/domain/enums.ts`는 재수출과 헬퍼만 (§1.4)
- 타입: Prisma Client가 생성 (`any` 없음 — CLAUDE.md)
- 런타임 검증: `z.nativeEnum(...)`

**전제 조건 (T01/T02에서 확인할 것):** `prisma`와 `@prisma/client`가 **`^6.2.0` 이상**이어야 한다. 그 미만이면 `prisma validate`가 SQLite에서 enum을 거부한다.

**기각한 대안:** `String` 컬럼 + 손으로 쓴 TS `as const` 배열 + Zod. 6.2.0 미만에서는 유일한 방법이지만, 지금은 (a) 값 목록이 Prisma 스키마와 TS 두 곳에 존재해 갈라질 수 있고, (b) DB가 값을 전혀 강제하지 못한다. 버전 제약을 받아들이는 편이 낫다.

**남는 대가:** enum은 **단일 컬럼의 값 범위만** 강제한다. §1.5의 I1·I2·I4처럼 **여러 컬럼에 걸친 조건**은 여전히 애플리케이션 계층의 몫이다. **완화: 서비스 계층을 우회해 Prisma를 직접 호출하는 코드를 만들지 않는다 (D14).**

**마이그레이션 주의:** enum 값을 나중에 추가/삭제하면 SQLite에서는 테이블 재작성 마이그레이션이 발생할 수 있다. `prisma migrate dev`가 생성한 마이그레이션을 직접 수정하지 말 것 (CLAUDE.md 금지 사항).

---

### D14 — 순수 도메인 계층 + 얇은 Route Handler (Server Actions 기각)

**선택:**

```
src/domain/     순수 함수. Prisma·Next 의존 없음. vitest의 주 대상
src/server/     Prisma 접근 + 트랜잭션 (서비스 계층)
src/app/api/    Route Handler — 파싱 → 서비스 호출 → 직렬화만
```

**기각한 대안:** Server Actions로 직접 처리.

**이유:** Server Action은 보일러플레이트가 적지만 **HTTP로 호출할 수 없어** 통합 테스트가 어렵고, CLAUDE.md가 요구하는 "정상 케이스 + 규칙 위반 케이스" 테스트를 붙이기 나쁘다. 반면 이 앱의 어려운 부분(밀림 판정 D7, 시작점 해석 D5, 전이 검증 §3, 날짜 경계 D8, 겹침 검증 I9)은 **전부 순수 함수로 떼어낼 수 있다.** 떼어내면 DB 없이 vitest로 전수 테스트가 가능하다.

**Codex 주의:** `src/domain`의 함수는 `PrismaClient`, `next/*`를 import 하지 않고 `new Date()`를 직접 호출하지 않는다. 필요한 값은 전부 인자로 받는다. **예외: `@prisma/client`에서 생성된 enum 값·타입 import는 허용된다** (§1.4 참고 — DB 연결을 만들지 않는다). 금지되는 것은 도메인 함수가 `prisma.*.findMany()` 같은 I/O를 하는 것이다.

---

### D15 — 범위 블록끼리 겹침 금지, 시점 마커는 예외

**선택:** `endMinute != null`인 블록끼리 시간 구간이 겹치면 저장 거부(409). 마커는 검증 대상에서 제외.

**이유:** 겹침을 허용하면 **"지금 뭐 할 시간?"의 답이 여러 개가 된다.** 이 질의가 아이 화면의 핵심이므로, 답이 항상 0개나 1개가 되도록 데이터 레벨에서 보장한다. 제약이 기능을 낳는 경우다. F18에서 실물이 이미 이 규칙을 지키고 있음을 확인했다.

마커를 제외하는 이유는 F17이다 — `8:00 아침식사 끝내기`(마커)와 `8:00~10:00`(범위)이 실제로 같은 시각에 공존한다.

**경계 규칙 (Codex: 정확히 이대로):** 구간은 **시작 포함, 끝 배타** `[start, end)`. 따라서 `[600, 660)`과 `[660, 690)`은 겹치지 않는다. 겹침 판정: `aStart < bEnd && bStart < aEnd`.

**부수 결정 (D15-b):** `Assignment.orderIndex`에는 유니크 제약을 걸지 않는다. 유니크면 순서 변경 시 임시값 우회가 필요해진다. 대신 **정렬은 항상 `orderIndex ASC, id ASC`** 로 하여 동점에서도 결정적이게 하고, 순서 변경은 한 트랜잭션에서 전체 인덱스를 다시 쓴다.

---

### D17 — 책 삭제는 "보관(archive)"과 "하드 삭제"로 나눈다

**Q2 확인(책을 직접 추가·수정·삭제하고 싶다)에서 나온 결정이다.**

초안은 참조가 있는 책의 삭제를 무조건 409로 막았다(I11). 그러면 **사용자가 목록을 정리할 방법이 없다** — 방학 중 읽은 책이 계속 쌓이는데, 다 읽은 책은 지난 계획이 참조하므로 영원히 지울 수 없다.

**핵심 구분:** "이 책을 목록에서 치우고 싶다"와 "이 책의 지난 계획 기록까지 지우고 싶다"는 **다른 요구다.** 실제로 원하는 것은 대개 전자다.

| 동작 | 조건 | 결과 |
|---|---|---|
| **보관** (`archivedAt = now()`) | 언제나 가능 | 책 선택 목록에서 사라진다. **지난 과제의 제목·진도 범위는 그대로 표시된다** |
| **보관 해제** | 언제나 가능 | 목록에 복귀 |
| **하드 삭제** | 참조 과제 **0건일 때만** | 완전 삭제 |
| 하드 삭제 시도 (참조 있음) | — | 409 + `{ referencedBy: 7 }` + **"대신 보관하시겠습니까?" 제안** |

**보관된 책이 진도 체인(§4.2)에서 빠지지 않는다는 점이 중요하다.** 보관은 UI 필터일 뿐이므로, 보관 후 같은 책의 과제를 다시 만들어도 진도가 이어진다. 체인 조회 쿼리에 `archivedAt` 조건을 넣지 말 것.

**기각한 대안:**

- *cascade 삭제* — 책을 지우면 그 책의 지난 계획이 통째로 사라진다. 사용자가 의도한 "목록 정리"의 결과로는 지나치게 파괴적이다.
- *`bookId`를 null로 만들고 삭제* — 읽기 과제인데 `bookId`가 null이 되어 I1을 위반한다. 데이터가 불변식을 깨는 상태로 남는다.
- *보관만 두고 하드 삭제 없음* — 오타로 만든 책("Kid Spy" 대신 "Kid Spu")을 지울 방법이 없어진다. 참조 0건일 때의 하드 삭제는 안전하고 필요하다.

---

### D18 — 방학 기간은 코드 상수로 둔다 (`2026-07-29` ~ `2026-08-17`)

**Q1 확인.** 초안에서는 범위 밖(§8)으로 미뤘으나, 날짜가 확정되었고 상시 실행 화면에서 "며칠 남았나"가 유용하므로 v1에 넣는다.

```ts
// src/domain/term.ts
export const TERM_START = '2026-07-29';  // 수요일
export const TERM_END   = '2026-08-17';  // 월요일 — 총 20일
```

**용도:** 달력의 기본 표시 범위, "방학 D-N", 전체 진행률. **어떤 핵심 기능도 이 값에 의존하지 않는다** — 값이 잘못돼도 남은 숙제 계산(§3.4)은 정상 동작해야 한다.

**기각한 대안:** `Settings` 단일 행 테이블. 편집 가능해지지만 테이블 하나와 "설정이 없을 때" 분기가 생기고, **방학 중에 방학 날짜가 바뀔 일은 없다.**

**대가:** 다음 방학에 쓰려면 코드 수정이 필요하다. 그때 `Settings`로 승격한다.

**기간 밖 날짜를 막지 않는다.** `TERM_END` 이후 날짜에도 과제를 만들 수 있다. 기간은 표시용 힌트이지 제약이 아니다 — 제약으로 만들면 방학이 연장되거나 밀린 숙제를 이후로 미룰 때 막힌다.

---

### D16 — 화면은 상시 열려 있다고 가정한다: 폴링 + 날짜 전환 감지 + 서버 시각 동기화

**Q4 확인(앱을 하루 종일 켜두고 진도를 점검한다)에서 나온 요구사항이다. 초안은 "가끔 여는 앱"을 가정했기 때문에 이 절이 없었다.**

한 번 렌더링하고 끝나는 화면이라면 필요 없지만, **화면이 하루 종일 떠 있으면 세 가지가 깨진다.**

| # | 깨지는 것 | 왜 |
|---|---|---|
| L1 | **자정을 넘기면 `today`가 낡는다** | 23:50에 서버가 계산해 보낸 `today`는 00:10에 틀린 값이다. "오늘 남은 것"에 어제 것이 남아 있고, 어제 미완료가 밀림으로 넘어가지 않는다 |
| L2 | **시간표의 "지금" 표시가 멈춘다** | 서버 렌더 시점에 강조된 블록이 3시간 뒤에도 그대로다. 하루 종일 보는 화면에서 이건 치명적이다 |
| L3 | **다른 기기의 변경이 안 보인다** | 태블릿(아이)과 폰(부모)이 동시에 보고 있으면, 아이가 체크한 것이 부모 화면에 반영되지 않는다 |

**선택:**

**(a) 서버는 여전히 `today`의 유일한 출처다 (D8 유지).** 클라이언트는 절대 자기 시계로 날짜를 계산하지 않는다.

**(b) 폴링 + 가시성 이벤트로 갱신한다.**

| 대상 | 주기 | 추가 트리거 |
|---|---|---|
| `GET /api/dashboard` | 60초 | `visibilitychange`(→visible), `focus`, 온라인 복귀 |
| `GET /api/schedule/today` | 60초 | 동일 |

태블릿이 절전에서 깨어나면 `visibilitychange`가 발생하므로, **깨어난 직후 즉시 최신 상태가 된다.** 이것이 폴링만으로는 부족한 이유다 — 절전 중에는 타이머가 신뢰할 수 없다.

**(c) 날짜 전환은 클라이언트가 "감지"하고 서버가 "판정"한다.**

응답의 `today` 값을 클라이언트가 보관하다가, 새 응답의 `today`가 달라지면 **날짜가 바뀐 것으로 간주하고 화면 전체를 다시 그린다.** 부분 갱신으로는 안 되는 이유는 날짜가 바뀌면 세 버킷(§3.4)의 소속이 전부 재계산되고 주간 범위까지 이동하기 때문이다.

전환 시 **조용히 내용을 바꾸지 않는다.** "날짜가 바뀌었습니다 (8월 3일)" 같은 짧은 안내를 함께 띄운다. 보고 있던 목록이 예고 없이 통째로 바뀌면 사용자는 자기가 뭘 잘못 눌렀다고 생각한다.

**(d) "지금"은 서버 시각 기준으로 틱한다.**

`GET /api/schedule/today` 응답에 `serverNowMinute`(자정 기준 분, D10)을 포함한다. 클라이언트는 최초 응답에서 **오프셋 = `serverNowMinute` − 기기 시각 분**을 구해두고, 이후 30초마다 로컬에서 틱하며 오프셋을 더해 현재 블록을 판정한다.

기기 시계를 직접 쓰지 않는 이유는 D8과 같다 — 태블릿 시계가 틀어져 있으면 엉뚱한 블록이 강조된다. 매 틱마다 서버에 묻지 않는 이유는 그럴 필요가 없기 때문이다(오프셋은 변하지 않는다).

**기각한 대안:**

| 대안 | 기각 이유 |
|---|---|
| WebSocket / SSE 실시간 푸시 | 기기 2~3대, 변경 빈도 분당 1회 미만. 폴링으로 충분한데 연결 관리·재연결·서버 상태가 늘어난다 |
| 클라이언트가 자기 시계로 자정을 감지 | 기기 시계 의존이 되살아난다 (D8 위반). 태블릿 시각이 틀리면 날짜가 하루 어긋난다 |
| 갱신하지 않고 사용자가 새로고침 | 하루 종일 켜두는 사용 방식에서 화면이 대부분의 시간 동안 틀린 정보를 보여준다 |
| Next.js ISR / `revalidate` | 이 데이터는 사용자별·시각별로 달라 캐시 무효화 시점이 곧 폴링 주기와 같아진다. 이득 없이 캐시 계층만 늘어난다 |

**(e) 상시 실행에 따르는 운영 사항 (Codex: T01/T02에서 반영할 것)**

- **SQLite를 WAL 모드로 연다.** 기본 저널 모드에서는 쓰기가 읽기를 막아, 폴링 중인 기기가 다른 기기의 체크 동작과 부딪히면 `SQLITE_BUSY`가 난다. 마이그레이션 직후 `PRAGMA journal_mode=WAL;`을 1회 적용한다.
- **`next dev`가 아니라 `next build` + `next start`로 띄운다.** dev 서버는 상시 실행용이 아니다(메모리 증가, HMR 오버헤드).
- **모든 `setInterval`은 언마운트 시 해제한다.** 하루 종일 열려 있는 페이지에서 타이머 누수는 실제로 누적된다.

**필수 테스트:**

- 자정 전후 응답의 `today`가 달라질 때 클라이언트가 전체 재조회를 수행하는가 (시각 주입으로 검증)
- `visibilitychange` 발생 시 즉시 재조회하는가
- `serverNowMinute` 오프셋 적용 후 현재 블록 판정이 기기 시계 조작에 영향받지 않는가

---

## 3. 상태 전이

### 3.1 저장되는 상태와 파생되는 상태

```mermaid
stateDiagram-v2
    [*] --> PLANNED : 과제 생성

    PLANNED --> IN_PROGRESS : 시작
    PLANNED --> DONE : 완료 체크 (주 경로 · 1탭)
    PLANNED --> SKIPPED : 건너뛰기

    IN_PROGRESS --> DONE : 완료 체크
    IN_PROGRESS --> PLANNED : 시작 취소
    IN_PROGRESS --> SKIPPED : 건너뛰기

    DONE --> PLANNED : 체크 해제 (오체크 복구)
    SKIPPED --> PLANNED : 되돌리기

    note right of PLANNED
      OVERDUE는 여기에 없다.
      date < today 인 PLANNED / IN_PROGRESS를
      조회 시 "밀림"으로 표시할 뿐이다 (D7)
    end note
```

### 3.2 전이 행렬 (이 표가 `canTransition()`의 명세다)

| from \ to | PLANNED | IN_PROGRESS | DONE | SKIPPED |
|---|---|---|---|---|
| **PLANNED** | – | ✅ | ✅ | ✅ |
| **IN_PROGRESS** | ✅ | – | ✅ | ✅ |
| **DONE** | ✅ | ❌ | – | ❌ |
| **SKIPPED** | ✅ | ❌ | ❌ | – |

허용하지 않는 전이의 이유:

- `DONE → IN_PROGRESS`: 의미가 없다. 되돌리려면 `PLANNED`를 거친다 (경로가 하나뿐이어야 UI가 단순하다).
- `DONE → SKIPPED`: 이미 한 일을 안 한 일로 만들 이유가 없다.
- `SKIPPED → DONE` / `SKIPPED → IN_PROGRESS`: 다시 하기로 했다면 먼저 `PLANNED`로 되돌린다.

**부수 효과 (서비스 계층이 자동 처리, 사용자 입력 아님 — I10):**
- `→ DONE`: `completedAt = now()`
- `DONE →` (이탈): `completedAt = null`

### 3.3 파생 표시 상태 (저장하지 않음)

```ts
export type DisplayStatus = AssignmentStatus | 'OVERDUE';

/** 순수 함수. today는 D8의 getToday()가 만든 값을 주입받는다. */
export function deriveDisplayStatus(
  a: { date: string; status: AssignmentStatus },
  today: string,
): DisplayStatus {
  if (a.status === 'DONE' || a.status === 'SKIPPED') return a.status;
  return a.date < today ? 'OVERDUE' : a.status;   // 문자열 비교로 충분 (D9)
}
```

**필수 테스트 케이스:**

| 입력 | 기대 |
|---|---|
| `date`=어제, `PLANNED` | `OVERDUE` |
| `date`=어제, `IN_PROGRESS` | `OVERDUE` |
| `date`=어제, `DONE` | `DONE` (밀림 아님) |
| `date`=어제, `SKIPPED` | `SKIPPED` (밀림 아님 — D12의 핵심) |
| `date`=오늘, `PLANNED` | `PLANNED` (**당일은 아직 밀린 것이 아니다**) |
| `date`=내일, `PLANNED` | `PLANNED` |

### 3.4 "남은 숙제" 버킷 정의 (요구사항의 핵심 — 정확한 정의)

`today`는 D8로 확정된 하나의 값이며, 아래 세 버킷은 **반드시 같은 `today`를 공유한다** (D7의 대가 완화).

| 버킷 | 정의 |
|---|---|
| **오늘 남은 것** | `date == today && status ∈ {PLANNED, IN_PROGRESS}` |
| **밀린 것** | `date < today && status ∈ {PLANNED, IN_PROGRESS}` |
| **이번 주 남은 것** | `weekStart <= date <= weekEnd && status ∈ {PLANNED, IN_PROGRESS}` |

**주의 — 주의 시작 요일:** `weekStart`는 **월요일**로 한다 (한국 관행). 다만 실물 계획표는 5칸 폭이라 요일과 무관하다 (F9) — 즉 "이번 주"는 실물에 없는, 앱이 새로 도입하는 개념이다. 월요일 시작을 상수 하나(`WEEK_START_DAY = 1`)로 두고 `src/domain/clock.ts`에 함께 둔다.

**"이번 주 남은 것"은 "밀린 것"과 겹칠 수 있다** (이번 주 월요일 미완료 = 둘 다 해당). 이는 의도된 것이다. UI에서는 밀린 것을 우선 표시하고 주간 카운트는 별도 지표로 다룬다. **중복 제거를 시도하지 말 것.**

---

## 4. 진도(시작점) 해석 규칙

D5·D6의 구현 명세다. **표시 경로는 절대 `assignment.startUnit`을 직접 읽지 않는다. 반드시 이 함수를 거친다.**

### 4.1 해석 함수

```ts
export interface ResolvedRange {
  start: number | null;       // null = 시작점을 알 수 없음 (체인 없음 + 미지정)
  end: number | null;         // null = 목표 미지정 (F4)
  unit: 'CHAPTER' | 'PAGE';
  inferred: boolean;          // true면 파생값 — UI에서 흐리게 표시
}

/**
 * @param a          대상 과제
 * @param book       a.bookId가 가리키는 책
 * @param prevEnd    같은 책의 직전 계획의 endUnit (§4.2 규칙으로 구함). 없으면 null
 */
export function resolveReadingRange(
  a: { startUnit: number | null; endUnit: number | null },
  book: { progressUnit: 'CHAPTER' | 'PAGE' },
  prevEnd: number | null,
): ResolvedRange
```

**해석 규칙 (우선순위 순):**

| # | 조건 | `start` | `inferred` |
|---|---|---|---|
| 1 | `a.startUnit != null` | `a.startUnit` | `false` |
| 2 | `a.startUnit == null && prevEnd != null` | `prevEnd + 1` | `true` |
| 3 | `a.startUnit == null && prevEnd == null` | `1` | `true` |

규칙 3의 근거: 그 책의 첫 계획이면 처음부터 읽는 것이 자연스럽다. 실물의 첫 등장(`Big Note ch.6`)도 1~6을 의미한다.

**표시 예시 (실물 대조):**

| 데이터 | 표시 |
|---|---|
| Big Note, `start=null`, `end=6`, prevEnd=없음 | `Big Note ch.1–6` |
| Big Note, `start=null`, `end=12`, prevEnd=6 | `Big Note ch.7–12` |
| wimpy kid, `start=null`, `end=217`, prevEnd=102 | `wimpy kid p.103–217` |
| Jake Drake, `start=null`, `end=null`, prevEnd=없음 | `Jake Drake Bully Buster` (범위 없음, F4) |

### 4.2 "직전 계획" 조회 규칙

```
prevEnd(A) =
  Assignment 중
    bookId == A.bookId
    AND endUnit != null                      -- 목표 없는 계획은 체인을 진전시키지 않는다 (F4)
    AND (date, orderIndex, id) < (A.date, A.orderIndex, A.id)   -- 사전식 비교
  를 (date DESC, orderIndex DESC, id DESC) 정렬해 첫 행의 endUnit.
  없으면 null.

  ※ status는 조건에 넣지 않는다 (D6).
  ※ 자기 자신은 제외된다 (엄격한 부등호).
```

`endUnit != null` 조건의 이유: `Jake Drake`처럼 목표가 없는 계획(F4)은 "어디까지 읽었다"는 정보를 담지 않으므로, 그 다음 계획의 시작점을 정할 근거가 되지 못한다. 건너뛰고 그 이전의 목표 있는 계획을 찾는다.

`id`까지 비교에 넣는 이유: 같은 날짜·같은 `orderIndex`가 가능하므로(D15-b에서 유니크 제약을 걸지 않았다) 결정적 순서를 보장하기 위함이다.

### 4.3 N+1 회피 (D5의 대가 처리 — 규정된 방식)

목록 화면에서 여러 읽기 과제를 표시할 때 과제마다 §4.2를 실행하면 안 된다. **다음 절차를 따른다:**

1. 화면에 필요한 과제들을 한 번에 조회한다.
2. 그중 읽기 과제의 `bookId` 집합 `B`를 만든다.
3. **한 번의 질의**로 `bookId ∈ B && endUnit != null`인 모든 과제의 `(bookId, date, orderIndex, id, endUnit)`을 가져온다 (표시 범위 밖의 이전 날짜도 포함해야 한다 — 그래야 범위 첫날의 시작점이 나온다).
4. 메모리에서 `bookId`별로 정렬해 각 과제의 `prevEnd`를 계산한다.

3번에서 "표시 범위 밖도 포함"이 빠지면 **달력에서 월을 넘길 때 첫 주의 시작점이 1로 잘못 나온다.** 반드시 통합 테스트로 고정할 것.

### 4.4 필수 테스트 케이스

| # | 상황 | 기대 |
|---|---|---|
| 1 | 같은 책 직전 계획 `end=102` | `start=103`, `inferred=true` |
| 2 | 직전 계획 없음 | `start=1`, `inferred=true` |
| 3 | `startUnit=150` 명시 (직전 `end=102`) | `start=150`, `inferred=false` |
| 4 | **다른 책이 사이에 끼어 있음** (F2) | 다른 책은 무시하고 같은 책의 직전을 따름 |
| 5 | **직전 계획이 `SKIPPED`** | `start`는 동일 (상태 무관, D6) |
| 6 | 직전 계획의 `endUnit == null` (Jake Drake) | 그 계획을 건너뛰고 더 이전을 찾음 |
| 7 | `endUnit == null` | `end=null`, 범위 없이 제목만 표시 |
| 8 | **직전 계획을 수정** (`end` 102→120) | 다음 계획의 `start`가 121로 자동 변경 (D5의 핵심 이점) |
| 9 | 같은 날짜에 같은 책 2건 | `orderIndex`로 순서가 결정됨 |

---

## 5. API 엔드포인트

Route Handler (`src/app/api/**/route.ts`). 모든 응답은 JSON. 검증 실패 400, 충돌 409, 없음 404.

### 5.1 대시보드 (핵심 화면 전용 집계)

| 메서드 | 경로 | 설명 |
|---|---|---|
| `GET` | `/api/dashboard` | 오늘/밀림/주간을 **한 번에** 반환 |

```jsonc
// GET /api/dashboard  → 200
{
  "today": "2026-08-02",              // 서버가 확정한 날짜 (D8). 클라이언트는 이 값을 신뢰한다
  "todayItems":   [ /* Assignment DTO[] */ ],
  "overdueItems": [ /* Assignment DTO[] */ ],
  "week": { "start": "2026-07-27", "end": "2026-08-02", "remaining": 7, "total": 12 }
}
```

**왜 별도 집계 엔드포인트인가:** 세 버킷을 3개 API로 나누면 요청 사이에 자정이 지날 때 서로 다른 `today`로 계산되어 **화면 안에서 분류가 어긋난다** (D7의 대가). 한 요청 = 하나의 `today`를 구조적으로 보장한다. 또 클라이언트가 자기 시계로 "오늘"을 계산할 유인을 없앤다 (D8).

### 5.2 과제

| 메서드 | 경로 | 설명 |
|---|---|---|
| `GET` | `/api/assignments?from=&to=&status=&type=` | 목록. `from`/`to`는 `YYYY-MM-DD` 포함 범위 |
| `POST` | `/api/assignments` | 생성. Zod discriminated union으로 I1~I6 검증 |
| `POST` | `/api/assignments/bulk` | **여러 날짜에 일괄 생성** |
| `GET` | `/api/assignments/:id` | 단건 (해석된 범위 포함) |
| `PATCH` | `/api/assignments/:id` | 내용 수정 (`status` 제외) |
| `DELETE` | `/api/assignments/:id` | 삭제 |
| `POST` | `/api/assignments/:id/status` | **상태 전이.** `{ "to": "DONE" }` |
| `POST` | `/api/assignments/reorder` | `{ "date": "...", "ids": [...] }` — 한 트랜잭션에서 `orderIndex` 재작성 |

**`status`를 PATCH에서 분리한 이유:** 상태 변경은 (a) 가장 빈번한 동작(아이의 체크)이고, (b) 전이 검증(§3.2)이라는 고유 규칙을 가지며, (c) `completedAt` 부수 효과를 동반한다. 일반 필드 수정과 섞으면 라우트가 "이번 요청이 전이인가 수정인가"를 추측해야 한다. 분리하면 아이가 쓰는 경로의 페이로드가 `{to}` 하나로 끝난다.

**`/bulk`가 필요한 이유:** F6에서 계획이 5일치씩 작성됨을 확인했고, 일기·워크시트는 여러 날에 반복된다. "8/4~8/8에 일기 추가"를 한 번에 하지 못하면 부모가 같은 입력을 5번 반복한다 — 도구를 안 쓰게 되는 실질적 원인이다.

**Assignment DTO (모든 응답 공통 — 파생값을 서버가 계산해 내려준다):**

```jsonc
{
  "id": "...",
  "date": "2026-08-09",
  "orderIndex": 0,
  "type": "ENGLISH_READING",
  "status": "PLANNED",           // 저장된 상태
  "displayStatus": "PLANNED",    // 파생 (D7) — 클라이언트가 다시 계산하지 않는다
  "displayTitle": "wimpy kid",   // title ?? book.title
  "completedAt": null,
  "book": { "id": "...", "title": "wimpy kid", "progressUnit": "PAGE" },
  "range": { "start": 103, "end": 217, "unit": "PAGE", "inferred": true }  // §4. 비읽기면 null
}
```

`displayStatus`와 `range`를 서버가 계산해 내려보내는 이유: 클라이언트가 계산하면 D8(타임존)과 §4.2(체인 조회)를 클라이언트에서 다시 구현해야 하고, 두 구현이 반드시 갈라진다.

### 5.3 책

| 메서드 | 경로 | 설명 |
|---|---|---|
| `GET` | `/api/books?q=&language=&includeArchived=` | 목록/자동완성. **기본은 보관 제외** (D17) |
| `POST` | `/api/books` | 생성. `title` 중복 시 **409가 아니라 기존 책을 반환**(find-or-create) |
| `PATCH` | `/api/books/:id` | 수정 (제목·언어·단위·총량) |
| `POST` | `/api/books/:id/archive` | 보관. `{ "archived": true \| false }` — 언제나 성공 (D17) |
| `DELETE` | `/api/books/:id` | **하드 삭제.** 참조 과제가 있으면 409 + `{ referencedBy: n }` (I11) |
| `GET` | `/api/books/:id/progress` | 이 책의 계획 체인 전체 + 마지막 `endUnit` |

`PATCH`로 `archivedAt`을 직접 쓰게 하지 않고 별도 엔드포인트를 둔 이유는 상태 전이(§5.2의 `/status`)와 같다 — 보관은 필드 수정이 아니라 의미 있는 동작이고, UI에서 "보관" 버튼 하나에 대응한다.

**한글책 관리 (Q2):** 위 엔드포인트가 한글책·영어책을 구분 없이 처리한다. `language=KO` 필터로 한글책만 볼 수 있고, 관리 화면(§6.2-5)에서 추가·수정·보관·삭제가 모두 가능하다. **시드에는 제목이 불명확한 책을 넣지 않는다** (§ 부록 C).

`POST /api/books`가 중복에 409 대신 기존 책을 주는 이유: 호출자는 "이 제목의 책을 쓰고 싶다"는 의도이지 "새로 만들겠다"가 아니다. 409를 주면 모든 호출자가 GET→없으면POST 패턴을 각자 구현하게 되고, 그 사이에 경합이 생긴다.

### 5.4 시간표

| 메서드 | 경로 | 설명 |
|---|---|---|
| `GET` | `/api/schedule/blocks` | 전체 블록 (`startMinute ASC`) |
| `POST` | `/api/schedule/blocks` | 생성. 겹침 검증 (I9, D15) |
| `PATCH` | `/api/schedule/blocks/:id` | 수정. 자기 자신 제외하고 겹침 검증 |
| `DELETE` | `/api/schedule/blocks/:id` | 삭제 |
| `GET` | `/api/schedule/today?date=` | 블록 + **각 블록에 매칭된 그날의 과제** (D11 규칙 적용). `date` 생략 시 서버의 오늘 |

### 5.5 달력

| 메서드 | 경로 | 설명 |
|---|---|---|
| `GET` | `/api/calendar?from=&to=` | 날짜별 요약: `{ date, total, done, overdue, hasPlan }` |

`hasPlan`이 별도로 필요한 이유: F7 — "과제 0건"과 "아직 계획을 안 세움"을 UI가 구분해 보여줘야 한다. 현재 모델에서 둘은 같은 상태이므로 `total === 0`으로 판정하되, **필드로 노출해 두어** 나중에 "계획 확정" 개념이 생겨도 API 계약이 바뀌지 않게 한다.

---

## 6. 화면

### 6.1 화면 목록

| # | 경로 | 이름 | 주 사용자 | 목적 |
|---|---|---|---|---|
| 1 | `/` | **오늘** | 아이 | 오늘 남은 것 + 밀린 것. 체크만 하면 되는 화면 |
| 2 | `/schedule` | **시간표** | 아이 | 지금 뭘 할 시간인지 + 그 시간의 과제 |
| 3 | `/calendar` | **달력** | 부모 · 아이 | 전체 조망, 날짜 이동 |
| 4 | `/calendar/[date]` | **날짜 상세** | 부모 | 그날 과제 CRUD, 순서 변경 |
| 5 | `/manage` | **관리** | 부모 | 책 목록·진도, 시간표 편집, 일괄 등록 |

### 6.2 화면별 요구사항

**1. 오늘 (`/`) — 기본 화면**

- 데이터 소스: `GET /api/dashboard` 하나.
- 구성: ① 밀린 숙제 배너(있을 때만) → ② 오늘 남은 것 → ③ 오늘 끝낸 것(접힌 상태)
- 체크박스는 손가락으로 누를 수 있는 크기(최소 44×44px). 탭 한 번에 `PLANNED → DONE` (§3.2의 주 경로).
- 읽기 과제는 해석된 범위를 그대로 보여준다: `wimpy kid p.103–217`. `inferred`면 시작점을 흐리게 (D5의 파생값임을 시각적으로 구분).
- **삭제 버튼을 두지 않는다.** 아이가 잘못 눌러 계획을 지우는 사고를 막는다. 삭제는 4번 화면에만 둔다. (인증을 도입하지 않고 위험을 낮추는 방법 — §9 참조)
- 밀린 것이 0건이면 배너를 렌더링하지 않는다. 빈 배너는 아무 정보도 주지 않으면서 실패를 상기시킨다.

**2. 시간표 (`/schedule`)**

- 데이터 소스: `GET /api/schedule/today`.
- 세로 타임라인. 마커(`endMinute == null`)는 얇은 선, 범위 블록은 높이가 지속 시간에 비례하는 상자 (F11).
- **현재 시각 블록을 강조하고 스크롤을 그 위치로 보낸다.** D15의 겹침 금지 덕분에 이 블록은 항상 최대 1개다.
- 각 블록 안에 매칭된 과제를 체크박스와 함께 표시 (D11). 매칭이 없는 블록(수학, 점심)은 라벨만 (F15, F16).
- 같은 과제가 두 블록에 나타나는 것은 정상이다 (F14). 한쪽에서 체크하면 양쪽 모두 반영된다.

**3. 달력 (`/calendar`)**

- 데이터 소스: `GET /api/calendar`.
- **7칸(월~일) 그리드**를 쓴다. 실물은 5칸이지만(F9), 요일 정렬이 안 되면 "이번 주"(§3.4)를 시각적으로 이해할 수 없다. **실물과 다른 배치를 택한 의도적 결정이다.**
- 각 칸: 날짜 + 과제 요약(제목 최대 3개) + 상태 점(완료/남음/밀림).
- 계획이 없는 날은 흐린 "계획 없음"으로 표시한다 (F7 — 빈칸으로 두면 데이터 오류처럼 보인다).

**4. 날짜 상세 (`/calendar/[date]`)**

- 그날 과제의 추가/수정/삭제/순서 변경 (F8).
- 유형 선택에 따라 폼이 바뀐다: 읽기 유형이면 책 선택(자동완성) + 목표 지점 입력, 나머지는 제목만 (D2의 STI가 UI에서는 판별 유니온으로 드러난다).
- 목표 지점 입력란 옆에 파생된 시작점을 미리 보여준다: `p.103부터 (자동)`. 다르게 하려면 시작점을 직접 입력 — 이때 `startUnit`이 저장된다 (D5의 규칙 1).
- 여러 날짜 일괄 추가 진입점 (`POST /api/assignments/bulk`).

**5. 관리 (`/manage`)**

- **책 관리 (Q2)** — 목록에 제목·언어·단위·**마지막 계획 지점**(`GET /api/books/:id/progress`)을 보여준다. 부모가 "이 책 어디까지 계획했지"를 확인하는 곳.
  - 추가: 제목·언어·진도 단위 입력
  - 수정: 오타 정정, 단위 변경
  - **보관**: 다 읽은 책을 목록에서 치운다. 지난 계획 기록은 그대로 남는다 (D17)
  - **삭제**: 참조가 없을 때만. 참조가 있으면 `"이 책을 쓰는 과제가 7개 있습니다"`와 함께 **보관을 대안으로 제시**한다 (D17)
  - `language=KO` 필터로 한글책만 볼 수 있다
- 시간표 편집: 블록 CRUD. 겹침 위반(I9)은 저장 전에 인라인으로 알려준다.
- 위험한 동작(책 삭제 등)은 전부 여기에만 둔다.

### 6.3 공통 UI 원칙

- **아이 화면(1, 2)에는 되돌릴 수 없는 동작을 두지 않는다.** 체크는 언제든 해제 가능하고(§3.2의 `DONE → PLANNED`), 삭제는 없다.
- 클라이언트는 "오늘"을 스스로 계산하지 않는다. 항상 서버가 준 `today`를 쓴다 (D8).
- 밀린 항목은 **개수를 강조하지 않고 항목을 보여준다.** "밀린 숙제 7개"보다 "일기(8/7), 워크시트(8/9)"가 행동으로 이어진다.
- 모든 화면은 D16의 갱신 규칙(폴링 + 가시성 이벤트 + 날짜 전환 감지)을 따른다.

### 6.4 태블릿 기준 (Q3)

아이의 기기는 **태블릿**이고 **하루 종일 켜져 있다**. 이 두 가지가 레이아웃 기준을 정한다.

| 항목 | 기준 | 이유 |
|---|---|---|
| 기준 폭 | **가로 1024px 우선**, 세로 768px도 깨지지 않을 것 | 태블릿은 거치해두고 쓰므로 가로가 기본이다 |
| 터치 타겟 | 체크박스·버튼 **최소 48×48px**, 간격 8px 이상 | 손가락 조작. 초등학생은 정밀도가 낮다 |
| hover 의존 | **금지.** hover로만 드러나는 기능을 두지 않는다 | 터치 기기에 hover가 없다 |
| 본문 글자 | 최소 16px, 과제 제목 18px 이상 | 거치된 태블릿은 눈에서 멀다 |
| 가로 배치 | 가로 모드에서 **오늘 목록과 시간표를 2단으로** 병치 | 하루 종일 보는 화면에서 화면 전환 없이 둘 다 보이는 것이 목적(Q4)에 맞는다 |
| 스크롤 | 오늘 화면은 스크롤 없이 한 화면에 들어가는 것을 목표로 | 아이가 스크롤해서 찾게 하지 않는다 |
| 화면 꺼짐 | 별도 처리 없음. 깨어나면 `visibilitychange`로 자동 갱신 (D16) | |

**2단 병치가 D16을 더 중요하게 만든다.** 시간표가 항상 보이므로 "지금" 표시가 멈춰 있으면 즉시 눈에 띈다.

---

## 7. 테스트 대상

CLAUDE.md의 "정상 케이스와 규칙 위반 케이스를 모두 포함한다"를 만족하도록 명시한다.

### 7.1 단위 테스트 (vitest) — `src/domain`, DB 불필요

| 대상 | 케이스 |
|---|---|
| `getToday(now, tz)` | KST 00:01 / KST 23:59 / 프로세스 TZ가 UTC일 때와 KST일 때 동일 결과 (D8) |
| `deriveDisplayStatus` | §3.3 표의 6케이스 전부 |
| `canTransition(from, to)` | §3.2 행렬의 허용 7건 + **거부 5건** |
| `resolveReadingRange` | §4.4의 9케이스 전부 |
| `getWeekRange(today)` | 월요일 시작 / 주 경계(일요일, 월요일) / 월 넘김 |
| `blocksOverlap` | 인접(`[600,660)` vs `[660,690)`)은 겹침 아님 / 포함 / 부분 겹침 / **마커는 항상 겹침 아님** (D15) |
| Zod 스키마 | I1~I8, I12 각각 통과 1건 + **위반 1건** |
| 날짜 전환 감지 (D16-c) | 이전 `today`와 새 `today`가 다를 때만 전체 재조회 판정 |
| 시각 오프셋 (D16-d) | 기기 시각이 ±30분 틀어져도 현재 블록 판정이 서버 기준을 따를 것 |
| `minutesToLabel` / `labelToMinutes` | `780 ↔ "13:00"` / 경계 `0`, `1439` |

### 7.2 통합 테스트 (vitest + 테스트용 SQLite)

| 대상 | 케이스 |
|---|---|
| `prevEnd` 조회 | F2 시나리오(책 교차) / `endUnit == null` 건너뛰기 / `SKIPPED` 무시 안 함 (D6) |
| §4.3 배치 로딩 | **표시 범위 이전의 계획이 필요한 경우** — 월 경계에서 시작점이 1로 무너지지 않을 것 |
| `POST /assignments/:id/status` | 허용 전이 200 + 거부 전이 400 + `completedAt` 설정/해제 (I10) |
| `DELETE /books/:id` | 참조 있으면 409 + 건수 / 참조 0건이면 200 (I11, D17) |
| 책 보관 | 보관 후 책 목록에서 제외 / **보관 후에도 진도 체인은 이어짐** (D17) / 보관된 책으로 새 과제 생성 시 400 (I12) |
| 블록 겹침 | 생성 시 409 / 수정 시 **자기 자신은 겹침 대상에서 제외** |
| `reorder` | 트랜잭션 — 중간 실패 시 전부 롤백 |

### 7.3 E2E (Playwright)

| # | 시나리오 |
|---|---|
| 1 | 오늘 화면에서 체크 → 남은 목록에서 사라지고 완료 목록에 나타남 |
| 2 | 어제 날짜의 미완료 과제가 밀림 배너에 보임 |
| 3 | 날짜 상세에서 같은 책의 두 번째 읽기 과제 추가 → 시작점이 자동으로 채워짐 (D5) |
| 4 | 직전 계획의 목표를 수정 → 다음 계획의 시작점이 따라 바뀜 (§4.4-8, D5 선택의 핵심 근거) |
| 5 | 시간표에서 현재 시각 블록이 강조되고, 그 블록의 과제를 체크하면 오늘 화면에도 반영됨 |
| 6 | 겹치는 시간 블록 저장 시도 → 오류 표시, 저장 안 됨 |
| 7 | **자정 전환**: `today`를 넘긴 시각으로 이동 → 화면이 자동 갱신되고 안내가 뜨며, 어제 미완료가 밀림으로 이동 (D16-c) |
| 8 | **다른 기기 반영**: 두 번째 컨텍스트에서 체크 → 첫 화면이 폴링/포커스 후 반영 (D16-b, L3) |
| 9 | 관리 화면에서 한글책 추가 → 날짜 상세의 책 선택에 나타남 → 보관 → 선택 목록에서 사라지되 기존 과제 표시는 유지 (D17, Q2) |

**시간 고정:** E2E는 반드시 시각을 고정해서 돌린다 (`APP_TIMEZONE` + 고정 `now` 주입). 실제 시계에 의존하면 자정 근처나 CI 타임존에서 무작위로 깨진다. 시나리오 7은 **시각을 주입해서** 검증한다 — 실제로 자정을 기다리지 않는다.

---

## 8. v1 범위 밖 (의도적 제외)

각각 **왜 지금 넣지 않는지**와 **넣게 될 때의 경로**를 남긴다. 그래야 나중에 "빠뜨린 것"과 "미룬 것"을 구분할 수 있다.

| 항목 | 제외 이유 | 확장 경로 |
|---|---|---|
| 인증 / 다중 사용자 | 가정 내 단일 아이용. 인증은 아이의 진입 마찰을 늘린다 | `Child` 테이블 + 모든 테이블에 `childId` FK |
| 평일/주말 별도 시간표 | 실물은 단일 루틴이다. 템플릿을 두면 "지금 활성 템플릿은?" 해석 규칙이 추가된다 | `ScheduleTemplate` 테이블 추가 + 기존 블록 전부를 기본 템플릿으로 backfill |
| 실제 진도(`actualEndUnit`) | 실물은 계획만 기록한다. D6에서 계획 기반을 명시적으로 택했다 | `Assignment.actualEndUnit` 추가. **계획 체인은 계획끼리 유지**하고 실적은 별도 표시 |
| ~~방학 기간 개념~~ | **v1에 포함됨** — Q1에서 날짜가 확정되어 D18로 편입 | — |
| 방학 기간을 화면에서 편집 | D18 — 방학 중에 방학 날짜가 바뀔 일이 없다 | `Settings` 단일 행 테이블로 승격 |
| 실시간 푸시(WebSocket/SSE) | D16 — 기기 2~3대, 변경 빈도가 낮아 폴링으로 충분하다 | SSE 추가 (폴링 코드를 교체) |
| 시간 블록의 항목별 체크 | D11-b — 수학 항목들은 계획표에 아예 없다 (F15) | `ScheduleBlockItem` 자식 테이블 |
| 특정 과제를 특정 블록에 고정 | D11 — 파생 매칭으로 충분하고 입력 부담이 0이다 | `Assignment.pinnedBlockId` nullable FK |
| 알림 / 푸시 | 앱이 상시 실행되지 않는다 (D7에서 크론을 기각한 것과 같은 이유) | — |
| 반복 과제 자동 생성 | `POST /bulk`로 대체 가능하고, 자동 생성은 "생성된 것을 지웠는데 또 생김" 문제를 만든다 | — |

---

## 부록 A. 구현 태스크 분해 (제안)

각 태스크는 `docs/specs/T##-*.md`로 별도 스펙을 작성한 뒤 착수한다. 의존 순서대로 나열했다.

| # | 태스크 | 범위 | 의존 |
|---|---|---|---|
| T01 | 프로젝트 초기화 | Next.js + TS + vitest + Playwright + lint. **`prisma`/`@prisma/client` `^6.2.0` 이상 (D13)**, **`next build`+`next start` 실행 스크립트 (D16-e)**. CI가 실제로 도는 상태까지 | – |
| T02 | Prisma 스키마 · 마이그레이션 · 시드 | §1.2 스키마(enum 포함), **WAL 모드 적용 (D16-e)**, 부록 C의 시드 | T01 |
| T03 | 도메인 기반 — enums 재수출 · clock · term · 전이 | §1.4, D8, D18, §3.2. **전부 순수 함수 + 단위 테스트** | T02 |
| T04 | 도메인 — 진도 해석 | §4.1 해석 규칙 + §4.4 테스트 (DB 없이) | T03 |
| T05 | 검증 스키마 (Zod) | I1~I12, 판별 유니온 | T03 |
| T06 | 서비스 계층 — 과제 CRUD | §4.2 체인 조회 + §4.3 배치 로딩 포함 | T02, T04, T05 |
| T07 | API — 과제 · 상태 전이 · reorder · bulk · **bulk-status** | §5.2, 부록 C.3 | T06 |
| T08 | API — 책 (**보관 포함**) | §5.3, D17 (find-or-create, 보관, 삭제 제약) | T06 |
| T09 | API — 시간표 (겹침 검증 + `serverNowMinute`) | §5.4, D15, D16-d | T02, T05 |
| T10 | API — 대시보드 · 달력 | §5.1, §5.5 (단일 `today` 보장) | T06 |
| T11 | **갱신 계층** — 폴링 · 가시성 · 날짜 전환 · 시각 오프셋 | D16 (a)~(d). 화면과 분리된 재사용 훅으로 | T09, T10 |
| T12 | 화면 — 오늘 · 시간표 (아이용, 태블릿 2단) | §6.2의 1·2, §6.4 | T11 |
| T13 | 화면 — 달력 · 날짜 상세 (부모용) | §6.2의 3·4, 부록 C.3의 일괄 완료 | T07, T11 |
| T14 | 화면 — 관리 (책 · 시간표) | §6.2의 5, D17 | T08, T09 |

초안의 12개에서 **14개로 늘었다.** Q4(상시 실행)로 갱신 계층(T11)이 독립 태스크가 되었고, 부모용 화면이 커져 T13/T14로 분리했다. 갱신 계층을 화면 태스크에 섞지 않는 이유는 D16의 규칙(특히 날짜 전환과 시각 오프셋)이 **DOM 없이 단위 테스트 가능한 로직**이기 때문이다 — 화면에 묻으면 테스트가 E2E로만 가능해진다.

E2E(§7.3)는 T12~T14에 각각 붙인다. 별도 태스크로 몰지 않는다 — 몰면 마지막에 밀려서 안 쓰이게 된다.

---

## 부록 B. Codex를 위한 요약 규칙

이 문서 전체에서 파생된, 구현 중 반드시 지켜야 할 규칙:

1. `src/domain/*`은 `PrismaClient`, `next/*`, `new Date()`를 import·호출하지 않는다. 전부 인자로 받는다. **생성된 enum import는 예외로 허용.** (D14, D8, §1.4)
2. "오늘"은 `getToday()`로만 구한다. 클라이언트가 계산하지 않는다. (D8)
3. `OVERDUE`를 DB에 저장하지 않는다. (D7)
4. `assignment.startUnit`을 표시 경로에서 직접 읽지 않는다. `resolveReadingRange()`를 거친다. (D5)
5. 진도 체인 조회에 `status` 조건을 넣지 않는다. (D6)
6. 열거값의 정의처는 **Prisma 스키마** 하나다. `src/domain/enums.ts`는 재수출·헬퍼 전용이며 값 배열을 손으로 적지 않는다. 문자열 리터럴을 여기저기 쓰지 않는다. (D13)
7. **클라이언트는 시각도 날짜도 스스로 판단하지 않는다.** 날짜는 서버의 `today`, 현재 시각은 서버 오프셋을 적용한 값을 쓴다. (D8, D16-d)
8. **진도 체인 조회에 `archivedAt` 조건을 넣지 않는다.** 보관은 UI 필터일 뿐이다. (D17)
9. `any`를 쓰지 않는다. 타입이 불분명하면 멈추고 질문한다. (CLAUDE.md)
10. 스펙(`docs/specs/T##-*.md`)에 없는 판단이 필요하면 진행하지 말고 질문한다. (CLAUDE.md)

---

## 부록 C. 시드 데이터 (`prisma/seed.ts`)

### C.1 시간표

D11의 표를 그대로 시드한다. 실물(`daily-schedule.jpg`)과 1:1 대응한다.

### C.2 과제 계획

§0.1의 표를 그대로 시드하되, **다음 두 가지를 지킨다.**

1. **제목이 불명확한 항목은 시드하지 않는다.** 7/29의 한글책(`김치찌…`)은 사진에서 판독이 안 된다 (Q2). 빈 상태로 두고 사용자가 관리 화면에서 추가한다 — CLAUDE.md의 "추측으로 진행하지 않는다"에 해당한다.
2. **책은 find-or-create로 만든다** (D4). 같은 책이 여러 날에 나오므로 제목당 `Book` 1개만 생성되어야 진도 체인(F1)이 이어진다.

시드할 책:

| 제목 | language | progressUnit | 근거 |
|---|---|---|---|
| Big Note | EN | CHAPTER | `ch.6`, `ch.12` |
| Kid Spy | EN | CHAPTER | `ch.10`, `ch.16` |
| 13 Tree House | EN | CHAPTER | `ch.7`, `ch.13` |
| Andrew Lost | EN | CHAPTER | 진도 표기 없음 → 단위는 기본값 |
| wimpy kid | EN | **PAGE** | `~p.102`, `~p.217` (F3 — 유일한 페이지 단위 책) |
| Jake Drake Bully Buster | EN | CHAPTER | 진도 표기 없음 |
| 엄마 5분만 | KO | CHAPTER | 진도 표기 없음 |
| 무지개 물고기 | KO | CHAPTER | 진도 표기 없음 |
| 김방구 3 | KO | CHAPTER | 진도 표기 없음. **`3`은 제목의 일부다 — 챕터로 파싱하지 말 것** |

`startUnit`은 **전부 `null`로 시드한다** (D5). 시작점은 실물에 없으므로 파생되게 둔다.

### C.3 이미 지난 날짜 처리 — 착수 시점 주의

**오늘은 2026-07-31이고 방학은 7/29에 시작했다. 즉 앱을 처음 켜는 시점에 이미 2일이 지나 있다.**

시드 직후 7/29·7/30의 과제는 전부 `PLANNED`이므로 **밀린 숙제로 표시된다.** 실제로는 종이 계획표에서 이미 수행했을 수 있다.

따라서 **날짜 상세 화면(§6.2-4)에 "이 날 전부 완료 처리" 동작이 필요하다.** 첫 실행 때 부모가 지난 날짜를 정리하는 유일한 경로다. 이것이 없으면 앱을 켜자마자 밀린 숙제 6건이 쌓여 있고 하나씩 눌러야 한다.

- 구현: `POST /api/assignments/bulk-status` `{ "date": "2026-07-29", "to": "DONE" }`
- 이 동작은 **관리·상세 화면에만** 둔다. 아이 화면에 두면 전부 완료 처리로 숙제를 없앨 수 있다 (§6.3).

---

## 확인 완료된 질문

| # | 질문 | 답변 (2026-07-31) | 반영 |
|---|---|---|---|
| Q1 | 방학 기간 | **2026-07-29(수) ~ 08-17(월), 20일** | D18 |
| Q2 | 한글책 제목 불명확 | 시드하지 말고 **추가·수정·삭제 관리 기능을 제공**할 것 | D17, §5.3, §6.2-5, 부록 C.2 |
| Q3 | 아이 기기 | **태블릿** | §6.4 |
| Q4 | 앱 실행 방식 | **상시 실행.** 하루 종일 보면서 진도 점검 | D16, D7 전제 수정, §6.4 |

## 미해결 질문

현재 없음. 구현 착수 가능하다.
