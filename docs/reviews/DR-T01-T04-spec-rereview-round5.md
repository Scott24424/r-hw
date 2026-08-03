# T01~T04 SPEC 독립 재검토 — Round 5

## 1. 검토 기준과 읽은 문서

- 검토자: Codex
- 요구사항·설계·SPEC 작성 및 수정자: Claude
- 검토 성격: 구현 전 문서 게이트의 독립 재검토
- 작업 경로: `/Volumes/SSD_1TB/Projects/r-hw`
  - 셸의 논리 경로는 `/Users/minim4/dev/r-hw`였고 `pwd -P`는 위 물리 경로와 일치했다.
- 기준 브랜치: `docs/specs-batch1`
- 검토 대상 전체 HEAD: `c8d59fec3f7e557b450ae78fd29ea00bf22f020b`
- `origin/docs/specs-batch1`: `c8d59fec3f7e557b450ae78fd29ea00bf22f020b`
- Claude revision 5 기준 전체 커밋: `be0d6b2777ae2bfc86f4c9331e9319c4c32b4d04`
- 검토 대상 diff: `be0d6b2777ae2bfc86f4c9331e9319c4c32b4d04..c8d59fec3f7e557b450ae78fd29ea00bf22f020b`
- 검토일: 2026-08-03
- 시작 상태: 브랜치·HEAD·원격이 요청값과 일치했고 작업 트리와 staging은 깨끗했다. `AGENTS.md`는 `CLAUDE.md`를 가리키는 심볼릭 링크였다.

다음 문서를 줄 번호와 함께 처음부터 끝까지 읽었다.

- `AGENTS.md`
- `CLAUDE.md`
- `docs/requirements.md`
- `docs/architecture.md`
- `docs/decisions.md`
- `docs/specs/T01-scaffold.md`
- `docs/specs/T02-test-harness.md`
- `docs/specs/T03-prisma-schema.md`
- `docs/specs/T04-seed.md`
- `docs/reviews/DR-T01-T04-spec-review.md`
- `docs/reviews/DR-T01-T04-spec-rereview-round1.md`
- `docs/reviews/DR-T01-T04-spec-rereview-round2.md`
- `docs/reviews/DR-T01-T04-spec-rereview-round3.md`
- `docs/reviews/DR-T01-T04-spec-rereview-round4.md`
- `docs/workflow/STATUS.md`

지정된 `git diff be0d6b2..c8d59fe -- docs/requirements.md docs/specs/T04-seed.md docs/workflow/STATUS.md`도 전체를 직접 읽었다. 비교 범위의 변경 파일은 이 세 문서뿐이다. Claude의 수정 보고와 STATUS 자기 선언은 판정 근거로 쓰지 않고 현재 원문, 단계 순서, fixture, 반증 mutation을 직접 대조했다.

## 2. 전체 판정

**PASS**

| 태스크 | 판정 | 근거 |
|---|---|---|
| T01 | **PASS** | Round 4 PASS의 Node·Next·typecheck·ESLint·Tailwind 계약과 RR-02 mutation이 변경되지 않았고 회귀가 없다 |
| T02 | **PASS** | Round 4 PASS의 Node 집합·Vitest·Playwright·CI·E2E 책임 계약이 변경되지 않았고 회귀가 없다 |
| T03 | **PASS** | DR-12의 네 DB artifact, 독립 기대 경로, journal sentinel, 개발 DB 4파일 보호 계약이 유지된다 |
| T04 | **PASS** | R2-04의 전체 snapshot 계약과 mutation 29b~29e가 fixture·단계 순서상 결정적으로 partial persistence를 만든다 |

- 직접 재검증 Finding: **3건 RESOLVED**
- 회귀 검사: **9건 모두 RESOLVED 유지**, 회귀 0건
- 신규 Finding: **0건**
- 구현 차단 Finding: **0건**
- 미승인 설계 가정: **0건**
- 미결 구현 상세: **0건**

## 3. R2-04 — RESOLVED

- **현재 판정:** RESOLVED
- **근거:** `docs/specs/T04-seed.md:99-191`, `:458-470`, `:489-562`, `:754`, `:766-768`
- **해결된 부분:** 정상 구현의 1~7단계는 같은 `$transaction`과 `tx` 안에 있다(`:99-113`). 실패 hook은 삭제 뒤·블록 생성 뒤·과제 생성 뒤에 각각 위치한다(`:77-121`). snapshot은 Book·ScheduleBlock·Assignment의 `SELECT *` 전체 행·전체 컬럼과 조건부 `sqlite_sequence`를 포함하고 `_prisma_migrations`만 제외한다(`:127-164`). `id`, `createdAt`, `updatedAt`, `completedAt`, `bookId`를 버리지 않으며 `normalizeRow`는 표현만 정규화하고 값 제거·반올림을 금지한다(`:129`, `:166-175`). 실패 후에는 같은 파일의 새 `PrismaClient`로 다시 읽고, 네 rollback 테스트 모두 `expect(after).toEqual(before)`를 사용한다(`:177-191`, `:467-470`). fixture나 seed 기대값을 rollback 기대값으로 공유하지 않는다(`:124`, `:186-188`).
- **남은 부분:** 없음.
- **구현 차단:** 아니오.
- **최소 수정안:** 없음.

### 3.1 mutation 29b 반증

- 29b는 단계 1만 단일 `client`로 먼저 커밋하고 트랜잭션 경계를 단계 2로 미룬다(`docs/specs/T04-seed.md:495`).
- fixture에는 Book `Big Note` 1권만 있고(`:458-460`), 시드 9권 중 같은 title은 `Big Note` 하나뿐이다(`:221-233`). Book upsert에는 count guard가 없고 title unique key를 사용한다(`:203`, `:515-521`; `docs/specs/T03-prisma-schema.md:516`). 따라서 기존 1권 update 여부와 무관하게 나머지 8권이 실제 create되어 Book 스냅샷이 1행에서 9행으로 바뀐다(`docs/specs/T04-seed.md:508-509`).
- 18은 단계 3, 18c는 단계 5 hook에서 실패하지만 8개 신규 Book은 이미 커밋되어 두 테스트의 전체 snapshot deep equality가 반드시 실패한다. `updatedAt` 변화는 추가 신호일 뿐 유일한 신호가 아니다(`:173`, `:508`).

### 3.2 mutation 29c 반증

- 29c는 1~4단계를 원래 순서대로 단일 `client`에서 커밋한 뒤 트랜잭션을 단계 5에서 시작한다(`docs/specs/T04-seed.md:496`, `:500-502`).
- 18b는 빈 DB이므로 Book 9권과 block 10건이 생성된다. 단계 5 hook 실패 뒤 snapshot은 0/0/0에서 9/10/0으로 달라진다(`:468`, `:510`).
- 18c는 `force: true`다. 단계 2에서 기존 Assignment 1건을 먼저 삭제하고 ScheduleBlock 1건을 삭제한 뒤, 단계 4의 block count가 0이 되어 10건을 실제 생성한다(`:103-108`, `:460`, `:511`, `:520`, `:523`). 단계 5 hook 실패 뒤 사용자 block·assignment 삭제와 seed block 생성이 모두 남으므로 호출 전 snapshot과 같을 수 없다.
- 기존 행 때문에 create가 skip되는 Round 4 반례는 단계 순서 보존으로 제거됐다.

### 3.3 mutation 29d 반증

- 29d는 1~6단계를 원래 순서대로 커밋하고 단계 7 hook만 트랜잭션에 둔다(`docs/specs/T04-seed.md:497`, `:512`).
- Book 9권 upsert가 Assignment보다 먼저 끝나 title→`bookId` 외래키가 성립한다. `force` 삭제가 두 count guard보다 앞서므로 block·assignment count는 각각 0이고 block 10건과 Assignment 27건이 실제 생성된다(`:103-109`, `:512`, `:520-523`).
- 단계 7 hook 실패 뒤 Book 1→9, block 1→10, assignment 1→27의 부분 영속화가 남아 18d 전체 snapshot deep equality가 반드시 실패한다. 생성 skip, FK 오류, 존재하지 않는 ID에 의존하지 않는다.

### 3.4 mutation 29e와 공통 금지 의존성 반증

- 29e는 트랜잭션만 제거하고 단계 1~7 순서를 유지한다(`docs/specs/T04-seed.md:498`). 18은 Book upsert와 force 삭제 뒤, 18b는 Book·block 생성 뒤, 18c는 force 삭제·block 생성 뒤, 18d는 Assignment 27건 생성 뒤 각각 hook이 던진다. 각 hook 전의 write가 이미 커밋되어 네 테스트 모두 snapshot 불일치로 실패한다(`:513`, `:535`).
- 29b~29e는 한 `client`에서 트랜잭션 시작 전 단계들을 순차 커밋한다. 별도 writer, `SQLITE_BUSY`, 타이밍 경쟁, 존재하지 않는 ID, 실제 create가 없는 no-op을 사용하지 않는다(`:523-525`, `:541-549`, `:767`).
- seam은 통합 테스트만 주입하고 `main()`은 정확히 `{ force }`만 전달한다. CLI·환경변수·HTTP·운영 API로 활성화할 수 없다(`:551-562`, `:768`).

## 4. R4-01 — RESOLVED

- **현재 판정:** RESOLVED
- **근거:** `docs/requirements.md:12-20`
- **해결된 부분:** 출처 bullet은 직접 세면 정확히 6개다. 앞의 4개는 요구사항 진술, AP-01~AP-12 결정, `OPEN-01` 결정, `OPEN-02` 결정이고 뒤의 2개는 두 mockup이다(`:12-18`). 설명은 이를 “여섯 항목”, “앞의 넷”, “뒤의 둘”로 정확히 부른다(`:20`).
- **남은 부분:** 없음.
- **구현 차단:** 아니오.
- **최소 수정안:** 없음.

## 5. R4-02 — RESOLVED

- **현재 판정:** RESOLVED
- **근거:** `docs/specs/T04-seed.md:489-498`, `:537`, `:564-579`, `:754`
- **해결된 부분:** seed mutation은 27·28·28b·29·29b·29c·29d·29e의 8개이고 `db:setup` mutation은 31·32의 2개로 총 10개다. 정상 케이스 30은 mutation이 아니라 두 `db:setup` mutation이 실패시킬 기준 테스트다(`:564-577`). 본문 총계와 완료 보고 요구가 동일한 10개를 정확히 열거한다(`:537`, `:754`). 원복 조건도 실제 변경 파일과 일치한다. seed mutation 뒤 `prisma/seed.ts` diff는 비어야 하고, package mutation 뒤 `package.json`에는 T04 요구사항 18의 영구 변경만 남아야 한다(`:537`, `:579`).
- **남은 부분:** 없음.
- **구현 차단:** 아니오.
- **최소 수정안:** 없음.

## 6. 직접 재검증 Finding 집계

| 상태 | 건수 | ID |
|---|---:|---|
| RESOLVED | 3 | R2-04, R4-01, R4-02 |
| PARTIALLY RESOLVED | 0 | — |
| UNRESOLVED | 0 | — |
| REGRESSED | 0 | — |

## 7. 기존 Finding과 회귀 검토

| Finding | Round 5 판정 | 현재 근거 |
|---|---|---|
| DR-12 | **RESOLVED 유지** | `docs/specs/T03-prisma-schema.md:278-290`, `:604-610`, `:622-669`, `:682` — 네 suffix의 단일 구현 정의, 독립 `EXPECTED_DB_ARTIFACTS`, sentinel 선행 존재 단정, 24b-2의 `-journal` 한 항목 제거와 16-a2 필수 실패, `.tmp` 경계·실패 후 정리·개발 DB 4파일 불변 유지 |
| RR-01 | **RESOLVED 유지** | `docs/requirements.md:12-20`, `:303-343`, `:355`, `:383`, `:388`, `:392-415` — 여섯 출처, 33개 조건, MR-30 역추적, OPEN 0건 유지 |
| RR-02 | **RESOLVED 유지** | `docs/specs/T01-scaffold.md:190-239`, `:279-312` — FlatCompat와 규칙을 남긴 채 `next/typescript` 제공자만 제거하는 mutation 및 종료 코드 2 계약 유지 |
| R2-01 | **RESOLVED 유지** | `docs/requirements.md:70`; `docs/architecture.md:727`, `:779-799` — 최소 48×48px 단일 값 유지 |
| R2-02 | **RESOLVED 유지** | `docs/requirements.md:106-110`, `:238-255`; `docs/architecture.md:588-645`, `:1042-1068`; `docs/decisions.md:762-798` — 원자성·멱등성·실패 분류와 테스트 계약 유지 |
| R2-03 | **RESOLVED 유지** | `docs/requirements.md:155-165`; `docs/architecture.md:83-92`; `docs/specs/T04-seed.md:239-250` — marker 2건+범위 8건=10건 유지 |
| R2-05 | **RESOLVED 유지** | `docs/architecture.md:1007-1025` — 기준일 2026-08-01과 밀린 과제 6건 계산 유지 |
| R3-01 | **RESOLVED 유지** | `docs/architecture.md:588-645`, `:1042-1068`; `docs/decisions.md:775-798` — `{ date, to }`, 날짜 전체 대상, 200/400/409/500, 9개 테스트, 첫 update 후 seam과 전체 snapshot 유지 |
| R3-02 | **RESOLVED 유지** | `docs/requirements.md:303-343`, `:355`, `:383`, `:388`, `:392-415`; `docs/architecture.md:1080-1082` — 31+2=33, MR-30, 양방향 누락 0, OPEN 0 유지 |

Round 5 diff는 requirements의 출처 개수 문장, T04의 R2-04 mutation 및 mutation 총계, STATUS만 바꾼다. T01~T03 SPEC·architecture·decisions는 변경되지 않았고, T04 변경도 기존 개발 DB 보호·사용자 승인 정책·태스크 책임을 건드리지 않았다. 회귀는 0건이다.

## 8. 신규 Finding과 집계

신규 Finding은 없다. R2-04·R4-01·R4-02의 잔여를 중복해서 R5 ID로 등록하지 않았다.

| 심각도 | 건수 | ID | 구현 차단 |
|---|---:|---|---|
| P0 | 0 | — | — |
| P1 | 0 | — | — |
| P2 | 0 | — | — |
| P3 | 0 | — | — |

## 9. 요구사항·설계·결정·SPEC·테스트·완료 조건 추적성

- 요구사항 출처: 실제 bullet 6개이며 설명의 4+2와 일치한다(`docs/requirements.md:12-20`).
- ID 집계: base UR 26, 조건 33, OR 3, MR 23, NR 9, OPEN 0이다. 조건 본문과 §8.1-b를 독립 추출하면 각각 33개이며 집합 차이는 0이다(`docs/requirements.md:46-116`, `:303-343`, `:392-415`).
- 조건 생성 경위: AP 결정+`OPEN-01`로 31건, `OPEN-02`의 UR-25.4·UR-25.5로 2건 추가, 총 33건이라는 설명이 requirements·architecture·STATUS에서 일치한다(`docs/requirements.md:305`, `:343`; `docs/architecture.md:1080-1082`; `docs/workflow/STATUS.md:328`).
- MR-30: requirements 본문 → D7 → architecture 부록 C 시드 → T04 정상 케이스 7로 이어진다(`docs/requirements.md:165`, `:355`, `:383`, `:388`, `:409`; `docs/architecture.md:1014`; `docs/specs/T04-seed.md:446`).
- `bulk-status`: 요청은 `{ date, to }`이고 Assignment ID 목록을 받지 않는다. 대상은 트랜잭션 시작 시점의 날짜 전체 과제다. 동일 상태는 성공 no-op, 빈 날짜는 200, 검증은 400/write 0, 금지 전이는 409/전부 rollback, 내부 실패는 500/전부 rollback이다. 현재 모델에서 NOT_FOUND·권한 오류가 발생 불가인 이유와 응답의 가짜 ID·내부 예외 비노출도 일치한다(`docs/architecture.md:588-645`; `docs/decisions.md:775-798`). 9개 테스트는 응답 계약과 쓰기 원자성을 분리하고 첫 update 후 test-only seam 및 전후 전체 snapshot deep equality를 요구한다(`docs/architecture.md:1042-1068`). T09·T17은 기존 예약 번호이고 배치 1 범위를 바꾸지 않는다.
- 개발 DB 보호: T03 16e와 T04 완료 검증은 `prisma/dev.db`, `-wal`, `-shm`, `-journal` 같은 4파일을 보호한다(`docs/specs/T03-prisma-schema.md:610`; `docs/specs/T04-seed.md:614-630`, `:644`, `:668`, `:748`). T04는 개발 DB 파일을 만들거나 삭제·변경하지 않고 존재 여부와 sha256만 전후 비교한다.
- 태스크 번호: 확정 T01~T04와 예약 T05·T07·T09·T12·T14·T17·T19 외 새 번호가 없다(`docs/architecture.md:891-940`). revision 5가 새 요구사항이나 태스크를 만들지 않았다.

**추적성 판정: PASS.** 정방향·역방향 누락은 0건이고 요구사항 → 설계 → 결정 → SPEC → 테스트 → 완료 조건의 연결에 미결 선택이나 실행 불가능한 필수 검증이 없다.

## 10. `implementation_allowed`

`implementation_allowed: true`

근거:

1. T01~T04가 모두 구현 가능한 수준이며 모두 PASS다.
2. P0·P1·구현 차단 P2가 0건이다.
3. R2-04 mutation은 실제 partial persistence를 만들고 지정 테스트를 결정적으로 실패시키므로 거짓 양성 구멍이 없다.
4. 요구사항·설계·SPEC의 미결 구현 선택은 0건이다.
5. Round 4 PASS/RESOLVED 항목의 회귀가 0건이다.

이 값은 문서의 구현 가능성 게이트 판정이다. 곧바로 구현을 시작한다는 뜻은 아니다. 문서 브랜치 PR, CI 또는 문서 검증, 사용자 Merge 승인을 거쳐 `main`에 병합된 뒤에만 T01 구현 브랜치를 만든다.

## 11. 변경한 파일

- 생성: `docs/reviews/DR-T01-T04-spec-rereview-round5.md`
- 수정: `docs/workflow/STATUS.md`

## 12. 변경하지 않은 영역

- `docs/requirements.md`, `docs/architecture.md`, `docs/decisions.md`
- `docs/specs/T01-scaffold.md`, `T02-test-harness.md`, `T03-prisma-schema.md`, `T04-seed.md`
- 기존 리뷰 문서
- `AGENTS.md`, `CLAUDE.md`, `README.md`
- `.github/**`, `.gitignore`
- `package.json`, `package-lock.json`
- `prisma/**`, `src/**`, `tests/**`, `e2e/**`
- 운영 코드, 테스트 코드, migration, seed, DB, CI

## 13. 실행하지 않은 금지 작업

브랜치 생성·변경, 패키지 설치, lint/test/build, Prisma 명령, migration, seed, DB 생성·조회·변경, 구현 코드 수정, staging, commit, push, PR 생성·수정, merge, 배포를 실행하지 않았다. `.env`도 읽거나 수정하지 않았다.

## 14. `git diff --check`

- 명령: `git diff --check`
- 결과: 종료 코드 0, 출력 없음

## 15. 다음 담당자와 작업

- 다음 담당자: **사용자**
- 다음 작업:
  1. Round 5 PASS 결과를 확인한다.
  2. 문서 브랜치 PR 생성을 승인한다.
  3. PR의 CI 또는 문서 검증 결과를 확인한다.
  4. 사용자가 Merge를 승인한다.
  5. `main` Merge 뒤에만 T01 구현 브랜치를 만들고 Codex가 T01을 구현한다.
  6. Claude가 T01 구현 결과를 리뷰한다.

이번 세션에서는 리뷰 문서와 STATUS만 갱신하고 commit·staging·push·PR·merge·구현은 하지 않는다.
