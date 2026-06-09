import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../screens/diagnostic_result_screen.dart';
import '../screens/service_request_screen.dart';
import '../screens/servicio_detalle_screen.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
      
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<void> initialize() async {
    // Para Android usamos el ícono por defecto de Flutter
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response.payload);
      },
    );
  }

  /// Maneja el tap en una notificación local
  static void _handleNotificationTap(String? payload) {
    if (payload == null || navigatorKey.currentState == null) return;

    try {
      final data = json.decode(payload) as Map<String, dynamic>;
      final accion = data['accion'] as String?;

      switch (accion) {
        case 'abrir_diagnostico':
          final solicitudId = int.tryParse(data['solicitud_id']?.toString() ?? '');
          if (solicitudId != null) {
            navigatorKey.currentState!.push(
              MaterialPageRoute(
                builder: (_) => DiagnosticResultScreen(solicitudId: solicitudId),
              ),
            );
          }
          break;

        case 'abrir_cotizacion_detalle':
          final diagnosticoId = int.tryParse(data['diagnostico_id']?.toString() ?? '');
          if (diagnosticoId != null) {
            navigatorKey.currentState!.push(
              MaterialPageRoute(
                builder: (_) => ServiceRequestScreen(diagnosticoId: diagnosticoId),
              ),
            );
          }
          break;

        case 'abrir_servicio_detalle':
          // Navegar al home (pestaña de servicios)
          navigatorKey.currentState!.pushNamedAndRemoveUntil('/home', (route) => false);
          break;

        case 'abrir_servicios':
          // Navegar al home y seleccionar la pestaña de servicios
          navigatorKey.currentState!.pushNamedAndRemoveUntil('/home', (route) => false);
          break;

        default:
          // Para payloads antiguos (solo un número = solicitudId de diagnóstico)
          final int? solicitudId = int.tryParse(payload);
          if (solicitudId != null) {
            navigatorKey.currentState!.push(
              MaterialPageRoute(
                builder: (_) => DiagnosticResultScreen(solicitudId: solicitudId),
              ),
            );
          }
      }
    } catch (e) {
      // Si no es JSON, intentar como payload antiguo (solicitudId simple)
      final int? solicitudId = int.tryParse(payload);
      if (solicitudId != null && navigatorKey.currentState != null) {
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (_) => DiagnosticResultScreen(solicitudId: solicitudId),
          ),
        );
      }
    }
  }

  /// Muestra notificación de sincronización exitosa (diagnóstico)
  static Future<void> showSyncSuccessNotification(int solicitudId) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'sync_channel',
      'Sincronización',
      channelDescription: 'Notificaciones sobre sincronización de datos offline',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      id: solicitudId,
      title: 'Diagnóstico IA Completado',
      body: 'Tu solicitud pendiente ha sido sincronizada. Toca aquí para ver los resultados de la IA.',
      notificationDetails: platformChannelSpecifics,
      payload: json.encode({
        'accion': 'abrir_diagnostico',
        'solicitud_id': solicitudId.toString(),
      }),
    );
  }

  /// Muestra una notificación genérica de servicio
  static Future<void> showServiceNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'service_channel',
      'Servicios',
      channelDescription: 'Notificaciones sobre solicitudes y servicios',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // Usar un ID basado en timestamp para no sobrescribir notificaciones previas
    final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _notificationsPlugin.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
      payload: data != null ? json.encode(data) : null,
    );
  }
}
