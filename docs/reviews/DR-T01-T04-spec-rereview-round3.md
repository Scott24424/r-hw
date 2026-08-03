# T01~T04 SPEC 재검토 — Round 3

## 1. 검토 기준 브랜치와 커밋

- 저장소: `/Volumes/SSD_1TB/Projects/r-hw`
- 브랜치: `docs/specs-batch1`
- 검토 대상: `4ff75fa5a838482ac7223fc82499bffcdc0cbcdf`
- Round 2 리뷰 커밋: `8b8c0512af62cb00902ca50901159590a5b4ebb9`
- 비교 범위: `8b8c051..4ff75fa`
- 검토일: 2026-08-01
- 검토자: Codex

시작 시 `HEAD`와 `origin/docs/specs-batch1`은 모두 `4ff75fa5a838482ac7223fc82499bffcdc0cbcdf`였고 작업 트리는 clean이었다. `AGENTS.md`는 `CLAUDE.md`를 가리키는 심볼릭 링크였다. 논리 경로는 `/Users/minim4/dev/r-hw`, 물리 저장소 경로와 Git top-level은 `/Volumes/SSD_1TB/Projects/r-hw`였다.

## 2. 읽은 문서와 원본

다음 파일을 처음부터 끝까지 읽었다.

- `AGENTS.md`, `CLAUDE.md`
- `docs/requirements.md`, `docs/architecture.md`, `docs/decisions.md`
- `docs/specs/T01-scaffold.md`, `T02-test-harness.md`, `T03-prisma-schema.md`, `T04-seed.md`
- `docs/reviews/DR-T01-T04-spec-review.md`
- `docs/reviews/DR-T01-T04-spec-rereview-round1.md`
- `docs/reviews/DR-T01-T04-spec-rereview-round2.md`
- `docs/workflow/STATUS.md`
- `git diff 8b8c051..4ff75fa`
- `git show --stat --oneline 4ff75fa`

Round 2에서 확인한 두 mockup의 원본 관찰도 요구사항의 MR 값과 대조했다. 이번 변경은 원본 이미지 파일을 바꾸지 않았다.

## 3. `8b8c051..4ff75fa` 변경 범위

`4ff75fa`는 문서 7개를 수정했다(477 insertions, 82 deletions).

- `docs/requirements.md`
- `docs/architecture.md`
- `docs/decisions.md`
- `docs/specs/T01-scaffold.md`
- `docs/specs/T03-prisma-schema.md`
- `docs/specs/T04-seed.md`
- `docs/workflow/STATUS.md`

T02 SPEC과 운영 코드·테스트·패키지·CI·Prisma·DB는 비교 범위에서 바뀌지 않았다.

## 4. 검토 방법

1. 시작 상태를 먼저 고정하고 필수 문서 전체를 읽었다.
2. 본문 ID와 추적표 ID를 기계적으로 추출해 집합·중복·개수를 비교했다.
3. requirements → architecture → decisions → SPEC의 정방향과 역방향을 대조했다.
4. 각 mutation이 명시된 결함을 실제로 만들 수 있는지 반례를 구성했다.
5. Next.js·ESLint·SQLite 전제는 공식 문서와 태그된 공식 소스로 확인했다. 패키지 설치나 DB 실행은 하지 않았다.

## 5. 기존 Finding 8건 개별 판정

### DR-12 — PARTIALLY RESOLVED

- 현재 심각도: **P2**
- 영향: **T03**, 구현 차단
- 검증한 계약: DB 본체·`-wal`·`-shm`·`-journal` 정리, 템플릿 교체 실패 복구, 실제 sidecar 삭제, `.tmp` 경계, mutation 검출력
- 근거:
  - `docs/specs/T03-prisma-schema.md` 278~290행: `DB_FILE_SUFFIXES`와 `dbFilePaths`가 네 DB 경로를 단일 정의한다.
  - 같은 파일 303~307행, 313~341행: 임시 파일 정리, DB rename 후 meta finalize 실패 시 최종 meta 삭제와 다음 호출 강제 재생성을 정의한다.
  - 같은 파일 603~608행: 실제 WAL/SHM 존재 확인, 연결 종료 후 네 파일 재생성·재정리, rename 후 실패 복구, `.tmp` 밖 불변 검사를 둔다.
  - 같은 파일 629~632행: `-journal`·meta·WAL/SHM mutation을 요구한다.
- 해결된 부분: 네 접미사의 단일 정의, `beforeMetaFinalizeHook`, rename 후 meta 제거·재생성, cleanup의 직접 삭제, 조기 반환 금지, `.tmp` 경계는 구현자가 추가 판단 없이 구현할 수 있다.
- 남은 문제:
  1. 케이스 16b는 migration이 **성공한 뒤** `beforeTemplateFinalizeHook`에서 실패한다(605행). SQLite 기본 DELETE journal 모드에서는 정상 transaction 종료 때 rollback journal이 삭제된다. 따라서 `DB_FILE_SUFFIXES`에서 `-journal`을 제거해도 실패 시점에 그 파일이 원래 없을 수 있어 24b mutation(630행)이 통과한다. `-journal`을 결정적으로 미리 만들거나 migration 도중 실패시키는 seam이 없다.
  2. 16b의 부재 단정이 구현의 `dbFilePaths`를 그대로 사용하면, 같은 상수에서 `-journal`을 제거한 mutation이 검사 대상 집합도 함께 줄이는 공유-상수 거짓 양성이 생긴다. 테스트 기대 경로는 독립 리터럴이어야 한다.
  3. `.tmp` 밖 불변 검사 16e는 `prisma/dev.db`, `-wal`, `-shm`만 본다(608행). 13-11은 개발 DB와 sidecar 전체를 보호한다고 쓰므로 `prisma/dev.db-journal`도 같은 불변 스냅샷에 있어야 한다.
- 결론: 정리 구현 계약은 크게 보강됐지만 `-journal` 누락 mutation을 실제로 탐지한다는 완료 조건은 아직 증명되지 않는다. 잘못된 구현이 필수 검증을 통과할 수 있어 RESOLVED가 아니다.

### RR-01 — PARTIALLY RESOLVED

- 현재 심각도: **P3**
- 영향: 공통 요구사항 권위·추적성, T01~T04 직접 구현 차단은 아님
- 검증한 계약: base UR 26, 조건 33, OR 3, MR 23, NR 9, OPEN 0, 양방향 추적, 관찰/사용자 결정 구분
- 근거:
  - `docs/requirements.md` 21~33행은 UR/OR/MR/NR/OPEN을 구분한다.
  - 같은 파일 43~113행의 base/조건 본문과 268~336행의 추적표를 기계 비교한 결과 두 집합은 각각 정확히 일치했고 중복은 없었다.
  - 같은 파일 387~396행의 26/33/3/23/9/0 집계는 실제 고유 ID 집합과 일치한다.
  - MR 관찰과 사용자 지정 날짜의 구분은 MR-20~22(152~154행), UR-26(73행), §7.2(252~255행)에 명확하다.
- 남은 문제: `docs/requirements.md` 300행은 제목과 실제 표가 33건인데도 “조건 ID 31개 전부”라고 쓰며, 12~17행의 원문 출처에 OPEN-02 사용자 결정을 누락한다. 역방향 표의 부록 C/T04 근거는 `MR-01~MR-29`까지만 적어 MR-30을 제외하지만(378, 383행), 검사 결과는 mockup 관찰 미반영 0건이라고 선언한다(404행). 자세한 결함은 R3-02다.
- 결론: 권위 문서의 ID 본문/추적표 집합은 복구됐지만 자기감사·출처·MR 역추적이 아직 완전히 정확하지 않다.

### RR-02 — RESOLVED

- 잔여 심각도: 없음
- 영향: **T01**, 구현 차단 없음
- 근거:
  - `docs/specs/T01-scaffold.md` 190~231행은 FlatCompat, `next/core-web-vitals`, `next/typescript`, `no-explicit-any`, 의존성 출처를 완결한다.
  - 같은 파일 279~312행은 규칙을 남긴 채 `next/typescript`만 제거하고, 설정 오류 취지와 종료 코드 2를 판정한다. 전체 문구 exact match는 요구하지 않는다.
- 공식 대조: `eslint-config-next` v15.5.4의 `typescript.js`는 `plugin:@typescript-eslint/recommended`를 확장하고, `index.js`는 TypeScript parser만 지정하며 `@typescript-eslint` plugin을 등록하지 않는다. `core-web-vitals.js`도 base와 Next plugin만 확장한다. ESLint v9.35.0 `throwRuleNotFoundError`는 plugin 부재 메시지를 만들고 공식 CLI 문서는 configuration problem의 종료 코드를 2로 정의한다.
- 결론: 구현 결함 없이 실패하거나 플러그인 누락이 있어도 통과하던 Round 2의 mutation 오류가 제거됐다. 깨끗한 checkout의 설정 파일·의존성 계약도 단일하다.

### R2-01 — RESOLVED

- 잔여 심각도: 없음
- 영향: 공통 UI, T01~T04 범위 확대 없음
- 근거: `docs/requirements.md` UR-20(67행), `docs/architecture.md` §6.2-1(699행), §6.4(764~771행)가 모두 너비·높이 최소 `48×48px`을 사용한다. 남은 `44×44px` 표기는 “쓰지 않는다”는 금지와 과거 Finding 이력뿐이다.
- 결론: 값의 정의처와 인수 기준이 하나이며 T01~T04에 UI 구현을 추가하지 않았다.

### R2-02 — PARTIALLY RESOLVED

- 현재 심각도: **P2**
- 영향: 공통 문서, 후속 **T09/T17**, 전체 구현 게이트 차단
- 근거:
  - `docs/requirements.md` 105~107행과 `docs/decisions.md` D22(762~787행)는 원자적 롤백과 동일 상태 성공 no-op을 사용자 승인값으로 일치시킨다.
  - `docs/workflow/STATUS.md` 25행은 requirements source에 OPEN-02를 포함한다.
  - 본문과 추적표의 실제 ID 집합은 26/33/3/23/9/0으로 일치한다.
- 해결된 부분: OPEN-02의 **정책 값**과 담당 T09/T17은 확정됐고 T01~T04 범위는 늘지 않았다.
- 남은 문제: 날짜 전체를 대상으로 하는 `{ date, to }` 요청과 항목별 `NOT_FOUND` 실패가 양립하지 않으며, 빈 날짜·validation 오류의 응답과 처리 순서도 정해지지 않았다. 따라서 `open_implementation_details: 0`은 실제로는 성립하지 않는다. R3-01이 구체적인 잔여 결함이다. 집계 설명의 stale `31개`는 R3-02에 기록한다.
- 결론: 사용자 선택은 종결됐지만 그 값을 API로 옮기는 계약에 구현자가 선택해야 할 사항이 1건 남았다.

### R2-03 — RESOLVED

- 잔여 심각도: 없음
- 영향: 공통 관찰/T04, 구현 차단 없음
- 근거: `docs/requirements.md` MR-21~22(153~154행)는 시점 2건과 범위 8건을 정확히 열거하고 합계 10을 명시한다. `docs/architecture.md` F11과 부록 C.1, `docs/specs/T04-seed.md` 요구사항 9의 10행도 같은 값이다.

### R2-04 — PARTIALLY RESOLVED

- 현재 심각도: **P2**
- 영향: **T04**, 구현 차단
- 검증한 계약: 블록/과제 생성 전후 실패, 빈 DB·사용자 DB·force, 호출 전후 전체 DB deep equality, transaction 밖 쓰기 mutation, seam의 운영 경로 비노출
- 근거:
  - `docs/specs/T04-seed.md` 77~125행은 세 hook과 동일 `tx`의 1~7단계를 정의한다.
  - 같은 파일 127~146행은 호출 전후 snapshot equality를 요구한다.
  - 같은 파일 417~425행은 빈 DB, 사용자 fixture+force, 블록 후, 과제 후의 네 rollback 테스트를 둔다.
  - 같은 파일 450~455행은 블록·과제 생성을 외부 client로 바꾸는 mutation을 둔다.
- 해결된 부분: 실패 seam의 위치와 운영 `main()` 비노출은 명확하고, 생성 단계 직후 실패 경로 자체는 구현 가능하다.
- 남은 문제:
  1. snapshot은 `id`, `createdAt`, `updatedAt`, `completedAt`, `bookId`를 제외한다(130~142행). 특히 Book upsert를 transaction 밖으로 옮긴 잘못된 구현은 기존 Book의 `updatedAt`만 커밋하고 rollback 테스트를 통과할 수 있다. 이는 “실행 전과 전체 DB 상태가 동일”을 증명하지 않는다.
  2. mutation 29b/29c는 이미 Book upsert·삭제로 write transaction이 열린 동안 별도 `client`로 같은 SQLite 파일에 쓰도록 한다. SQLite는 한 번에 writer 하나만 허용하므로 외부 쓰기가 `SQLITE_BUSY`/timeout으로 reject될 수 있다. 테스트의 기대도 reject + 전후 동일이므로, 잘못된 구현이 실제 행을 남기지 못한 채 **성공적으로 mutation 검증을 통과**할 수 있다.
  3. Book upsert 자체를 transaction 밖으로 옮기는 mutation은 없다. 요구사항 113행은 Book까지 같은 `tx`라고 하지만 현재 mutation은 블록·과제만 대상으로 한다.
- 최소 수정 방향: 모든 컬럼을 포함한 raw/Prisma snapshot으로 전후를 비교하되 의도적으로 허용할 차이가 있다면 rollback 계약에서 명시한다. 외부 client mutation은 잠금 실패가 아니라 부분 commit을 결정적으로 만드는 위치로 이동하거나, transaction client 사용 여부를 독립 spy/adapter로 검증한다. Book upsert 경계 mutation도 추가한다.
- 결론: rollback 정상 테스트는 늘었지만 명시된 mutation이 transaction 밖 commit 결함을 결정적으로 만들지 못한다.

### R2-05 — RESOLVED

- 잔여 심각도: 없음
- 영향: 공통 파일럿 시나리오, 구현 차단 없음
- 근거: `docs/architecture.md` 부록 C.3(981~995행)은 기준일을 `2026-08-01`로 고정하고 7/29·7/30·7/31 각 2건, 합계 6건을 표로 계산한다. 같은 절 995행은 기준일이 7/31이면 4건임을 별도로 설명한다. T04 원본 seed 값은 바뀌지 않았다.

## 6. 기존 Finding 집계

| 상태 | 건수 | ID |
|---|---:|---|
| RESOLVED | 4 | RR-02, R2-01, R2-03, R2-05 |
| PARTIALLY RESOLVED | 4 | DR-12, RR-01, R2-02, R2-04 |
| UNRESOLVED | 0 | — |
| REGRESSED | 0 | — |

## 7. OPEN-02 종결 검증

| 항목 | 판정 | 근거 |
|---|---|---|
| 실패 1건이면 전체 rollback | PASS | requirements UR-25.4(106행), D22(770행), architecture 581·603~617·1008행 |
| 동일 상태 성공 no-op | PASS | requirements UR-25.5(107행), D22(771·783행), architecture 599·614·1010행 |
| 요청 `{ date, to }`와 날짜 전체 대상 | PASS | architecture 581·590~592·1002행 |
| 성공 `changed`/`unchanged`/`items` | PASS | architecture 594~601·614행 |
| 실패 HTTP/status/body | **FAIL** | architecture 603~610행은 409·`applied:false`를 보이지만 날짜 대상에서 만들 수 없는 항목별 `NOT_FOUND`를 포함하고 validation/빈 날짜 계약이 없다(R3-01) |
| 최소 테스트 1·3·4·5 | PASS | architecture 1018, 1020~1022행 |
| 최소 테스트 2의 결정성 | **FAIL** | 없는 과제는 요청 모델상 지정할 수 없고, “성공 항목 먼저”를 보장할 처리 순서가 없다(1019·1024행) |
| T01~T04 범위 확대 없음 | PASS | requirements 250행, D22 787행, architecture 1014행 |
| T09/T17 예약 번호 | PASS | architecture 586·887·900·1014행의 기존 예약 번호와 일치 |

승인된 두 **정책 값은 종결**됐다. 다만 그 정책을 날짜 기반 API로 구현하는 상세 계약은 종결되지 않았다.

## 8. 신규 Finding

### R3-01 — 날짜 전체 `bulk-status` 요청에서 항목별 `NOT_FOUND`와 rollback mutation을 만들 수 없다

- 심각도: **P2**
- 대상: 공통 architecture/requirements, 후속 T09·T17
- 근거: `docs/requirements.md` UR-25.4(106행), `docs/architecture.md` §5.2(581, 588~617행), 부록 C.3(1002, 1014~1024행)
- 실제 문제: 요청에는 assignment ID가 없고 서버가 `date`로 존재하는 전체 행을 선택한다. 따라서 선택 결과 안의 특정 ID가 `NOT_FOUND`일 수 없으며, “성공 항목 뒤에 없는 과제”를 배치할 수도 없다. 날짜에 행이 0건일 때 성공 no-op인지 404인지, malformed `date`/`to`가 409인지 400/422인지도 정의되지 않았다. 금지 전이를 뒤에 두는 대안도 처리 순서가 정해지지 않아 mutation이 결정적이지 않다.
- 구현 시 예상 실패: T09 구현자가 ID 입력을 새로 추가하거나 `NOT_FOUND`를 제거하거나 빈 날짜/validation 상태를 임의로 선택해야 한다. 테스트 작성자는 존재 불가능한 fixture를 만들거나 구현 순서에 결합된 거짓 음성 테스트를 작성하게 된다.
- 최소 수정 방향: `{ date, to }`를 유지한다면 항목별 `NOT_FOUND`를 제거하고 빈 날짜·validation 응답을 정의한다. 금지 전이 항목으로 rollback을 검증할 경우 대상 처리 순서를 고정하거나, 한 번의 실제 write 뒤 실패시키는 test seam으로 transaction 밖 구현을 결정적으로 검출한다.
- 판정 영향: `open_implementation_details: 1`, 전체 **BLOCK**. T01~T04의 파일 범위를 늘리지는 않지만 구현 허용 게이트는 열 수 없다.

### R3-02 — 요구사항 권위 문서의 출처·개수 문구와 MR 역추적이 실제 집합과 다르다

- 심각도: **P3**
- 대상: `docs/requirements.md`
- 근거: 7·12~17행, 298~300행, 378·383·404행
- 실제 문제: OPEN-02 사용자 결정이 권위 문서의 원문 출처 목록에 없고, 실제 33개 조건 표를 “31개 전부”라고 부른다. MR-30은 본문에 있지만 부록 C/T04 역추적 범위가 MR-29에서 끝나면서 “mockup 관찰 미반영 0건” 선언과 맞지 않는다.
- 구현 시 예상 실패: 자동 집합 검사는 통과해도 사람이 출처와 역추적 범위를 재검증할 때 서로 다른 결론을 얻는다. MR-30을 의도적으로 제외했는지 누락했는지 판정할 수 없다.
- 최소 수정 방향: 원문 출처에 OPEN-02를 추가하고 `31`을 `33`으로 고친다. MR-30의 반영 위치 또는 의도적 비채택/비요구 근거를 역추적 표에 명시한다.
- 판정 영향: 요구사항 권위 검증은 **PASS WITH CHANGES** 수준의 잔여다. 단독으로 T01~T04를 막지는 않는다.

### 신규 Finding 심각도 집계

| 심각도 | 건수 | ID |
|---|---:|---|
| P0 | 0 | — |
| P1 | 0 | — |
| P2 | 1 | R3-01 |
| P3 | 1 | R3-02 |

## 9. 요구사항·설계·SPEC 정합성 결과

- ID 집합: base UR 26, 조건 33, OR 3, MR 23, NR 9, OPEN 0의 **본문 ID 집합**은 정확하고 중복이 없다. base/조건 본문과 정방향 추적표의 ID 집합도 각각 일치한다.
- 사용자 결정과 mockup 관찰: UR/MR/NR 구분, 2026 연도·`2026-07-29` 날짜의 사용자 지정 성격, 일일 시간표 날짜 부재는 일치한다.
- UR-26 계열: 10개 블록은 7/29에만 생성되고 다른 19일은 0건이며 빈 시간표가 정상이다. `ScheduleBlock.date`, 날짜 인덱스와 날짜별 조회가 가능하고 템플릿/반복은 MVP 밖이며 파일럿 날짜를 제품 상수로 만들지 않는다.
- 기술 기반: Node `{22,24,26}`, `.nvmrc=22`, engines, CI `node-version-file`, Next 15.5+, TS, ESLint 9/FlatCompat, Vitest/Playwright, lockfile, `next typegen && tsc --noEmit`, Tailwind 구조/브라우저 책임 분리는 T01~T02와 decisions에 일치한다.
- Prisma/DB: 6.2.0 이상, enum의 SQLite DB 비강제 수준, schema 단일 정의, `ScheduleBlock.date`, 날짜별 겹침, 인덱스, D19 npm script, `db:setup` 합성 검증은 일치한다. T03 helper의 `-journal` mutation 검출력만 DR-12로 차단된다.
- T04: 9/10/27 exact fixture 독립성, 단일 transaction 요구, 비파괴 기본·Book 보존·force 범위, 새 임시 DB 검증, 7/29 전용 블록, 반복 실행은 일치한다. 생성 rollback mutation의 결정성은 R2-04로 차단된다.
- 의존 순서와 소유권: T01 → T02 → T03 → T04와 T04의 `src/server/prisma.test.ts` 한정 예외가 명시되어 있고 새 태스크 번호는 없다.
- 최종 정합성: **FAIL / BLOCK**. 핵심 데이터와 도구 값은 대체로 일치하지만 DR-12, R2-04, R3-01 때문에 반증 가능성과 구현 무모순성이 부족하다.

`unapproved_design_assumptions: 0`은 타당하다. 사용자 승인 없이 새 제품 결정을 확정한 것은 찾지 못했다. `open_implementation_details`는 **1**이며 ID는 R3-01이다.

## 10. 태스크별 판정

### T01 — PASS

RR-02가 해결됐고 T01의 Node/Next/TypeScript/ESLint/Tailwind/typegen/clean checkout 계약은 추가 판단 없이 실행 가능하다.

### T02 — PASS

Round 3에서 바뀌지 않았다. Round 2 PASS 근거인 Vitest, Playwright, Node 지원 집합, CI, 브라우저 `42px` 검증 계약에 새 모순을 찾지 못했다.

### T03 — BLOCK

DR-12가 PARTIALLY RESOLVED다. `-journal` 정리 누락 mutation이 거짓 양성으로 통과할 수 있어 helper 정리·재현성 완료 조건이 아직 반증 가능하지 않다.

### T04 — BLOCK

R2-04가 PARTIALLY RESOLVED다. snapshot이 전체 DB 상태가 아니고, 외부 client mutation이 SQLite writer lock으로 단순 실패해 테스트가 통과할 수 있어 단일 transaction과 완전 rollback을 증명하지 못한다.

## 11. 전체 판정

**BLOCK**

- 미해결 구현 차단 P2: DR-12, R2-02, R2-04, R3-01
- 비차단 P3: RR-01, R3-02
- P0/P1: 0

## 12. `implementation_allowed`

`implementation_allowed: false`

T03·T04의 데이터 안전성/재현성 mutation이 거짓 양성을 허용하고, OPEN-02를 옮긴 날짜 기반 API 계약에 구현 결정 1건이 남는다. T01과 T02가 PASS여도 T01→T04 순차 구현 전체 게이트는 열 수 없다.

## 13. 공식 자료와 검증 한계

확인일은 모두 2026-08-01이다.

- Next.js 15.5.4 `eslint-config-next` 공식 소스:
  - https://github.com/vercel/next.js/blob/v15.5.4/packages/eslint-config-next/typescript.js
  - https://github.com/vercel/next.js/blob/v15.5.4/packages/eslint-config-next/index.js
  - https://github.com/vercel/next.js/blob/v15.5.4/packages/eslint-config-next/core-web-vitals.js
  - https://github.com/vercel/next.js/blob/v15.5.4/packages/eslint-config-next/package.json
- ESLint v9.35.0 missing-plugin 공식 소스: https://github.com/eslint/eslint/blob/v9.35.0/lib/config/config.js
- ESLint CLI exit code: https://eslint.org/docs/latest/use/command-line-interface#exit-codes
- SQLite rollback journal: https://www.sqlite.org/tempfiles.html#rollback_journals
- SQLite 단일 writer/격리: https://www.sqlite.org/isolation.html, https://www.sqlite.org/wal.html

패키지 설치와 실제 T01 mutation, Prisma/SQLite integration test는 금지 범위 때문에 실행하지 않았다. RR-02는 태그된 공식 소스의 정적 계약으로 판정했다. DR-12와 R2-04는 공식 SQLite 동작 및 SPEC에 명시된 실패 위치로 반례를 구성했으며 실제 패키지 조합의 오류 전문·timeout 시간은 구현 시에만 확인할 수 있다.

## 14. 변경한 파일과 변경하지 않은 영역

이번 검토가 생성·수정하는 파일은 다음 둘뿐이다.

- 생성: `docs/reviews/DR-T01-T04-spec-rereview-round3.md`
- 수정: `docs/workflow/STATUS.md`

requirements, architecture, decisions, T01~T04 SPEC, 기존 리뷰 3개, AGENTS/CLAUDE/README, 운영 코드, 테스트, 패키지, CI, Prisma, DB는 수정하지 않았다.

## 15. 다음 담당자와 작업

- 다음 담당자: **Claude**
- 다음 작업:
  1. DR-12의 `-journal` 실패 파일을 결정적으로 만들고 독립 기대 경로로 검사하며 개발 `-journal` 불변성도 포함한다.
  2. R2-04의 전체-row snapshot, Book 경계 mutation, SQLite writer lock에 의존하지 않는 외부 transaction 결함 검증을 정의한다.
  3. R3-01의 날짜 기반 요청·실패 분류·빈 날짜·HTTP 상태·결정적 rollback test를 무모순하게 고친다.
  4. R3-02의 출처·33건 문구·MR-30 역추적을 정정한다.
  5. 수정 후 Codex에 Round 4 독립 재검토를 요청한다.

이번 세션에서는 구현을 시작하지 않는다.
