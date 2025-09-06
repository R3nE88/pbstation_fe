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
    //required this.fondoInicial,
    this.ventaTotal,
    required this.estado,
    //required this.ventasIds,
    required this.cortesIds,
    required this.tipoCambio,
  });

  String? id; 
  String? folio; 
  String usuarioId; 
  String sucursalId;
  String fechaApertura;
  String? fechaCierre;
  //Decimal fondoInicial;
  Decimal? ventaTotal;
  String estado;
  //List<String> ventasIds;
  List<String> cortesIds;
  double tipoCambio;



  factory Cajas.fromJson(String str) => Cajas.fromMap(json.decode(str));
  String toJson() => json.encode(toMap());

  factory Cajas.fromMap(Map<String, dynamic> json) => Cajas(
    folio: json["folio"],
    usuarioId: json["usuario_id"],
    sucursalId: json["sucursal_id"],
    fechaApertura: json["fecha_apertura"],
    fechaCierre: json["fecha_cierre"],
    //fondoInicial: Decimal.parse(json["fondo_inicial"]),
    ventaTotal: json["venta_total"],
    estado: json["estado"],
    //ventasIds: List<String>.from(json["ventas_ids"] ?? []),
    cortesIds: List<String>.from(json["cortes_ids"] ?? []),
    tipoCambio: json["tipo_cambio"],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "folio": folio,
    "usuario_id": usuarioId,
    "sucursal_id": sucursalId,
    "fecha_apertura": fechaApertura,
    "fecha_cierre": fechaCierre,
    //"fondo_inicial": fondoInicial,
    "venta_total": ventaTotal,
    "estado": estado,
    //"ventas_ids": ventasIds,
    "cortes_ids": cortesIds,
    "tipo_cambio": tipoCambio
  };
}
