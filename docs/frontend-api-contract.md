# Heimdall 백엔드–프론트엔드 API 명세

이 문서는 백엔드 구현자가 프론트엔드와 합의된 HTTP REST API와 WebSocket 인터페이스를 구현·유지하기 위한 계약 명세다. 각 endpoint, 요청/응답 JSON schema, 이벤트 이름과 의미는 프론트가 소비하는 wire contract이므로 내부 DB·Redis·큐 구현과 분리해 관리한다. 기준 코드는 현재 `heimdall_ai/backend`의 controller/DTO/validator와 `heimdall_frontend`의 Dio/WebSocket data source다.

## 공통 규칙

- HTTP base URL은 프론트의 `API_BASE_URL`에 설정한다. 백엔드는 별도 global prefix를 사용하지 않으므로 아래 경로를 그대로 붙인다. WebSocket URL은 프론트의 `DEBATE_WEBSOCKET_BASE_URL`(토론)과 `WEBSOCKET_BASE_URL`(커뮤니티)에서 주입한다.
- 모든 HTTP 경로는 기본적으로 `Authorization: Bearer <accessToken>`이 필요하다. 예외는 `POST /auth/signup`, `/auth/login`, `/auth/refresh`, `/auth/logout`이다.
- 성공 응답은 JSON이며, `204` 응답은 본문이 없다.
- ID는 UUID 문자열이다. 날짜/시간은 ISO-8601 문자열이다.
- 일반 오류는 Nest 표준 `{ statusCode, message, error }` 형식이다. WebSocket 오류는 아래 `error` 이벤트를 사용한다.
- access token 만료 시 프론트 interceptor가 `POST /auth/refresh`로 교환한 뒤 원 요청을 재시도한다.

## 열거형

```ts
type CommunityStatus = 'WAITING' | 'ACTIVE' | 'CLOSED';
type CommunityMemberRole = 'HOST' | 'MEMBER';
type CommunityDebateIntent = 'OPEN_TO_DEBATE' | 'PREPARING';
type DebateStatus = 'READY' | 'IN_PROGRESS' | 'DEBATE_FINALIZED' | 'JUDGING' | 'COMPLETED' | 'FAILED';
type DebatePhase = 'OPENING' | 'REBUTTAL_QUESTION' | 'CLOSING';
type DebateSide = 'SIDE_A' | 'SIDE_B';
type VoteType = 'LIKE' | 'DISLIKE';
type VerificationStatus = 'SUPPORTED' | 'CONTRADICTED' | 'PARTIALLY_SUPPORTED' | 'INSUFFICIENT_EVIDENCE' | 'NOT_VERIFIABLE' | 'OUTDATED';
type JudgmentWinner = 'SIDE_A' | 'SIDE_B' | 'DRAW';
```

## REST API

아래 endpoint는 HTTP 요청/응답 인터페이스다. 모든 경로는 HTTP base URL 뒤에 붙인다.

### 인증 API

| method | endpoint | request | response |
|---|---|---|---|
| POST | `/auth/signup` | `SignUpMemberRequest` | `AuthTokenResponse` (201) |
| POST | `/auth/login` | `{ email, password }` | `AuthTokenResponse` (200) |
| POST | `/auth/refresh` | `{ refreshToken }` | `AuthTokenResponse` (200) |
| POST | `/auth/logout` | `{ refreshToken }` | empty (204) |

```ts
interface SignUpMemberRequest { email: string; password: string; displayName: string; profileImageUrl?: string|null; gender?: string|null; age?: number|null }
interface AuthTokenResponse { member: Member; accessToken: string; refreshToken: string }
interface Member { id: string; email: string|null; displayName: string; profileImageUrl: string|null; gender: string|null; age: number|null; score: number; createdAt: string; updatedAt: string }
```

Validation highlights: email 형식/최대 320자, password 최소 8자(로그인은 1자)/최대 UTF-8 72바이트, signup displayName 최대 20자, age 0–150.

### 회원 API

| method | endpoint | request | response |
|---|---|---|---|
| POST | `/members` | `{ displayName, profileImageUrl? }` | `Member` (201) |
| GET | `/members` | — | `Member[]` (200) |
| GET | `/members/:memberId` | — | `Member` (200) |
| PATCH | `/members/:memberId` | `{ displayName?; profileImageUrl?: string|null }` | `Member` (200) |
| DELETE | `/members/:memberId` | — | empty (204) |

PATCH/DELETE는 토큰의 사용자와 `memberId`가 같아야 한다. displayName 최대 100자, profileImageUrl 최대 1000자.

### 커뮤니티 API

| method | endpoint | request/query | response |
|---|---|---|---|
| POST | `/communities` | `CreateCommunityRequest` | `Community` (201) |
| GET | `/communities` | — | `Community[]` (200) |
| GET | `/communities/:communityId` | — | `Community` (200) |
| POST | `/communities/:communityId/members/me` | — | empty (204) |
| DELETE | `/communities/:communityId/members/me` | — | empty (204) |
| GET | `/communities/:communityId/members` | — | `CommunityMember[]` (200) |
| PUT | `/communities/:communityId/members/me/debate-intent` | `{ debateIntent }` | empty (204) |
| GET | `/communities/:communityId/messages` | `limit`(default 50), `before`(ISO optional) | `CommunityMessage[]` (200) |
| POST | `/communities/:communityId/messages` | `{ clientMessageId, text }` | `CommunityMessage` (201) |
| GET | `/communities/:communityId/opinions` | — | `CommunityOpinion[]` (200) |
| PUT | `/communities/:communityId/opinions/me` | `{ claim, reasons }` | `CommunityOpinion` (200) |

```ts
interface CreateCommunityRequest { title: string; topic: string; category: string; rounds: number; isPublic: boolean; hostClaim: string; hostReasons: string[] }
interface Community { id: string; title: string; topic: string; category: string; status: CommunityStatus; rounds: number; isPublic: boolean; hostClaim: string; hostReasons: string[]; host: { id: string; displayName: string }; participantPreviews: ParticipantPreview[]; memberCount: number; createdAt: string; isOwnedByCurrentUser: boolean; isJoined: boolean }
interface ParticipantPreview { id: string; displayName: string; profileImageUrl: string|null }
interface CommunityMember { id: string; displayName: string; profileImageUrl: string|null; role: CommunityMemberRole; debateIntent: CommunityDebateIntent; joinedAt: string }
interface CommunityMessage { id: string; communityId: string; clientMessageId: string; authorId: string; authorName: string; text: string; messageType: string; debateId: string|null; createdAt: string }
interface CommunityOpinion { id: string; communityId: string; authorId: string; authorName: string; claim: string; reasons: string[]; createdAt: string; updatedAt: string; action?: 'CREATED'|'UPDATED' }
```

Create 제한: `rounds` 1–9, title ≤200, topic ≤5000, category ≤30, hostClaim ≤2000, hostReasons는 비어 있지 않은 문자열 최대 10개. 메시지 text ≤2000, opinion claim/reason ≤2000, reasons 최대 10개.

### 커뮤니티 토론 초대 API

| method | endpoint | request | response |
|---|---|---|---|
| POST | `/communities/:communityId/debates/start` | `{ opponentMemberId }` | `DebateInvitation` (201) |
| GET | `/communities/:communityId/debates/active` | — | `DebateDetail \| null` (200) |
| POST | `/communities/:communityId/debates/:invitationId/accept` | — | `DebateDetail` (201) |
| POST | `/communities/:communityId/debates/:invitationId/reject` | — | empty (204) |

```ts
interface DebateInvitation { id: string; communityId: string; hostMemberId: string; hostName: string; opponentMemberId: string; expiresAt: string }
```

5초 대기 화면의 계약은 별도 endpoint가 아니라 다음 조합이다.

1. 방장 화면이 `POST /communities/:communityId/debates/start`를 호출해 `DebateInvitation`을 받는다.
2. 초대받은 사용자 화면은 커뮤니티 WebSocket의 `debate.requested` 이벤트(`{ communityId, invitation: DebateInvitation }`)를 받아 5초 응답 UI를 표시한다.
3. 수락은 `POST .../:invitationId/accept`, 거절은 `POST .../:invitationId/reject`다.
4. 5초 내 응답이 없으면 백엔드가 양쪽에 `{ communityId, invitationId }` 형태의 `debate.request.expired`를 보낸다. 명시적 거절은 방장에게 `{ communityId, invitationId, opponentMemberId }` 형태의 `debate.request.rejected`를 보낸다. 수락 완료 후에는 양쪽에 `debate.started`와 `{ debateId, sideASpeaker, sideBSpeaker, startedAt, expiresAt }`를 보낸다.

따라서 5초 카운트다운은 프론트 UI 타이머이고, 실제 만료 여부는 백엔드의 `expiresAt`와 만료 이벤트를 기준으로 처리한다.

### 토론 API

| method | endpoint | request/query | response |
|---|---|---|---|
| POST | `/debates` | `CreateDebateRequest` | `Debate` (201) |
| GET | `/debates` | `?status=DebateStatus` optional | `Debate[]` (200) |
| GET | `/debates/:debateId` | — | `DebateDetail` (200) |
| GET | `/debates/:debateId/turns` | — | `DebateTurnWithVotes[]` (200) |
| GET | `/debates/:debateId/result` | — | `DebateResult` (200) |
| POST | `/debates/:debateId/start` | — | `Debate` (200) |
| POST | `/debates/:debateId/judging` | — | `Debate` (200) |
| POST | `/debates/:debateId/forfeit` | — | empty (204) |
| PUT | `/debates/:debateId/turns/:turnId/vote` | `{ type: VoteType }` | `VoteSummary` (200) |
| DELETE | `/debates/:debateId/turns/:turnId/vote` | — | `VoteSummary` (200) |

```ts
interface CreateDebateRequest { communityId: string; topic: string; sideASpeakerId: string; sideBSpeakerId: string; rebuttalQuestionRounds: number }
interface Debate { id: string; communityId: string; topic: string; sideASpeakerId: string; sideBSpeakerId: string; rebuttalQuestionRounds: number; status: DebateStatus; currentPhase: DebatePhase|null; currentRound: number|null; currentTurnSide: DebateSide|null; currentTurnStartedAt: string|null; createdAt: string; startedAt: string|null; endedAt: string|null; judgingStartedAt: string|null; expiresAt: string|null }
interface DebateDetail extends Debate { sideASpeaker: DebateSpeaker; sideBSpeaker: DebateSpeaker; viewerSide: DebateSide|null; turns: DebateTurnWithVotes[] }
interface DebateSpeaker { id: string; displayName: string; profileImageUrl: string|null; score: number; claim: string; reasons: string[] }
interface DebateTurnWithVotes extends DebateTurn { likeCount: number; dislikeCount: number }
interface VoteSummary { turnId: string; likeCount: number; dislikeCount: number }
interface DebateResult { debate: Debate; viewerSide: DebateSide|null; judgmentResult: JudgmentResult; factChecks: FactCheckResult[] }
```

`CreateDebateRequest.topic` 최대 500자, 양쪽 speaker/community ID는 UUID이고 서로 달라야 한다. `forfeit` 등 사용자 행위는 인증된 사용자 권한을 추가로 검사한다.

### 판정 API

| method | endpoint | request | response |
|---|---|---|---|
| POST | `/debates/:debateId/judge` | — | `JudgmentResult` (200); 아직 실행 중이면 409 |
| POST | `/debates/:debateId/judge/retry` | — | `JudgmentResult` (200); 재시도 불가/진행 중이면 409 |

```ts
interface JudgmentResult { id: string; debateId: string; winner: JudgmentWinner; sideAArgumentationScore: number; sideAInteractionScore: number; sideAFactualReliabilityScore: number; sideATotalScore: number; sideBArgumentationScore: number; sideBInteractionScore: number; sideBFactualReliabilityScore: number; sideBTotalScore: number; overallReason: string; sideAFeedback: string; sideBFeedback: string; judgedAt: string }
interface FactCheckSource { title: string; publisher: string; url: string }
interface FactCheckResult { id: string; componentId: string; speakerId: string; speakerSide: DebateSide; statement: string; status: VerificationStatus; reason: string; sources: FactCheckSource[]; checkedAt: string }
```

### 토론 채팅 HTTP snapshot

| method | endpoint | request | response |
|---|---|---|---|
| GET | `/debates/:debateId/chat` | — | `DebateChatSnapshot` (200) |
| POST | `/debates/:debateId/chat/messages` | `DebateTurnMessageSendCommand` 또는 flat command | `DebateTurnMessageAppendResult` (200) |
| POST | `/debates/:debateId/chat/finalize` | finalize command | `DebateChatTurn` (200) |

```ts
interface DebateChatSnapshot { currentTurn: CurrentTurn|null; turns: DebateChatTurn[]; draftMessages: DraftMessage[] }
interface CurrentTurn { phase: DebatePhase; round: number; turnSide: DebateSide; startedAt: string; maxDurationSeconds: number; maxTotalCharacters: number }
interface DraftMessage { id: string; debateId: string; clientMessageId?: string; speakerId: string; speakerSide: DebateSide; phase: DebatePhase; round: number; content: string; createdAt: string }
interface DebateChatTurn extends DraftMessage { sequence: number }
interface DebateTurnMessageAppendResult { status: 'APPENDED'|'DUPLICATE'; message: DraftMessage }
```

메시지 command의 `payload`에는 `speakerId`, `speakerSide`, `phase`, `round`, `content`가 들어간다. 서버는 Bearer 토큰의 member와 speakerId가 다르면 거부하고, content 최대 길이는 환경변수 `DEBATE_TURN_MAX_CONTENT_LENGTH`(현재 기본 500)이다.

## WebSocket API

서버는 `DEBATE_CHAT_WS_PORT`(기본 8080)의 단일 WebSocket 서버를 열며, 프론트는 다음 경로로 연결한다. 인증은 handshake의 `Authorization: Bearer <accessToken>` 헤더다.

### 연결 경로

- 토론 채팅: `ws(s)://<host>:<port>/debates/:debateId/chat`
- 커뮤니티 채팅: `ws(s)://<host>:<port>/communities/:communityId/chat`

### 토론 채팅 client command

```ts
{ id: string; type: 'debate.turn.send'|'debate.turn.message.send'; clientMessageId?: string; payload: { speakerId: string; speakerSide: DebateSide; phase: DebatePhase; round: number; content: string }; sentAt?: string }
{ id: string; type: 'debate.turn.finalize'; payload: { speakerId: string; speakerSide: DebateSide; phase: DebatePhase; round: number } }
```

### 토론 채팅 server event

| type | payload |
|---|---|
| `connection.restored` | `{ debateId, currentTurn, turns, draftMessages }` |
| `debate.turn.message.ack` | `{ debateId, commandId, clientMessageId?, status, message }` |
| `debate.turn.message.created` | `{ debateId, message }` |
| `debate.turn.finalized` | `{ debateId, turn }` |
| `debate.processing.stage` | `{ debateId, stage: 'ANALYZER'\|'FACT_CHECK'\|'JUDGE', status: 'STARTED'\|'RETRYING'\|'COMPLETED'\|'FAILED', attempt, message, occurredAt }` |
| `debate.ended` | `{ communityId, debateId, status, reason }` |
| `error` | `{ debateId?, commandId?, code, message }` |

### 커뮤니티 채팅 client command

```ts
{ id: string; type: 'message.send'; clientMessageId: string; payload: { text: string } }
{ id: string; type: 'opinion.submit'; payload: { claim: string; reasons: string[] } }
```

### 커뮤니티 채팅 server event

| type | payload |
|---|---|
| `message.created` | `{ communityId, message: CommunityMessage }` |
| `community.message.ack` | `{ communityId, commandId, clientMessageId, status: 'STORED'\|'DUPLICATE', message }` |
| `opinion.submitted` | `{ communityId, opinion: CommunityOpinion }` |
| `community.opinion.ack` | `{ communityId, commandId, status: 'STORED', opinion }` |
| `community.member.debate-intent.changed` | `{ communityId, member: CommunityMember }` |
| `debate.started` / `debate.requested` / `debate.request.rejected` / `debate.request.expired` | 이벤트별 초대/토론 식별자와 서버 payload |
| `debate.ended` | `{ communityId, debateId, status, reason }` |
| `error` | `{ communityId?, commandId?, code, message }` |

커뮤니티 WebSocket 접속 시 서버가 최근 메시지(최대 50개)와 현재 의견 목록을 각각 `message.created`, `opinion.submitted` 이벤트로 replay한다. 따라서 재접속 복구는 HTTP가 아니라 이 초기 WebSocket replay도 함께 고려해야 한다.

## 구현 참고 (API 계약 외)

내부 구현 설계와 현재 구현 예시는 별도 문서로 분리했습니다: [backend-internal-design.md](./backend-internal-design.md). 이 문서는 REST/WebSocket 외부 계약만 정의하며, 백엔드 내부 저장소·큐·동시성·broadcast 구현은 별도 문서를 참고합니다.

## 프론트 연동 검증 기준

백엔드 변경 시 다음을 회귀 검증한다. 프론트는 `auth`, `/communities` 목록/상세·멤버·메시지·의견·초대, `/debates/:id` 상세/결과/turn/vote/forfeit/judge-retry, 그리고 두 WebSocket 채팅 경로를 사용한다. 응답 mapper는 서버의 `sideA*`, `sideB*`, `judgmentResult`, `factChecks`, `participantPreviews` 필드를 그대로 읽으므로 필드명·타입·nullability·enum 값을 임의로 변경하지 않는다.
