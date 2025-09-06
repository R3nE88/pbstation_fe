import 'dart:convert';

class MovimientosCajas {
  MovimientosCajas({
    this.id,
    required this.usuarioId,
    required this.tipo,
    required this.monto,
    required this.motivo,
    required this.fecha,
  });

  String? id; 
  String usuarioId; 
  String tipo;
  double monto;
  String motivo;
  String fecha;

  factory MovimientosCajas.fromJson(String str) => MovimientosCajas.fromMap(json.decode(str));
  String toJson() => json.encode(toMap());

  factory MovimientosCajas.fromMap(Map<String, dynamic> json) => MovimientosCajas(
    usuarioId: json["usuario_id"],
    tipo: json["tipo"],
    monto: json["monto"],
    motivo: json["motivo"],
    fecha: json["fecha"],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "usuario_id": usuarioId,
    "tipo": tipo,
    "monto": monto,
    "motivo": motivo,
    "fecha": fecha,
  };
}
