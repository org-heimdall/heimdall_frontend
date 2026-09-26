# `heimdall_backend` 연동 수정 요구사항

이 문서는 현재 프론트(`heimdall_frontend`)가 기대하는 wire format과 새 백엔드(`heimdall_backend`)의 구현 사이의 차이를 정리한 수정 요구사항이다. 기준 계약은 [frontend-api-contract.md](./frontend-api-contract.md)이며, 아래 항목은 내부 DB·Redis 구현이 아니라 프론트와 직접 맞춰야 하는 외부 인터페이스 문제다.

## 1. 요약

현재 프론트의 WebSocket client command는 room ID와 클라이언트 시각을 전송하지 않고, 다음처럼 보낸다.

```json
{
  "id": "command-id",
  "type": "message.send",
  "clientMessageId": "client-message-id",
  "payload": { "text": "메시지" }
}
```

이 command 형식은 `heimdall_backend`의 DTO와 호환된다. 그러나 서버 event 응답은 현재 호환되지 않는다.

## 2. WebSocket server event envelope 불일치

### 현재 `heimdall_backend` 구현

```json
{
  "type": "community.message.ack",
  "payload": {
    "communityId": "...",
    "commandId": "...",
    "clientMessageId": "...",
    "status": "STORED",
    "message": {}
  }
}
```

구현 근거: `src/common/ws/ws-event.ts`의 `WsServerEvent<T> { type, payload }` 및 각 publisher/gateway.

### 프론트가 기대하는 형식

```json
{
  "type": "community.message.ack",
  "communityId": "...",
  "commandId": "...",
  "clientMessageId": "...",
  "status": "STORED",
  "message": {}
}
```

프론트는 `community_chat_realtime_repository_impl.dart`, `community_chat_realtime_client.dart`, `debate_chat_event_mapper.dart`에서 event 데이터를 최상위 필드로 읽는다.

### 백엔드 수정 요구

다음 중 하나를 선택해야 한다.

1. `heimdall_backend`가 기존 계약대로 flat event를 전송한다. **권장**
2. 프론트의 모든 WebSocket parser와 ACK resolver를 `{ type, payload }` envelope에 맞게 수정한다.

두 구현을 동시에 유지하지 말고 하나의 event envelope를 계약으로 고정해야 한다.

## 3. WebSocket event별 요구사항

`heimdall_backend`의 모든 event는 아래처럼 payload 내용을 최상위로 펼쳐 전송해야 한다.

| event | 최상위에 있어야 하는 필드 |
|---|---|
| `community.message.ack` | `communityId`, `commandId`, `clientMessageId`, `status`, `message` |
| `message.created` | `communityId`, `message` |
| `community.opinion.ack` | `communityId`, `commandId`, `status`, `opinion` |
| `opinion.submitted` | `communityId`, `opinion` |
| `debate.turn.message.ack` | `debateId`, `commandId`, `clientMessageId?`, `status`, `message` |
| `debate.turn.message.created` | `debateId`, `message` |
| `connection.restored` | `debateId`, `currentTurn`, `turns`, `draftMessages` |
| `debate.turn.finalized` | `debateId`, `turn` |
| `debate.processing.stage` | `debateId`, `stage`, `status`, `attempt`, `message`, `occurredAt` |
| `debate.ended` | `communityId`, `debateId`, `status`, `reason` |
| `error` | `communityId?` 또는 `debateId?`, `commandId?`, `code`, `message` |

## 4. event ID 요구사항

프론트 domain event 모델은 모든 WebSocket event에 `id`가 있다고 가정한다. 현재 `heimdall_backend/src/common/ws/ws-event.ts`의 `WsServerEvent`에는 `id`가 없다.

백엔드는 모든 server event에 고유한 `id`를 추가해야 한다.

```ts
interface WsServerEvent<TPayload> {
  id: string;
  type: string;
  // flat contract를 사용할 경우 payload 필드는 전송하지 않는다.
}
```

`id`는 재접속 replay와 실시간 event 중복 제거에 사용한다.

## 5. ACK 및 broadcast 규칙

- ACK의 `commandId`는 client command의 `id`와 같아야 한다.
- ACK는 command를 보낸 socket에만 보낸다.
- `message.created`와 `debate.turn.message.created`는 저장 성공 시 송신자를 제외한 room에 broadcast한다.
- `debate.turn.finalized`와 `debate.processing.stage`는 debate room 전체에 broadcast한다.
- `community.opinion.ack`는 송신자에게, `opinion.submitted`는 다른 커뮤니티 연결자에게 보낸다.
- 같은 `clientMessageId`의 메시지는 `DUPLICATE` ACK만 반환하고 새 created event를 보내지 않는다.
- 오류는 원 command의 `commandId`를 포함해야 프론트가 pending command를 종료할 수 있다.

## 6. REST 확인사항

현재 확인된 REST 경로는 프론트와 새 백엔드가 대체로 일치한다.

- `/auth/*`
- `/communities/*`
- `/communities/:communityId/debates/*`
- `/debates/:debateId/*`
- `/members/*`

다만 실제 연결 전 다음 응답 DTO를 프론트 mapper와 대조해야 한다.

- `CommunityDto`의 `participantPreviews`, `host`, `isJoined`, `isOwnedByCurrentUser`
- `DebateDetailDto`의 `sideASpeaker`, `sideBSpeaker`, `viewerSide`
- `DebateResultDto`의 `judgmentResult`, `factChecks`
- `CommunityMessageDto`의 `authorName`, `messageType`, `debateId`

REST 경로가 같아도 필드명·nullability·enum이 다르면 프론트에서 별도 수정이 필요하다.

### 추가로 확인된 REST/DTO 불일치

1. **커뮤니티 category 값과 themes 의미가 다르다.**
   프론트는 `POLITICS` 같은 대문자 category code를 전송하지만, 새 백엔드의
   `CreateCommunityDto.category`는 `GET /communities/themes`가 반환하는 theme name을
   받도록 구현되어 있다. 백엔드는 안정적인 enum/code를 받도록 바꾸거나, 프론트가
   themes 조회 결과의 ID/name을 사용하도록 계약을 하나로 확정해야 한다.

2. **커뮤니티 host의 프로필 이미지가 응답에서 누락된다.**
   프론트 `CommunityResponseMapper`와 상세 화면은 `host.profileImageUrl`을 읽지만,
   새 백엔드 `CommunityHostDto`는 `id`, `displayName`만 반환한다. `profileImageUrl: string | null`
   을 DTO와 `CommunityDto.from()` 결과에 추가해야 한다(또는 프론트에서 해당 필드를
   선택 사항으로 명시적으로 처리해야 한다).

3. **커뮤니티 messageType enum 값이 다르다.**
   프론트는 `DEBATE_STARTED`, `DEBATE_RESULT`, `DEBATE_FORFEIT`, `DEBATE_TIMEOUT` 같은
   시스템 메시지 타입을 별도로 렌더링한다. 새 백엔드는 현재 `text`, `system`,
   `opinionNotice`만 사용한다. 시스템 알림을 동일하게 렌더링하려면 백엔드 enum/event
   값을 프론트 계약에 맞추거나, 프론트 mapper가 새 enum을 명시적으로 변환해야 한다.

4. **커뮤니티 목록 pagination 기본값이 프론트 가정과 다르다.**
   새 백엔드 `GET /communities`는 기본 `page=1`, `size=10`으로 최대 10개만 반환한다.
   현재 프론트는 query 없이 한 번 호출한 결과를 전체 목록으로 간주한다. 백엔드가
   전체 목록을 반환하도록 계약을 바꾸거나, 프론트가 `page`/`size`를 전달하고 페이지를
   합치는 처리가 필요하다.

5. **방장의 토론 의사 상태와 토론 시작 권한이 어긋난다.**
   프론트의 토론 시작 화면은 현재 사용자가 방장이고 상대가 `OPEN_TO_DEBATE`이면
   `토론하기`를 제공한다. 방장 자신의 `debateIntent`가 `PREPARING`인지 여부로 시작
   버튼을 막지 않는다.

   이 동작은 기존 `heimdall_ai/backend`의 `startCommunityDebate()`와도 일치한다.
   기존 시작 로직은 방장 권한과 상대의 `OPEN_TO_DEBATE`만 확인하고, 방장 자신의
   `debateIntent`는 시작 조건으로 검사하지 않았다. 따라서 방장이 `준비할래요`인
   상태에서도 방장이 토론을 시작하고 상대를 초대할 수 있었다.

   `준비할래요`는 해당 멤버가 현재 토론에 참여하지 못하거나 참여 의사가 없음을
   알리는 상태이지, 커뮤니티 방장의 토론 시작 권한을 제거하는 상태가 아니다. 토론
   시작권이 방장에게 있는 현재 UX에서는 방장이 `준비할래요`인 상태에서 상대를
   초대하고 토론을 진행하는 것이 자연스럽다.

   반면 새 `heimdall_backend`는 `start()`에서 방장과 상대 모두
   `OPEN_TO_DEBATE`인지 검사한다. 방장이 `PREPARING`이면
   `DEBATE_INVITATION.HOST_NOT_OPEN_TO_DEBATE`(409)를 반환하고, 프론트에는 현재
   상세 오류 대신 `토론을 시작하지 못했습니다.`가 표시된다.

   **수정 요구:** `POST /communities/:communityId/debates/start`에서는 방장 자신의
   `debateIntent`를 시작 조건에서 제외한다. 방장 권한·커뮤니티 소속·상대의
   `OPEN_TO_DEBATE` 검사는 유지한다. 초대 수락 시 상대방의 현재 참여 의사를 다시
   확인하는 정책은 기존 동작과 별도로 유지한다.

6. **토론 시작 후 10초 웜업 시간이 누락되어 있다.**
   기존 백엔드는 초대 수락 후 첫 턴을 즉시 시작하지 않고, `startedAt`과 첫 턴의
   시작 시각을 현재 시각보다 10초 뒤로 설정했다. 프론트는 이 미래 시각을 기준으로
   카운트다운을 표시하고, 웜업 동안 입력창을 비활성화한다.

   기존 프론트가 기대하는 웜업 UX는 다음과 같다.

   - `토론자가 결정되었습니다.` 안내
   - `N초 뒤, 비프로스트의 문이 열립니다.` 카운트다운
   - `잠시 후 입론을 시작할 수 있습니다` placeholder
   - 웜업 중 발언 입력·전송 비활성화

   기존 `heimdall_ai/backend`는 `DEBATE_PREPARATION_DURATION_MS = 10 * 1000`과
   `getDebateStartsAt()`으로 이 계약을 제공한다. 반면 새 `heimdall_backend`의
   `DebateChatState.start()`는 `startedAt = now`로 즉시 시작하므로, 현재 프론트에서는
   웜업 없이 첫 턴 시간이 바로 흐른다.

   **수정 요구:** 초대 수락으로 토론을 시작할 때 첫 턴 시작 시각을 현재 시각보다
   10초 뒤로 설정하고, `startedAt`, `currentTurnStartedAt`, `expiresAt` 계산이 이
   지연을 일관되게 반영하도록 한다. 웜업 중에는 턴 제한 시간이 차감되지 않아야 하며,
   재접속·복구 시에도 동일한 미래 시작 시각을 기준으로 남은 시간을 계산해야 한다.

현재 위 네 항목 외에, 수정된 프론트 command JSON에서 새 백엔드 DTO에 없는 추가 필드는
확인되지 않았다. `communityId`/`debateId`와 `sentAt`은 wire command에서 제거했고,
room ID는 WebSocket URL 라우팅에만 사용한다.

## 7. 완료 조건

- [ ] server event envelope를 flat 구조로 확정
- [ ] 모든 event에 고유 `id` 추가
- [ ] ACK의 `commandId` 및 송신자 routing 검증
- [ ] duplicate message의 `DUPLICATE` 처리 검증
- [ ] 커뮤니티 replay와 토론 snapshot의 field shape 검증
- [ ] REST DTO를 프론트 mapper와 대조하는 통합 테스트 추가
- [ ] category/theme 값 체계 확정
- [ ] `host.profileImageUrl` 응답 추가 또는 프론트 optional 처리
- [ ] `messageType` enum 체계 통일
- [ ] 커뮤니티 목록 pagination 계약 확정
- [ ] 방장이 `PREPARING`이어도 상대가 `OPEN_TO_DEBATE`이면 토론 초대가 생성되는지 통합 테스트
- [ ] 토론 시작 시 10초 웜업과 첫 턴 입력 잠금·카운트다운 통합 테스트
