# Workflow Status

- current_branch: docs/specs-batch1
- stage: spec-revision
- doc_status: ready-for-rereview
- active_tasks: T01, T02, T03, T04
- spec_writer: claude
- spec_reviewer: codex
- review_file: docs/reviews/DR-T01-T04-spec-review.md
- review_commit: b4511c7
- revision_round: 1
- next_action: Codex re-review T01-T04 revised specs
- implementation_allowed: false

## Verdict (Codex, b4511c7 — 변경하지 않음)

- overall_verdict: BLOCK
- T01_verdict: PASS WITH CHANGES
- T02_verdict: BLOCK
- T03_verdict: BLOCK
- T04_verdict: BLOCK

위 판정은 Codex의 것이며 Claude가 갱신하지 않는다. 재검증 결과로만 바뀐다.

## Finding 처리 현황

전체 14건 (P0 0 / P1 7 / P2 4 / P3 3). Claude 판단으로 **14건 전부 Accepted**, Rejected 0건.

| ID | 심각도 | 대상 | 판정 | 처리 |
|---|---|---|---|---|
| DR-01 | P2 | T01 | Accepted | `typecheck`를 `next typegen && tsc --noEmit`으로 변경. 깨끗한 checkout과 build 이후 두 환경에서 같은 명령·같은 결과를 완료 조건에 넣음. `next` 하한을 `^15.5.0`으로 올림 |
| DR-02 | P3 | T01 · T02 | Accepted | `<h1>`에 `text-[42px]` 고정. T01은 빌드 산출 CSS의 `42px` 문자열, T02는 Playwright computed style로 검증. 검증 책임을 두 태스크로 분담 |
| DR-03 | P1 | T02 | Accepted | **D21 신설.** Node 22로 통일, `.nvmrc`를 정의처로 두고 CI는 `node-version-file`로 읽음. Playwright 범위·lockfile·설치 버전 보고 규칙 명시 |
| DR-04 | P2 | T02 | Accepted | T02의 검증 범위를 "실행 환경 전제"로 한정. `이 태스크가 검증하지 않는 것` 절을 추가해 D8 도메인 검증을 T05로 이관하고 architecture §7.1에 2프로세스 요구를 기록 |
| DR-05 | P1 | T03 | Accepted | 선행 태스크를 `T02`로 수정. 전이 포함·병렬 금지·Merge 후 브랜치 생성을 `구현 순서상의 위치` 절로 명시 |
| DR-06 | P1 | T03 | Accepted | `DATABASE_URL` 기본값을 갖는 스크립트를 6개로 확정(`db:generate`/`db:validate`/`db:migrate`/`db:deploy`/`db:diff`/`db:wal`). "4개 이상"을 제거하고 이름 집합 exact match로 교체. CI도 npm script 사용. `env -u DATABASE_URL` 완료 조건 추가 |
| DR-07 | P2 | T03 | Accepted | `tests/integration/db-foundation.test.ts` 신설. `sqlite_master`·`table_info`·`index_list`·`index_info`·`foreign_key_list`로 컬럼 순서·nullable·기본값·인덱스·FK를 exact match. mutation 확인 절차 2종 추가 |
| DR-08 | P1 | T04 | Accepted | 선행은 `T03` 유지, 전이 포함(T01·T02·T03)과 전제 제공 태스크를 표로 명시 |
| DR-09 | P1 | T04 | Accepted | `tests/fixtures/seed-expected.ts` 신설. Book 9 / Block 10 / Assignment 27을 정렬 후 deep equality. seed와 fixture의 상호 import 금지. seed 구현을 변조하는 mutation 확인 3종 |
| DR-10 | P1 | T04 | Accepted | 전체를 단일 `$transaction`으로. Book은 `update: {}`, `force`는 Book 미변경. 사용자 데이터 보존 3건 + `beforeCreateHook`으로 롤백 검증 1건 추가 |
| DR-11 | P1 | T04 | Accepted | 완료 검증을 `.tmp/`의 새 절대 DB URL에서만 수행. `trap` 정리 + 개발 DB checksum 전후 비교. 개발 DB 삭제·`SEED_FORCE` 금지 명문화 |
| DR-12 | P2 | T03 | Accepted | 테스트 DB 헬퍼를 T03으로 이동. 내부 `try/catch` 정리, cleanup registry, 마이그레이션 지문 기반 템플릿 원자적 재생성, `{ ...process.env, DATABASE_URL }` 명시 |
| DR-13 | P3 | T04 | Accepted | 비즈니스 규칙 표의 테스트 참조를 번호에서 **고유 테스트명**으로 전면 교체 |
| DR-14 | P3 | 공통 | Accepted | architecture 서두의 "설계 결정 18건"에서 개수를 제거하고 §2 표를 유일한 색인으로 지정 |

- total_findings: 14
- accepted: 14
- partially_accepted: 0
- rejected: 0
- remaining_P0: 0
- remaining_P1: addressed_by_claude=7, confirmed_resolved=unverified
- remaining_P2: addressed_by_claude=4, confirmed_resolved=unverified
- remaining_P3: addressed_by_claude=3, confirmed_resolved=unverified

**`remaining_P1`을 0으로 확정하지 않는다.** Claude는 스펙 작성자이므로 자신의 수정이 Finding을 해소했는지 판정할 수 없다. Codex 재검증만이 이 값을 0으로 만들 수 있다.

## 부수 변경 (Finding 대응 중 파생)

- 완료 조건에서 **누적 테스트 개수 합산(`N passed`)을 제거**하고, `--reporter=verbose` 출력에 명명된 테스트 이름이 나타나는지로 판정하도록 전 태스크 통일. 개수 합산은 후속 태스크가 테스트를 추가할 때마다 어긋나며 그 어긋남은 실제 결함이 아니다 (DR-13과 같은 부류의 문제)
- T03의 파일 수가 13개로 "태스크당 10개 이내" 목표를 초과. 구조 검증(DR-07)과 테스트 DB 헬퍼(DR-12)를 T03에 두어 **자기 검증 가능성**을 파일 수보다 우선한 결과이며, 각 스펙에 사유를 명시
- T01의 파일 수가 11개(`.nvmrc` 추가, D21)
- `package.json`에 `"prisma": { "seed": ... }` 설정을 추가하지 않기로 결정. `prisma db seed` 경로는 D19의 기본값 주입을 거치지 않는다

## 추가 수정 — 수동 정합성 검사 (Codex 재검토 전)

Codex 재검증에 넘기기 전 수동 정합성 검사에서 `docs/architecture.md` 부록 A의 태스크 번호 충돌이 발견되어 함께 수정했다. Codex 리뷰(b4511c7)의 Finding에는 없던 항목이다.

- 부록 A가 "실제 착수 기준은 `docs/specs`"라고 선언하면서도 표 안에서 `T01`~`T04`를 현재 스펙과 다른 작업에 재사용하고 있었다
- 부록 A의 `T05`(Zod)가 T02 스펙이 D8 검증을 이관한 `T05`(도메인 기반)와 직접 충돌했다. 같은 종류의 충돌이 `T07`·`T09`·`T12`·`T14`·`T17`·`T19`에도 있었다
- 앞부분("14개 → 19개")과 뒷부분("초안의 12개에서 14개로")의 개수 설명이 서로 모순이었고, 표에는 `T01`~`T14`만 있었다
- "이 표는 T19에서 갱신한다"로 현재 정합성 수정을 존재하지 않는 태스크에 미루고 있었다

조치: 부록 A를 A.1(배치 1 확정 4건) / A.2(배치 1 스펙이 이미 예약한 번호) / A.3(후속 범위, ID 미정)으로 재작성. 개수 문장과 T19 연기 문구를 제거했다. **`T05` 이상에 새 번호를 배정하지 않았다** — A.2는 배치 1 스펙 본문이 이미 참조하는 번호를 기록한 것이고, 그 외는 "미정"이다.

- appendix_a_conflict: resolved
- appendix_a_fix_scope: docs/architecture.md 부록 A only
- T01~T04 스펙 파일: **변경하지 않음**

### 후속 — decisions.md의 오래된 태스크 참조 (같은 수동 검사에서 발견)

부록 A를 정리하면서 `docs/decisions.md`에도 같은 종류의 오래된 참조 2건이 남아 있음을 확인해 수정했다. 역시 Codex 리뷰(b4511c7)의 Finding에는 없던 항목이다.

- **D13** — "전제 조건 (T01/T02에서 확인할 것)"이 Prisma 버전 확인을 T01/T02에 묶어 지정했으나, **T01 스펙은 Prisma 의존성 추가를 명시적으로 금지**하고 스키마 기반은 T03의 범위다. 담당을 **T03**으로 고치고, 확인 방법을 T03 스펙의 실제 완료 조건(`npx prisma --version`, `env -u DATABASE_URL npm run db:validate`)과 일치시켰다. 본문의 `prisma validate`도 D19에 맞춰 `npm run db:validate`로 바로잡았다
- **D16-e** — 제목의 "(Codex: T01/T02에서 반영할 것)" 묶음 참조를 제거하고 하위 세 항목의 담당을 개별 명시했다: `next build`+`next start` → **T01**, WAL → **T03**, `setInterval` 정리 → **후속 갱신 계층 스펙(ID 미정)**
- 새 태스크 번호를 만들지 않았다. 부록 A의 확정·예약·ID 미정 정책을 따르며, 그 정책을 D16-e 말미에 명시적으로 참조했다

- decisions_stale_task_refs: resolved
- decisions_fix_scope: D13 전제 조건 문단, D16-e (e) 절
- 새로 배정한 태스크 번호: 없음

## 구현 순서 (고정)

```
T01 → T02 → T03 → T04
```

- 병렬 구현·병렬 PR 금지. 네 태스크가 `package.json`, `package-lock.json`, `.gitignore`, `.github/workflows/ci.yml`을 공유한다
- 각 태스크의 브랜치는 직전 태스크가 `main`에 Merge된 뒤에 생성
- T03은 T02를, T04는 T03을 선행으로 선언하며 전이 의존을 각 스펙에 명시

## 문서 상태

- Codex 재검증 전까지 `approved`로 표시하지 않는다
- 구현 가능하다고 선언하지 않는다
- `implementation_allowed: false` 유지

## 이번 라운드에서 변경한 파일

- docs/specs/T01-scaffold.md
- docs/specs/T02-test-harness.md
- docs/specs/T03-prisma-schema.md
- docs/specs/T04-seed.md
- docs/architecture.md
- docs/decisions.md (D21 신설)
- docs/workflow/STATUS.md

## 변경하지 않은 파일

- docs/reviews/DR-T01-T04-spec-review.md (리뷰 원본 보존)
- AGENTS.md, CLAUDE.md, README.md
- .github/workflows/ci.yml, .gitignore
- package.json, package-lock.json
- prisma/**, src/**, 운영 코드·테스트 코드 전체
