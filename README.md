# global_airsoft_app

A new Flutter project.

## Environment Configuration (CI/CD)

Network configuration is centralized in `AppConfig` and loaded via
`--dart-define`, making it easy to swap values in pipelines without code
changes.

Available variables:

- `API_BASE_URL` (default: `https://api.global-airsoft.com`)
- `API_CONNECT_TIMEOUT_MS` (default: `10000`)
- `API_RECEIVE_TIMEOUT_MS` (default: `10000`)
- `API_SEND_TIMEOUT_MS` (default: `10000`)

Example:

```bash
flutter run \
	--dart-define=API_BASE_URL=https://staging-api.global-airsoft.com \
	--dart-define=API_CONNECT_TIMEOUT_MS=15000 \
	--dart-define=API_RECEIVE_TIMEOUT_MS=15000 \
	--dart-define=API_SEND_TIMEOUT_MS=15000
```

In CI/CD, apply the same flags to `flutter build` commands for each environment.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
