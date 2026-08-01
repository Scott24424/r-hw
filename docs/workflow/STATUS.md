# Workflow Status

- current_branch: docs/specs-batch1
- stage: spec-rereview-complete
- doc_status: changes-required
- active_tasks: T01, T02, T03, T04
- spec_writer: claude
- spec_reviewer: codex
- review_round: 2
- review_target_commit: 2557d75bd5e56b371dd81980985206bc75df4a31
- review_file: docs/reviews/DR-T01-T04-spec-rereview-round2.md
- previous_review_file: docs/reviews/DR-T01-T04-spec-rereview-round1.md
- original_review_file: docs/reviews/DR-T01-T04-spec-review.md
- original_review_commit: b4511c7
- rereview_base_commit: c77ab5c33122da5fd3414e1ed054fe22224506fc
- revision_round: 2
- revision_baseline_commit: 944fe85
- overall_verdict: BLOCK
- T01_verdict: BLOCK
- T02_verdict: PASS
- T03_verdict: BLOCK
- T04_verdict: BLOCK
- implementation_allowed: false
- requirements_file: docs/requirements.md
- requirements_source: user statements of 2026-08-01 (requirements + AP-01..AP-12 decisions + OPEN-01 decision) + both mockups
- unapproved_design_assumptions: 0
- open_implementation_details: 1
- next_action: Claude fixes Round 2 residual and new findings; then Codex independently rereviews
- next_owner: claude

## Verdict ownership

**Only Codex changes finding verdicts.** Claude is the spec author and does not mark its own work `RESOLVED` or `PASS`. Claude가 제출한 `addressed_by_claude` / `pending_codex_verification` 이력은 아래에 보존하고, 현재 `overall_verdict`와 태스크별 판정은 Codex의 Round 2 결과다.

`doc_status`는 Round 2에서 잔여·신규 결함이 확인됐으므로 `changes-required`다. `implementation_allowed`는 계속 `false`다.

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

### Round 2 — Codex verdict at target `2557d75`

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

| Finding | Codex Round 2 verdict | Remaining issue |
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

### AP-03 rejection — data model change

`ScheduleBlock` gains `date String`. Propagated to: `architecture.md` §0.2, §0.3, §1.1, §1.2, §1.3, §1.5 (I9 scoped per date, I13 added), §5.4, §6.2-2, appendix C.1; `decisions.md` D1, D11, D15; `T03-prisma-schema.md` (column table now 9 columns, index becomes `ScheduleBlock_date_startMinute_idx`, business rules, mutation case 20b); `T04-seed.md` (10 blocks carry a date, fixture interface, sort key, tests 10/10b/28b).

**No new task numbers were created** (UR-16.4). Deferred scope was added to `architecture.md` appendix A.3 without IDs.

## OPEN-01 — decided 2026-08-01

**Which date the 10 seeded schedule blocks belong to: `2026-07-29`.** Promoted to `UR-26` with conditions `UR-26.1`…`UR-26.6`. **OPEN-01 자체는 해결됐다.** 다만 Codex Round 2는 별개의 UR-25.3 실패 정책을 미결 구현 상세 1건으로 판정했다(R2-02).

- The date is **user-designated**, not read from `daily-schedule.jpg` (which has no date, MR-20). Documents must not claim it was read from the image — same property as the year `2026` under UR-15.3.
- **The other 19 days having no schedule is intended behaviour** (UR-26.2, UR-26.4), not a defect, and must not be reported as a failure. Schedule templates are outside the MVP (UR-26.3, NR-03); users enter each day's schedule (UR-26.5).
- `2026-07-29` is a pilot seed value, **not a product-wide hardcoded constant** (UR-26.6).
- Reflected in: `requirements.md` §1.2/§1.3/§7/§8, `architecture.md` appendix C.1 and 미해결 질문, `decisions.md` D11 seed table, T03 traceability, T04 requirement 9-A / fixture / tests 10b.

## Gate

`implementation_allowed` is `false`. No implementation, package install, DB operation, branch change, commit, push, PR, merge, or deployment is authorized by this status.

Round 2 재검토는 완료됐다. **다음 담당자는 Claude**이며, Round 2 리뷰의 잔여 Finding 3건과 신규 Finding 5건을 문서에서 수정한 뒤 Codex 독립 재검토를 다시 요청한다.
