# T01~T04 SPEC 독립 재검토 — Round 1

- 검토자: Codex
- SPEC 작성·수정자: Claude
- 기준 브랜치: `docs/specs-batch1`
- 기준 HEAD: `c77ab5c33122da5fd3414e1ed054fe22224506fc`
- 최초 리뷰 커밋: `b4511c7`
- Claude 수정 커밋: `c77ab5c`
- 최초 리뷰 원본: `docs/reviews/DR-T01-T04-spec-review.md`
- 검토일: 2026-07-31
- 검토 성격: 구현이 아닌 설계·스펙 재검토

## 전체 판정

**BLOCK**

| 태스크 | 판정 | 구현 차단 근거 |
|---|---|---|
| T01 | **BLOCK** | 필수 대조 문서 부재(RR-01), ESLint FlatCompat 요구 삭제 회귀(RR-02) |
| T02 | **BLOCK** | 필수 대조 문서 부재(RR-01), 지원되지 않는 Node 메이저를 허용하는 정책(DR-03) |
| T03 | **BLOCK** | 필수 대조 문서 부재(RR-01), SQLite enum 보장 수준의 설계 문서 충돌(DR-07), 테스트 DB 헬퍼 실패 정리 누락(DR-12) |
| T04 | **BLOCK** | 필수 대조 문서 부재(RR-01), 개발 DB WAL sidecar를 놓치는 불변 검사(DR-11), `db:setup` 검증 누락(RR-03) |

현재 남은 Finding은 P0 0건, P1 5건, P2 2건, P3 0건이다. P1이 남아 있으므로 구현을 시작할 수 없다. 이번 재검토 결과와 무관하게 `implementation_allowed`는 `false`다.

## 검증 상태와 범위

### Git 상태

검토 시작 시 직접 확인한 결과:

```text
git status --short --branch
## docs/specs-batch1...origin/docs/specs-batch1

git log -3 --oneline --decorate
c77ab5c (HEAD -> docs/specs-batch1, origin/docs/specs-batch1) docs: revise T01-T04 specs for Codex re-review
b4511c7 docs: record Codex review for T01-T04 specs
13a9c57 docs: T01~T04 구현 스펙 및 D19·D20 결정 추가
```

`git diff --name-status b4511c7..c77ab5c`에는 `docs/architecture.md`, `docs/decisions.md`, T01~T04 SPEC, `docs/workflow/STATUS.md`만 나타났다. `git diff --exit-code b4511c7..c77ab5c -- docs/reviews/DR-T01-T04-spec-review.md`와 작업 트리 기준 같은 명령은 모두 종료 코드 0이었다. 따라서 최초 리뷰 원본은 `c77ab5c`에서 수정되지 않았고, 검토 시작 시 작업 트리는 깨끗했다.

### 읽은 파일

- `AGENTS.md` 전체 — 설계 문서는 `architecture.md`와 `decisions.md`가 한 쌍이고, 스펙 밖 판단은 중단해야 한다는 규칙 확인 (`AGENTS.md:8-14`, `AGENTS.md:31-34`)
- `CLAUDE.md` 전체 — `AGENTS.md`와 같은 내용의 심볼릭 링크임을 확인
- `docs/architecture.md` 전체
- `docs/decisions.md` 전체
- `docs/specs/T01-scaffold.md` 전체
- `docs/specs/T02-test-harness.md` 전체
- `docs/specs/T03-prisma-schema.md` 전체
- `docs/specs/T04-seed.md` 전체
- `docs/reviews/DR-T01-T04-spec-review.md` 전체
- `docs/workflow/STATUS.md` 전체
- `docs/requirements.md` — **읽지 못함. 현재 HEAD, 추적 파일 목록, 전체 Git 이력에 파일이 존재하지 않는다.**

### 실행한 읽기 전용 확인

- `pwd`
- `git status --short --branch`
- `git log -3 --oneline --decorate`
- `git rev-parse HEAD`
- `git diff --name-status b4511c7..c77ab5c`
- `git diff b4511c7..c77ab5c -- <설계·스펙 파일>`
- `git diff --exit-code b4511c7..c77ab5c -- docs/reviews/DR-T01-T04-spec-review.md`
- `git diff --exit-code -- docs/reviews/DR-T01-T04-spec-review.md`
- `git ls-files`
- `git ls-files --error-unmatch docs/requirements.md`
- `git cat-file -e c77ab5c:docs/requirements.md`
- `git log --all -- docs/requirements.md`
- `rg`를 이용한 태스크 번호·Decision·파일·명령 참조 교차 검색
- `nl -ba`를 이용한 현재 문서 행 번호 확인

패키지 설치, 테스트 실행, DB 생성·삭제·마이그레이션은 하지 않았다. 이번 판정은 스펙의 완전성·일관성·구현 가능성에 한정한다.

## 기존 Finding 14건 재검토

### DR-01 — RESOLVED

- **판정:** RESOLVED
- **현재 근거:** `docs/specs/T01-scaffold.md:62`, `docs/specs/T01-scaffold.md:85-89`, `docs/specs/T01-scaffold.md:193-194`, `docs/specs/T01-scaffold.md:227-231`, `docs/specs/T02-test-harness.md:245`
- **해소 설명:** `typecheck`가 정확히 `next typegen && tsc --noEmit`으로 고정됐다. `.next`와 `next-env.d.ts`가 없는 상태와 build 이후 상태를 별도 검증하고, CI도 같은 npm script를 호출한다. Next 하한도 `^15.5.0`으로 올라갔다. 공식 Next 15 CLI 문서도 `typegen`이 15.5.0에 추가됐고 이 조합을 CI용 예로 든다: [Next.js 15 CLI](https://nextjs.org/docs/15/pages/api-reference/cli/next).
- **남은 수정 조건:** 없음.
- **구현 차단:** 아니오.

### DR-02 — RESOLVED

- **판정:** RESOLVED
- **현재 근거:** `docs/specs/T01-scaffold.md:139-158`, `docs/specs/T01-scaffold.md:196`, `docs/specs/T01-scaffold.md:209-211`, `docs/specs/T02-test-harness.md:170-183`, `docs/specs/T02-test-harness.md:287`, `docs/specs/T02-test-harness.md:296`
- **해소 설명:** T01은 build 산출 CSS의 `42px` 생성 여부를 보고, T02는 브라우저 computed style `42px`를 본다. `text-[42px]` 제거 mutation은 실제 적용 단정을 실패시킨다. 생성과 적용의 책임이 분리됐고 두 검사 모두 반증 가능하다.
- **남은 수정 조건:** 없음.
- **구현 차단:** 아니오.

### DR-03 — PARTIALLY RESOLVED

- **판정:** PARTIALLY RESOLVED — 잔여 P1
- **현재 근거:** `docs/specs/T01-scaffold.md:42-46`, `docs/specs/T01-scaffold.md:55`, `docs/specs/T02-test-harness.md:45-49`, `docs/specs/T02-test-harness.md:95-99`, `docs/specs/T02-test-harness.md:113-121`, `docs/decisions.md:650-675`
- **해소 설명:** `.nvmrc=22`, CI의 `node-version-file`, Node 22 기준, lockfile 고정, 설치된 Playwright 버전 보고는 일관되게 추가됐다. Node 24.18.0을 허용하는 설명도 공식 지원 메이저 24와 모순되지 않는다. 그러나 문서가 스스로 지원 범위를 `22 / 24 / 26`으로 적으면서 `engines.node: ">=22"`와 실행 테스트 `major >= 22`를 사용한다. 따라서 Node 23·25·27도 정책 테스트를 통과한다. 공식 Playwright 시스템 요구사항은 현재 “latest 22.x, 24.x or 26.x”다: [Playwright 설치 문서](https://playwright.dev/docs/intro).
- **남은 수정 조건:** 허용 메이저를 22·24·26으로 제한하는 검사와 `engines.node` 범위를 정의하거나, `.nvmrc` 사용을 로컬 필수 조건으로 만들고 지원되지 않는 메이저에서 완료 검증이 실패하도록 해야 한다. D21, T01, T02의 문구와 테스트 기대를 함께 맞춰야 한다.
- **구현 차단:** **예.** 현재 명세만 따르면 지원되지 않는 런타임에서 모든 Node 정책 테스트가 통과할 수 있다.

### DR-04 — RESOLVED

- **판정:** RESOLVED
- **현재 근거:** `docs/specs/T02-test-harness.md:7`, `docs/specs/T02-test-harness.md:86-111`, `docs/specs/T02-test-harness.md:310-320`, `docs/architecture.md:696-703`, `docs/architecture.md:793`
- **해소 설명:** T02는 ICU·타임존 데이터와 프로세스 환경 전제만 검사한다고 명시한다. D8의 `getToday` 도메인 검증은 예약된 T05로 이관됐고, `TZ=UTC`와 `TZ=Asia/Seoul`을 서로 다른 프로세스로 실행해야 한다는 조건이 T02와 architecture 양쪽에 있다.
- **남은 수정 조건:** 없음. T05 스펙 작성 시 현재 예약 조건을 실제 완료 조건으로 옮겨야 하지만 이는 현재 T02 결함이 아니다.
- **구현 차단:** 아니오.

### DR-05 — RESOLVED

- **판정:** RESOLVED
- **현재 근거:** `docs/specs/T02-test-harness.md:13-15`, `docs/specs/T03-prisma-schema.md:7-19`, `docs/architecture.md:772-783`
- **해소 설명:** T03 선행 태스크가 T02로 수정됐고 T01은 전이 의존으로 설명된다. T02와 T03은 공유 파일 및 CI 패치 전제 때문에 병렬 구현·병렬 PR이 금지됐다.
- **남은 수정 조건:** 없음.
- **구현 차단:** 아니오.

### DR-06 — RESOLVED

- **판정:** RESOLVED
- **현재 근거:** `docs/specs/T03-prisma-schema.md:134-152`, `docs/specs/T03-prisma-schema.md:235-264`, `docs/specs/T03-prisma-schema.md:461-471`, `docs/specs/T03-prisma-schema.md:484-489`, `docs/specs/T04-seed.md:234-249`
- **해소 설명:** T03에서 기본값 리터럴을 갖는 script는 정확히 6개이며 요구사항 목록과 `EXPECTED_DB_URL_SCRIPTS` 배열이 일치한다. `db:setup`은 리터럴 없이 하위 script를 조합하고, T04가 `db:seed`를 추가하면서 기대 배열을 7개로 갱신한다. Prisma CLI 완료 검증은 `env -u DATABASE_URL`과 npm script를 사용하며 직접 `npx prisma`는 연결 문자열이 필요 없는 버전 확인만 예외다.
- **남은 수정 조건:** 기존 DR-06 자체에는 없음. 다만 T04의 `db:setup` 조합을 실제로 검증하지 않는 별도 결함은 RR-03에 기록한다.
- **구현 차단:** 아니오.

### DR-07 — PARTIALLY RESOLVED

- **판정:** PARTIALLY RESOLVED — 잔여 P1
- **현재 근거:** `docs/specs/T03-prisma-schema.md:60-79`, `docs/specs/T03-prisma-schema.md:291-367`, `docs/specs/T03-prisma-schema.md:419-447`, `docs/architecture.md:281-284`, `docs/decisions.md:384-400`, `docs/specs/T03-prisma-schema.md:510`
- **해소 설명:** 컬럼 순서·타입·nullable·PK·기본값 범위·FK·인덱스 이름/유니크/컬럼 순서를 SQLite 내부 메타데이터로 검사하도록 강화됐고, 잘못된 기대값과 schema drift mutation도 추가됐다. T03은 SQLite enum이 `TEXT`이고 `CHECK`가 없으며 Prisma 계층에서만 강제된다고 올바르게 적었다. 공식 Prisma 문서도 SQLite enum에는 DB 및 migration 수준의 값 강제가 없다고 설명한다: [Prisma SQLite connector](https://www.prisma.io/docs/orm/v6/overview/databases/sqlite).
- **남은 수정 조건:** `architecture.md:283`의 “DB/엔진이 강제”와 `decisions.md:398`의 대안 기각 근거 “DB가 값을 전혀 강제하지 못한다”를 T03의 실제 전제와 일치시켜야 한다. DB 우회 쓰기에서는 invalid enum이 들어갈 수 있고 읽을 때 런타임 실패한다는 보장 수준, T07 Zod의 책임, 서비스 계층 우회 금지의 역할을 세 문서에서 동일하게 정의해야 한다.
- **구현 차단:** **예.** 단일 출처인 architecture/decisions와 구현 스펙이 핵심 데이터 무결성 보장 수준을 서로 다르게 말한다.

### DR-08 — RESOLVED

- **판정:** RESOLVED
- **현재 근거:** `docs/specs/T04-seed.md:7-22`, `docs/architecture.md:772-783`
- **해소 설명:** T04는 직접 선행 T03과 전이 선행 T01·T02를 모두 설명한다. 테스트 하니스와 DB 헬퍼의 제공 태스크도 표로 명시됐다. 전체 순서 및 병렬 PR 금지는 부록 A와 일치한다.
- **남은 수정 조건:** 없음.
- **구현 차단:** 아니오.

### DR-09 — RESOLVED

- **판정:** RESOLVED
- **현재 근거:** `docs/specs/T04-seed.md:101-171`, `docs/specs/T04-seed.md:173-230`, `docs/specs/T04-seed.md:274-299`, `docs/specs/T04-seed.md:326-336`, `docs/architecture.md:846-873`
- **해소 설명:** Book 9, Block 10, Assignment 27의 모든 셀이 명시됐고 architecture의 관찰·시드 표와 일치한다. 구현과 fixture의 상호 import가 금지됐고, `bookId`는 `bookTitle`로 바꿔 비교한다. 문자열은 locale/ICU가 아닌 코드 유닛 순서로 정렬한다. mutation은 fixture가 아니라 `prisma/seed.ts`의 각 표 셀을 바꾼다.
- **남은 수정 조건:** 없음.
- **구현 차단:** 아니오.

### DR-10 — RESOLVED

- **판정:** RESOLVED
- **현재 근거:** `docs/specs/T04-seed.md:43-93`, `docs/specs/T04-seed.md:300-313`, `docs/specs/T04-seed.md:386-415`
- **해소 설명:** Book upsert부터 삭제·hook·count·생성까지 단일 트랜잭션이고, force 삭제는 Assignment 다음 ScheduleBlock 순서다. 기본 경로는 사용자 Book 필드와 기존 Block/Assignment를 보존한다. force도 Book은 삭제·덮어쓰기 하지 않는다. `beforeCreateHook`은 rollback을 결정적으로 검증하는 seam으로만 노출되고 `main()`/운영 경로 전달이 금지됐다. 실패 시 사용자 Block/Assignment가 모두 남는 테스트가 있다.
- **남은 수정 조건:** 없음.
- **구현 차단:** 아니오.

### DR-11 — PARTIALLY RESOLVED

- **판정:** PARTIALLY RESOLVED — 잔여 P1
- **현재 근거:** `docs/specs/T04-seed.md:353-384`, `docs/specs/T04-seed.md:386-394`, `docs/specs/T03-prisma-schema.md:111-125`
- **해소 설명:** 완료 검증은 `.tmp`의 절대 경로 새 DB에서 수행하고 EXIT trap으로 임시 DB와 sidecar를 정리한다. 개발 DB 삭제와 완료 검증의 `SEED_FORCE=1` 사용도 금지됐다. 그러나 개발 DB 불변 검사는 `prisma/dev.db` 본체 하나의 `shasum`만 비교한다. 개발 DB가 WAL 모드라면 오작동한 명령의 쓰기가 `prisma/dev.db-wal`에만 남아 본체 checksum이 같을 수 있다. 또한 검증 script는 상속된 `SEED_FORCE`를 명시적으로 unset하지 않는다.
- **남은 수정 조건:** 검증 시작·종료에 `prisma/dev.db`, `prisma/dev.db-wal`, `prisma/dev.db-shm`의 존재 여부와 hash를 모두 비교하고, seed 호출은 `env -u SEED_FORCE DATABASE_URL=...`로 실행해야 한다. 실패 경로에서도 이 검사가 실행되도록 EXIT trap 또는 별도 cleanup/check 함수의 순서를 명시해야 한다.
- **구현 차단:** **예.** 현재 완료 절차가 개발 데이터 변경을 놓친 채 통과할 수 있다.

### DR-12 — PARTIALLY RESOLVED

- **판정:** PARTIALLY RESOLVED — 잔여 P2
- **현재 근거:** `docs/specs/T03-prisma-schema.md:179-221`, `docs/specs/T03-prisma-schema.md:280-288`, `docs/specs/T03-prisma-schema.md:427-445`, `docs/specs/T03-prisma-schema.md:507-508`
- **해소 설명:** registry, 복사 후 내부 실패 정리, migration fingerprint, 원자적 template/meta 교체, `{ ...process.env, DATABASE_URL }` 병합, 개별 DB sidecar 정리와 `afterCopyHook` seam이 명시됐다. seam은 `tests/helpers/db.ts`에만 있어 운영 코드에 노출되지 않는다. 그러나 “복사 이후” 실패 정리만 규정되어 있고, 유일 임시 template DB에서 `migrate deploy`가 실패하거나 rename/meta 쓰기가 실패할 때 그 template `.db`와 sidecar를 지우라는 규칙·테스트가 없다. `$disconnect()` 자체가 실패해도 파일 정리를 계속해야 하는지도 명시되지 않았다. 또한 template 생성의 실제 자식 명령을 `npm run db:deploy`로 할지 직접 Prisma CLI로 할지 명시하지 않은 채 `npx` 탐색을 설명해, `npx prisma` 직접 호출 금지(`docs/specs/T03-prisma-schema.md:152`, `:488`)와 긴장이 남는다.
- **남은 수정 조건:** template 생성 전체를 `try/finally`로 감싸 임시 template DB와 `-wal`/`-shm`을 모든 실패에서 지우고 이를 mutation/seam으로 검증해야 한다. cleanup은 disconnect 실패와 개별 unlink 실패가 있어도 나머지 파일 정리를 시도하도록 정한다. 자식 명령은 저장소 루트에서 `npm run db:deploy`처럼 금지 사항과 양립하는 정확한 executable/arguments/cwd로 고정해야 한다.
- **구현 차단:** **예.** 구현 정확성에 필요한 실패 경로와 호출 방식이 아직 구현자 판단에 남아 있다.

### DR-13 — RESOLVED

- **판정:** RESOLVED
- **현재 근거:** `docs/specs/T04-seed.md:252-268`, `docs/specs/T04-seed.md:338-351`, `docs/specs/T03-prisma-schema.md:459-480`, `docs/specs/T02-test-harness.md:322-337`
- **해소 설명:** 비즈니스 규칙은 고유 테스트명을 직접 참조하고, 완료 조건은 누적 pass 수 대신 명명된 테스트의 reporter 출력 존재를 사용한다. T02·T03·T04가 같은 원칙을 쓴다.
- **남은 수정 조건:** 없음.
- **구현 차단:** 아니오.

### DR-14 — RESOLVED

- **판정:** RESOLVED
- **현재 근거:** `docs/architecture.md:9-12`, `docs/architecture.md:302-334`
- **해소 설명:** “20개 결정” 같은 중복 개수 표기가 제거됐다. architecture는 §2 표를 유일한 결정 색인으로 선언하고 개수를 본문에 적지 않는다.
- **남은 수정 조건:** 없음.
- **구현 차단:** 아니오.

### 기존 Finding 해소 집계

| 상태 | 건수 | ID |
|---|---:|---|
| RESOLVED | 10 | DR-01, DR-02, DR-04, DR-05, DR-06, DR-08, DR-09, DR-10, DR-13, DR-14 |
| PARTIALLY RESOLVED | 4 | DR-03, DR-07, DR-11, DR-12 |
| UNRESOLVED | 0 | — |
| REGRESSED | 0 | — |

## 수동 정합성 검사

### A. architecture 부록 A — PASS

`docs/architecture.md:762-785`의 확정 태스크는 T01 프로젝트 스캐폴드, T02 테스트 하니스, T03 Prisma 스키마·마이그레이션 기반, T04 초기 시드이며 각 스펙의 제목·범위·직접 의존과 일치한다. 순서 `T01 → T02 → T03 → T04`, 공유 파일 때문에 병렬 구현·병렬 PR을 금지하는 조건도 각 스펙과 같다.

`docs/architecture.md:787-825`는 후속 범위를 다음처럼 구분한다.

- 확정 번호: T01~T04 — 스펙 존재
- 예약 번호: T05, T07, T09, T12, T14, T17, T19 — 현재 스펙이 이미 참조하지만 스펙 미작성
- ID 미정: 나머지 후속 범위 — 태스크 ID를 배정하지 않음

과거 T01~T14 표나 총 태스크 개수 주장은 검색 결과 남아 있지 않았다.

### B. decisions의 오래된 태스크 참조 — PASS

- D13의 Prisma 의존성·스키마·마이그레이션 책임은 T03이다 (`docs/decisions.md:390-396`).
- D16-e의 `next build + next start`와 `serve`는 T01이다 (`docs/decisions.md:493-498`).
- WAL은 T03이다 (`docs/decisions.md:498`).
- `setInterval` 정리는 후속 갱신 계층 스펙, ID 미정이다 (`docs/decisions.md:499-501`).

오래된 T01/T02 묶음 책임 표기는 검색 결과 남아 있지 않았다.

## 새 Findings

### RR-01 — 필수 요구사항 문서가 저장소와 Git 이력에 없다

- **심각도:** P1
- **대상 SPEC:** T01, T02, T03, T04 공통
- **정확한 위치:** `docs/requirements.md` — 파일 부재로 행 번호 없음. `git ls-files --error-unmatch docs/requirements.md`와 `git cat-file -e c77ab5c:docs/requirements.md`가 실패하고 `git log --all -- docs/requirements.md`도 결과가 없다.
- **문제:** 이번 게이트가 명시적으로 요구한 requirements와 architecture/decisions/spec 간 정합성을 검증할 원문이 없다. STATUS의 “Accepted” 주장이나 architecture를 requirements의 대체물로 추정할 수 없다.
- **재현 또는 발생 조건:** 현재 `c77ab5c`에서 위 세 명령을 실행하거나 파일을 열려고 하면 즉시 재현된다.
- **영향:** 외부 요구의 누락·변형 여부를 독립 검증할 수 없으므로 네 SPEC 모두에 대한 최종 승인 근거가 불완전하다.
- **근거:** 프로젝트 규칙도 설계에 답이 없으면 임의 진행하지 말라고 한다 (`AGENTS.md:8-14`, `AGENTS.md:31-34`). 이번 재검토 요청은 `docs/requirements.md`를 필수 입력으로 지정했다.
- **권장 수정:** 권위 있는 requirements 문서를 해당 경로에 복원·추가하고, architecture/decisions/T01~T04와 값·범위·완료 조건을 다시 대조한다. 문서가 애초에 존재하지 않아야 한다면 검토 입력 목록과 요구사항 단일 출처를 사용자가 명시적으로 정정해야 한다.
- **수정 후 검증:** `git ls-files docs/requirements.md`로 추적 여부를 확인하고 파일 전체를 읽은 뒤, 모든 요구 ID·값·범위가 architecture/decisions/spec에 반영됐는지 양방향 참조표로 검증한다.

### RR-02 — T01 수정에서 ESLint FlatCompat 명세가 삭제됐다

- **심각도:** P1
- **대상 SPEC:** T01
- **정확한 위치:** 파일 생성 목록 `docs/specs/T01-scaffold.md:25`, 의존성 `docs/specs/T01-scaffold.md:70-77`, `any` 차단 주장 `docs/specs/T01-scaffold.md:174-177`, mutation 기대 `docs/specs/T01-scaffold.md:203-211`. 이들 사이에 `eslint.config.mjs` 내용 요구가 없다. 반면 `b4511c7` 원문에는 FlatCompat와 `next/core-web-vitals`, `next/typescript`, `@typescript-eslint/no-explicit-any: error` 구성이 있었다가 `b4511c7..c77ab5c` diff에서 삭제됐다.
- **문제:** 어떤 flat config를 작성해야 하는지, 설치한 `@eslint/eslintrc`를 어떻게 쓰는지, `no-explicit-any` 규칙을 어디서 켜는지가 사라졌다. 문서는 여전히 lint가 `any`를 잡아야 한다고 요구하므로 요구사항과 구현 지시가 내부 모순이다.
- **재현 또는 발생 조건:** 현재 T01만 보고 `eslint.config.mjs`를 작성할 때 발생한다. 빈 config, Next 권장 config, FlatCompat 중 무엇이 정답인지 결정할 근거가 없고, 일부 선택에서는 케이스 7이 통과하지 않는다.
- **영향:** 구현자가 임의 설정을 선택하거나 `npm run lint`가 `any`를 놓칠 수 있다. T01 완료 조건이 같은 스펙으로부터 결정적으로 구현되지 않는다.
- **근거:** T01은 목록 밖 판단을 허용하지 않고(`docs/specs/T01-scaffold.md:36`), AGENTS 규칙도 스펙에 없는 판단을 금지한다 (`AGENTS.md:31-34`).
- **권장 수정:** ESLint 9 flat config의 전체 내용을 다시 명시하고, 현재 지정 의존성만으로 `next/core-web-vitals`와 `next/typescript`를 확장하며 `no-explicit-any`를 error로 강제하도록 한다. 기존 `b4511c7` 구성을 복원할 경우 Next 15.5/ESLint 9 조합과 실제 export 형식도 함께 고정한다.
- **수정 후 검증:** 깨끗한 설치 후 `npm run lint` 성공, `any` mutation 실패, config에서 제거한 mutation 실패를 확인하고 실제 출력과 원복 diff를 보고한다.

### RR-03 — T04가 변경하는 `db:setup` 경로를 로컬 완료 검증이 실행하지 않는다

- **심각도:** P2
- **대상 SPEC:** T04
- **정확한 위치:** `db:setup` 변경 요구 `docs/specs/T04-seed.md:232-238`, 완료 검증 `docs/specs/T04-seed.md:338-384`, CI가 이 경로에 의존한다는 설명 `docs/specs/T04-seed.md:418`, T03의 CI 호출 `docs/specs/T03-prisma-schema.md:382-388`
- **문제:** T04의 핵심 변경 중 하나는 `db:setup = db:deploy && db:wal && db:seed`이지만 완료 검증은 세 하위 script를 따로 실행한다. `src/server/prisma.test.ts`의 exact match는 기본값 리터럴 script 이름만 확인하며 `db:setup`의 구성 순서·포함 여부는 확인하지 않는다.
- **재현 또는 발생 조건:** 구현자가 `db:setup`에 `db:seed`를 누락하거나 순서를 잘못 둬도 T04의 명명된 unit/integration 테스트와 현재 임시 DB 완료 script는 모두 통과할 수 있다. 현재 smoke E2E도 시드 데이터에 의존하지 않아 CI가 결함을 가릴 수 있다.
- **영향:** 후속 E2E가 시드 데이터를 전제로 할 때 처음 깨지며, T04 자체 완료 시점에는 핵심 운영 경로가 검증되지 않는다. 로컬 검증과 CI 준비 경로가 같은 조건을 보지 않는다.
- **근거:** T04는 CI를 다시 수정하지 않고 T03의 `db:setup`을 확장하는 설계를 명시한다. 따라서 조합 script 자체가 T04의 검증 대상이어야 한다.
- **권장 수정:** package script exact test에 `db:setup`의 정확한 명령과 순서를 추가하고, 개발 DB가 아닌 새 임시 DB에서 `DATABASE_URL=... env -u SEED_FORCE npm run db:setup`을 한 번 실행해 migration·WAL·9/10/27 seed 결과를 함께 검증한다.
- **수정 후 검증:** 잘못된 `db:setup` mutation(예: `db:seed` 제거)이 exact test 또는 임시 DB 완료 명령을 실패시키고, 정상 경로는 WAL 및 9/10/27 exact 테스트를 통과하는지 확인한다.

### 새 Finding 심각도 집계

| 심각도 | 건수 | ID |
|---|---:|---|
| P0 | 0 | — |
| P1 | 2 | RR-01, RR-02 |
| P2 | 1 | RR-03 |
| P3 | 0 | — |

## 태스크 간 충돌과 소유권 검증

- T01→T02→T03→T04 순서는 네 SPEC과 architecture 부록 A에서 일치한다 (`docs/specs/T01-scaffold.md:11-13`, `docs/specs/T02-test-harness.md:13-15`, `docs/specs/T03-prisma-schema.md:13-19`, `docs/specs/T04-seed.md:20-22`, `docs/architecture.md:779-783`).
- T02와 T03은 `package.json`, `package-lock.json`, `.gitignore`, CI를 공유하고 T03이 T02의 하니스를 사용하므로 병렬 구현할 수 없다.
- T03 테스트는 T02의 vitest, script, config, 배치 규약 없이는 실행할 수 없다고 명시됐다 (`docs/specs/T03-prisma-schema.md:17-19`).
- T04 통합 테스트는 T02 하니스와 T03 schema/client/helper를 모두 필요로 한다 (`docs/specs/T04-seed.md:11-18`).
- 네 태스크 모두 `package.json`을 순차 수정하고 T01~T03은 lockfile을 수정한다. 순차 Merge 규칙이 지켜지면 소유권 충돌은 제어된다.
- T02가 T01 파일을 건드리는 mutation은 임시 변경과 원복으로 한정되고 영구 변경이 금지됐다 (`docs/specs/T02-test-harness.md:341-345`).
- T04가 T03 소유 `src/server/prisma.test.ts`를 영구 수정하는 예외는 변경 목록과 정확한 배열 변경으로 명시됐다 (`docs/specs/T04-seed.md:32-37`, `docs/specs/T04-seed.md:238-249`). `tests/helpers/db.ts`의 역방향 수정은 금지됐다 (`docs/specs/T04-seed.md:400`).
- 테스트 파일 범위는 T02의 배치 규약과 일치하며 태스크 간 같은 테스트 파일의 우발적 중복 소유는 없다. 위 `src/server/prisma.test.ts`의 의도된 후속 수정만 예외다.
- T01 11개와 T03 13개의 파일 수 초과 사유는 각각 `.nvmrc` 추가와 구조 검증/생성 마이그레이션으로 실제 범위와 대응한다 (`docs/specs/T01-scaffold.md:34`, `docs/specs/T03-prisma-schema.md:42`).
- `afterCopyHook`은 테스트 전용 helper에만 있고 `beforeCreateHook`은 seed 함수의 rollback 검증용이며 운영 `main()` 전달이 금지되어, seam 자체가 제품 요청 경로를 오염시키지는 않는다. 다만 DR-12의 실패 정리 계약은 보완해야 한다.

## 구현 전 필수 수정

1. RR-01: `docs/requirements.md`를 복원하거나 권위 있는 요구사항 출처를 명시하고 네 SPEC을 다시 대조한다.
2. RR-02: T01의 ESLint 9 flat config/FlatCompat 전체 요구와 `no-explicit-any` 강제를 복원한다.
3. DR-03: Node 허용 정책과 테스트를 Playwright의 실제 지원 메이저에 맞춘다.
4. DR-07: SQLite enum의 ORM 수준 보장과 DB 수준 비보장을 architecture, decisions, T03에 동일하게 기록한다.
5. DR-11: 개발 DB 본체와 WAL/SHM sidecar 모두의 불변을 실패 경로에서도 검증하고 `SEED_FORCE`를 unset한다.
6. DR-12: template 생성 실패 정리, disconnect 실패 시 best-effort cleanup, 정확한 migration 자식 명령을 명세한다.
7. RR-03: T04의 `db:setup` 정확한 구성과 격리된 실행을 자동 검증한다.

## 확인하지 못한 항목

- `docs/requirements.md`가 없어 requirements와 설계·스펙의 정합성은 확인하지 못했다.
- 운영 코드와 package lockfile은 아직 없으므로 실제 설치 버전, macOS arm64 실행 결과, 생성 migration DDL은 실행 검증하지 않았다. 이는 이번 스펙 재검토의 범위 밖이며, 스펙이 요구하는 구현 완료 보고에서 검증해야 한다.
- Prisma `--shadow-database-url`의 상대 경로가 실제로 어느 기준에서 해석되는지는 T03이 명시한 완료 검사 전에는 확정하지 않았다. T03은 관찰 결과가 다르면 중단·보고하도록 요구하므로 현재는 조건부 전제로 남길 수 있다 (`docs/specs/T03-prisma-schema.md:225-233`, `:511`).

## 권장 다음 작업

다음 담당자는 **Claude**다. Claude가 이 문서의 DR-03, DR-07, DR-11, DR-12 및 RR-01~RR-03을 설계·스펙에서 해소한 뒤, Codex가 새 커밋을 다시 독립 검증해야 한다. 현재는 T01 구현 범위 승인 단계로 넘어가지 않는다.
