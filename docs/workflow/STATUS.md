# Workflow Status

- current_branch: docs/specs-batch1
- stage: spec-rereview-complete
- doc_status: changes-required
- active_tasks: T01, T02, T03, T04
- spec_writer: claude
- spec_reviewer: codex
- review_round: 3
- review_target_commit: 4ff75fa5a838482ac7223fc82499bffcdc0cbcdf
- review_file: docs/reviews/DR-T01-T04-spec-rereview-round3.md
- previous_review_file: docs/reviews/DR-T01-T04-spec-rereview-round2.md
- original_review_file: docs/reviews/DR-T01-T04-spec-review.md
- original_review_commit: b4511c7
- rereview_base_commit: c77ab5c33122da5fd3414e1ed054fe22224506fc
- revision_round: 3
- revision_baseline_commit: 8b8c0512af62cb00902ca50901159590a5b4ebb9
- overall_verdict: BLOCK
- T01_verdict: PASS
- T02_verdict: PASS
- T03_verdict: BLOCK
- T04_verdict: BLOCK
- implementation_allowed: false
- requirements_file: docs/requirements.md
- requirements_source: user statements of 2026-08-01 (requirements + AP-01..AP-12 decisions + OPEN-01 decision + OPEN-02 decision) + both mockups
- unapproved_design_assumptions: 0
- open_implementation_details: 1
- open_implementation_detail_ids: R3-01 — `{ date, to }` bulk-status의 NOT_FOUND·빈 날짜·validation/HTTP·결정적 rollback test 계약
- next_action: Claude fixes Round 3 residual/new findings; then Codex independently performs Round 4 rereview
- next_owner: claude

## Verdict ownership

**Only Codex changes finding verdicts.** Claude is the spec author and does not mark its own work `RESOLVED` or `PASS`. 아래 revision 3의 `addressed_by_claude` / `pending_codex_verification` 이력은 그대로 보존한다. **현재 `overall_verdict`와 태스크별 판정은 Codex Round 3의 결과다.**

Round 2와 Claude revision 3의 집계는 과거 이력이다. 현재 잔여 심각도는 아래 **Round 3 — Codex verdict** 절이 정의한다.

`doc_status`는 Round 3에서 구현 차단 P2가 남아 `changes-required`다. `OPEN-02`의 두 사용자 정책 값은 결정됐지만 날짜 기반 API로 옮기는 계약은 R3-01 때문에 미결 1건이다. `implementation_allowed`는 계속 `false`다.

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

**조건 총계는 33건이다** (base UR 26건). AP 결정으로 31건이었고, `OPEN-02` 결정으로 `UR-25.4`·`UR-25.5` 2건이 추가됐다. 전체 목록과 반영 위치는 `docs/requirements.md` §8.1-b에 있다 — 이전의 "22건" 표기는 실제 ID 집합과 달라 정정했다 (R2-02).

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

`implementation_allowed` is `false`. No implementation, package install, DB operation, branch change, commit, push, PR, merge, or deployment is authorized by this status.

Codex Round 3 재검토는 완료됐다. **다음 담당자는 Claude**이며 DR-12, RR-01, R2-02, R2-04, R3-01, R3-02를 문서에서 수정한 뒤 Codex에 Round 4 독립 재검토를 요청한다. Claude revision 3의 자기 보고와 Codex Round 2 기록은 과거 이력으로 보존했다.
