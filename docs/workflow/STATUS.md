# Workflow Status

- current_branch: docs/specs-batch1
- stage: spec-reviewed
- doc_status: changes-requested
- active_tasks: T01, T02, T03, T04
- spec_writer: claude
- spec_reviewer: codex
- review_round: 4
- review_target_commit: 9a70c5c42ea9d38aea0d30b5eccb9a527b20c7b1
- review_file: docs/reviews/DR-T01-T04-spec-rereview-round4.md
- previous_review_file: docs/reviews/DR-T01-T04-spec-rereview-round3.md
- original_review_file: docs/reviews/DR-T01-T04-spec-review.md
- original_review_commit: b4511c7
- rereview_base_commit: c77ab5c33122da5fd3414e1ed054fe22224506fc
- revision_round: 4
- revision_baseline_commit: 9acc7b2
- overall_verdict: BLOCK
- T01_verdict: PASS
- T02_verdict: PASS
- T03_verdict: PASS
- T04_verdict: BLOCK
- implementation_allowed: false
- requirements_file: docs/requirements.md
- requirements_source: user statements of 2026-08-01 (requirements + AP-01..AP-12 decisions + OPEN-01 decision + OPEN-02 decision) + both mockups
- unapproved_design_assumptions: 0
- open_implementation_details: 0
- open_implementation_detail_ids: —
- next_action: Claude fixes blocking R2-04 mutation 29c/29d and nonblocking R4-01/R4-02; Codex then independently rereviews
- next_owner: claude

## Verdict ownership

**Only Codex changes finding verdicts.** Claude is the spec author and does not mark its own work `RESOLVED`, `PASS`, or `CLOSED`. 아래 revision 3·4의 `addressed_by_claude` / `pending_codex_verification` 이력은 그대로 보존한다. **현재 `overall_verdict`와 태스크별 판정은 Codex Round 4의 결과다** — T01 PASS · T02 PASS · T03 PASS · T04 BLOCK · overall BLOCK.

Round 2·3의 Codex 판정과 심각도 집계는 **역사적 기록이며 변경하지 않았다.** Claude revision 3·4의 집계도 과거 수정 이력이다. 현재 잔여 심각도는 아래 **Round 4 — Codex verdict** 절이 정의한다.

`doc_status`는 `changes-requested`다. 기존 재검증 Finding 6건 중 5건은 RESOLVED, R2-04는 PARTIALLY RESOLVED이며, 회귀 대상 4건은 모두 RESOLVED를 유지한다. 신규 P3 R4-01·R4-02는 비차단이지만 R2-04의 잔여 P2가 T04 구현을 차단하므로 `implementation_allowed`는 `false`다.

`open_implementation_details`가 `0`인 것은 **R3-01이 지적한 미결 선택(빈 날짜 · validation · HTTP 분류 · 결정적 rollback test)을 문서가 이제 지정한다**는 사실 기록이다. Codex Round 4는 이 원문 계약을 독립 대조해 R3-01을 `RESOLVED`로 판정했다.

## Finding Status

### Round 1 snapshot — Codex at `944fe85`

- existing_findings_total: 14
- existing_resolved: 10
- existing_partially_resolved: 4
- existing_unresolved: 0
- existing_regressed: 0
- new_findings_total: 3
- remaining_P0: 0
- remaining_P1: 5
- remaining_P2: 2
- remaining_P3: 0
- remaining_P0_P1: 5

### Round 2 — Codex verdict at target `2557d75` (변경 없음)

- rereviewed_existing_findings_total: 7
- existing_resolved_round2: 4
- existing_partially_resolved_round2: 3
- existing_unresolved_round2: 0
- existing_regressed_round2: 0
- new_findings_total_round2: 5
- new_P0_round2: 0
- new_P1_round2: 0
- new_P2_round2: 3
- new_P3_round2: 2
- remaining_P0: 0
- remaining_P1: 2
- remaining_P2: 4
- remaining_P3: 2
- remaining_P0_P1: 2

| Finding | Codex Round 2 verdict | Remaining issue (Codex 기록) |
|---|---|---|
| DR-03 | RESOLVED | — |
| DR-07 | RESOLVED | — |
| DR-11 | RESOLVED | — |
| DR-12 | PARTIALLY RESOLVED | template rollback journal, finalize failure, sidecar deletion false positive |
| RR-01 | PARTIALLY RESOLVED | requirements authority/traceability defects; R2-01~R2-03 |
| RR-02 | PARTIALLY RESOLVED | mutation case 15 cannot produce its specified missing-plugin error |
| RR-03 | RESOLVED | — |

| New Finding | Severity | Target |
|---|---|---|
| R2-01 | P2 | requirements/architecture — 48×48 vs 44×44 |
| R2-02 | P2 | requirements/architecture/STATUS — open detail and trace count |
| R2-03 | P3 | requirements — range block count |
| R2-04 | P2 | T04 — creation-stage rollback test gap |
| R2-05 | P3 | architecture — pilot date/overdue count mismatch |

### Round 3 — Codex verdict at target `4ff75fa`

- rereviewed_existing_findings_total_round3: 8
- existing_resolved_round3: 4
- existing_partially_resolved_round3: 4
- existing_unresolved_round3: 0
- existing_regressed_round3: 0
- new_findings_total_round3: 2
- new_P0_round3: 0
- new_P1_round3: 0
- new_P2_round3: 1
- new_P3_round3: 1
- remaining_P0: 0
- remaining_P1: 0
- remaining_P2: 4
- remaining_P3: 2
- remaining_P0_P1: 0

| Finding | Codex Round 3 verdict | Current severity | Implementation blocking | Remaining issue |
|---|---|---:|---|---|
| DR-12 | PARTIALLY RESOLVED | P2 | yes — T03 | `-journal` mutation이 파일을 결정적으로 만들지 않고 기대 경로가 구현 상수를 공유할 수 있음; dev `-journal` 불변 검사 누락 |
| RR-01 | PARTIALLY RESOLVED | P3 | no | stale `31개`, OPEN-02 출처 누락, MR-30 역추적 누락 |
| RR-02 | RESOLVED | — | no | — |
| R2-01 | RESOLVED | — | no | — |
| R2-02 | PARTIALLY RESOLVED | P2 | yes — overall/T09·T17 | 정책 값은 결정됐으나 날짜 요청의 실패 계약 R3-01이 남음 |
| R2-03 | RESOLVED | — | no | — |
| R2-04 | PARTIALLY RESOLVED | P2 | yes — T04 | snapshot이 전체 DB가 아니고 외부 client mutation이 SQLite writer lock으로 거짓 양성 가능 |
| R2-05 | RESOLVED | — | no | — |

| New Finding | Severity | Target | Implementation blocking |
|---|---:|---|---|
| R3-01 | P2 | requirements/architecture, follow-up T09·T17 | yes — overall |
| R3-02 | P3 | requirements authority/traceability | no |

Round 3 태스크 판정은 **T01 PASS / T02 PASS / T03 BLOCK / T04 BLOCK / overall BLOCK**이다. 상세 근거는 `docs/reviews/DR-T01-T04-spec-rereview-round3.md`에 있다.

### Round 4 — Codex verdict at target `9a70c5c`

- rereviewed_existing_findings_total_round4: 6
- existing_resolved_round4: 5
- existing_partially_resolved_round4: 1
- existing_unresolved_round4: 0
- existing_regressed_round4: 0
- regression_findings_checked_round4: 4
- regression_findings_resolved_round4: 4
- new_findings_total_round4: 2
- new_P0_round4: 0
- new_P1_round4: 0
- new_P2_round4: 0
- new_P3_round4: 2
- remaining_P0: 0
- remaining_P1: 0
- remaining_P2: 1
- remaining_P3: 2
- implementation_blocking_findings: 1

| Existing Finding | Codex Round 4 verdict | Implementation blocking | Result |
|---|---|---|---|
| DR-12 | RESOLVED | no | T03 cleanup의 `-journal` 직접 삭제와 mutation 검출력이 독립 기대값·sentinel 절차로 결정적으로 지정됨 |
| RR-01 | RESOLVED | no | 권위 요구사항, 출처, 33개 조건, MR-30 역추적이 완결됨 |
| R2-02 | RESOLVED | no | OPEN-02 정책과 bulk-status 요청·실패 계약이 일치하고 미결 구현 상세가 없음 |
| R2-04 | PARTIALLY RESOLVED | yes — T04 | 전체 DB snapshot·새 client·deep equality는 보강됐으나 29c·29d가 force fixture에서 생성을 skip해 지정 테스트가 통과할 수 있음 |
| R3-01 | RESOLVED | no | `{ date, to }` 계약, 400/409/500/빈 날짜, 9개 테스트와 rollback seam이 무모순하게 지정됨 |
| R3-02 | RESOLVED | no | 출처·33개 생성 경위·MR-30·양방향 추적·OPEN 0건이 일치함 |

| Regression Finding | Codex Round 4 verdict | Result |
|---|---|---|
| RR-02 | RESOLVED 유지 | T01 ESLint mutation의 오류와 종료 코드 계약에 회귀 없음 |
| R2-01 | RESOLVED 유지 | 48×48 최소 터치 영역 계약에 회귀 없음 |
| R2-03 | RESOLVED 유지 | 범위 블록 8건과 시점 2건의 구분에 회귀 없음 |
| R2-05 | RESOLVED 유지 | 기준일 2026-08-01과 밀린 6건 계산에 회귀 없음 |

| New Finding | Severity | Target | Implementation blocking | Required change |
|---|---:|---|---|---|
| R4-01 | P3 | requirements source count wording | no | `docs/requirements.md:20`의 `다섯 항목`을 실제 6개 출처와 맞게 `여섯 항목`으로 정정 |
| R4-02 | P3 | T04 mutation command count wording | no | `docs/specs/T04-seed.md:500`, `:717`을 실제 10개 mutation 명령과 일치시킴 |

Round 4 태스크 판정은 **T01 PASS / T02 PASS / T03 PASS / T04 BLOCK / overall BLOCK**이다. P2 R2-04가 T04 구현을 차단하므로 `implementation_allowed`는 **false**다. 상세 근거는 `docs/reviews/DR-T01-T04-spec-rereview-round4.md`에 있다.

### Revision 3 — Claude 수정 (baseline `8b8c051`, 미커밋)

**모든 항목의 상태는 `addressed_by_claude` / `pending_codex_verification`이다. RESOLVED 판정은 다음 Codex 독립 재검토에서만 나온다.**

| Finding | 상태 | 무엇을 고쳤는가 |
|---|---|---|
| DR-12 | addressed_by_claude / pending_codex_verification | T03에 `DB_FILE_SUFFIXES = ["", "-wal", "-shm", "-journal"]` 단일 정의처(12-A)를 두어 rollback journal을 정리 대상에 포함. 13-A에 `beforeMetaFinalizeHook` seam과 **DB rename 이후 실패 경로(3'-b)** 추가 — 최종 meta를 지워 다음 호출이 강제 재생성하게 한다. 케이스 16을 "cleanup 전 sidecar 존재 단정 + 이후 4경로 부재"로 바꾸고, **cleanup이 sidecar를 직접 지운다는 것을 증명하는 16-a**(연결이 없는 상태에서 파일을 다시 만든 뒤 재호출) 추가. 13-10에 조기 반환 금지 명시. 13-11로 정리 범위를 `<root>/.tmp/` 안으로 한정하고 개발 DB 불변을 16e로 검증. 신규 mutation 24c·24d, 경계 31, 완료 조건 `ls -A .tmp/` 추가 |
| RR-01 | addressed_by_claude / pending_codex_verification | requirements의 자기 검사를 실제 ID 집합에서 다시 산출 — base UR **26**, 조건 **31**, OR 3, MR 23, NR 9, OPEN **1**. **이후 `OPEN-02` 결정으로 `UR-25.4`·`UR-25.5`가 추가되어 현재 값은 조건 33 · OPEN 0이다** (아래 "OPEN-02 — decided"). 조건 전부의 반영 위치를 §8.1-b 표로 신설. §8.3에 ID 개수 표·중복 검사·값 충돌 검사 행 추가. `OPEN-02`를 §7/§7.1에 기록해 "미결 0건" 주장을 제거. R2-01·R2-02·R2-03의 개별 수정은 아래 각 행 |
| RR-02 | addressed_by_claude / pending_codex_verification | T01 케이스 15를 **`extends`에서 `next/typescript`만 제거**(규칙은 유지)하는 mutation으로 교체. 기대 결과를 `Key "rules": ... Could not find plugin "@typescript-eslint" in configuration.` + **종료 코드 2**로 고정. 근거로 `eslint-config-next` v15.5.4 공식 소스(플러그인은 `typescript.js`에서만 등록, base는 파서만 지정)와 ESLint v9.35.0 `config.js`의 오류 생성 코드를 URL·확인일과 함께 기록. 요구사항 19로 "ESLint 설정 파일은 `eslint.config.mjs` 하나, 삭제할 레거시 파일 없음"을 명시 |
| R2-01 | addressed_by_claude / pending_codex_verification | architecture §6.2-1의 `44×44px`을 **`48×48px`**로 통일하고 정의처가 UR-20임을 명시. §6.4에 "화면별로 다른 값을 쓰지 않는다 · 너비와 높이 둘 다 48px 이상 · 후속 화면 태스크의 인수/E2E 기준도 같은 값" 규칙 추가. requirements §8.1의 UR-20 행과 §8.2에 값 정의처 기록. **규범적으로 `44×44px`을 지시하는 문장 0건** — 남은 `44×44` 언급은 architecture §6.4의 "쓰지 않는다"는 금지 문장과 이 STATUS의 Finding 기록뿐이다 |
| R2-02 | addressed_by_claude / pending_codex_verification | 집계는 실제 ID에서 재산출(위 RR-01). 정책은 Claude가 정하지 않고 `OPEN-02`로 사용자에게 올렸으며, **2026-08-01 사용자 승인으로 종결**되어 `UR-25.4`(원자적 전부 롤백)·`UR-25.5`(동일 상태 멱등 no-op)로 승격 → **`open_implementation_details: 0`**. 결정 기록은 `decisions.md` **D22**, 계약은 architecture §5.2, 최소 테스트 조건 5건은 부록 C.3·§7.2, 담당은 T09(API)·T17(화면)로 배치 1 범위 밖. **T01~T04 범위 밖임을 세 문서에 함께 명시.** 추적성 검사 중 발견한 추가 결함도 함께 수정 — 부록 C.3이 지시하는 `POST /api/assignments/bulk-status`가 architecture §5.2의 API 표에 **없었다.** 요청 계약(`{ date, to }`)·적용 대상·`OPEN-02` 표시와 함께 표에 추가하고, 엔드포인트는 T09·진입 화면은 T17이라는 소유 구분을 명시했다 |
| R2-03 | addressed_by_claude / pending_codex_verification | 원본 `daily-schedule.jpg`를 다시 관찰해 MR-22를 **`9건` → `8건`**으로 정정하고 시점 2 + 범위 8 = 10건을 명시. 8건의 시각 목록을 MR-22에 나열. architecture §0.2 F11에도 같은 수를 기록해 UR-24.5·부록 C.1·T04와 값이 하나가 되게 함 |
| R2-04 | addressed_by_claude / pending_codex_verification | T04에 `afterBlocksHook`·`afterAssignmentsHook` 두 seam을 트랜잭션 **안**에 추가(요구사항 2의 5·7단계). 요구사항 2-A에 seam별 반증 대상 표, 2-B에 **호출 전 스냅샷과의 deep equal** 판정 계약(fixture 비교 금지)을 신설. 신규 테스트 18b(빈 DB)·18c(사용자 데이터 + force)·18d(과제 생성 이후), 신규 mutation 29b·29c(생성 단계를 트랜잭션 밖으로 옮기면 실패), 완료 조건에 롤백 테스트 4개 이름 명시. `main()`은 `{ force }`만 넘긴다는 규칙과 금지 사항 추가 |
| R2-05 | addressed_by_claude / pending_codex_verification | architecture 부록 C.3의 기준일을 **`2026-08-01`로 고정**하고 "오늘" 표현을 제거. 지난 날짜 7/29·7/30·7/31과 날짜별 시드 과제 수(2+2+2=6)를 표로 계산해 **밀린 6건**의 근거를 명시. 밀림 정의(§3.4)와 파생 `OVERDUE`(D7·UR-18)를 함께 참조하고, 기준일이 7/31이면 4건이 된다는 대응 관계도 남김 |

### Revision 4 — Claude 수정 (baseline `9acc7b2`, 미커밋)

**모든 항목의 상태는 `addressed_by_claude` / `pending_codex_verification`이다. RESOLVED · PASS · CLOSED 판정은 Codex Round 4 독립 재검토에서만 나온다.** Round 3의 Codex 판정과 심각도 집계는 위 절에 그대로 남아 있다.

| Finding | Round 3 Codex verdict (불변) | 상태 | 무엇을 고쳤는가 |
|---|---|---|---|
| DR-12 | PARTIALLY RESOLVED (P2, T03) | addressed_by_claude / pending_codex_verification | T03에 정상 케이스 **16-a2 `cleanup이 -journal sentinel 파일을 직접 지운다`** 신설. 요구사항 **16-A**가 절차를 고정한다 — `createTestDb()` → `cleanup()`으로 **열린 연결을 없앤 뒤** 테스트가 `<db>`·`-wal`·`-shm`·`-journal` 네 파일을 직접 만들고 `-journal`에 고유 `JOURNAL_SENTINEL`을 쓴다. 전제 확인 후 `cleanup()` 재호출, 네 경로 부재 단정. 기대 경로는 구현의 `dbFilePaths()`가 아니라 **테스트 파일의 `EXPECTED_DB_ARTIFACTS` 리터럴**이라 mutation과 함께 줄어들지 않는다. 정상/mutation 경로 기대 결과를 표로 기록하고, mutation이 바꾸는 정확한 코드 조각(`DB_FILE_SUFFIXES`의 `"-journal"` 한 항목)과 실패해야 할 고유 테스트명을 명시. 신규 mutation **24b-2** 추가. 16b의 `-journal` 단정은 **보조 단정**으로 강등했다(정상 종료한 migration 뒤라 SQLite가 journal을 이미 지웠을 수 있다). 16e에 **`prisma/dev.db-journal`** 을 불변 스냅샷 대상으로 추가. sentinel은 `<root>/.tmp/` 안에서만 만들고 `afterEach`에서 정리한다 |
| RR-01 | PARTIALLY RESOLVED (P3) | addressed_by_claude / pending_codex_verification | 잔여는 R3-02와 동일한 결함이므로 아래 R3-02 행의 수정으로 함께 처리했다 |
| R2-02 | PARTIALLY RESOLVED (P2) | addressed_by_claude / pending_codex_verification | 잔여였던 R3-01(요청·실패 모델 모순)을 아래 R3-01 행대로 정리. 사용자 승인 정책 값(`UR-25.4` 원자적 전부 롤백 · `UR-25.5` 동일 상태 멱등 no-op)은 **변경하지 않았다.** T01~T04 범위를 늘리지 않았고 새 태스크 번호를 만들지 않았다 (T09 · T17 유지) |
| R2-04 | PARTIALLY RESOLVED (P2, T04) | addressed_by_claude / pending_codex_verification | T04 요구사항 **2-B를 전체 DB 스냅샷으로 교체** — `SELECT *`로 Book · ScheduleBlock · Assignment의 **전체 행 · 전체 컬럼**(`id`·`createdAt`·`updatedAt`·`completedAt`·`bookId` 포함)을 `ORDER BY "id"`로 안정 정렬해 캡처하고, `sqlite_sequence`가 존재하면 함께 캡처한다(`_prisma_migrations`는 제외). `normalizeRow`는 null · timestamp · BigInt · Buffer의 **표현만** 정규화하고 값을 버리지 않는다. 실패 후 스냅샷은 **새 `PrismaClient`(독립 연결)** 로 읽는다. 판정은 오직 `expect(after).toEqual(before)`이며 잠금 · 파일 존재 · 예외 발생만으로 통과시키지 않는다. mutation을 **SQLite writer lock에 의존하지 않는 형태로 교체** — 29b(Book upsert) · 29c(블록) · 29d(과제)는 해당 단계를 `$transaction` **시작 전**으로 끌어올려 단일 연결로 커밋시키고, 29e는 트랜잭션 래퍼 자체를 제거한다. 두 번째 writer 연결 · `SQLITE_BUSY` · 존재하지 않는 ID를 쓰지 않는다는 금지를 명시. seam 3종의 타입 · 기본값(`undefined`) · 호출 위치 · 주입 주체와 **운영 경로 비노출**(`main()`은 `{ force }`만 전달)을 표로 고정 |
| R3-01 | NEW (P2) | addressed_by_claude / pending_codex_verification | architecture §5.2의 `bulk-status` 계약을 요청 모델과 무모순하게 재작성. 요청은 `{ date, to }`만이고 대상은 **트랜잭션 시작 시점의 그 날짜 과제 전체**. 실패를 **요청 수준 / 항목 수준**으로 분류 — 검증 실패 **400**(`BULK_STATUS_INVALID_REQUEST`, `applied:false`, write 0건, 항목 ID 생성 없음), 금지된 전이 **409**(실재 대상의 id · 현재 상태 · 요청 상태 · 사유, 전부 롤백), 내부 실패 **500**(`BULK_STATUS_INTERNAL_ERROR`, 예외 세부정보 비노출, 가짜 항목 ID 없음), **빈 날짜는 200 성공 빈 batch**(`changed:0` · `unchanged:0` · `items:[]`). 항목별 **`NOT_FOUND` 제거**(요청에 ID가 없어 발생 불가)와 **권한 오류 제거**(MVP에 인증 없음 — 후속 401/403 · write 0건은 고려사항으로만 기록). 부록 C.3의 최소 테스트를 **9건**으로 확장(빈 날짜 · 400 · 409 · 500 · seam 기반 결정적 rollback)하고 2번(응답 계약)과 9번(쓰기 원자성)의 역할을 분리해 중복·충돌을 정리. rollback 테스트는 **첫 update 이후** test-only seam이 던지고 전후 전체 스냅샷 deep equal로 판정하며 **writer lock · 존재하지 않는 ID · 처리 순서 결합을 쓰지 않는다.** 같은 사상을 `decisions.md` D22와 `requirements.md` §7.1에 기록. **정책 값 · T01~T04 범위 · 태스크 번호는 그대로다** |
| R3-02 | NEW (P3) | addressed_by_claude / pending_codex_verification | `requirements.md` 원문 출처에 **`OPEN-02` 사용자 결정** 추가 — 이제 2026-08-01 사용자 요구사항 · AP-01~AP-12 결정 · OPEN-01 결정 · OPEN-02 결정 · mockup 2건 전부가 들어간다. 상단 상태 문장에도 `OPEN-02`를 반영하고, 출처 유형(mockup 관찰 / 사용자 요구 / 사용자 결정 / 설계 결정)을 섞지 않는다는 규칙을 명시. §8.1-b의 stale **`31개` → `33개`** 정정과 함께 **생성 경위**를 §8.1-b · §8.3 · 이 STATUS에서 같은 표현으로 통일 — "AP 결정 + OPEN-01로 31건, OPEN-02로 `UR-25.4`·`UR-25.5` 2건이 추가되어 총 33건". **MR-30 역추적 추가** — §8.1-b의 부록 C 시드 · T04 행을 `MR-01~MR-30`으로 넓히고 반영 위치를 T04 정상 케이스 7(모든 과제 `status = PLANNED`)로 명시, §8.2 D7 행에 MR-30 추가, §8.3의 "mockup 관찰 미반영 0건" 행에 근거를 기재 |

**재계산한 ID 집계 (실제 ID 집합에서 다시 셌다).** base UR **26** · 조건 **33** · OR **3** · MR **23** · NR **9** · OPEN **0**. 조건 33건의 내역은 UR-14 1 · UR-15 4 · UR-16 4 · UR-19 1 · UR-20 2 · UR-22 3 · UR-23 1 · UR-24 6 · UR-25 5 · UR-26 6이며, 본문 ID 집합과 §8.1-b 추적표 ID 집합이 정확히 일치하고 중복은 없다. 정방향(requirements → architecture/decisions/specs) 누락 0건, 역방향(architecture/decisions/specs → requirements) 누락 0건. **이 수치는 Claude의 재계산 결과이며 판정이 아니다.**

**Round 4 재검토 전 수동 정합성 수정 — T04 개발 DB 보호 범위 (Finding 아님).**

Round 4 사전 검증에서 **T03과 T04의 개발 DB 보호 대상 집합이 어긋나 있는 것**이 발견되어 T04만 T03에 맞췄다. T03 정상 케이스 16e는 `prisma/dev.db`·`-wal`·`-shm`·`-journal` **4파일**을 불변 검사 대상으로 삼는데, T04 완료 검증 스크립트의 `DEV_DB_FILES`에는 앞의 3개만 있었고 임시 검증 DB cleanup에도 `-journal`이 빠져 있었다. 같은 개발 DB를 두 태스크가 다른 범위로 보호하면 한쪽이 놓치는 파일이 생긴다.

| 위치 | 수정 |
|---|---|
| T04 2-1 보호 대상 표 | `prisma/dev.db-journal` 행 추가. "세 파일" → **"네 파일"**. T03 16e와 같은 집합임을 명시 |
| T04 2-2 스크립트 `DEV_DB_FILES` | `("prisma/dev.db" "prisma/dev.db-wal" "prisma/dev.db-shm" "prisma/dev.db-journal")` |
| T04 2-2 `finish()` cleanup | 임시 검증 DB 정리 대상에 `"$VERIFY_DB-journal"` 추가 |
| T04 2-3 실행 순서·기대 표 | BEFORE 스냅샷 "3파일" → **"4파일"**, cleanup 대상에 `-journal` 추가, 기대 표를 "개발 DB 4파일" 전후 동일로 통일 |
| T04 요구사항 추적·금지 사항·스펙 미정 18 | 개발 DB 불변 검사 범위를 4파일로 통일하고 T03 16e와 같은 집합임을 명시 |

**개발 DB 파일을 실제로 만들거나 지우거나 고치지 않는다.** `prisma/dev.db-journal`이 존재하면 sha256을 기록해 전후를 비교하고, 존재하지 않으면 `absent` 상태가 전후 동일한지만 확인한다.

이 수정은 **문서 간 정합성 보정이며 새 Finding도 판정 변경도 아니다.** Codex Round 3 판정과 심각도 집계, `overall_verdict: BLOCK`, T01 PASS / T02 PASS / T03 BLOCK / T04 BLOCK, `implementation_allowed: false`, 모든 Finding의 `addressed_by_claude` / `pending_codex_verification` 상태, `next_owner: codex`는 **전부 그대로다.**

**이번 revision이 수정한 파일:** `docs/requirements.md`, `docs/architecture.md`, `docs/decisions.md`, `docs/specs/T03-prisma-schema.md`, `docs/specs/T04-seed.md`, `docs/workflow/STATUS.md`. **`docs/specs/T01-scaffold.md`와 `docs/specs/T02-test-harness.md`는 T01 · T02가 PASS이므로 변경하지 않았다.** `docs/reviews/**`, 운영 코드, 테스트, 패키지, CI, Prisma, DB 파일도 변경하지 않았다.

### Round 2 제출 당시 Claude revisions — historical pending state

| Finding | Codex round 1 verdict | Claude round 2 state | What changed |
|---|---|---|---|
| DR-03 | PARTIALLY RESOLVED (P1) | `addressed_by_claude` / `pending_codex_verification` | Node policy is the set `{22, 24, 26}`, not a lower bound. `engines.node = "22 \|\| 24 \|\| 26"`, `SUPPORTED_NODE_MAJORS = [22, 24, 26]`, membership replaces `>= 22`. Playwright range re-verified 2026-08-01. D21, T01, T02 aligned |
| DR-07 | PARTIALLY RESOLVED (P1) | `addressed_by_claude` / `pending_codex_verification` | Identical 7-row enforcement table in `architecture.md` §1.5, `decisions.md` D13, T03 requirement 3. D13's "DB가 값을 전혀 강제하지 못한다" ground removed. Prisma SQLite behaviour re-verified 2026-08-01 |
| DR-11 | PARTIALLY RESOLVED (P1) | `addressed_by_claude` / `pending_codex_verification` | T04 completion check snapshots presence+sha256 of `prisma/dev.db`, `-wal`, `-shm`; one EXIT trap covers success and failure paths; original exit code preserved; exit-code priority defined; `SEED_FORCE` unset |
| DR-12 | PARTIALLY RESOLVED (P2) | `addressed_by_claude` / `pending_codex_verification` | T03 13-A fixes the child command to `npm run db:deploy` at repo root and cleans all four temp artifacts on any template-generation failure; 13-B defines best-effort cleanup and error precedence; two named tests plus a `forceTemplateRebuild` seam |
| RR-01 | NEW (P1) | `addressed_by_claude` / `pending_codex_verification` | `docs/requirements.md` written from the user's authoritative statements plus direct observation of both mockups. IDs assigned; AP-01…AP-12 resolved by user decision on 2026-08-01; bidirectional traceability run |
| RR-02 | NEW (P1) | `addressed_by_claude` / `pending_codex_verification` | T01 requirements 17–18 restore the full ESLint 9 flat config (FlatCompat, `next/core-web-vitals`, `next/typescript`, `no-explicit-any: error`, three ignores) plus mutation cases 14–15 |
| RR-03 | NEW (P2) | `addressed_by_claude` / `pending_codex_verification` | T04 requirement 20 adds an exact-match test for the `db:setup` string; completion check runs `npm run db:setup` itself against a fresh temp DB; mutation cases 31–32 |

## OPEN-02 — decided 2026-08-01 (user approval)

**`bulk-status`의 일부 실패 처리 정책이 확정되어 `OPEN-02`가 종결됐다.** 이로써 `open_implementation_details`는 **0**이다.

| 결정 항목 | 승인된 값 | 승격된 요구 ID |
|---|---|---|
| **OPEN-02.1** 실패 원자성 | **전부 성공하거나 전부 롤백.** 실제 실패 항목이 1건이라도 있으면 요청 전체를 롤백한다. 부분 성공 없음. 쓰기는 단일 트랜잭션. 실제 실패 = 존재하지 않는 과제 · 허용되지 않는 상태 전이 · 권한 오류 · 검증 오류 | **UR-25.4** |
| **OPEN-02.2** 동일 상태 재적용 | **성공하는 멱등 no-op.** 데이터를 바꾸지 않고 성공으로 집계하며 실패로 세지 않는다. 이미 `DONE`인 과제에 `DONE`을 보내도 전체 롤백이 일어나지 않는다. 재시도해도 결과가 같다 | **UR-25.5** |

반영 위치:

- `requirements.md` — §0 분류표(OPEN 0건), §1.3의 `UR-25.4`·`UR-25.5`, §7 표와 §7.1(결정 기록), §8.1의 UR-25 행, §8.1-b의 UR-25.2~25.5 행, §8.2의 D22 행, §8.3 집계
- `decisions.md` — **D22** 신설(선택 / 기각한 대안 2건 / 이유 / 남는 대가), 색인과 요구사항 추적 표에 등록
- `architecture.md` — §2 결정 색인, §5.2의 `bulk-status` 행과 **요청·응답 최소 계약**, §7.2 통합 테스트 행, 부록 C.3의 정책 표와 **최소 테스트 조건 5건**, 부록 A.2(T17)·A.3(T09), 사용자 확정 사항 표, "미해결 질문"
- T01~T04 SPEC — **변경 없음.** `bulk-status`는 배치 1의 범위가 아니다 (엔드포인트 T09 · 화면 T17, 둘 다 예약 번호)

**이 결정은 Finding 판정과 무관하다.** DR-12·RR-01·RR-02·R2-01~R2-05는 여전히 `addressed_by_claude` / `pending_codex_verification`이며, RESOLVED 판정은 Codex 독립 재검토에서만 나온다.

## User decisions of 2026-08-01 — AP-01 … AP-12

All twelve are resolved. **No unapproved design assumption remains.**

| AP | Decision | Promoted to |
|---|---|---|
| AP-01 | approved | UR-14, UR-14.1, NR-07, NR-09 |
| AP-02 | approved with conditions | UR-15, UR-15.1 … UR-15.4 |
| AP-03 | **rejected and corrected** | UR-16, UR-16.1 … UR-16.4, NR-03 |
| AP-04 | approved | UR-17 |
| AP-05 | approved | UR-18 |
| AP-06 | approved with conditions | UR-19, UR-19.1, NR-04 |
| AP-07 | approved with conditions | UR-20, UR-20.1, UR-20.2, NR-05 |
| AP-08 | approved | UR-21, NR-06 |
| AP-09 | approved with conditions | UR-22, UR-22.1 … UR-22.3 |
| AP-10 | approved | UR-23, UR-23.1 |
| AP-11 | approved with conditions | UR-24, UR-24.1 … UR-24.6 |
| AP-12 | approved | UR-25, UR-25.1 … UR-25.3 |
| — | OPEN-01 decided | UR-26, UR-26.1 … UR-26.6 |
| — | **OPEN-02 decided** | **UR-25.4, UR-25.5** (설계 결정 **D22**) |

**조건 총계는 33건이다** (base UR 26건). AP 결정 + `OPEN-01`로 31건이었고, `OPEN-02` 결정으로 `UR-25.4`·`UR-25.5` 2건이 추가됐다. 전체 목록과 반영 위치는 `docs/requirements.md` §8.1-b에 있다 — 이전의 "22건" 표기는 실제 ID 집합과 달라 정정했다 (R2-02).

### AP-03 rejection — data model change

`ScheduleBlock` gains `date String`. Propagated to: `architecture.md` §0.2, §0.3, §1.1, §1.2, §1.3, §1.5 (I9 scoped per date, I13 added), §5.4, §6.2-2, appendix C.1; `decisions.md` D1, D11, D15; `T03-prisma-schema.md` (column table now 9 columns, index becomes `ScheduleBlock_date_startMinute_idx`, business rules, mutation case 20b); `T04-seed.md` (10 blocks carry a date, fixture interface, sort key, tests 10/10b/28b).

**No new task numbers were created** (UR-16.4). Deferred scope was added to `architecture.md` appendix A.3 without IDs.

## OPEN-01 — decided 2026-08-01

**Which date the 10 seeded schedule blocks belong to: `2026-07-29`.** Promoted to `UR-26` with conditions `UR-26.1`…`UR-26.6`. 별개의 미결이던 `OPEN-02`(UR-25.3의 실패 정책)도 같은 날 결정되어 위 "OPEN-02 — decided" 절에 있다. **두 OPEN 모두 닫혔다.**

- The date is **user-designated**, not read from `daily-schedule.jpg` (which has no date, MR-20). Documents must not claim it was read from the image — same property as the year `2026` under UR-15.3.
- **The other 19 days having no schedule is intended behaviour** (UR-26.2, UR-26.4), not a defect, and must not be reported as a failure. Schedule templates are outside the MVP (UR-26.3, NR-03); users enter each day's schedule (UR-26.5).
- `2026-07-29` is a pilot seed value, **not a product-wide hardcoded constant** (UR-26.6).
- Reflected in: `requirements.md` §1.2/§1.3/§7/§8, `architecture.md` appendix C.1 and 미해결 질문, `decisions.md` D11 seed table, T03 traceability, T04 requirement 9-A / fixture / tests 10b.

## Gate

`implementation_allowed` is `false`. Codex Round 4에서 R2-04의 구현 차단 P2가 남았으므로 구현을 시작할 수 없다. 이번 검토 작업에는 구현, package install, DB operation, branch change, commit, push, PR, merge, deployment가 포함되지 않았다.

Codex Round 4 독립 재검토가 끝났다. **다음 담당자는 Claude**이며, 다음 작업은 R2-04의 mutation 29c·29d를 결정적으로 고치고 비차단 문구 결함 R4-01·R4-02도 수정하는 것이다. 그 뒤 **Codex가 다시 독립 재검토**하며, 구현은 그 판정 전까지 시작하지 않는다. Claude revision 3·4의 자기 보고와 Codex Round 2·3 기록은 과거 이력으로 보존했다.

이번 세션에서 구현은 시작하지 않았고 커밋 · 푸시 · PR · merge · 패키지 설치 · migration · seed · DB 실행도 하지 않았다.
