import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../screens/diagnostic_result_screen.dart';

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
        if (response.payload != null) {
          final int? solicitudId = int.tryParse(response.payload!);
          if (solicitudId != null && navigatorKey.currentState != null) {
            // Navegamos directamente a la pantalla de resultados
            navigatorKey.currentState!.push(
              MaterialPageRoute(
                builder: (_) => DiagnosticResultScreen(solicitudId: solicitudId),
              ),
            );
          }
        }
      },
    );
  }

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
      id: solicitudId, // Usamos el ID de la solicitud para que no se sobrescriban si hay varias
      title: 'Diagnóstico IA Completado',
      body: 'Tu solicitud pendiente ha sido sincronizada. Toca aquí para ver los resultados de la IA.',
      notificationDetails: platformChannelSpecifics,
      payload: solicitudId.toString(),
    );
  }
}
