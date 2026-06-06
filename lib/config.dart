// lib/config.dart
// API base URL configuration.
// ⚠️  MODO LOCAL — apunta al backend en http://192.168.100.8:8000
// Para volver a producción (Render), cambia defaultValue a:
//   'https://backend-repo-2ncr.onrender.com/api/v1/'
// También se puede sobreescribir en tiempo de ejecución:
//   flutter run --dart-define=API_URL=http://192.168.100.8:8000/api/v1/

const String kApiBaseUrl = String.fromEnvironment(
  'API_URL',
  // defaultValue: 'https://talleres-si2-production.up.railway.app/api/v1/', // <- Producción (Railway)
  defaultValue: 'http://192.168.100.8:8000/api/v1/', // <- Local (Celular por Wi-Fi)
);

// Helper note:
// - Android emulator (AVD) to host machine: use http://10.0.2.2:8000/api/v1/
// - iOS simulator: use http://localhost:8000/api/v1/
// - Physical device: use host machine LAN IP, e.g. http://192.168.100.8:8000/api/v1/
// - For production APK: use https://backend-repo-2ncr.onrender.com/api/v1/
