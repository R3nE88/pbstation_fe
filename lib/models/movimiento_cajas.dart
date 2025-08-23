import 'dart:convert';

class MovimientoCajas {
  MovimientoCajas({
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

  factory MovimientoCajas.fromJson(String str) => MovimientoCajas.fromMap(json.decode(str));
  String toJson() => json.encode(toMap());

  factory MovimientoCajas.fromMap(Map<String, dynamic> json) => MovimientoCajas(
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
