import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config.dart';

/// Servicio centralizado de WebSocket para comunicación en tiempo real.
/// 
/// Canales disponibles:
/// - servicio/{id}  → cambios de estado del servicio
/// - tracking/{id}  → ubicación GPS del técnico en vivo
/// - taller/{id}    → notificaciones del taller
class WebSocketService {
  final Map<String, WebSocketChannel> _channels = {};
  final Map<String, StreamController<Map<String, dynamic>>> _controllers = {};
  final Map<String, Timer> _reconnectTimers = {};

  /// Construye la URL WebSocket a partir de la URL HTTP base.
  String get _wsBaseUrl {
    String httpUrl = kApiBaseUrl;
    // Convertir http:// → ws:// y https:// → wss://
    String wsUrl = httpUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
    // Asegurar que termine con /
    if (!wsUrl.endsWith('/')) wsUrl += '/';
    return '${wsUrl}ws/';
  }

  /// Conecta a un canal WebSocket y devuelve un Stream de mensajes.
  Stream<Map<String, dynamic>> connect(String channel, {String? token}) {
    // Si ya existe una conexión activa, devolver el stream existente
    if (_controllers.containsKey(channel)) {
      return _controllers[channel]!.stream;
    }

    final controller = StreamController<Map<String, dynamic>>.broadcast();
    _controllers[channel] = controller;

    _establishConnection(channel, token);

    return controller.stream;
  }

  void _establishConnection(String channel, String? token) {
    try {
      final url = '$_wsBaseUrl$channel${token != null ? "?token=$token" : ""}';
      print('🔌 WS conectando a: $url');

      final wsChannel = WebSocketChannel.connect(Uri.parse(url));
      _channels[channel] = wsChannel;

      wsChannel.stream.listen(
        (data) {
          try {
            final Map<String, dynamic> message = json.decode(data);
            print('📩 WS [$channel]: $message');
            _controllers[channel]?.add(message);
          } catch (e) {
            print('⚠️ WS parse error [$channel]: $e');
          }
        },
        onError: (error) {
          print('❌ WS error [$channel]: $error');
          _scheduleReconnect(channel, token);
        },
        onDone: () {
          print('🔌 WS cerrado [$channel]');
          _scheduleReconnect(channel, token);
        },
        cancelOnError: false,
      );
    } catch (e) {
      print('❌ WS connection failed [$channel]: $e');
      _scheduleReconnect(channel, token);
    }
  }

  /// Programa una reconexión automática después de 5 segundos.
  void _scheduleReconnect(String channel, String? token) {
    _reconnectTimers[channel]?.cancel();
    _reconnectTimers[channel] = Timer(const Duration(seconds: 5), () {
      if (_controllers.containsKey(channel) && !_controllers[channel]!.isClosed) {
        print('🔄 WS reconectando a [$channel]...');
        _channels.remove(channel);
        _establishConnection(channel, token);
      }
    });
  }

  /// Envía un mensaje JSON por un canal WebSocket.
  void send(String channel, Map<String, dynamic> data) {
    final wsChannel = _channels[channel];
    if (wsChannel != null) {
      try {
        wsChannel.sink.add(json.encode(data));
      } catch (e) {
        print('⚠️ WS send error [$channel]: $e');
      }
    } else {
      print('⚠️ WS canal no conectado: $channel');
    }
  }

  /// Envía un ping para mantener la conexión viva.
  void ping(String channel) {
    final wsChannel = _channels[channel];
    if (wsChannel != null) {
      try {
        wsChannel.sink.add('ping');
      } catch (e) {
        print('⚠️ WS ping error [$channel]: $e');
      }
    }
  }

  /// Desconecta un canal específico.
  void disconnect(String channel) {
    _reconnectTimers[channel]?.cancel();
    _reconnectTimers.remove(channel);

    _channels[channel]?.sink.close();
    _channels.remove(channel);

    _controllers[channel]?.close();
    _controllers.remove(channel);

    print('🔌 WS desconectado de [$channel]');
  }

  /// Desconecta todos los canales.
  void disposeAll() {
    final channels = List<String>.from(_channels.keys);
    for (final channel in channels) {
      disconnect(channel);
    }
  }
}
