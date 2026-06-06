import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/solicitud_offline.dart';

class SqliteHelper {
  static final SqliteHelper instance = SqliteHelper._init();
  static Database? _database;

  SqliteHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('emergencias_offline.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE solicitudes_pendientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        descripcion TEXT NOT NULL,
        latitud REAL NOT NULL,
        longitud REAL NOT NULL,
        matricula TEXT,
        marca TEXT,
        modelo TEXT,
        anio INTEGER,
        color TEXT,
        tipo_vehiculo TEXT,
        fotos_paths TEXT NOT NULL,
        audio_path TEXT,
        fecha_creacion TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertarSolicitud(SolicitudOffline solicitud) async {
    final db = await instance.database;
    return await db.insert('solicitudes_pendientes', solicitud.toMap());
  }

  Future<List<SolicitudOffline>> obtenerSolicitudesPendientes() async {
    final db = await instance.database;
    final result = await db.query(
      'solicitudes_pendientes',
      orderBy: 'fecha_creacion ASC',
    );

    return result.map((json) => SolicitudOffline.fromMap(json)).toList();
  }

  Future<int> eliminarSolicitud(int id) async {
    final db = await instance.database;
    return await db.delete(
      'solicitudes_pendientes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
