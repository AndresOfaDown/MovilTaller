import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class PagosApi {
  static String get baseUrl => kApiBaseUrl;

  /// Marca un servicio como pagado en efectivo
  static Future<void> marcarPagoEfectivo(String token, int servicioId, double montoTotal) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}pagos/servicio/$servicioId/pago-efectivo'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'monto_total': montoTotal}),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al marcar pago en efectivo: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error en marcarPagoEfectivo: $e');
      rethrow;
    }
  }

  /// Genera un pago con Stripe y devuelve la URL de pago
  static Future<String> generarPagoStripe(String token, int servicioId, double montoTotal) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}pagos/servicio/$servicioId/generar'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'monto_total': montoTotal}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['url_qr'] as String;
      } else {
        throw Exception('Error al generar pago Stripe: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error en generarPagoStripe: $e');
      rethrow;
    }
  }

  /// Consulta el estado de una factura
  static Future<Map<String, dynamic>> consultarFactura(String token, int servicioId) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}pagos/servicio/$servicioId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      } else {
        throw Exception('Error al consultar factura: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error en consultarFactura: $e');
      rethrow;
    }
  }
}
