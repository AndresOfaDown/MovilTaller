class SolicitudOffline {
  final int? id;
  final String descripcion;
  final double latitud;
  final double longitud;
  final String? matricula;
  final String? marca;
  final String? modelo;
  final int? anio;
  final String? color;
  final String? tipoVehiculo;
  final List<String> fotosPaths;
  final String? audioPath;
  final DateTime fechaCreacion;

  SolicitudOffline({
    this.id,
    required this.descripcion,
    required this.latitud,
    required this.longitud,
    this.matricula,
    this.marca,
    this.modelo,
    this.anio,
    this.color,
    this.tipoVehiculo,
    required this.fotosPaths,
    this.audioPath,
    required this.fechaCreacion,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'descripcion': descripcion,
      'latitud': latitud,
      'longitud': longitud,
      'matricula': matricula,
      'marca': marca,
      'modelo': modelo,
      'anio': anio,
      'color': color,
      'tipo_vehiculo': tipoVehiculo,
      'fotos_paths': fotosPaths.join(','), 
      'audio_path': audioPath,
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
  }

  factory SolicitudOffline.fromMap(Map<String, dynamic> map) {
    return SolicitudOffline(
      id: map['id'],
      descripcion: map['descripcion'],
      latitud: map['latitud'],
      longitud: map['longitud'],
      matricula: map['matricula'],
      marca: map['marca'],
      modelo: map['modelo'],
      anio: map['anio'],
      color: map['color'],
      tipoVehiculo: map['tipo_vehiculo'],
      fotosPaths: map['fotos_paths'].toString().isNotEmpty
          ? map['fotos_paths'].toString().split(',')
          : [],
      audioPath: map['audio_path'],
      fechaCreacion: DateTime.parse(map['fecha_creacion']),
    );
  }
}
