import 'dart:convert';
import 'package:decimal/decimal.dart';
import 'package:pbstation_frontend/models/models.dart';

class MovimientoCajas {
  MovimientoCajas({
    this.id,
    required this.usuarioId,
    required this.tipo,
    required this.monto,
    required this.metodo,
    required this.motivo,
    required this.fecha,
    required this.observaciones,
  });

  String? id; 
  String usuarioId; 
  String tipo;
  Decimal monto;
  String metodo;
  String motivo;
  String fecha;
  String observaciones;

  factory MovimientoCajas.fromJson(String str) => MovimientoCajas.fromMap(json.decode(str));
  String toJson() => json.encode(toMap());

  factory MovimientoCajas.fromMap(Map<String, dynamic> json) => MovimientoCajas(
    usuarioId: json["usuario_id"],
    tipo: json["tipo"],
    monto: Decimal.parse(json["monto"]),
    metodo: json["metodo"],
    motivo: json["motivo"],
    fecha: json["fecha"],
    observaciones: json["observaciones"],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "usuario_id": usuarioId,
    "tipo": tipo,
    "monto": monto,
    "metodo": metodo,
    "motivo": motivo,
    "fecha": fecha,
    "observaciones": observaciones
  };
}
