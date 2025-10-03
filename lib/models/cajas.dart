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
    this.ventaTotal,
    required this.estado,
    required this.cortesIds,
    required this.tipoCambio,
  });

  String? id; 
  String? folio; 
  String usuarioId; 
  String sucursalId;
  String fechaApertura;
  String? fechaCierre;
  Decimal? ventaTotal;
  String estado;
  List<String> cortesIds;
  double tipoCambio;

  factory Cajas.fromJson(String str) => Cajas.fromMap(json.decode(str));
  String toJson() => json.encode(toMap());

  factory Cajas.fromMap(Map<String, dynamic> json) => Cajas(
    id: json['id']?.toString(),
    folio: json['folio'],
    usuarioId: json['usuario_id'],
    sucursalId: json['sucursal_id'],
    fechaApertura: json['fecha_apertura'],
    fechaCierre: json['fecha_cierre'],
    ventaTotal: json['venta_total']!=null ? Decimal.tryParse(json['venta_total'].toString()) : null,
    estado: json['estado'],
    cortesIds: List<String>.from(json['cortes_ids'] ?? []),
    tipoCambio: double.parse(json['tipo_cambio'].toString()),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'folio': folio,
    'usuario_id': usuarioId,
    'sucursal_id': sucursalId,
    'fecha_apertura': fechaApertura,
    'fecha_cierre': fechaCierre,
    'venta_total': ventaTotal,
    'estado': estado,
    'cortes_ids': cortesIds,
    'tipo_cambio': tipoCambio
  };
}