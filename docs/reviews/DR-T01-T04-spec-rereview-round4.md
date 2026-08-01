# T01~T04 SPEC 독립 재검토 — Round 4

## 1. 검토 기준

- 검토자: Codex
- 요구사항·설계·SPEC 작성 및 수정자: Claude
- 검토 성격: 구현 전 문서 게이트의 독립 재검토
- 기준 브랜치: `docs/specs-batch1`
- 검토 대상 전체 HEAD: `9a70c5c42ea9d38aea0d30b5eccb9a527b20c7b1`
- `origin/docs/specs-batch1`: `9a70c5c42ea9d38aea0d30b5eccb9a527b20c7b1`
- Round 3 리뷰 커밋: `9acc7b2`
- Claude Round 4 수정 커밋: `9a70c5c`
- 검토일: 2026-08-01

검토 시작 시 현재 브랜치와 원격 추적 브랜치의 커밋은 같았고 작업 트리는 clean이었다. `AGENTS.md`는 `CLAUDE.md`를 가리키는 심볼릭 링크였다. `pwd`는 동일 작업공간의 논리 경로 `/Users/minim4/dev/r-hw`를 표시했다.

## 2. 읽은 문서

다음 파일을 줄 번호와 함께 처음부터 끝까지 읽었다.

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
- `docs/workflow/STATUS.md`

Claude의 `STATUS.md` 수정 보고는 판정 근거로 사용하지 않았다. 각 Finding은 위 원문 문서와 현재 행을 직접 대조해 다시 판정했다.

## 3. 전체 판정

**BLOCK**

| 태스크 | 판정 | 근거 |
|---|---|---|
| T01 | **PASS** | RR-02가 해결된 상태를 유지하며 스캐폴드·Node·typecheck·ESLint·Tailwind 계약에 회귀가 없다 |
| T02 | **PASS** | Node 집합·테스트 하니스·CI·1024×768 E2E·책임 이관이 일치한다 |
| T03 | **PASS** | DR-12의 journal 직접 삭제와 mutation 검출력이 결정적으로 완결됐다 |
| T04 | **BLOCK** | R2-04의 전체 스냅샷 계약은 보강됐지만 mutation 29c·29d가 지정 테스트의 실패를 결정적으로 만들지 못한다 |

- 기존 재검증 Finding: **5건 RESOLVED, 1건 PARTIALLY RESOLVED**
- Round 3 RESOLVED 회귀 검사: **4건 전부 RESOLVED 유지**
- 신규 Finding: **P3 2건**, 구현 차단 0건
- 미승인 설계 가정: **0건**
- 미결 구현 상세: **0건**
- 구현 허용: **아니오**

R2-04의 남은 P2는 잘못된 트랜잭션 경계를 검출해야 하는 mutation 검증 자체가 지정 테스트를 실패시키지 못하는 결함이므로 T04 구현을 차단한다. 두 신규 P3는 출처 목록과 mutation 명령의 이미 명시된 실제 내용을 바꾸지 않는 문구·집계 오류라 별도로는 구현을 차단하지 않는다.

## 4. 기존 Finding 개별 판정

### DR-12 — RESOLVED

- **근거:** `docs/specs/T03-prisma-schema.md:278-290`, `:303-307`, `:604-610`, `:622-669`, `:682`, `:738-741`
- **해결된 부분:** `DB_FILE_SUFFIXES = ["", "-wal", "-shm", "-journal"]`가 구현 정리 대상의 단일 정의처다. 테스트의 `EXPECTED_DB_ARTIFACTS`는 구현 상수나 `dbFilePaths()`를 import·재사용하지 않고 네 리터럴 경로를 독립 정의한다. 16-a2는 `<root>/.tmp/` 경계를 먼저 단정하고 열린 연결을 제거한 뒤 journal sentinel을 직접 만든다. sentinel 내용을 먼저 확인하고 두 번째 `cleanup()` 뒤 부재를 확인하며, `afterEach`가 단정 실패 뒤에도 네 파일을 정리한다. mutation 24b-2는 구현 상수에서 `"-journal"` 한 항목만 제거하고 고유 테스트 `cleanup이 -journal sentinel 파일을 직접 지운다`를 반드시 실패시킨다. 정상 케이스 16e는 개발 DB 본체·WAL·SHM·journal 네 파일의 존재 여부와 sha256을 전후 비교한다.
- **남은 부분:** 없음.
- **구현 차단:** 아니오.
- **최소 수정안:** 없음.

### RR-01 — RESOLVED

- **근거:** `docs/requirements.md:7-20`, `:303-343`, `:355`, `:383`, `:388`, `:392-415`; `docs/workflow/STATUS.md:25-28`
- **해결된 부분:** 권위 요구사항 문서가 존재한다. 요구사항 진술, AP-01~AP-12 결정, OPEN-01 결정, OPEN-02 결정, 두 mockup이 출처 목록과 `requirements_source`에 모두 들어 있다. 조건 본문과 §8.1-b 추적표의 실제 집합은 각각 같은 33개이며, 생성 경위도 AP 결정+OPEN-01의 31건에 OPEN-02의 UR-25.4·UR-25.5 2건을 더한 총 33건으로 일치한다. MR-30은 D7, 부록 C 시드, T04 정상 케이스 7까지 역추적된다.
- **남은 부분:** RR-01이 지적했던 누락은 없다. 출처 항목 수를 잘못 부르는 별도 신규 오기는 R4-01로 분리한다.
- **구현 차단:** 아니오.
- **최소 수정안:** 없음.

### R2-02 — RESOLVED

- **근거:** `docs/requirements.md:106-110`, `:238-255`; `docs/architecture.md:581-645`, `:837`, `:1027-1068`; `docs/decisions.md:762-798`
- **해결된 부분:** OPEN-02의 정책 값은 원자적 전부 롤백과 동일 상태 멱등 no-op으로 확정됐다. 현재 `{ date, to }` 요청에서 존재하지 않는 과제와 권한 오류가 발생 불가인 이유, 검증 400·금지 전이 409·내부 실패 500·빈 날짜 200의 사상이 요구사항 설명, D22, API 계약, 9개 테스트에서 일치한다. `open_implementation_details`는 실제로 0이다.
- **남은 부분:** 없음.
- **구현 차단:** 아니오.
- **최소 수정안:** 없음.

### R2-04 — PARTIALLY RESOLVED

- **현재 심각도:** P2
- **근거:** `docs/specs/T04-seed.md:99-191`, `:467-470`, `:489-525`, `:562-569`, `:729-733`
- **해결된 부분:** rollback 스냅샷은 Book·ScheduleBlock·Assignment의 모든 행·모든 컬럼을 `SELECT *`로 읽고 `id`, `createdAt`, `updatedAt`, `completedAt`, `bookId`를 포함한다. `sqlite_sequence`가 존재할 때 포함하고 `_prisma_migrations`만 제외한다. `normalizeRow`는 키·null·timestamp·BigInt·Buffer의 표현만 정규화하고 값을 제거하거나 반올림하지 않는다. 실패 뒤 별도의 새 `PrismaClient`로 다시 읽는다. 테스트 18·18b·18c·18d는 모두 호출 직전과 실패 후의 전체 스냅샷 deep equality를 사용한다. 29b와 29e는 실제 partial persistence를 만들고 지정 테스트를 실패시킨다. 두 번째 writer, SQLite lock/`SQLITE_BUSY`, 존재하지 않는 ID를 금지하며 seam은 CLI·환경변수·HTTP·운영 API에 노출되지 않는다.
- **남은 부분:** `docs/specs/T04-seed.md:99-110`의 4·6단계는 각각 현재 행 수가 0일 때만 생성하며, `:458-470`의 18c·18d는 기존 사용자 블록과 과제가 각각 1건 있는 `force` fixture다. 그런데 mutation 29c(`:496`)는 블록 생성 단계를 트랜잭션 시작 전으로 그대로 옮긴다. 이 시점에는 force 삭제 전이라 기존 블록이 1건이고 생성이 skip된다. 이후 트랜잭션 안의 삭제가 hook 예외로 롤백되면 호출 전 상태가 복원되므로, 29c가 지정한 18c는 deep equality로 **통과할 수 있다**. mutation 29d(`:497`)도 같은 이유로 기존 과제 1건을 보고 트랜잭션 밖 생성을 skip하므로 지정 테스트 18d가 **통과할 수 있다**. 29d는 필요한 Book 9권 upsert보다 앞에서 실행되는 문제도 있어, 빈 DB로 바꾸는 것만으로는 27개 과제의 외래키 전제를 충족하지 못한다. 따라서 29c·29d가 실제 partial persistence를 만들고 각각 지정 테스트를 실패시킨다는 `:510-511`의 주장이 절차로 보장되지 않는다. mutation 실행 명령 총계의 별도 문구 오류는 R4-02다.
- **구현 차단:** 예 — T04. transaction 경계 검증의 반증 가능성이 구현 완료 조건이다.
- **최소 수정안:** 29c·29d를 조건부 생성 단계를 단순히 트랜잭션 앞으로 옮기는 방식이 아니라, 선행 단계와 외래키를 정상 완료한 뒤 해당 생성만 `client`에서 커밋하고 지정 hook이 예외를 던지게 하는 결정적 절차로 다시 정의한다. 각 mutation에 대해 호출 전 스냅샷과 mutation 후 남아야 할 정확한 행을 명시하고, 29c는 18b·18c, 29d는 18d가 반드시 실패함을 절차상 보장한다.

### R3-01 — RESOLVED

- **근거:** `docs/architecture.md:588-645`, `:837`, `:1042-1068`; `docs/decisions.md:775-784`, `:794-798`; `docs/requirements.md:249-255`
- **해결된 부분:** 요청은 정확히 `{ date, to }`이고 ID 목록을 받지 않는다. 대상은 트랜잭션 시작 시점의 해당 날짜 전체 과제다. 동일 상태는 성공하는 no-op이고 빈 날짜는 200 빈 batch다. 요청 검증은 400/write 0건, 금지 전이는 409/전체 rollback, 내부 실패는 500/전체 rollback이다. `NOT_FOUND`와 권한 오류는 현재 모델에서 발생 불가이고 가짜 Assignment ID나 내부 예외 세부정보를 응답에 만들지 않는다. 최소 테스트 9건은 응답 계약과 쓰기 원자성을 분리하며, 첫 실제 update 직후 test-only seam과 전후 전체 대상 스냅샷 deep equality를 명시한다. seam은 운영 라우트·환경변수에 노출되지 않는다. 담당 T09/T17은 예약 번호이며 배치 1 범위를 바꾸지 않는다.
- **남은 부분:** 없음.
- **구현 차단:** 아니오.
- **최소 수정안:** 없음.

### R3-02 — RESOLVED

- **근거:** `docs/requirements.md:12-20`, `:303-343`, `:355`, `:383`, `:388`, `:392-415`; `docs/architecture.md:1080-1082`; `docs/workflow/STATUS.md:25`, `:229`
- **해결된 부분:** OPEN-02 사용자 결정이 출처에 추가됐고 조건 수는 모든 현재 문서에서 33건이다. 생성 경위는 31+2=33으로 일치한다. MR-30은 요구사항 본문, D7, 부록 C 시드, T04 정상 케이스 7에 연결된다. 정방향 대상 base UR 26+조건 33+OR 3의 62개 ID와 역방향 설계·SPEC 근거에서 누락은 0건이며 OPEN도 0건이다.
- **남은 부분:** R3-02가 지적했던 항목은 없다. 출처 항목 수의 새 산술 오기는 R4-01로 분리한다.
- **구현 차단:** 아니오.
- **최소 수정안:** 없음.

## 5. 기존 Finding 집계

| 상태 | 건수 | ID |
|---|---:|---|
| RESOLVED | 5 | DR-12, RR-01, R2-02, R3-01, R3-02 |
| PARTIALLY RESOLVED | 1 | R2-04 |
| UNRESOLVED | 0 | — |
| REGRESSED | 0 | — |

## 6. Round 3 RESOLVED Finding 회귀 검사

| Finding | 현재 판정 | 근거 |
|---|---|---|
| RR-02 | **RESOLVED 유지** | `docs/specs/T01-scaffold.md:190-239`, `:279-312`, `:345-359` — 규칙을 남긴 채 `next/typescript` 제공자만 제거하는 mutation과 exit 2 계약 유지 |
| R2-01 | **RESOLVED 유지** | `docs/requirements.md:70`, `docs/architecture.md:727`, `:779-799` — 조작 영역은 너비·높이 모두 최소 48×48px 하나 |
| R2-03 | **RESOLVED 유지** | `docs/requirements.md:155-165`, `docs/architecture.md:83-92`, `docs/specs/T04-seed.md:239-250` — 시점 2+범위 8=10 일치 |
| R2-05 | **RESOLVED 유지** | `docs/architecture.md:1007-1025` — 기준일 2026-08-01, 지난 3일 2+2+2=6과 7/31 기준 4건 설명 일치 |

회귀된 Finding은 없다.

## 7. 집중 검증 결과

### A. DR-12 / T03

요청된 8개 확인 항목을 모두 충족한다. 네 suffix의 구현 단일 정의, 독립 기대 배열, journal sentinel 사전 존재 확인, cleanup 후 부재, 정확한 24b-2 mutation과 고유 테스트 실패, `.tmp/` 경계와 실패 후 정리, 개발 DB 네 파일 보호가 `docs/specs/T03-prisma-schema.md:278-290`, `:604-610`, `:622-669`, `:682`에 함께 고정돼 있다.

### B. R2-04 / T04

전체 스냅샷·새 연결·deep equality·단일 writer·운영 비노출 조건은 충족한다. 그러나 partial-persistence mutation은 완결되지 않았다. 18c·18d의 fixture에는 기존 블록·과제가 있으므로 force 삭제 전으로 4·6단계를 옮기면 0건 조건이 거짓이 되어 생성이 skip된다(`docs/specs/T04-seed.md:99-110`, `:458-470`, `:496-497`). 그 뒤 hook 실패로 트랜잭션 내부 삭제가 롤백되면 전후 스냅샷이 같아 29c의 지정 테스트 18c와 29d의 지정 테스트 18d가 통과할 수 있다. 따라서 집중 검증 B는 **FAIL**이다.

### C. R2-02 / R3-01 / bulk-status

요청·대상·응답·원자성·멱등성·빈 날짜·오류 분류·가짜 ID 및 예외 비노출·9개 테스트·첫 update seam·T09/T17 범위가 하나의 계약으로 일치한다. 핵심 근거는 `docs/architecture.md:588-645`, `:1042-1068`과 `docs/decisions.md:775-798`이다.

### D. RR-01 / R3-02 / 추적성

- 출처의 실질 목록: 요구사항 진술, AP 결정, OPEN-01 결정, OPEN-02 결정, mockup 2건 모두 존재
- 조건: 본문 33개와 §8.1-b 33개가 같은 집합이며 중복 0
- 생성 경위: 31+2=33으로 requirements·architecture·STATUS가 일치
- MR-30: requirements → D7 → 부록 C 시드 → T04 정상 케이스 7
- 정방향 누락: 0건
- 역방향 누락: 0건
- OPEN: 0건

출처 목록을 “다섯 항목”이라고 부르는 한 단어의 산술 오기는 R4-01이다. 실제 목록·추적 결과를 바꾸지는 않는다.

### E. 수동 정합성 수정

`docs/specs/T03-prisma-schema.md:610`과 `docs/specs/T04-seed.md:577-593`은 동일한 개발 DB 네 파일을 보호한다. T04의 `DEV_DB_FILES`에는 `prisma/dev.db-journal`이 있고(`:607`), 임시 DB cleanup에도 `VERIFY_DB-journal`이 있다(`:631`). 스크립트는 개발 DB를 만들거나 삭제하거나 변경하지 않고 존재 여부와 sha256만 전후 비교한다(`:609-620`, `:633-641`).

## 8. 신규 Finding

### R4-01 — 출처 6개를 “다섯 항목”이라고 부른다

- **심각도:** P3
- **대상:** `docs/requirements.md`
- **근거:** `docs/requirements.md:12-18`은 사용자 요구사항, AP 결정, OPEN-01 결정, OPEN-02 결정, mockup 2건의 **6개 bullet**을 열거하지만 `docs/requirements.md:20`은 “위 다섯 항목 중 앞의 넷 … 뒤의 둘”이라고 쓴다. 4+2도 6이므로 같은 문장 안에서도 수가 맞지 않는다.
- **거짓 양성 반증:** OPEN-02를 AP나 OPEN-01에 포함된 하위 설명으로 볼 수 없다. 세 항목은 14~16행에 서로 다른 사용자 결정과 승격 ID로 별도 bullet이다. mockup도 17~18행에 각각 별도 파일이다. 따라서 실제 출처 항목은 6개다.
- **영향:** 출처 자체는 모두 존재하므로 추적 결과나 구현값은 바뀌지 않는다. 사람이 source cardinality를 재검증할 때만 혼선을 준다.
- **구현 차단:** 아니오.
- **최소 수정안:** `docs/requirements.md:20`의 “위 다섯 항목”을 “위 여섯 항목”으로 바꾼다.

### R4-02 — T04 mutation 명령 총계가 실제 10개와 다르다

- **심각도:** P3
- **대상:** `docs/specs/T04-seed.md`
- **근거:** `docs/specs/T04-seed.md:489-498`은 seed mutation 27, 28, 28b, 29, 29b, 29c, 29d, 29e의 8개를 명시하고 `:537-540`은 `db:setup` mutation 31, 32의 2개를 더 명시한다. 실제 출력 대상은 총 10개다. 그러나 `:500`은 이를 “아홉 명령”이라고 부르고 마지막을 모호한 “30 계열”로 적는다. `:542`는 31·32가 두 명령임을 다시 확인하고 `:717`도 mutation 27~29·31·32의 출력을 요구한다.
- **거짓 양성 반증:** 정상 케이스 30 자체는 mutation이 아니며, 31과 32는 서로 다른 임시 변경과 기대 실패를 가진 두 명령이다. “30 계열”을 한 명령으로 세어 9로 만드는 해석은 `:542`의 “두 명령”과 양립하지 않는다.
- **영향:** 개별 mutation과 기대 실패는 모두 명시돼 있어 구현·검출력은 유지된다. 완료 보고 명령 수를 요약할 때 하나를 누락할 위험이 있다.
- **구현 차단:** 아니오.
- **최소 수정안:** `docs/specs/T04-seed.md:500`을 “열 명령(27·28·28b·29·29b·29c·29d·29e·31·32)”으로 고치고 `:717`도 같은 명시 목록을 사용한다.

## 9. 신규 Finding 집계

| 심각도 | 건수 | ID | 구현 차단 |
|---|---:|---|---|
| P0 | 0 | — | — |
| P1 | 0 | — | — |
| P2 | 0 | — | — |
| P3 | 2 | R4-01, R4-02 | 아니오 |

## 10. 요구사항·설계·결정·SPEC·테스트·완료 조건 추적성

- base UR 26, 조건 33, OR 3, MR 23, NR 9, OPEN 0의 실제 ID 집합과 문서 집계가 일치한다.
- 조건 본문과 정방향 조건 추적표는 같은 33개 ID이며 중복·누락이 없다.
- T01~T04의 요구사항 추적 표는 architecture 부록 A.1의 명칭·범위·의존 `T01 → T02 → T03 → T04`와 일치한다.
- 예약 번호는 T05·T07·T09·T12·T14·T17·T19뿐이며 새 번호를 만들지 않았다.
- T03의 테스트명 16-a2, mutation 24b-2, 완료 조건 reporter 이름이 일치한다.
- T04의 rollback 테스트명 18·18b·18c·18d와 mutation 29b~29e의 표상 매핑은 존재하지만, 29c→18c와 29d→18d는 실제 fixture·실행 순서에서 실패가 보장되지 않는다(R2-04). 명령 총계 요약에는 별도 R4-02도 있다.
- MR-30의 `status = PLANNED` 근거는 requirements D7 역추적, architecture 부록 C, T04 정상 케이스 7로 이어진다.
- `bulk-status`는 요구 UR-25.3~25.5 → D22 → architecture API 계약 → 9개 테스트 → T09/T17 완료 조건으로 이어진다.

**추적성 판정: BLOCK.** 요구사항·설계·결정의 정방향·역방향 누락은 0건이지만, T04의 mutation → 지정 테스트 → 완료 조건 연결이 R2-04에서 결정적이지 않다. 신규 P3 두 건도 남는다.

## 11. `implementation_allowed`

`implementation_allowed: false`

근거:

1. 재검증 대상 기존 Finding 중 R2-04가 PARTIALLY RESOLVED다.
2. 회귀 검사 4건이 모두 RESOLVED 상태를 유지한다.
3. T04 구현 정확성에 필요한 P2 R2-04가 1건 남았다.
4. `open_implementation_details`는 0이다.
5. T01~T03은 구현 가능한 수준이지만 T04의 완료 검증은 아직 완결되지 않았다.
6. 신규 R4-01·R4-02는 이미 열거된 실질 계약을 바꾸지 않는 비차단 P3지만, R2-04의 차단성을 낮추지 않는다.

## 12. 변경한 파일

- 생성: `docs/reviews/DR-T01-T04-spec-rereview-round4.md`
- 수정: `docs/workflow/STATUS.md`

## 13. 변경하지 않은 영역

- `docs/requirements.md`, `docs/architecture.md`, `docs/decisions.md`
- `docs/specs/T01-scaffold.md`, `T02-test-harness.md`, `T03-prisma-schema.md`, `T04-seed.md`
- 기존 리뷰 문서
- `AGENTS.md`, `CLAUDE.md`, `README.md`
- `.github/**`, `.gitignore`
- `package.json`, `package-lock.json`
- `prisma/**`, `src/**`, `tests/**`, `e2e/**`
- 구현 코드, 테스트 코드, DB, migration, seed, CI

## 14. 실행하지 않은 금지 작업

패키지 설치, lint/test/build, Prisma 명령, migration, seed, DB 생성·조회·변경, 브랜치 생성·변경, staging, commit, push, PR 생성·수정, merge, 배포를 실행하지 않았다. `.env`는 읽거나 수정하지 않았다.

## 15. `git diff --check`

- 명령: `git diff --check`
- 결과: 종료 코드 0, 출력 없음

## 16. 다음 담당자와 작업

- 다음 담당자: **Claude**
- 다음 작업: R2-04의 mutation 29c·29d를 실제 partial persistence와 지정 테스트 실패가 보장되도록 수정하고, R4-01·R4-02의 최소 문구 수정도 적용한다.
- 그다음 담당자: **Codex 독립 재검토자**
- 구현은 다음 독립 재검토가 차단 Finding 해소를 확인하기 전까지 시작하지 않는다.

이번 세션에서는 구현을 시작하지 않고 리뷰 문서와 STATUS만 갱신한다.
