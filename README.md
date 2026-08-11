# Heimdall Frontend

Flutter 기반 Heimdall 클라이언트입니다. 로그인/회원가입, 커뮤니티와 영속 채팅, 기조 발언, 커뮤니티 토론 생성·진행·관전·투표·기권과 결과 조회를 `heimdall_ai/backend` API에 연결합니다.

## Prerequisites

- Flutter SDK (프로젝트 기준 Dart SDK `^3.11.0`)
- iOS: Xcode와 실행 가능한 Simulator 또는 개발자 설정을 마친 실기기
- Android: Android Studio와 Emulator 또는 개발자 모드 실기기
- HTTP `3000`, WebSocket `8080`으로 실행 중인 `heimdall_ai/backend`

## Setup

`heimdall_frontend` 디렉터리에서 의존성을 설치하고 로컬 환경 파일을 만듭니다.

```bash
flutter pub get
cp .env.example .env
```

`.env`의 host는 앱이 실행되는 기기에서 접근 가능한 백엔드 host여야 합니다.

```bash
API_BASE_URL=http://localhost:3000
DEBATE_WEBSOCKET_BASE_URL=ws://localhost:8080
WEBSOCKET_BASE_URL=ws://localhost:8080
```

- iOS Simulator: Mac에서 실행 중인 백엔드라면 보통 `localhost`를 사용합니다.
- Android Emulator: host Mac은 보통 `10.0.2.2`로 접근합니다.
- iPhone/Android 실기기: `localhost`가 아니라 Mac의 같은 Wi-Fi LAN 주소를 사용합니다. 예: `http://192.168.x.x:3000`, `ws://192.168.x.x:8080`.
- `API_BASE_URL`은 HTTP(S), 두 WebSocket 값은 WS(S) URL입니다. 현재 커뮤니티와 토론 WebSocket은 같은 서버/포트를 사용하지만 환경 키는 각각 필요합니다.

## Run

사용 가능한 기기를 확인합니다.

```bash
flutter devices
```

iOS Simulator가 닫혀 있다면 다음처럼 열 수 있습니다.

```bash
open -a Simulator
```

환경 파일을 build-time define으로 전달해 실행합니다. `.env`는 런타임 dotenv 파일이 아니므로 이 옵션 없이 실행하면 API URL이 주입되지 않습니다.

```bash
flutter run --dart-define-from-file=.env
```

여러 기기가 보이면 device ID를 지정합니다.

```bash
flutter run -d <device-id> --dart-define-from-file=.env
```

VS Code의 `Heimdall (local env)` launch configuration도 같은 `.env`를 자동 적용합니다.

## Verification

```bash
flutter analyze
flutter test
```

연결 오류가 나면 Flutter 로그의 실제 URI를 먼저 확인합니다. `Connection refused`는 대개 백엔드가 꺼져 있거나 잘못된 LAN IP/포트를 가리키는 경우이며, `EADDRINUSE`는 백엔드의 HTTP 또는 WebSocket 포트를 다른 프로세스가 이미 사용 중이라는 뜻입니다.
