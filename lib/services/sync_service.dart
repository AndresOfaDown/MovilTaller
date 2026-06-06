import 'dart:io';
import '../database/sqlite_helper.dart';
import '../models/solicitud_offline.dart';
import 'diagnostic_api.dart';
import 'session.dart';

class SyncService {
  static Future<List<int>> syncPendingDiagnostics() async {
    final token = await Session.getToken();
    if (token == null) return [];

    final solicitudes = await SqliteHelper.instance.obtenerSolicitudesPendientes();
    if (solicitudes.isEmpty) return [];

    List<int> syncedIds = [];

    for (final solicitud in solicitudes) {
      try {
        final fotos = solicitud.fotosPaths.map((path) => File(path)).where((file) => file.existsSync()).toList();
        final audio = solicitud.audioPath != null && File(solicitud.audioPath!).existsSync() ? File(solicitud.audioPath!) : null;

        final result = await DiagnosticApi.createDiagnostic(
          token: token,
          descripcion: solicitud.descripcion,
          ubicacion: '${solicitud.latitud},${solicitud.longitud}',
          matricula: solicitud.matricula,
          marca: solicitud.marca,
          modelo: solicitud.modelo,
          anio: solicitud.anio,
          color: solicitud.color,
          tipoVehiculo: solicitud.tipoVehiculo,
          fotos: fotos,
          audio: audio,
        );

        // Si es exitoso, eliminar localmente
        if (solicitud.id != null) {
          await SqliteHelper.instance.eliminarSolicitud(solicitud.id!);
          syncedIds.add(result['id']);
        }
      } catch (e) {
        print('Error sincronizando solicitud ${solicitud.id}: $e');
        // Continuamos con la siguiente para no bloquear todo si una falla
      }
    }

    return syncedIds;
  }
}
