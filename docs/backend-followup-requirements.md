# 백엔드 후속 보강 요구사항

이 문서는 [`frontend-api-contract.md`](./frontend-api-contract.md)와 현재 새 백엔드의 동작을 기준으로, 프론트와 연결하기 전에 보강해야 하는 백엔드 요구사항을 정의한다. API wire contract와 내부 구현 방법을 섞지 않되, 장애 복구와 관측성처럼 외부 동작에 영향을 주는 규칙은 명시한다.

## 1. 토론 종료 후 커뮤니티 상태 복귀

토론이 시작될 때 커뮤니티는 `ACTIVE`가 되고, 토론이 terminal 상태가 되면 다시 `WAITING`으로 돌아가야 한다.

terminal 상태:

- 정상 종료: `COMPLETED`
- 기권: `FAILED` + `FORFEIT`
- 전체 시간 초과: `FAILED` + `TOTAL_TIME_EXPIRED`
- 판정 파이프라인 최종 실패: `FAILED`

상태 복귀는 토론 상태 전이와 같은 DB 트랜잭션 또는 조건부 갱신으로 처리한다. 중복 종료 이벤트가 와도 커뮤니티를 다시 `WAITING`으로 설정하는 것은 멱등이어야 한다.

동시에 다음을 보장한다.

- `debate.ended`는 debate room과 community room에 한 번만 전달한다.
- 기권·전체 timeout은 커뮤니티 시스템 메시지/이벤트에 원인과 debate ID를 포함한다.
- 종료 직후 `GET /communities/:communityId`와 목록 API가 `WAITING`을 반환한다.
- 이미 다른 활성 토론이 같은 커뮤니티에 존재하면 상태를 무조건 `WAITING`으로 덮어쓰지 않고 활성 토론을 기준으로 결정한다.

## 2. AI 호출 토큰·비용 로그

Analyzer, FactCheck, Judge 호출의 토큰 사용량과 응답 시간을 로그로 남긴다. 예측 비용 산정과 실험 수치로 활용한다.

AI 응답 완료 로그 필드:

- Analyzer: `debateId`, `turnIds`, `phase`, `round`, `durationMs`
- FactCheck: `stage`, `debateId`, `phase`, `round`, `targets`, `durationMs`
- Judge: `debateId`, `durationMs`
- 모든 단계 공통: `inputTokens`, `cachedTokens`, `outputTokens`, `thinkingTokens`, `totalTokens`

작업 처리 로그에는 기존 형식대로 `jobId`, `taskId`, `attempt`, `maxAttempts`, `retryDelayMs`, `durationMs`, `error`를 남긴다.

SDK가 thinking token을 제공하지 않는 기존 경우에는 현재 로그 형식인 `thinkingTokens=unknown`을 유지한다. 기존 로그에는 원화 비용 자체가 저장되지 않으므로, 비용은 로그의 token usage와 해당 호출 시점의 모델 가격표를 이용해 외부에서 계산한다.

이 로그는 동일 시나리오의 단계별 응답 시간·토큰·캐시 적중량을 비교하고, 재시도에 따른 비용을 산출하는 근거로 사용한다.

### 운영 정책 권고: FactCheck/grounding 상한

Grounding은 검색 대상과 출처가 늘수록 토큰 비용과 응답 시간이 커질 수 있으므로, 품질·비용 측정 결과에 따라 턴/배치의 FactCheck 대상 수와 결과 출처 수에 상한(예: 5개)을 두는 것을 권장한다. 이 상한은 프론트 API 계약이 아니라 환경변수로 조정 가능한 운영 정책으로 둔다.

기존 `heimdall_ai/backend`의 기본 제한은 다음과 같다.

- Analyzer 한 턴의 신규 component: 최대 10개
- 한 턴의 FactCheck target: 최대 5개
- FactCheck batch 전체 target: 최대 10개
- Grounding 검색 출처: 최대 5개
- 최종 FactCheck 결과 출처: 최대 5개

## 3. 검증 기준

- 토론 정상 종료/기권/전체 timeout/Judge 최종 실패 각각에서 커뮤니티가 올바른 상태로 복귀한다.
- 모든 AI 호출 로그에 기존 token usage 필드와 `durationMs`가 존재한다.

## 4. 기존 백엔드와 비교했을 때 누락된 보장

다음은 기존 백엔드가 제공하던 동작 중 새 백엔드에 빠져 있는 부분이다. 프론트 화면과의 호환때문에 보장이 요구된다.

### 4.1 시스템 알림의 DB 영속화

토론 시작, 정상 종료·결과, 기권, 전체 시간 초과 알림은 WebSocket broadcast만으로 처리하지 않는다. 커뮤니티 메시지 테이블에 시스템 메시지를 먼저 저장하고, 저장 성공 후 `message.created`와 `debate.ended`를 발행한다.

- 시스템 메시지는 `communityId`, `debateId`, `messageType`, `clientMessageId`, `createdAt`을 저장한다.
- `clientMessageId`는 `debate_started:{debateId}`, `debate_result:{debateId}`, `debate_forfeit:{debateId}`, `debate_timeout:{debateId}`처럼 결정적으로 만들어 중복 생성을 막는다.
- 재접속 replay와 커뮤니티 메시지 조회에서 시스템 메시지도 동일하게 반환한다.
- DB 저장과 debate/community 상태 전이는 같은 트랜잭션 또는 조건부 멱등 처리로 묶는다.

### 4.2 커뮤니티 메시지 작성 전제조건

커뮤니티 일반 메시지는 인증된 멤버라는 조건만으로 허용하지 않고, 해당 커뮤니티에 기조발언(opinion)을 작성한 멤버만 보낼 수 있어야 한다. 기조발언이 없으면 `403` 계열의 일관된 오류와 command ID를 반환하며 메시지를 저장하거나 broadcast하지 않는다.

### 4.3 판정 결과와 회원 점수 반영

기존 백엔드는 판정이 확정되면 승자의 회원 점수를 보상하고, 기권·시간 초과로 승자가 정해지는 경우에도 같은 보상을 반영했다. 새 백엔드도 결과 저장과 점수 갱신을 하나의 트랜잭션으로 처리해야 한다.

- `SIDE_A`/`SIDE_B` 승자에게만 정해진 승리 보상을 1회 반영한다.
- `DRAW`에는 승리 보상을 지급하지 않는다.
- 기권·시간 초과로 결정된 승자도 정상 판정 승자와 동일한 점수 정책을 적용한다.
- 동일 Judge 재시도나 중복 완료 요청으로 점수가 중복 증가하지 않도록 debate/judgment의 멱등 조건을 함께 확인한다.
- 점수 갱신 실패 시 판정 결과 완료와 커뮤니티 종료 상태 변경을 성공으로 확정하지 않는다.
