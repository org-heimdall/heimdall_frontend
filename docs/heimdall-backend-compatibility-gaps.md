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
