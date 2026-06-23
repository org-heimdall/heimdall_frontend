# Community Chat Realtime Design

## Goal

커뮤니티 채팅은 WebSocket 연결 하나로 송신 command와 수신 event를 처리한다.

- 메시지 전송: `CommunityChatRepository.sendMessage`
- 실시간 구독: `CommunityChatRealtimeRepository.watchEvents`
- 화면 반영: `communityChatEventsProvider(communityId)`를 listen해서 로컬 메시지 목록에 merge
- optimistic 메시지 확정: `clientMessageId`를 기준으로 서버 push와 병합

## Event Flow

1. 사용자가 메시지를 입력한다.
2. 화면은 `clientMessageId`를 만들고 pending 메시지를 즉시 추가한다.
3. pending 메시지에 대한 10초 timeout timer를 시작한다.
4. `sendCommunityChatMessageProvider(communityId).notifier.send(...)`가 WebSocket command를 서버에 전송한다.
5. 서버가 DB에 저장한 뒤 `message.created` event를 push한다.
6. 화면은 같은 `clientMessageId`를 가진 pending 메시지를 서버가 발급한 메시지 ID를 가진 sent 메시지로 교체한다.
7. 같은 `clientMessageId`의 push가 10초 안에 오면 timeout timer를 취소한다.
8. command 전송이 실패하거나 timeout 안에 push가 오지 않으면 pending 메시지를 failed로 바꾼다.
9. failed 메시지는 `전송 실패 · 다시 보내기` 액션으로 새 `clientMessageId`를 만들어 재전송할 수 있다.
10. 내 메시지의 push가 나중에 도착해도 `clientMessageId` 또는 서버가 발급한 메시지 ID 기준으로 중복 추가하지 않는다.

## Client Command Shape

프론트가 서버에 WebSocket으로 보내는 command는 최소한 아래 정보를 포함한다.

```json
{
  "id": "command-123",
  "type": "message.send",
  "communityId": "room-2",
  "clientMessageId": "client-123",
  "payload": {
    "text": "hello"
  },
  "sentAt": "2026-06-23T10:00:00.000Z"
}
```

클라이언트는 `authorId`를 보낼 수 있지만, 서버는 인증 토큰 기준 사용자 ID를 신뢰해야 한다. 즉 서버 저장 시 작성자는 command body의 `authorId`보다 인증된 principal에서 결정한다.

## Server Event Shape

서버 이벤트는 최소한 아래 정보를 포함해야 한다.

```json
{
  "id": "event-123",
  "type": "message.created",
  "communityId": "room-2",
  "message": {
    "id": "message-123",
    "communityId": "room-2",
    "clientMessageId": "client-123",
    "authorId": "user-1",
    "authorName": "Username",
    "text": "hello",
    "createdAt": "2026-06-23T10:00:00.000Z"
  }
}
```

여기서 `message.id`는 서버 자체의 ID가 아니라, 서버가 DB에 메시지를 저장하면서 발급한 메시지 ID다.

## Opening Statement Event Shape

기조발언 알림도 채팅 타임라인 안의 시스템 메시지로 들어간다.

```json
{
  "id": "event-456",
  "type": "opening_statement.created",
  "communityId": "room-2",
  "notice": {
    "authorId": "user-3",
    "authorName": "Username3",
    "createdAt": "2026-06-23T10:02:00.000Z"
  }
}
```

프론트는 이 이벤트를 `CommunityChatMessageType.openingStatementNotice` 메시지로 변환한다. 그래서 일반 메시지와 같은 `createdAt` 정렬 규칙을 따른다.

## Required Event Types

### Client Commands

- `message.send`: 채팅 메시지 전송
- `typing.started`: 입력 중 상태 시작
- `typing.stopped`: 입력 중 상태 종료
- `opening_statement.submit`: 기조 발언 제출

### Server Events

- `message.created`: 새 채팅 메시지
- `message.updated`: 서버 보정 또는 상태 변경
- `message.deleted`: 삭제 또는 숨김
- `opening_statement.created`: 기조 발언 알림
- `connection.restored`: 재연결 후 서버 기준 상태 동기화 트리거

## Client Responsibilities

- WebSocket 연결 생성
- 커뮤니티 채팅방 구독
- command를 서버로 전송
- raw event를 `Map<String, dynamic>`으로 전달
- 연결 종료 시 stream close
- 네트워크 오류 전달
- 연결 실패 시 제한된 횟수로 재연결 시도

## Repository Responsibilities

- raw event 타입 파싱
- `CommunityChatEvent`로 변환
- 알 수 없는 이벤트 무시 또는 오류 처리
- 나중에 서버 스펙이 확정되면 여기만 수정

## Screen Merge Rules

- `message.created`
  - 같은 `clientMessageId`가 있으면 교체
  - 같은 서버 발급 메시지 `id`가 있으면 교체
  - 둘 다 없으면 추가
- `message.updated`
  - 같은 서버 발급 메시지 `id`를 교체
- `message.deleted`
  - 같은 서버 발급 메시지 `id`를 제거하거나 deleted 상태로 표시
- `opening_statement.created`
  - 시스템 메시지로 변환해서 일반 채팅과 같은 타임라인에 반영

## Pending Timeout and Retry

프론트에서 처리 가능한 최소 안정성 정책은 현재 구현되어 있다.

- pending 메시지를 만들 때 `clientMessageId`별 10초 timer를 시작한다.
- 같은 `clientMessageId`를 가진 서버 push가 오면 timer를 취소한다.
- command 전송 자체가 실패하면 즉시 `failed`로 전환한다.
- command 전송은 성공했지만 10초 안에 push가 오지 않으면 `failed`로 전환한다.
- 실패 메시지는 `전송 실패 · 다시 보내기`를 표시한다.
- 재전송 시 기존 실패 메시지를 제거하고 같은 텍스트로 새 `clientMessageId`를 만들어 다시 보낸다.

이 정책은 push 유실과 서버 미연결 상태에서 사용자가 메시지 상태를 알 수 있게 하기 위한 프론트 UX 장치다. 서버가 실제로 DB에 저장했지만 push만 누락된 경우까지 완전히 판별하려면 별도 reconcile API 또는 ack 이벤트가 필요하다.

## Source of Truth

- 내가 보낸 메시지: 프론트 optimistic 메시지로 먼저 보이지만, 최종 확정 데이터는 서버 push다.
- 다른 사용자의 메시지: 프론트가 직접 만들지 않고 항상 서버 push로 들어온다.
- 초기 진입/재접속 이후 누락 메시지: 현재 문서 기준으로는 별도 동기화 API가 필요하다.

## Current Implementation

현재 기본 구현은 `WebSocketCommunityChatRealtimeClient`를 사용한다.

송신 경로:

```text
CommunityChatScreen
-> sendCommunityChatMessageProvider(communityId)
-> CommunityChatRepository.sendMessage
-> WebSocketCommunityChatRepository
-> CommunityChatRealtimeClient.send(command)
-> WebSocket JSON command
```

수신 경로:

```text
WebSocket JSON event
-> CommunityChatRealtimeClient.subscribe
-> CommunityChatRealtimeRepository.watchEvents
-> communityChatEventsProvider(communityId)
-> CommunityChatScreen merge
```

화면 상태 처리:

```text
message.send command 성공
-> pending 유지
-> message.created push 도착
-> clientMessageId 기준으로 pending 교체

message.send command 실패
-> pending을 failed로 변경

message.created push timeout
-> pending을 failed로 변경
```

실행 시 `WEBSOCKET_BASE_URL`을 dart-define으로 주입한다.

```bash
flutter run --dart-define=WEBSOCKET_BASE_URL=wss://api.example.com
```

기본값은 로컬 개발용이다.

```text
ws://localhost:8080/communities/{communityId}/chat
```

서버 이벤트 파싱은 `MockCommunityChatRealtimeRepository`가 담당한다. 이름은 mock이지만 현재 역할은 raw JSON 이벤트를 domain event로 변환하는 adapter다. 서버 스펙이 확정되면 이 repository의 parser를 조정한다.

테스트나 서버 없는 개발에서는 `communityChatRealtimeClientProvider`를 `MockCommunityChatRealtimeClient`로 override할 수 있다.

화면과 provider 계약은 유지한다.

## Remaining Backend Contracts

아직 서버 스펙 확정이 필요한 부분:

- `message.send` command에 대한 ack 이벤트를 둘지 여부
- 재연결 후 `lastMessageId` 또는 `lastEventId` 기준 누락 이벤트 동기화
- `clientMessageId` 저장 여부 확인 API
- heartbeat/ping-pong
- 인증 토큰 전달 방식
- 메시지 삭제를 hard delete로 볼지 tombstone event로 볼지
