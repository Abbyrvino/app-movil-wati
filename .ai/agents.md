# agents.md — TarifaBot Mobile (SDD-002-FLT v2 · Hackathon)

## Identidad del Proyecto

**Nombre:** TarifaBot — Aplicación cliente móvil  
**Documento de referencia:** `.ai/SDD - Mobile.md` (SDD-002-FLT v2 Hackathon)  
**Plan hardware:** `.ai/Plan de Implementación ESP32-S3 (Hackathon).md`  
**Framework:** Flutter 3.22 / Dart 3.4  
**Targets:** Android 7+ · iOS 14+

---

## ⚠️ Estado Hackathon — Cambios Críticos vs SDD Original

El firmware ESP32-S3 fue **radicalmente simplificado**. La app móvil debe reflejar esto:

| Eliminado del sistema | Impacto en la app |
|-----------------------|-------------------|
| BLE (aprovisionamiento) | Sin `flutter_blue_plus`, sin wizard BLE |
| PZEM-004T (watts/kWh) | Sin `PowerGaugeWidget`, sin lectura de energía |
| PIR (presencia) | Sin detección de ausencia, sin notificación AC-off |
| IR (control AC) | Sin `AcControllerCard`, sin tab de Control |
| OCR de factura | Sin `camera`/`image_picker`, sin `bill_repository` |
| OpenWeatherMap API | Temperatura exterior = DS18B20 interior + 5 °C (simulado en firmware) |
| Timestamp en ESP32 | El backend (Cloud Run) genera el timestamp al recibir el POST |

**Lo que SÍ hace el ESP32 ahora:**
- Lee temperatura con DS18B20 cada 10s, promedia cada 30s
- Simula temperatura exterior = interior + 5 °C
- Envía HTTP POST a Cloud Run con `device_id` (MAC), `temp_interior_c`, `temp_exterior_c`, `samples_averaged`, `uptime_s`, `wifi_rssi_dbm`
- WiFi configurado con credenciales hardcodeadas en `config.h`

---

## Contexto del Sistema

TarifaBot es una app IoT que permite al usuario (versión hackathon):
1. Vincular su dispositivo ESP32-S3 ingresando el `device_id` (MAC impresa en el hardware)
2. Monitorear temperatura interior y exterior en tiempo real desde Firestore
3. Visualizar el bloque tarifario CRE y proyección de factura mensual
4. Recibir notificaciones FCM por alertas de temperatura y estado del dispositivo

**Backend:** Firebase (Auth, Firestore, FCM) + Cloud Run REST  
**State Management:** Riverpod 2.x (`flutter_riverpod`)  
**Navegación:** `go_router` 14.x

---

## Payload del ESP32 en Firestore

El ESP32 publica este JSON al endpoint Cloud Run, que lo persiste en Firestore:

```json
{
  "hardware": {
    "device_id": "ESP32_MAC_A1B2C3",
    "firmware_version": "1.2.0-MINIMAL"
  },
  "tenant": {
    "user_id": "USR_987654321"
  },
  "telemetry": {
    "temp_interior_c": 24.50,
    "temp_exterior_c": 29.50,
    "samples_averaged": 3
  },
  "diagnostics": {
    "uptime_s": 3600,
    "wifi_rssi_dbm": -65
  }
}
```

> El campo `timestamp_utc` lo agrega el backend al recibir el POST. El ESP32 no lo envía.

---

## Arquitectura de Capas

```
lib/
├── core/          → Tema, constantes CRE, utilidades de cálculo
├── data/          → Repositorios (Firestore, Cloud Run, Auth) + Modelos
├── presentation/  → Pantallas (auth, onboarding, dashboard) + Widgets
└── providers/     → Providers Riverpod (auth, device stream)
```

**Regla:** La lógica de negocio vive en `providers/` y `data/repositories/`. Las pantallas solo consumen providers.

---

## Pantallas Activas (Hackathon)

| Ruta | Archivo | Descripción |
|------|---------|-------------|
| `/login` | `auth/login_screen.dart` | Autenticación Firebase |
| `/onboarding` | `onboarding/setup_wizard.dart` | Wizard 2 pasos |
| `/onboarding/step1` | `onboarding/step1_device_id.dart` | Ingreso manual del device_id (MAC) |
| `/onboarding/step2` | `onboarding/step2_preferences.dart` | Umbrales de alerta |
| `/home` | `dashboard/home_screen.dart` | Tab 1 — Temperatura + bloque tarifario |
| `/estimations` | `dashboard/estimations_screen.dart` | Tab 2 — Proyección de factura |
| `/notifications` | `dashboard/notifications_screen.dart` | Tab 3 — Historial FCM |

> **Eliminadas:** `control_screen.dart` (sin AC), 5 pasos BLE del wizard original

---

## Providers Riverpod Activos

| Provider | Archivo | Responsabilidad |
|----------|---------|-----------------|
| `deviceStreamProvider` | `providers/device_provider.dart` | Stream Firestore del dispositivo (`tenant.user_id == uid`) |
| `authProvider` | `providers/auth_provider.dart` | Estado de autenticación Firebase |

> **Eliminados:** `commandProvider` (sin actuadores), `weatherProvider` (temperatura viene del ESP32)

---

## Widgets Activos (Hackathon)

| Widget | Archivo | Descripción |
|--------|---------|-------------|
| `TemperatureCard` | `widgets/temperature_card.dart` | Muestra `temp_interior_c` y `temp_exterior_c` del DS18B20 |
| `TariffBlockBar` | `widgets/tariff_block_bar.dart` | Barra de progreso CRE. Alerta naranja si quedan < 50 kWh |
| `TemperatureChart` | `widgets/projection_chart.dart` | fl_chart: interior (azul) + exterior (naranja punteado) vs tiempo |

> **Eliminados:** `PowerGaugeWidget` (sin PZEM), `AcControllerCard` (sin IR/AC)

---

## Repositorios Activos

| Repositorio | Archivo | Descripción |
|-------------|---------|-------------|
| `device_repository` | `data/repositories/device_repository.dart` | Firestore: devices/ — linkDeviceToUser, saveFcmToken |
| `telemetry_repository` | `data/repositories/telemetry_repository.dart` | Cloud Run REST — lecturas históricas |
| `auth_repository` | `data/repositories/auth_repository.dart` | Firebase Auth |

> **Eliminados:** `bill_repository` (sin OCR), referencias a `firebase_storage`

---

## Flujo de Datos

```
ESP32-S3 (DS18B20, cada 30s)
    → HTTP POST → Cloud Run (agrega timestamp_utc)
    → Firestore devices/{device_id}/telemetry/

Firestore (stream en tiempo real)
    → deviceStreamProvider (Riverpod)
    → TemperatureCard / TariffBlockBar / TemperatureChart

Usuario vincula dispositivo
    → Ingresa device_id (MAC) en step1_device_id.dart
    → device_repository.linkDeviceToUser(deviceId)
    → Firestore: devices/{device_id}/tenant/user_id = uid
```

---

## Dependencias Activas en pubspec.yaml

| Paquete | Versión | Uso |
|---------|---------|-----|
| `flutter_riverpod` | ^2.5.0 | State management |
| `cloud_firestore` | ^5.0.0 | Real-time DB |
| `firebase_messaging` | ^15.0.0 | Push notifications |
| `firebase_auth` | ^5.0.0 | Autenticación |
| `go_router` | ^14.0.0 | Navegación declarativa |
| `fl_chart` | ^0.68.0 | Gráfica de temperatura |
| `percent_indicator` | ^4.2.3 | Barra bloque tarifario |
| `flutter_animate` | ^4.5.0 | Animaciones UI |
| `dio` | ^5.4.0 | HTTP (Cloud Run REST) |
| `intl` | ^0.19.0 | Formateo de fechas/números |
| `shared_preferences` | ^2.2.3 | Preferencias locales |
| `permission_handler` | ^11.3.0 | Permisos runtime |

> **NO agregar:** `flutter_blue_plus`, `wifi_iot`, `camera`, `image_picker`, `firebase_storage` — eliminados en hackathon.

---

## Notificaciones FCM — Tipos Activos

| Tipo (`data.type`) | Ruta destino | Descripción |
|--------------------|-------------|-------------|
| `tariff_alert` | `/estimations` | Alerta de bloque tarifario |
| `temp_alert` | `/home` | Temperatura fuera de rango |
| `daily_forecast` | `/home` | Resumen diario |
| `device_offline` | `/home` | ESP32 sin reportar |

> **Eliminado:** `absence_ac_off` — no hay PIR ni control de AC

---

## Tema Visual

- **Paleta:** Azul oscuro + Naranja energético
- **Fuente:** `core/theme/typography.dart`
- **Colores:** `core/theme/colors.dart`
- **Alerta tarifaria:** Naranja cuando quedan < 50 kWh para el siguiente bloque CRE

---

## Reglas para la IA

1. **El ESP32 solo mide temperatura.** No generar código que espere watts, PIR, estado del AC, ni datos del PZEM-004T.
2. **Sin BLE.** No usar `flutter_blue_plus` ni lógica de escaneo Bluetooth. El WiFi está hardcodeado en el firmware.
3. **Sin OCR de facturas.** No usar `camera`, `image_picker` ni `bill_repository`. La factura no se escanea en hackathon.
4. **Sin control de AC.** No agregar botones de encendido/apagado ni `commandProvider`.
5. **Temperatura exterior viene del ESP32, no de OpenWeatherMap.** El campo es `temp_exterior_c` (calculado como interior + 5 °C en firmware).
6. **La query Firestore filtra por `tenant.user_id`.** No usar `user_id` directamente (estructura anidada del payload).
7. **No inventar providers.** Solo usar `deviceStreamProvider` y `authProvider`.
8. **No saltarse la capa de repositorio.** Toda llamada a Firestore o HTTP pasa por `data/repositories/`.
9. **Los widgets son tontos.** Sin lógica de negocio en `presentation/`. Todo va al provider o repositorio.
10. **Navegación con go_router.** No usar `Navigator.push` salvo dialogs/bottomSheets.
11. **Riverpod annotation (`@riverpod`) para nuevos providers.** Consistencia con el código generado.
12. **Tarifas CRE en `core/constants/cre_tariffs.dart`.** No hardcodear bloques tarifarios en pantallas.
13. **No agregar dependencias sin consultar.** Verificar primero los paquetes ya incluidos.
14. **El scope es solo la app móvil (SDD-002-FLT).** No modificar firmware ESP32 (`config.h`, `main.cpp`) ni backend Cloud Run dentro de este proyecto.

---

_Referencias: `.ai/SDD - Mobile.md` · `.ai/Plan de Implementación ESP32-S3 (Hackathon).md`_  
_TarifaBot CRE · Build With AI 2026 · Última actualización: 31 de mayo de 2026_
