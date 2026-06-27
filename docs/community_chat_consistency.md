# Community Chat Consistency Notes

이 문서는 커뮤니티 채팅 개발 과정에서 중복 이벤트 처리, 재실행/재연결 시 데이터 정합성, 멱등성을 고려한 로직을 코드 기준으로 정리한다.

## Message Identity

채팅 메시지는 두 종류의 식별자를 가진다.

- `id`: 서버가 DB에 저장하면서 발급한 메시지 ID
- `clientMessageId`: 클라이언트가 전송 직전에 만든 임시 ID

관련 코드:

- `CommunityChatMessage.id`
- `CommunityChatMessage.clientMessageId`
- `SendCommunityChatMessageRequest.clientMessageId`
- `CommunityChatCommand.clientMessageId`

의도:

- 전송 직후에는 서버가 발급한 메시지 ID가 아직 없으므로 `clientMessageId`로 pending 메시지를 식별한다.
- 서버가 같은 `clientMessageId`를 포함한 `message.created` 이벤트를 push하면 기존 pending 메시지를 교체한다.
- 서버 이벤트가 중복 도착해도 같은 `id` 또는 `clientMessageId`를 기준으로 새 메시지를 중복 추가하지 않는다.

## Optimistic Send

사용자가 메시지를 보내면 화면은 서버 응답을 기다리지 않고 즉시 pending 말풍선을 추가한다.

관련 코드:

- `_send`
- `_sendText`
- `_startPendingTimeout`
- `_cancelPendingTimeout`
- `_retryMessage`
- `CommunityChatMessageDeliveryStatus.pending`
- `CommunityChatMessageDeliveryStatus.failed`
- `sendCommunityChatMessageProvider`
- `WebSocketCommunityChatRepository`
- `CommunityChatCommand`

동작:

1. 입력값이 비어 있으면 전송하지 않는다.
2. `clientMessageId`를 만든다.
3. pending 메시지를 `_messages`에 추가한다.
4. `clientMessageId` 기준 10초 pending timeout을 시작한다.
5. WebSocket `message.send` command를 보낸다.
6. command 전송 자체가 실패하면 같은 `clientMessageId`를 가진 메시지를 `failed`로 바꾼다.
7. command 전송은 성공했지만 10초 안에 같은 `clientMessageId`의 서버 push가 오지 않아도 `failed`로 바꾼다.
8. 실패 메시지의 `전송 실패 · 다시 보내기`를 누르면 기존 failed 메시지를 제거하고 새 `clientMessageId`로 다시 보낸다.

정합성 포인트:

- 전송 실패가 발생해도 사용자가 입력한 메시지는 화면에 남는다.
- 실패 표시는 같은 pending 메시지 객체를 `copyWith`로 갱신한다.
- 사용자는 어떤 메시지가 실패했는지 유지된 위치에서 확인할 수 있다.
- send command 성공은 메시지 확정으로 보지 않는다. 서버가 DB 저장 후 push한 메시지가 도착해야 pending이 확정된다.
- 서버 push가 누락된 경우를 대비해 프론트 단에서 10초 timeout을 둔다.

## Outbound Command Shape

프론트가 서버로 보내는 WebSocket payload는 `CommunityChatCommand`다.

관련 코드:

- `CommunityChatCommand`
- `CommunityChatCommandType.messageSend`
- `CommunityChatCommand.toJson`
- `WebSocketCommunityChatRepository.sendMessage`
- `CommunityChatRealtimeClient.send`

현재 전송 형태:

```json
{
  "id": "command-client-123",
  "type": "message.send",
  "communityId": "room-2",
  "clientMessageId": "client-123",
  "authorId": "user-1",
  "payload": {
    "text": "hello"
  },
  "sentAt": "2026-06-23T10:00:00.000Z"
}
```

정합성 포인트:

- `clientMessageId`는 서버 저장 결과 push와 optimistic 메시지를 합치기 위한 멱등성 키다.
- `id`는 command 자체의 식별자이고, 서버가 DB 저장 후 발급하는 메시지 `id`와 다르다.
- 서버는 같은 `clientMessageId`의 중복 command를 받으면 새 메시지를 중복 생성하지 않고 기존 저장 결과를 반환하거나 같은 이벤트를 다시 push하는 정책이 필요하다.

## Server Push Merge

서버 이벤트는 `_mergeRealtimeEvent`에서 타입별로 처리하고, 메시지 생성/수정/기조발언 알림은 `_upsertMessage`로 합친다.

관련 코드:

- `_mergeRealtimeEvent`
- `_upsertMessage`
- `CommunityChatEventType.messageCreated`
- `CommunityChatEventType.messageUpdated`
- `CommunityChatEventType.openingStatementCreated`

중복 방지 순서:

1. `incoming.clientMessageId`가 있으면 기존 메시지의 `clientMessageId`와 먼저 비교한다.
2. 없거나 찾지 못하면 서버 `id`로 비교한다.
3. 둘 다 없으면 새 메시지로 추가한다.
4. 찾으면 기존 메시지를 서버가 준 최신 메시지로 교체한다.

이 순서는 내 optimistic 메시지와 서버 push 메시지의 중복 생성을 막기 위한 것이다.

pending timeout 정리:

- 같은 `clientMessageId`의 서버 push가 오면 `_cancelPendingTimeout`으로 실패 전환 예약을 취소한다.
- 서버 push 메시지는 pending 메시지를 교체하므로 `deliveryStatus`도 서버가 준 확정 상태로 바뀐다.
- timeout이 먼저 실행되어 failed가 된 뒤 같은 `clientMessageId`의 서버 push가 늦게 도착해도 `_upsertMessage`가 같은 메시지로 찾아 교체한다.

## Delete Event Handling

삭제 이벤트는 서버 메시지 ID 기준으로 제거한다.

관련 코드:

- `_mergeRealtimeEvent`
- `CommunityChatEventType.messageDeleted`
- `_messages.removeWhere((item) => item.id == message.id)`

정합성 포인트:

- 서버가 삭제한 메시지와 같은 `id`를 가진 로컬 메시지만 제거한다.
- 다른 클라이언트 pending 메시지나 unrelated 메시지는 건드리지 않는다.

## Time Ordering

화면 렌더링은 `_messages` 원본 삽입 순서가 아니라 `createdAt` 기준 정렬 결과를 사용한다.

관련 코드:

- `_orderedMessages`
- `CommunityChatMessage.createdAt`
- `CommunityChatMessageType.openingStatementNotice`

의도:

- 일반 채팅과 시스템 메시지를 같은 타임라인에 배치한다.
- `"Username3 님이 기조 발언을 작성했습니다."` 같은 알림도 실제 생성 시간에 맞춰 채팅 사이에 나타난다.
- WebSocket 이벤트가 늦게 도착해도 서버 시간이 있으면 표시 순서가 보정된다.

## System Message Consistency

기조발언 알림은 별도 UI 하드코딩이 아니라 `CommunityChatMessage`의 한 타입으로 저장한다.

관련 코드:

- `CommunityChatMessageType.openingStatementNotice`
- `CommunityChatMessage.relatedUserId`
- `_DiscussionGuide`
- `MockCommunityChatRealtimeRepository._parseOpeningStatementNotice`

정합성 포인트:

- 알림도 `id`, `communityId`, `createdAt`을 가진다.
- 알림의 버튼은 `relatedUserId`를 사용해 주체 사용자 프로필을 연다.
- 같은 알림 이벤트가 다시 와도 `id` 기준으로 중복 추가하지 않고 교체된다.

## Community Boundary

실시간 이벤트는 현재 보고 있는 커뮤니티와 같은 `communityId`일 때만 반영한다.

관련 코드:

- `_mergeRealtimeEvent`
- `if (!mounted || event.communityId != widget.community.id) return;`

의도:

- 다른 커뮤니티 채팅방 이벤트가 현재 화면 메시지 목록에 섞이지 않게 한다.
- WebSocket 구독 또는 서버 이벤트 라우팅에 문제가 있어도 화면 단에서 한 번 더 방어한다.

## Reconnect Behavior

WebSocket 클라이언트는 연결 오류가 발생하면 제한된 횟수로 재연결한다.

관련 코드:

- `WebSocketCommunityChatRealtimeClient.subscribe`
- `reconnectDelay`
- `maxReconnectAttempts`
- `_connect`
- `_sockets`

동작:

- 채팅방별 열린 socket을 `_sockets[communityId]`로 재사용한다.
- subscribe와 send가 같은 채팅방 WebSocket 연결을 공유한다.
- 오류가 나면 `reconnectDelay * attempts`로 선형 backoff 후 재시도한다.
- 재시도 횟수가 `maxReconnectAttempts`를 넘으면 stream error로 올린다.

정합성 포인트:

- 연결이 끊겨도 즉시 화면 상태를 초기화하지 않는다.
- 이미 받은 메시지 목록은 유지한다.
- 재연결 후 서버가 같은 이벤트를 다시 보내도 `_upsertMessage`가 중복을 줄인다.
- 재연결 전후에 pending 메시지는 `clientMessageId`와 timeout 정책을 유지한다.
- 서버가 이미 저장했지만 push만 누락된 메시지는 현재 프론트에서는 timeout 후 failed가 된다. 이후 서버 동기화 API가 붙으면 `clientMessageId` 기준으로 저장 여부를 확인해야 한다.

## Scroll Consistency

새 메시지 도착 시 사용자의 읽기 위치를 보존한다.

관련 코드:

- `_isNearBottom`
- `_scrollToBottomAfterBuild`
- `_upsertMessage`
- `_mergeRealtimeEvent`

정책:

- 내가 메시지를 보내면 항상 하단으로 이동한다.
- 실시간 이벤트는 사용자가 하단 근처에 있을 때만 자동 스크롤한다.
- 사용자가 과거 메시지를 읽는 중이면 새 메시지가 와도 강제로 내리지 않는다.
- 하단 근처 기준은 `96px` 이내다.

UI/UX 정합성:

- 새 메시지 실시간성을 유지하면서도 과거 메시지 탐색을 방해하지 않는다.

## Retry Policy

실패 메시지는 같은 텍스트를 새 command로 다시 보낸다.

관련 코드:

- `_retryMessage`
- `_sendText`
- `CommunityChatMessageDeliveryStatus.failed`

정책:

- failed 메시지를 그대로 두고 중복으로 보내지 않는다.
- 기존 failed 메시지를 먼저 제거하고 새 pending 메시지를 추가한다.
- 새 전송은 새 `clientMessageId`를 가진다.
- 백엔드에 `clientMessageId` 저장 여부 확인 API가 추가되면 재전송 전에 기존 `clientMessageId`가 이미 DB에 저장됐는지 확인하는 단계가 들어가는 것이 더 안전하다.

## Current Gaps

아직 완전한 서버 정합성을 보장하려면 아래가 추가로 필요하다.

- 재연결 후 `lastEventId` 또는 `lastMessageId` 기준 missed event 재동기화
- WebSocket heartbeat/ping-pong
- 인증 토큰 만료 시 재인증
- 서버 ack 이벤트 명세
- 재전송 전 `clientMessageId` 저장 여부 확인 API
- 메시지 삭제를 실제 삭제 대신 tombstone 상태로 보여줄지 정책 결정
- `message.updated`, `message.deleted` payload parser 보강

현재 구현은 프론트 화면 상태에서 중복 추가를 막고, optimistic 메시지와 서버 push 메시지를 합치기 위한 1차 정합성 장치까지 포함한다.
