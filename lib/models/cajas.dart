import 'dart:convert';
import 'package:decimal/decimal.dart';

class Cajas {
  Cajas({
    this.id,
    this.folio,
    required this.usuarioId,
    required this.sucursalId,
    required this.fechaApertura,
    this.fechaCierre,
    required this.efectivoApertura,
    this.efectivoCierre,
    this.totalTeorico,
    this.diferencia,
    required this.estado,
    required this.ventasIds,
    required this.movimientoCaja,
    this.observaciones
  });

  String? id; 
  String? folio; 
  String usuarioId; 
  String sucursalId;
  String fechaApertura;
  String? fechaCierre;
  Decimal efectivoApertura;
  Decimal? efectivoCierre;
  Decimal? totalTeorico;
  Decimal? diferencia;
  String estado;
  List<String> ventasIds;
  List<String> movimientoCaja;
  String? observaciones;



  factory Cajas.fromJson(String str) => Cajas.fromMap(json.decode(str));
  String toJson() => json.encode(toMap());

  factory Cajas.fromMap(Map<String, dynamic> json) => Cajas(
    folio: json["folio"],
    usuarioId: json["usuario_id"],
    sucursalId: json["sucursal_id"],
    fechaApertura: json["fecha_apertura"],
    fechaCierre: json["fecha_cierre"],
    efectivoApertura: Decimal.parse(json["efectivo_apertura"]),
    efectivoCierre : json["efectivo_cierre"]!=null ? Decimal.parse(json["efectivo_cierre"]) : null,
    totalTeorico : json["efectivo_cierre"]!=null ? Decimal.parse(json["efectivo_cierre"]) : null,
    diferencia : json["diferencia"]!=null ? Decimal.parse(json["diferencia"]) : null,
    estado: json["estado"],
    ventasIds: List<String>.from(json["ventas_ids"] ?? []),
    movimientoCaja: List<String>.from(json["movimiento_caja"] ?? []),
    observaciones: json["observaciones"],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "folio": folio,
    "usuario_id": usuarioId,
    "sucursal_id": sucursalId,
    "fecha_apertura": fechaApertura,
    "fecha_cierre": fechaCierre,
    "efectivo_apertura": efectivoApertura,
    "efectivo_cierre": efectivoCierre,
    "total_teorico": totalTeorico,
    "diferencia": diferencia,
    "estado": estado,
    "ventas_ids": ventasIds,
    "movimiento_caja": movimientoCaja,
    "observaciones": observaciones
  };
}
