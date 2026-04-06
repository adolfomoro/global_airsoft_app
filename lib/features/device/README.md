## 🔧 Device Registration Service

Sistema centralizado de registro de dispositivo que identifica cada instalação única do app e a mantém sincronizada com o backend.

### 📋 Fluxo de Funcionamento

```
┌─ App Abre (primeira vez)
│
├─ initializeDeviceService() chamado em main.dart
├─ Carrega informações do device:
│  ├─ Platform (Android/iOS)
│  ├─ Device Type (modelo do device)
│  ├─ App Version (versão do app)
│  ├─ Device Model (nome do modelo)
│  └─ Push Notification Token (FCM/APNS)
│
├─ POST /device/register (deviceId = null)
│  └─ Retorna: { deviceId: "UUID" }
│
├─ Salva deviceId em SharedPreferences
├─ Configura Dio Interceptor com X-Device-Id
└─ App está pronto

┌─ Próximas vezes que abre
├─ Carrega informações do device novamente
├─ Compara com último registro salvo
├─ SE mudou algo (app version, push token, etc):
│  └─ POST /device/register (deviceId = UUID anterior)
│     └─ Atualiza dados no backend
└─ App está pronto
```

### 🏗️ Arquitetura

**Domain Layer** (`lib/features/device/domain/models/`)
- `PushNotificationType` - Enum (FCM, APNS, WebPush, Unknown)
- `RegisterDeviceInputDto` - DTO de entrada (com toJson())
- `RegisterDeviceOutputDto` - DTO de saída (com fromJson())

**Data Layer** (`lib/features/device/data/`)
- `DeviceRepository` - Comunicação com `/device/register` endpoint

**Core Services** (`lib/core/services/`)
- `DeviceStorageService` - Gerencia SharedPreferences (armazena deviceId e histórico)
- `DeviceService` - Orquestra todo o fluxo (carrega info, detecta mudanças, chama API)

**Network** (`lib/core/network/`)
- `DeviceIdInterceptor` - Injeta `X-Device-Id` em todos os requests

**Providers** (`lib/core/providers/`)
- `device_providers.dart` - Centraliza Riverpod providers e função de inicialização

### 🚀 Como Usar

#### 1. **Inicialização (já feita em main.dart)**
```dart
final container = ProviderContainer();
await initializeDeviceService(container);
runApp(ProviderScope(child: MyApp()));
```

#### 2. **Acessar deviceId em qualquer lugar**
```dart
final deviceId = await ref.watch(storedDeviceIdProvider.future);
```

#### 3. **Forçar re-registro (ex: após logout)**
```dart
final deviceService = await ref.watch(deviceServiceProvider.future);
await deviceService.reregister();
```

#### 4. **Limpar dados do device**
```dart
final storageService = await ref.watch(deviceStorageServiceProvider.future);
await storageService.clearAll();
```

### 📝 Detalhes Técnicos

**X-Device-Id Header**
- Adicionado automaticamente em TODOS os requests via `DeviceIdInterceptor`
- Recuperado do `DeviceService.getStoredDeviceId()`

**Detecção de Mudanças**
- Compara: platform, deviceType, appVersion, deviceModel, pushToken
- Se qualquer campo mudou → re-registra automaticamente

**Push Notification Type**
- Android → `PushNotificationType.fcm` (Firebase Cloud Messaging)
- iOS → `PushNotificationType.apns` (Apple Push Notification Service)
- Web → `PushNotificationType.webPush`

**Storage Local**
- `device_id` - UUID retornado pelo backend
- `last_platform`, `last_device_type`, `last_app_version`, `last_device_model`, `last_push_token`
  - Usados para detecção de mudanças

### ⚙️ Configuração do Backend

**Endpoint:** `POST /device/register`

**Request:**
```json
{
  "deviceId": null,  // null na primeira vez, UUID nas atualizações
  "platform": "Android",
  "deviceType": "SM-G991B",
  "appVersion": "1.0.0",
  "deviceModel": "Galaxy S21",
  "pushNotificationToken": "eOi...",
  "pushNotificationType": 1  // 1=FCM, 2=APNS
}
```

**Response:**
```json
{
  "deviceId": "550e8400-e29b-41d4-a716-446655440000"
}
```

### 📱 Informações Carregadas

| Campo | Fonte | Exemplo |
|-------|-------|---------|
| Platform | `io.Platform` | "Android" ou "iOS" |
| Device Type | `androidInfo.device` ou `iosInfo.utsname.machine` | "SM-G991B" |
| App Version | `PackageInfo.version` | "1.0.0" |
| Device Model | `androidInfo.model` ou `iosInfo.model` | "Galaxy S21" |
| Push Token | TODO: Firebase Cloud Messaging | "eOi..." |
| Push Type | Platform-based | 1 (FCM) ou 2 (APNS) |

### 🔐 Segurança

- deviceId é um UUID gerado no backend (único para cada device)
- Armazenado localmente em SharedPreferences (seguro em ambas plataformas)
- Sempre enviado no header `X-Device-Id` para identificação
- Permite rastrear comportamento do app sem depender de login

### 🐛 Debug

Logs automáticos:
```
✅ Dispositivo inicializado com sucesso
❌ Erro ao inicializar dispositivo: ...
```

### 📌 Próximas Integrações

1. **Firebase Cloud Messaging (FCM)**
   - Implementar em `getPushNotificationToken()` em `device_providers.dart`

2. **Logout**
   - Chamar `deviceService.reregister()` após logout

3. **Testes**
   - MockDeviceRepository para testes unitários
   - Simular diferentes devices e platforms

---

**Criado em:** 05/04/2026
**Status:** ✅ Pronto para integração com backend
