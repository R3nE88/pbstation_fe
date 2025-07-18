import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:pbstation_frontend/models/models.dart';

class Cotizaciones {
  Cotizaciones({
    this.id,
    this.folio,
    required this.clienteId,
    required this.usuarioId,
    required this.sucursalId,
    required this.detalles,
    required this.fechaCotizacion,
    required this.comentariosVenta,
    required this.subTotal,
    required this.descuento,
    required this.iva,
    required this.total,
    required this.vigente,
  });

  String? id; //id automatico de la base de datos
  String? folio; //Folio generado por el sistema backend
  String clienteId; //Cliente que hizo la compra
  String usuarioId; //usuario que realizo la venta
  String sucursalId; //Sucursal donde se hizo lo venta
  List<DetallesVenta> detalles; //todos los detalles de venta
  String fechaCotizacion; //en que momento se realizo la venta (se genera al "imprimir ticket")
  String comentariosVenta; //Comentario en general de la venta
  Decimal subTotal; //Total sin descuento ni impuestos $
  Decimal descuento; //Total del descuento $
  Decimal iva; //Total de impuestos $
  Decimal total; //Total total
  bool vigente;


  factory Cotizaciones.fromJson(String str) => Cotizaciones.fromMap(json.decode(str));
  String toJson() => json.encode(toMap());

  factory Cotizaciones.fromMap(Map<String, dynamic> json) => Cotizaciones(
    folio: json["folio"],
    clienteId: json["cliente_id"],
    usuarioId: json["usuario_id"],
    sucursalId: json["sucursal_id"],
    detalles: List<DetallesVenta>.from(
      json["detalles"].map((x) => DetallesVenta.fromMap(x as Map<String, dynamic>)),
    ),
    fechaCotizacion: json["fecha_cotizacion"],
    comentariosVenta: json["comentarios_venta"],
    subTotal: Decimal.parse(json["subtotal"]),
    descuento: Decimal.parse(json["descuento"]),
    iva: Decimal.parse(json["iva"]),
    total: Decimal.parse(json["total"]), 
    vigente: json["vigente"],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "folio": folio,
    "cliente_id": clienteId,
    "usuario_id": usuarioId,
    "sucursal_id": sucursalId,
    'detalles': detalles.map((d) => d.toMap()).toList(),
    "fecha_cotizacion": fechaCotizacion,
    "comentarios_venta": comentariosVenta,
    "subtotal": subTotal,
    "descuento": descuento,
    "iva": iva,
    "total": total,
    "vigente":vigente
  };
}