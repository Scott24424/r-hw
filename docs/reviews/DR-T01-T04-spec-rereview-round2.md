# T01~T04 SPEC 독립 재검토 — Round 2

## 1. 검토 기준

- 검토자: Codex
- 요구사항·설계·SPEC 작성 및 Round 2 수정자: Claude
- 검토 성격: 구현 전 문서 게이트의 독립 재검토
- 판정 원칙: 문서의 자기 선언이나 `STATUS.md`의 `addressed_by_claude`를 해결 근거로 사용하지 않고, 현재 HEAD의 원문·mockup·공식 1차 자료를 서로 대조한다.
- 범위: `docs/requirements.md`, `docs/architecture.md`, `docs/decisions.md`, T01~T04 SPEC, 기존 리뷰 2건, `STATUS.md`
- 제외: 구현, 패키지 설치, 테스트 실행, DB·migration·seed 실행, 브랜치 변경, commit/push/PR/merge/deploy

## 2. 기준 브랜치와 커밋

- 작업 경로: `/Volumes/SSD_1TB/Projects/r-hw`
  - 셸의 논리 경로는 `/Users/minim4/dev/r-hw`로 표시됐지만 `pwd -P`, `git rev-parse --show-toplevel`, 두 경로의 device/inode를 대조해 같은 작업공간임을 확인했다.
- 브랜치: `docs/specs-batch1`
- 검토 대상 HEAD: `2557d75bd5e56b371dd81980985206bc75df4a31`
- `origin/docs/specs-batch1`: `2557d75bd5e56b371dd81980985206bc75df4a31`
- Round 1 검토 기록 커밋: `944fe85`
- Claude Round 2 수정 커밋: `2557d75`
- 시작 시 작업 트리: 깨끗함
- `AGENTS.md`: `CLAUDE.md`를 가리키는 심볼릭 링크
- 필수 문서: 전부 존재

기준 상태는 요청과 일치했다. 따라서 허용된 두 문서의 작성·갱신을 진행했다.

## 3. 읽은 문서 목록

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
- `docs/workflow/STATUS.md`

원본 자료도 원본 해상도로 직접 확인했다.

- `docs/mockups/plan-20days.jpg`
- `docs/mockups/daily-schedule.jpg`

## 4. 검토 방법

1. 기준 상태와 허용 수정 범위를 먼저 고정했다.
2. 필수 문서 전체를 읽은 뒤 requirements → architecture → decisions → SPEC의 정방향과 역방향을 대조했다.
3. 두 mockup을 직접 보고 9권·10블록·27과제 전사, 판독 불가 항목, 일일 시간표의 날짜 부재를 다시 확인했다.
4. Round 1의 미해결 7건을 현재 줄에서 독립 재판정했다.
5. 각 태스크에서 잘못된 구현이 완료 검증을 통과하는 반례를 구성했다.
6. 기술 전제는 공식 문서와 공식 소스만 확인했다. 패키지 설치나 실행으로 보완하지 않았다.
7. 요구사항 ID는 기계적으로 추출해 중복·개수·추적성 자기 선언을 대조했다.

## 5. 기존 7개 Finding 개별 재판정

### DR-03 — RESOLVED

- 관련 파일: `docs/decisions.md` D21(713~752행), `docs/specs/T01-scaffold.md` 요구사항 2~4(56~103행), `docs/specs/T02-test-harness.md` 요구사항 2·9·15(61~68, 134~165, 239~287행)
- 요구사항 대응: UR-14의 도구 스택과 OR-01~03의 재현성·품질 목표가 `.nvmrc`, engines, CI, lockfile 검증으로 이어진다.
- 판정 근거: `.nvmrc = 22`, `engines.node = "22 || 24 || 26"`, `SUPPORTED_NODE_MAJORS = [22, 24, 26]`, CI `node-version-file`이 같은 정책을 말한다. `>=` 비교는 금지됐고 20·21·23·25·27 거부 mutation이 있다. Playwright 정확 버전은 lockfile로 고정하고 설치 버전·Node 지원 변화 시 중단하도록 했다.
- 공식 대조: Playwright의 현재 공식 지원 문구는 Node 22.x·24.x·26.x다.
- 구현자 추가 판단: 없음.

### DR-07 — RESOLVED

- 관련 파일: `docs/architecture.md` §1.5(297~329행), `docs/decisions.md` D13 보장 수준(439~455행), `docs/specs/T03-prisma-schema.md` 요구사항 3·18~22(107~125, 388~493행)
- 요구사항 대응: UR-14의 Prisma·SQLite 선택, UR-17의 enum 상태, OR-03의 구조 검증이 세 문서에서 같은 보장 수준으로 연결된다.
- 판정 근거: 세 문서 모두 SQLite/migration은 enum 범위를 DB 수준에서 강제하지 않고, SQLite 컬럼은 `TEXT`, invalid raw 값은 Prisma Client 조회 오류가 될 수 있으며, 외부 입력 범위는 T07 Zod가 담당한다고 명시한다. T03은 테이블·컬럼·nullable·기본값·인덱스·FK와 `CHECK` 부재를 실제 임시 DB 메타데이터로 검증한다.
- 공식 대조: Prisma 공식 SQLite 문서의 enum DB 비강제 및 runtime failure 설명, 기능 표의 SQLite enum 6.2.0 도입과 일치한다.
- 구현자 추가 판단: 없음.

### DR-11 — RESOLVED

- 관련 파일: `docs/specs/T04-seed.md` 완료 조건 2-1~2-3(434~576행), 금지 사항(578~584행)
- 요구사항 대응: UR-24.1~24.5의 파일럿·테스트 시드와 기존 사용자 데이터 보존이 새 임시 DB 실행 및 개발 DB 불변 검사로 연결된다.
- 판정 근거: 검증은 `.tmp`의 절대 경로 DB에서 `npm run db:setup` 자체를 실행한다. 개발 DB 본체·WAL·SHM의 존재 여부와 SHA-256을 전후 비교하고, `SEED_FORCE`를 명시적으로 unset하며, EXIT trap이 성공·실패 양쪽에서 cleanup과 불변 검사를 수행한다. 개발 DB를 지우거나 force로 맞추는 경로가 금지됐다.
- 구현자 추가 판단: 없음.

### DR-12 — PARTIALLY RESOLVED

- 관련 파일: `docs/specs/T03-prisma-schema.md` 요구사항 12~15(234~343행), helper 테스트(388~413, 559~570행), 금지 사항(623~630행)
- 요구사항 대응: OR-03의 격리·교차 검증과 D19의 절대 테스트 DB URL이 테스트 DB helper의 캐시·정리 계약으로 이어진다.
- 해결된 부분: 저장소 절대 경로, migration 지문, 고유 임시 이름, `renameSync`, `{ ...process.env, DATABASE_URL }`, `npm run db:deploy`, registry, DB/WAL/SHM cleanup, best-effort 오류 우선순위, `forceTemplateRebuild`가 구체화됐다.
- 남은 문제:
  1. 템플릿은 WAL을 적용하지 않으므로 migration 실패 시 SQLite rollback journal인 `<tmpDb>-journal`이 남을 수 있지만 13-7의 정리 목록(282~285, 301~303행)과 16b 테스트(562행)는 `.db`·`-wal`·`-shm`·meta만 본다.
  2. 템플릿 DB rename 후 meta 쓰기/rename이 실패하는 단계도 “호출 전 최종 템플릿·meta 상태를 보존”한다고 주장하지만, 유일한 실패 seam은 DB rename 전(296행)이다. 16b·16c는 DB rename 이후 실패를 만들지 못해 이 계약을 증명하지 않는다.
  3. `cleanup이 db·wal·shm 세 파일을 모두 지운다`는 테스트 입력(561행)은 cleanup 직전에 WAL/SHM이 실제 존재하도록 마련하라고 하지 않는다. disconnect나 checkpoint로 sidecar가 이미 사라지면 sidecar 삭제를 누락한 구현도 통과할 수 있다.
- 왜 부분 해결인가: 정상·대표 실패 경로는 정해졌지만, 요청된 sidecar 정리와 템플릿 finalize 원자성을 위반하는 구현이 아직 테스트를 통과할 수 있다.
- 구현자 추가 판단: 어떤 실패 지점과 어떤 sidecar를 더 처리할지 판단해야 하므로 남아 있다.

### RR-01 — PARTIALLY RESOLVED

- 관련 파일: `docs/requirements.md` 전체, 특히 §0(19~29행), §1(33~107행), §7(220~232행), §8(236~325행)
- 요구사항 대응: 새 문서는 UR/OR/MR/NR/OPEN을 구분하고 architecture·decisions·T01~T04의 근거 문서 역할을 수행한다.
- 해결된 부분: 파일이 존재하고, 사용자 확정 요구와 mockup 관찰, 제외 범위를 분리했다. UR-01~26, 조건 ID, OR/MR/NR은 중복 없이 식별된다. UR-26과 조건은 설계·T03·T04로 추적된다.
- 남은 문제: 권위 문서의 자기 검사가 실제 원문과 일치하지 않는다. §8.3은 “UR 25 + 조건 22”라고 하지만 실제로는 base UR 26개와 조건 31개다(319~323행). 또 `open_implementation_details: 0`과 양립하지 않는 UR-25.3의 미결 선택이 architecture에 남아 있고, 확정 48px과 architecture의 44px이 충돌하며, MR-22의 관찰 개수도 원본과 맞지 않는다. 자세한 결함은 R2-01~R2-03에 기록한다.
- 왜 부분 해결인가: 요구사항 대조는 가능해졌지만, 그 문서 자체를 오류 없는 권위 출처로 승인할 수는 없다.
- 구현자 추가 판단: 현재 충돌·미결을 그대로 두면 후속 UI/T17 구현자가 선택해야 한다.

### RR-02 — PARTIALLY RESOLVED

- 관련 파일: `docs/specs/T01-scaffold.md` 요구사항 17~18(190~227행), 위반 케이스 14~15 및 순서(270~287행)
- 요구사항 대응: CLAUDE.md의 `any` 금지와 OR-03의 실패 검출 목표가 ESLint 9 flat config와 mutation으로 이어진다.
- 해결된 부분: `FlatCompat`, `next/core-web-vitals`, `next/typescript`, `@typescript-eslint/no-explicit-any: "error"` 및 ignores가 완전한 코드로 복원됐다. 공식 Next 15 예시와도 맞는다.
- 남은 문제: 케이스 15는 `...compat.config({ ... })` 블록 전체를 제거하면서 그 블록 안의 `rules`도 함께 제거한다. 그러면 남은 config에는 `@typescript-eslint/no-explicit-any` 참조 자체가 없으므로 “플러그인이 로드되지 않아 규칙을 해석할 수 없다는 설정 오류”가 날 수 없다. 즉 명세된 정확한 정상 config를 구현해도 필수 mutation의 기대 결과를 만족시킬 수 없다.
- 최소 해소 방향: 규칙은 남긴 채 `next/typescript` 확장만 제거하는 mutation처럼, 플러그인 제공자만 제거하도록 바꾸고 실제 기대 오류를 고정한다.
- 구현자 추가 판단: 현재 절차를 그대로 실행할지 기대 오류를 포기할지 선택해야 하므로 남아 있다.

### RR-03 — RESOLVED

- 관련 파일: `docs/specs/T04-seed.md` 요구사항 18~20(269~304행), 케이스 30~32(399~416행), 완료 조건 2(434~576행)
- 요구사항 대응: UR-24.3의 파일럿·개발 초기화 명령과 OR-03의 검증 목표가 최종 합성 명령 검증으로 이어진다.
- 판정 근거: `db:setup` 문자열을 `db:deploy → db:wal → db:seed` exact match로 검사하고, 누락·순서 변경 mutation을 둔다. 별도의 새 임시 DB에서 `npm run db:setup` 자체를 한 번 실행한 뒤 migration·WAL·9/10/27을 확인한다. 하위 명령만 따로 실행해 대체하는 것이 금지됐다.
- 구현자 추가 판단: 없음.

## 6. 기존 Finding 집계

| 상태 | 건수 | ID |
|---|---:|---|
| RESOLVED | 4 | DR-03, DR-07, DR-11, RR-03 |
| PARTIALLY RESOLVED | 3 | DR-12, RR-01, RR-02 |
| UNRESOLVED | 0 | — |
| REGRESSED | 0 | — |

기존 7건이 모두 RESOLVED라는 구현 허용 조건을 충족하지 않는다.

## 7. 새로운 Finding

### R2-01 — 확정 터치 영역이 architecture 안에서 48px과 44px로 충돌한다

- 심각도: P2
- 대상: 공통 문서 / 후속 화면 구현
- 근거: `docs/requirements.md` UR-20(63행), `docs/architecture.md` §6.2-1(664행), §6.4(726~734행)
- 실제 문제: 권위 요구사항과 공통 UI 표는 주요 조작 요소 최소 48×48px을 요구하지만 오늘 화면 체크박스는 최소 44×44px이라고 별도로 지시한다.
- 예상 실패: T14 구현자가 화면별 44px을 따르면 UR-20을 위반하고, 공통 48px을 따르면 §6.2-1의 명세와 달라진다. 어느 쪽도 추가 판단 없이 선택할 수 없다.
- 최소 수정 방향: §6.2-1을 48×48px로 통일하고 관련 인수 테스트도 48px 기준으로 고정한다.
- 판정 영향: 현재 T01~T04 파일에는 UI 구현이 없지만, requirements ↔ architecture 정합성과 `open_implementation_details: 0` 주장을 깨므로 전체 게이트의 P2다.

### R2-02 — `open_implementation_details: 0`과 추적성 0건 주장이 실제 문서와 다르다

- 심각도: P2
- 대상: `docs/requirements.md`, `docs/architecture.md`, `docs/workflow/STATUS.md`
- 근거: `docs/requirements.md` 상태·분류(7, 27~29행), UR-25.3(101행), §8.3(315~325행), `docs/architecture.md` C.3(949~952행), 미해결 질문(967~969행), 기존 `STATUS.md` 23~24행
- 실제 문제:
  - UR-25.3은 bulk-status 일부 실패 정책을 결정적으로 정하라고 확정했지만 architecture는 “전부 롤백”과 “성공분 반영” 중 무엇을 택할지 T17 스펙이 나중에 고른다고 남겼다. 이는 명시적인 미결 구현 상세 1건이다.
  - requirements §8.3은 base UR을 25개, 조건을 22개로 집계하지만 실제 ID는 base UR 26개, 조건 31개다. 따라서 “모두 추적했고 남은 미결 0건”이라는 자체 검사 결과가 재현되지 않는다.
- 예상 실패: T17 작성자가 실패 원자성을 새로 결정해야 하고, 게이트 자동화나 다음 리뷰가 잘못된 총계를 신뢰해 조건 누락을 놓칠 수 있다.
- 최소 수정 방향: 사용자/설계자가 UR-25.3 정책을 확정해 requirements·architecture·향후 T17에 반영하고, §8.3 집계와 조건별 추적 결과를 실제 ID 집합에서 다시 산출한다.
- 판정 영향: `open_implementation_details`는 0이 아니라 1이다. 구현 허용 필수 조건을 직접 위반한다.

### R2-03 — MR-22의 범위 블록 개수가 원본 및 T04와 다르다

- 심각도: P3
- 대상: `docs/requirements.md`
- 근거: `docs/requirements.md` MR-21~22(147~148행), `docs/mockups/daily-schedule.jpg`, `docs/specs/T04-seed.md` 시간표 표(141~156행)
- 실제 문제: 사진은 시점 마커 2건과 범위 블록 8건, 합계 10건이다. MR-22는 “나머지 9건”이라고 적어 합계 11건을 뜻한다. UR-24.5와 T04는 10건으로 올바르다.
- 예상 실패: requirements만 근거로 관찰 개수를 재사용하면 11건으로 오해할 수 있다. T04 exact table 덕분에 현재 시드 구현은 결정적이므로 즉시 구현 차단은 아니다.
- 최소 수정 방향: MR-22의 `9건`을 `8건`으로 정정한다.
- 판정 영향: 권위 요구사항의 관찰 정확성에 대한 P3 변경 필요.

### R2-04 — T04 롤백 테스트가 생성 단계의 부분 실패를 증명하지 않는다

- 심각도: P2
- 대상: T04
- 근거: `docs/specs/T04-seed.md` 요구사항 1~2(67~99행), rollback 테스트 18(366~372행), 경계·mutation 목록(375~397행)
- 실제 문제: 유일한 실패 seam `beforeCreateHook`은 삭제 직후이자 모든 블록·과제 생성 전 호출된다. 따라서 테스트는 Book upsert와 force 삭제가 롤백되는지만 증명한다. 블록을 생성한 뒤 과제 생성에서 실패하는 경로는 만들지 못한다.
- 통과 가능한 잘못된 구현: Book upsert·delete·hook만 transaction에 두고, ScheduleBlock/Assignment 생성을 transaction 밖에서 수행해도 성공 exact-match 테스트와 현재 `beforeCreateHook` rollback 테스트를 모두 통과할 수 있다.
- 예상 실패: 실제 생성 중 두 번째 단계가 실패하면 일부 시드 블록 또는 과제가 남아 “전체 시드 단일 트랜잭션”과 완전 롤백을 위반한다.
- 최소 수정 방향: 첫 생성 단계 뒤 실패를 주입하는 테스트 전용 seam을 transaction 내부에 추가하고, 기존 사용자 데이터가 복원되며 새 seed 행이 하나도 남지 않는지 검증한다. seam은 운영 `main()`에서 전달하지 않는다.
- 판정 영향: 데이터 안전성과 반증 가능성을 막는 T04 P2로, T04와 전체 판정을 BLOCK으로 만든다.

### R2-05 — architecture의 파일럿 착수 시각 설명과 밀린 건수 근거가 서로 맞지 않는다

- 심각도: P3
- 대상: `docs/architecture.md` 부록 C.3
- 근거: `docs/architecture.md` 943~947행, `docs/specs/T04-seed.md` Assignment 표 172~198행
- 실제 문제: “오늘은 2026-07-31”, “이미 2일이 지남”, “앱을 켜면 밀린 숙제 6건”을 함께 주장한다. 2026-07-31 기준으로 지난 7/29·7/30의 판독 가능한 시드 과제는 2+2=4건이다. 6건은 7/31의 2건까지 지난 뒤인 2026-08-01에 대응한다.
- 예상 실패: bulk-status 도입 근거와 예시 날짜가 불일치해 후속 T17 인수 시나리오가 4건인지 6건인지 혼동된다. 기능 필요성 자체는 UR-25로 확정되어 현재 T01~T04를 막지는 않는다.
- 최소 수정 방향: 기준일과 지난 날짜 범위를 일치시키고, 시간에 따라 변하는 “오늘” 표현 대신 파일럿 착수 예시의 고정 시점을 명시한다.
- 판정 영향: 공통 문서 P3.

## 8. 새로운 Finding 심각도 집계

| 심각도 | 건수 | ID |
|---|---:|---|
| P0 | 0 | — |
| P1 | 0 | — |
| P2 | 3 | R2-01, R2-02, R2-04 |
| P3 | 2 | R2-03, R2-05 |

## 9. 요구사항 추적성 검증

### 분류와 ID

- 사용자 확정 `UR`/`OR`, mockup 관찰 `MR`, 제외 `NR`, 미결 `OPEN`은 §0에서 명확히 구분된다.
- base UR-01~UR-26, 조건 31개, OR-01~03, MR 23개, NR-01~09는 ID 중복이 없다.
- 다만 §8.3의 “UR 25 + 조건 22” 집계는 실제 ID와 불일치한다(R2-02).

### 정방향

- T01~T04에 직접 관련된 UR-14, UR-16, UR-17, UR-20, UR-22, UR-24, UR-26과 OR-01~03은 각 SPEC 요구사항 추적 표에 연결된다.
- `ScheduleBlock.date`, `(date, startMinute)` 인덱스, 날짜별 겹침 범위, `2026-07-29` 시드 값은 requirements → architecture/D1·D11·D15 → T03/T04로 일치한다.
- UR-24.1~24.6은 T03의 `db:setup` 성격과 T04의 비파괴·exact seed 검증으로 연결된다.
- UR-25.3은 T17로 연결되지만 선택 자체가 아직 정해지지 않아 “미결 0”으로 볼 수 없다(R2-02).

### 역방향

- T01~T04의 주요 기술 선택은 UR-14와 OR-01~03, D13·D19·D21 및 architecture 부록 A로 돌아간다.
- T04의 데이터 값은 MR과 UR-15·UR-24·UR-26으로 돌아간다.
- 설계에만 존재하면서 T01~T04 구현자가 새 제품 기능을 발명해야 하는 항목은 찾지 못했다.
- 그러나 후속 화면의 터치 크기 충돌(R2-01)과 bulk-status 실패 정책(R2-02)은 역방향 추적만으로 단일 구현값을 얻을 수 없다.

### 결론

- T01~T04의 핵심 데이터·도구 추적: 대체로 일치
- 권위 요구사항 문서 전체의 무모순성·완결성: 실패
- `unapproved_design_assumptions`: **0** — 현재 발견한 문제는 승인되지 않은 새 가정을 추가한 것이 아니라 확정값 충돌과 미결 정책이다.
- `open_implementation_details`: **1** — UR-25.3의 일부 실패 정책.

## 10. 사용자 확정 사항 검증 — UR-26·UR-26.1~26.6

| 확인 항목 | 판정 | 근거 |
|---|---|---|
| 10개 블록이 `2026-07-29`에만 속함 | PASS | requirements 69, 102행; architecture C.1 911~916행; decisions D11 374~387행; T04 141~156행 |
| 날짜가 사진 판독값이 아니라 사용자 지정 파일럿 값 | PASS | requirements 69, 226~230행; architecture 915행; T04 160~163행. 원본 사진에도 날짜가 없음 |
| 다른 19일 자동 복제 금지 | PASS | requirements 103행; architecture 914·916행; T04 164~165행 |
| 다른 날짜의 빈 시간표가 정상 상태 | PASS | requirements 105행; architecture §5.4 634행·§6.2-2 676행; T04 165행 |
| 날짜별 입력 가능한 구조 | PASS | T03 `ScheduleBlock.date`와 복합 인덱스(100~105, 459~482행), architecture 시간표 CRUD(622~634행) |
| 반복·템플릿 MVP 제외 | PASS | requirements 84, 104, 170행; architecture 799행; decisions D11 391행 |
| `2026-07-29`가 제품 전체 상수로 확산되지 않음 | PASS | requirements 107행; architecture 915행; T04 163·166행. T03은 값이 아니라 date 구조만 만든다 |

UR-26 계열 자체에는 구현 차단 누락이 없다.

## 11. T01 개별 판정

**BLOCK**

- Node 정책, Next `^15.5.0`, `next typegen && tsc --noEmit`, Tailwind 생성/브라우저 적용 책임 분리, ESLint 9 FlatCompat의 정상 구성은 명확하고 공식 자료와 일치한다.
- clean checkout 재현성은 lockfile·`npm ci`·typegen 순서로 정의됐다.
- 그러나 RR-02의 필수 케이스 15는 mutation과 기대 오류가 논리적으로 양립하지 않는다. 완료 보고가 반드시 그 실제 출력을 포함해야 하므로 정확한 구현도 완료 조건을 만족할 수 없다.

## 12. T02 개별 판정

**PASS**

- T01 의존, Node {22,24,26}, `.nvmrc`/engines/test/CI 대조, Playwright lockfile 고정, Chromium 1종, 1024×768, production webServer가 일치한다.
- Playwright 공식 문서에서 `webServer.env`는 기본적으로 `process.env`를 상속하므로 요구사항 12의 PATH 방어는 보수적이지만 충돌하지 않는다.
- `text-[42px]` computed style 검증은 T01의 산출 CSS 검사와 서로 다른 계층을 증명한다.
- 도메인 날짜 함수 검증을 T05로 이관한 경계도 명확하다.

## 13. T03 개별 판정

**BLOCK**

- Prisma/@prisma-client `^6.2.0`, SQLite enum 보장 수준, schema·migration 구조 검증, `ScheduleBlock.date`, 날짜 복합 인덱스, D19 기본값 script exact set, npm script 사용, WAL이 일치한다.
- 공식 Prisma 6.19.0 소스에서 `--to-schema-datamodel`과 `--shadow-database-url`이 실제 지원됨을 확인해 `db:diff` 명령은 현재 지정 범위와 양립한다.
- 그러나 DR-12가 PARTIALLY RESOLVED다. rollback journal과 실제 sidecar 삭제를 놓친 구현, DB rename 이후 finalize 실패 계약을 증명하지 못하는 구현이 테스트를 통과할 수 있다. 테스트 DB 기반 전체 태스크의 재현성·정리 안전성에 직접 영향을 준다.

## 14. T04 개별 판정

**BLOCK**

- 9권·10블록·27과제의 표와 mockup 전사는 일치한다. seed와 fixture는 상호 import하지 않고 exact match와 mutation을 함께 둔다.
- 시드 기본 경로는 기존 Block/Assignment를 보존하고 Book 사용자 필드를 덮어쓰지 않는다. force는 Book을 삭제하거나 사용자 필드를 덮어쓰지 않으며, 개발 DB가 아닌 새 임시 DB에서 `db:setup` 자체를 검증한다.
- 10개 블록은 `2026-07-29`에만 생성되고 다른 19일은 0건인 정상 상태다.
- 그러나 R2-04 때문에 생성 단계 중간 실패가 전체 rollback되는지는 검증되지 않는다. 데이터 안전성 요구를 위반하는 구현이 초록이 될 수 있어 BLOCK이다.

## 15. 전체 판정

**BLOCK**

| 태스크 | 판정 | 핵심 근거 |
|---|---|---|
| T01 | BLOCK | RR-02 부분 해결 — 필수 mutation 기대가 성립하지 않음 |
| T02 | PASS | 하니스·Node·CI·Tailwind 브라우저 검증이 결정적 |
| T03 | BLOCK | DR-12 부분 해결 — template/sidecar 실패 검증 구멍 |
| T04 | BLOCK | R2-04 — 생성 단계 부분 실패 rollback을 증명하지 못함 |

남은 기존 P1과 구현 정확성·재현성·데이터 안전성을 방해하는 P2가 있으므로 전체 BLOCK이다.

## 16. implementation_allowed 판정

`implementation_allowed: false`

필수 조건 중 다음을 충족하지 못한다.

- 기존 7개 Finding 전부 RESOLVED: 실패(4 RESOLVED, 3 PARTIALLY RESOLVED)
- 새로운 구현 차단 P2 0건: 실패(R2-04, 공통 R2-01·R2-02)
- T01~T04가 순서대로 모두 구현 가능: 실패(T01·T03·T04 BLOCK)
- 추적성에 구현 차단 누락 없음: 실패(R2-01·R2-02)
- 미결 구현 결정 0건: 실패(UR-25.3 1건)
- 완료 조건이 모두 반증 가능: 실패(RR-02, DR-12, R2-04)

## 17. 구현 순서와 다음 담당자

구현 순서 자체는 `T01 → T02 → T03 → T04`로 일관되며, 공유 파일 때문에 병렬 구현·병렬 PR을 금지한 규칙도 충분하다(`architecture.md` 부록 A.1 819~834행 및 각 SPEC의 “구현 순서상의 위치”).

다음 담당자는 **Claude**다. 다음 작업은 코드 구현이 아니라 아래 문서 수정이다.

1. RR-02 mutation을 실제로 반증 가능한 형태로 고친다.
2. DR-12의 rollback journal, sidecar 존재 전제, DB rename 이후 finalize 실패 검증을 보완한다.
3. R2-01~R2-05를 수정한다. 특히 UR-25.3은 설계자/사용자 결정이 필요한 값이므로 임의 선택하지 않는다.
4. 수정 후 Codex 독립 재검토를 다시 요청한다.

## 18. 검증 한계

- 사용자 지시에 따라 패키지를 설치하지 않았고 `npm ci`, lint, typecheck, build, Vitest, Playwright, Prisma CLI를 실행하지 않았다.
- DB·migration·seed를 생성하거나 실행하지 않았다. 생성 DDL, WAL/SHM/journal의 실제 수명, macOS/Linux에서의 CLI 출력은 구현 태스크의 완료 검증에서 확인해야 한다.
- 공식 웹 조회 도구가 네트워크 오류로 두 번 실패해, 승인된 읽기 전용 `curl`로 공식 URL과 공식 Prisma 6.19.0 소스를 확인했다.
- Prisma CLI의 `--to-schema-datamodel`은 현재 v6 문서 표기보다 공식 6.19.0 소스가 더 직접적인 근거여서 소스를 우선했다. 실제 설치 버전은 lockfile 생성 후 다시 보고해야 한다.
- 후속 T05/T07/T09/T12/T14/T17/T19 SPEC은 아직 없으므로, 이 리뷰는 예약된 책임이 현재 문서에 모순 없이 기록됐는지만 확인했다.

## 19. 변경한 파일과 변경하지 않은 영역

변경한 파일:

- `docs/reviews/DR-T01-T04-spec-rereview-round2.md` — 새 리뷰
- `docs/workflow/STATUS.md` — Round 2 판정 추가

변경하지 않은 영역:

- requirements, architecture, decisions, T01~T04 SPEC
- 기존 리뷰 문서
- AGENTS.md, CLAUDE.md, README.md
- `.github/**`, `.gitignore`, package 파일
- `prisma/**`, `src/**`, `tests/**`, `e2e/**`
- 운영 코드·테스트 코드·DB·CI

## 20. 확인한 공식 자료 URL과 확인 날짜

확인일: **2026-08-01**

- [Playwright Installation / System requirements](https://playwright.dev/docs/intro) — Node 22.x·24.x·26.x
- [Playwright Web server](https://playwright.dev/docs/test-webserver) — `webServer.env`의 `process.env` 상속
- [Next.js 15 CLI / `next typegen`](https://nextjs.org/docs/15/app/api-reference/cli/next) — 15.5.0 도입, CI type generation
- [Next.js 15 ESLint](https://nextjs.org/docs/15/app/api-reference/config/eslint) — FlatCompat, core-web-vitals, TypeScript 확장
- [Prisma database features](https://www.prisma.io/docs/orm/reference/database-features) — SQLite JSON/Enum 6.2.0 도입
- [Prisma SQLite connector](https://www.prisma.io/docs/orm/overview/databases/sqlite) — Enum → TEXT, DB 수준 비강제, invalid 값 runtime failure
- [Prisma v6 upgrade guide](https://www.prisma.io/docs/orm/more/upgrade-guides/upgrading-versions/upgrading-to-prisma-6) — Prisma v6 Node 최소 버전 정책
- [Prisma v6 CLI reference](https://www.prisma.io/docs/orm/v6/reference/prisma-cli-reference#migrate-diff) — migrate diff 입력·exit-code
- [Prisma 6.19.0 `MigrateDiff.ts` 공식 소스](https://github.com/prisma/prisma/blob/6.19.0/packages/migrate/src/commands/MigrateDiff.ts) — `--to-schema-datamodel`, `--shadow-database-url` 실제 지원
