# SDD-002 — Mobile / Flutter

## Aplicación Cliente TarifaBot

| Campo            | Valor                                                   |
| ---------------- | ------------------------------------------------------- |
| Documento        | SDD-002-FLT (v2 — Hackathon Edition)                    |
| Framework        | Flutter 3.22 (Dart 3.4)                                 |
| Target           | Android 7+ / iOS 14+                                    |
| State Management | **Riverpod** (flutter_riverpod 2.x)                     |
| Backend          | Firebase (Auth, Firestore, FCM) + Cloud Run REST        |
| Hardware         | ESP32-S3 + DS18B20 únicamente (versión hackathon)       |

> **⚠️ Estado Hackathon:** El firmware ESP32-S3 fue simplificado radicalmente.
> Solo mide temperatura interior (DS18B20), simula la exterior (+5 °C por software),
> usa WiFi con credenciales hardcodeadas y delega el timestamp al backend.
> **Eliminados:** BLE, PZEM-004T (energía), PIR (presencia), IR (AC), OLED.

---

## 1. Estructura del Proyecto Flutter

```
tarifabot_app/
├── lib/
│   ├── main.dart                  # Punto de entrada, providers globales
│   ├── firebase_options.dart      # FlutterFire CLI (auto-generado)
│   │
│   ├── core/
│   │   ├── theme/
│   │   │   ├── colors.dart        # Paleta: azul oscuro + naranja energético
│   │   │   └── typography.dart
│   │   ├── constants/
│   │   │   └── cre_tariffs.dart   # Bloques tarifarios CRE
│   │   └── utils/
│   │       ├── bill_calculator.dart
│   │       └── kwh_formatter.dart
│   │
│   ├── data/
│   │   ├── repositories/
│   │   │   ├── device_repository.dart      # Firestore: devices/
│   │   │   ├── telemetry_repository.dart   # Cloud Run REST
│   │   │   └── auth_repository.dart        # Firebase Auth
│   │   └── models/
│   │       ├── device_model.dart
│   │       ├── telemetry_snapshot.dart
│   │       └── notification_model.dart
│   │
│   ├── presentation/
│   │   ├── auth/
│   │   │   └── login_screen.dart
│   │   ├── onboarding/               # Setup wizard simplificado (sin BLE)
│   │   │   ├── setup_wizard.dart
│   │   │   ├── step1_device_id.dart  # Ingreso manual del device_id (MAC)
│   │   │   └── step2_preferences.dart # Preferencias y umbrales de alerta
│   │   ├── dashboard/
│   │   │   ├── home_screen.dart          # Tab 1
│   │   │   ├── estimations_screen.dart   # Tab 2
│   │   │   └── notifications_screen.dart # Tab 3
│   │   └── widgets/
│   │       ├── temperature_card.dart     # Temperatura interior/exterior DS18B20
│   │       ├── tariff_block_bar.dart     # Barra de progreso del bloque CRE
│   │       └── projection_chart.dart     # fl_chart
│   │
│   └── providers/                   # Riverpod providers
│       ├── auth_provider.dart
│       ├── device_provider.dart      # Stream de Firestore
│       ├── weather_provider.dart
│       └── command_provider.dart
│
├── pubspec.yaml
└── android/ ios/                    # Configuraciones nativas
```

### 1.1 Dependencias Clave (pubspec.yaml)

> **Cambios Hackathon:** Se eliminaron `flutter_blue_plus`, `wifi_iot`, `camera`,
> `image_picker` y `firebase_storage` — ninguno es necesario sin BLE ni OCR.

```yaml
dependencies:
    flutter:
        sdk: flutter

    # Firebase
    firebase_core: ^3.0.0
    firebase_auth: ^5.0.0
    cloud_firestore: ^5.0.0
    firebase_messaging: ^15.0.0
    # firebase_storage: ELIMINADO — sin OCR de facturas en hackathon

    # Estado
    flutter_riverpod: ^2.5.0
    riverpod_annotation: ^2.3.0

    # UI
    fl_chart: ^0.68.0 # Gráficas de consumo/temperatura
    percent_indicator: ^4.2.3 # Barra del bloque tarifario
    flutter_animate: ^4.5.0 # Animaciones suaves

    # IoT / Setup — ELIMINADOS en hackathon
    # flutter_blue_plus: ELIMINADO — WiFi hardcodeado en firmware
    # wifi_iot: ELIMINADO — sin setup WiFi desde la app

    # Cámara / OCR — ELIMINADOS en hackathon
    # camera: ELIMINADO
    # image_picker: ELIMINADO

    # HTTP / API
    dio: ^5.4.0

    # Utilidades
    intl: ^0.19.0
    shared_preferences: ^2.2.3
    permission_handler: ^11.3.0
    go_router: ^14.0.0 # Navegación declarativa
```

---

## 2. Diseño de Pantallas

### 2.1 Dashboard Principal (Tab 1)

> **Hackathon:** Solo muestra temperatura. No hay watts, no hay control de AC ni PIR.
> El campo `temp_exterior_c` viene del ESP32 (DS18B20 interior + 5 °C simulado).

```dart
// presentation/dashboard/home_screen.dart

class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Stream directo de Firestore — se actualiza cada ~30 segundos (ciclo del ESP32)
    final deviceSnapshot = ref.watch(deviceStreamProvider);

    return deviceSnapshot.when(
      data: (device) => Column(children: [

        // ── TARJETA DE TEMPERATURA ───────────────────────────────────
        TemperatureCard(
          interiorTemp: device.tempInteriorC,    // DS18B20 real
          exteriorTemp: device.tempExteriorC,    // interior + 5°C (simulado)
          samplesAveraged: device.samplesAveraged,
        ),

        // ── BARRA DE BLOQUE TARIFARIO ─────────────────────────────
        TariffBlockBar(
          consumed: device.monthlyKwh,
          blockMax: device.currentBlockMaxKwh,
          blockNumber: device.currentTariffBlock,
          remaining: device.kwhToNextBlock,
          projectedBs: device.projectedMonthBs,
        ),

          onToggle: () => ref.read(commandProvider.notifier)
              .sendCommand(device.id, 'AC_TOGGLE'),
        ),

      ]),
      loading: () => const _DashboardSkeleton(),
      error: (e, _) => _ErrorCard(error: e),
    );
  }
}
```

### 2.2 Widget Barra de Bloque Tarifario

```dart
// presentation/widgets/tariff_block_bar.dart

class TariffBlockBar extends StatelessWidget {
  final double consumed, blockMax, remaining, projectedBs;
  final int blockNumber;

  @override
  Widget build(BuildContext context) {
    final pct = consumed / blockMax;
    final isWarning = remaining < 50;  // Menos de 50 kWh → alerta

    return Card(
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("📊 MES ACTUAL", style: Theme.of(context).textTheme.labelLarge),
          // Badge del bloque actual
          Container(
            padding: EdgeInsets.symmetric(h: 8, v: 4),
            decoration: BoxDecoration(
              color: isWarning ? Colors.orange : Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text("Bloque $blockNumber", style: TextStyle(color: Colors.white)),
          ),
        ]),

        SizedBox(height: 8),

        // Barra de progreso con gradiente
        LinearPercentIndicator(
          percent: pct.clamp(0.0, 1.0),
          lineHeight: 16,
          progressColor: isWarning ? Colors.orange : Colors.blue,
          backgroundColor: Colors.grey[200]!,
          animation: true,
          center: Text("${consumed.toStringAsFixed(0)} / ${blockMax.toStringAsFixed(0)} kWh",
              style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
        ),

        SizedBox(height: 6),

        // Alerta de kWh restantes
        if (isWarning)
          _WarningChip(text: "⚠️ Quedan ${remaining.toStringAsFixed(0)} kWh para el próximo bloque"),

        Text("Proyección: Bs ${projectedBs.toStringAsFixed(0)} este mes",
            style: TextStyle(color: Colors.grey[600])),
      ]),
    );
  }
}
```

### 2.3 Provider de Device (Riverpod + Firestore Streaming)

> El payload que escribe el ESP32 en Firestore (vía el backend Cloud Run) tiene esta forma:
> ```json
> {
>   "hardware": { "device_id": "ESP32_MAC_A1B2C3", "firmware_version": "1.2.0-MINIMAL" },
>   "tenant":   { "user_id": "USR_987654321" },
>   "telemetry": { "temp_interior_c": 24.50, "temp_exterior_c": 29.50, "samples_averaged": 3 },
>   "diagnostics": { "uptime_s": 3600, "wifi_rssi_dbm": -65 }
> }
> ```
> El `timestamp_utc` lo agrega el backend al recibirlo — el ESP32 ya no lo envía.

```dart
// providers/device_provider.dart

@riverpod
Stream<DeviceModel> deviceStream(DeviceStreamRef ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) throw Exception("Not authenticated");

  // Stream en tiempo real de Firestore — zero polling
  return FirebaseFirestore.instance
      .collection('devices')
      .where('tenant.user_id', isEqualTo: user.uid)
      .limit(1)
      .snapshots()
      .map((snap) => snap.docs.isEmpty
          ? throw Exception("No device registered")
          : DeviceModel.fromFirestore(snap.docs.first));
}
```


---

## 3. Setup Wizard — Versión Hackathon (sin BLE)

> **Cambio vs SDD original:** El wizard BLE de 5 pasos fue eliminado.
> El ESP32 tiene las credenciales WiFi hardcodeadas en `config.h`.
> El usuario solo ingresa el `device_id` (MAC address impresa en el dispositivo).

```dart
// onboarding/step1_device_id.dart

class DeviceIdStep extends ConsumerStatefulWidget {
  @override
  _DeviceIdStepState createState() => _DeviceIdStepState();
}

class _DeviceIdStepState extends ConsumerState<DeviceIdStep> {
  final _controller = TextEditingController();

  Future<void> _linkDevice() async {
    final deviceId = _controller.text.trim();
    if (deviceId.isEmpty) return;

    // Busca el dispositivo en Firestore por device_id (MAC)
    await ref.read(deviceRepositoryProvider).linkDeviceToUser(deviceId);
    ref.read(setupWizardProvider.notifier).nextStep();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Text("Ingresa el ID de tu dispositivo TarifaBot"),
      const Text("(Impreso en la etiqueta del ESP32-S3)",
          style: TextStyle(fontSize: 12)),
      TextField(
        controller: _controller,
        decoration: const InputDecoration(labelText: "Device ID (ej: ESP32_MAC_A1B2C3)"),
      ),
      ElevatedButton(
        onPressed: _linkDevice,
        child: const Text("VINCULAR DISPOSITIVO"),
      ),
    ]);
  }
}
```



---

## 4. Notificaciones FCM en Flutter

> **Hackathon:** Se eliminan los tipos `absence_ac_off` (no hay PIR ni control AC).
> Solo quedan alertas de temperatura y estado del dispositivo.

```dart
// main.dart — Configuración FCM

void _setupFCM() async {
  final messaging = FirebaseMessaging.instance;

  // Pedir permiso (iOS)
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  // Token FCM → enviar al backend para guardar en Firestore
  final token = await messaging.getToken();
  await ref.read(deviceRepositoryProvider).saveFcmToken(token!);

  // Foreground: mostrar banner
  FirebaseMessaging.onMessage.listen((message) {
    _showInAppBanner(message);
  });

  // Background tap → navegar a pantalla correcta
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    final type = message.data['type'];
    final route = {
      'tariff_alert':   '/estimations',
      'temp_alert':     '/home',
      'daily_forecast': '/home',
      'device_offline': '/home',
    }[type] ?? '/home';

    ref.read(routerProvider).push(route);
  });
}
```


---

## 5. Gráfica de Temperatura (fl_chart)

> **Hackathon:** La gráfica muestra historial de temperatura interior/exterior
> (no kWh, que ya no se mide). El eje Y representa grados Celsius.

```dart
// presentation/widgets/projection_chart.dart

class TemperatureChart extends StatelessWidget {
  final List<TelemetrySnapshot> history; // ÚLtimas lecturas del Firestore

  @override
  Widget build(BuildContext context) {
    return LineChart(LineChartData(
      gridData: FlGridData(show: true, drawVerticalLine: false),

      lineBarsData: [
        // Temperatura interior — azul sólido
        LineChartBarData(
          spots: history.asMap().entries
              .map((e) => FlSpot(e.key.toDouble(), e.value.tempInteriorC))
              .toList(),
          isCurved: true,
          color: Colors.blue,
          barWidth: 3,
          dotData: FlDotData(show: true),
        ),

        // Temperatura exterior — naranja punteado
        LineChartBarData(
          spots: history.asMap().entries
              .map((e) => FlSpot(e.key.toDouble(), e.value.tempExteriorC))
              .toList(),
          isCurved: true,
          color: Colors.orange,
          barWidth: 2,
          dashArray: [5, 5],
          dotData: FlDotData(show: false),
        ),
      ],

      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (val, meta) => Text("${val.toInt()}°C",
              style: TextStyle(fontSize: 10)),
        )),
      ),
    ));
  }
}
```

---

## Tabla de Cambios: SDD Original vs Hackathon

| Aspecto | SDD Original | Hackathon | Razón |
|---------|-------------|-----------|-------|
| **Aprovisionamiento** | BLE 5.0 desde la app | device_id manual (MAC) | Elimina BLE stack |
| **Sensor energía** | PZEM-004T (watts/kWh) | Eliminado | Reducción hardware |
| **Sensor presencia** | PIR | Eliminado | Simplificación |
| **Control AC** | IR + comandos Firestore | Eliminado | Sin actuadores |
| **Temperatura exterior** | OpenWeatherMap API | DS18B20 interior +5°C (simulado) | Sin API externa |
| **Timestamp** | NTP en el ESP32 | Delegado al backend | Simplifica firmware |
| **Setup wizard** | 5 pasos (BLE/WiFi/OCR...) | 2 pasos (device_id + prefs) | Sin BLE ni cámara |
| **Paquetes eliminados** | flutter_blue_plus, wifi_iot, camera, image_picker, firebase_storage | N/A | No aplican |

---

_— Fin del Paquete SDD v2.0 (Hackathon) —_

_SDD-001-GCP | SDD-002-FLT | SDD-003-ESP_  
_Build With AI 2026 · TarifaBot CRE · Santa Cruz de la Sierra, Bolivia_  
_Última actualización: 31 de mayo de 2026 (post-simplificación hackathon)_
