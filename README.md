# Heimdall Frontend

## Local environment

Create the local environment file and set the backend host reachable from the
target device.

```bash
cp .env.example .env
```

Run Flutter with the build-time environment file.

```bash
flutter run --dart-define-from-file=.env
```

VS Code's `Heimdall (local env)` launch configuration applies the same file.
