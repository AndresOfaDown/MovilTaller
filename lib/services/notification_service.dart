import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'session.dart';
import '../config.dart';
import 'local_notification_service.dart';
import '../screens/service_request_screen.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static String get baseUrl => kApiBaseUrl;

  /// Inicializa Firebase y configura las notificaciones
  static Future<void> initialize() async {
    try {
      print('🔥 Inicializando Firebase...');
      
      // Inicializar Firebase
      await Firebase.initializeApp();
      print('✅ Firebase inicializado correctamente');

      // Solicitar permisos de notificación
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('📱 Permisos de notificación: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Obtener token FCM
        String? token = await _firebaseMessaging.getToken();
        if (token != null) {
          print('🎯 Token FCM obtenido: ${token.substring(0, 50)}...');
          await _registerTokenWithBackend(token);
        } else {
          print('❌ No se pudo obtener token FCM');
        }

        // Configurar listeners
        _setupMessageHandlers();

        // Listener para cuando se actualiza el token
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          print('🔄 Token FCM actualizado: ${newToken.substring(0, 50)}...');
          _registerTokenWithBackend(newToken);
        });
      } else {
        print('❌ Permisos de notificación denegados: ${settings.authorizationStatus}');
      }
    } catch (e) {
      print('💥 Error inicializando Firebase: $e');
    }
  }

  /// Registra el token FCM en el backend
  static Future<void> _registerTokenWithBackend(String token) async {
    try {
      print('📤 Registrando token FCM en backend...');
      
      final sessionToken = await Session.getToken();
      if (sessionToken == null) {
        print('❌ No hay sesión activa, no se puede registrar token FCM');
        return;
      }

      print('🔑 Sesión encontrada, enviando request...');

      final response = await http.post(
        Uri.parse('$baseUrl/notifications/register-token'),
        headers: {
          'Authorization': 'Bearer $sessionToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({'token_fcm': token}),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Token FCM registrado: ${data['message']}');
      } else {
        print('❌ Error registrando token FCM: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('💥 Error registrando token FCM: $e');
    }
  }

  /// Desregistra el token FCM del backend (al cerrar sesión)
  static Future<void> unregisterToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      final sessionToken = await Session.getToken();
      
      if (token == null || sessionToken == null) return;

      final response = await http.delete(
        Uri.parse('$baseUrl/notifications/unregister-token'),
        headers: {
          'Authorization': 'Bearer $sessionToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({'token_fcm': token}),
      );

      if (response.statusCode == 200) {
        print('Token FCM desregistrado exitosamente');
      }
    } catch (e) {
      print('Error desregistrando token FCM: $e');
    }
  }

  /// Configura los manejadores de mensajes
  static void _setupMessageHandlers() {
    // Mensaje recibido cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Mensaje recibido en primer plano: ${message.notification?.title}');
      _handleForegroundMessage(message);
    });

    // Mensaje tocado cuando la app está en segundo plano
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('👆 Mensaje tocado desde segundo plano: ${message.notification?.title}');
      _handleMessageTap(message);
    });

    // Verificar si la app se abrió desde una notificación
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('🚀 App abierta desde notificación: ${message.notification?.title}');
        // Pequeño delay para que el navigator esté listo
        Future.delayed(const Duration(seconds: 2), () {
          _handleMessageTap(message);
        });
      }
    });
  }

  /// Maneja mensajes recibidos en primer plano: muestra notificación local
  static void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;
    
    if (notification != null) {
      // Mostrar como notificación local visible para el usuario
      LocalNotificationService.showServiceNotification(
        title: notification.title ?? 'Asistencia Vehicular',
        body: notification.body ?? '',
        data: data.isNotEmpty ? Map<String, dynamic>.from(data) : null,
      );
    }
  }

  /// Maneja cuando el usuario toca una notificación (desde segundo plano o terminada)
  static void _handleMessageTap(RemoteMessage message) {
    final data = message.data;
    final accion = data['accion'];

    print('🔀 Notificación tocada - Acción: $accion, Data: $data');

    final navigator = LocalNotificationService.navigatorKey.currentState;
    if (navigator == null) {
      print('⚠️ Navigator no disponible aún');
      return;
    }

    switch (accion) {
      case 'abrir_cotizacion_detalle':
        // Navegar a la pantalla de solicitudes de servicio (donde se ve la cotización)
        final diagnosticoId = int.tryParse(data['diagnostico_id']?.toString() ?? '');
        if (diagnosticoId != null) {
          navigator.push(
            MaterialPageRoute(
              builder: (_) => ServiceRequestScreen(diagnosticoId: diagnosticoId),
            ),
          );
        } else {
          // Si no hay diagnosticoId, ir al home
          navigator.pushNamedAndRemoveUntil('/home', (route) => false);
        }
        break;
        
      case 'abrir_servicio_detalle':
        // Navegar al home (pestaña de servicios) - el usuario verá su servicio ahí
        navigator.pushNamedAndRemoveUntil('/home', (route) => false);
        break;

      case 'abrir_valoracion':
        // Navegar al home (pestaña de servicios)
        navigator.pushNamedAndRemoveUntil('/home', (route) => false);
        break;

      default:
        // Navegar al home
        navigator.pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }

  /// Envía una notificación de prueba
  static Future<void> sendTestNotification() async {
    try {
      final sessionToken = await Session.getToken();
      if (sessionToken == null) {
        print('No hay sesión activa');
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/notifications/test-notification'),
        headers: {
          'Authorization': 'Bearer $sessionToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Notificación de prueba enviada: ${data['message']}');
      } else {
        print('Error enviando notificación de prueba: ${response.statusCode}');
      }
    } catch (e) {
      print('Error enviando notificación de prueba: $e');
    }
  }
}

/// Manejador de mensajes en segundo plano (debe ser función top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Mensaje en segundo plano: ${message.notification?.title}');
}