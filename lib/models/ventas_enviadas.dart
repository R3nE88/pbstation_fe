import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:pbstation_frontend/models/models.dart';

class VentasEnviadas {
  VentasEnviadas({
    this.id,
    required this.clienteId,
    required this.usuarioId,
    required this.sucursalId,
    required this.pedidoPendiente,
    this.fechaEntrega,
    required this.detalles,
    required this.comentariosVenta,
    required this.subTotal,
    required this.descuento,
    required this.iva,
    required this.total,
  });

  String? id; //id automatico de la base de datos
  String clienteId; //Cliente que hizo la compra
  String usuarioId; //usuario que realizo la venta
  String sucursalId; //Sucursal donde se hizo lo venta
  bool pedidoPendiente; //determina si es pedido y se entregara en otro momento
  String? fechaEntrega; //fecha establecida para entrega
  List<DetallesVenta> detalles; //todos los detalles de venta
  String comentariosVenta; //Comentario en general de la venta
  Decimal subTotal; //Total sin descuento ni impuestos $
  Decimal descuento; //Total del descuento $
  Decimal iva; //Total de impuestos $
  Decimal total; //Total total
  


  factory VentasEnviadas.fromJson(String str) => VentasEnviadas.fromMap(json.decode(str));
  String toJson() => json.encode(toMap());

  factory VentasEnviadas.fromMap(Map<String, dynamic> json) => VentasEnviadas(
    clienteId: json["cliente_id"],
    usuarioId: json["usuario_id"],
    sucursalId: json["sucursal_id"],
    pedidoPendiente: json["pedido_pendiente"],
    fechaEntrega: json["fecha_entrega"],
    detalles: List<DetallesVenta>.from(
      json["detalles"].map((x) => DetallesVenta.fromMap(x as Map<String, dynamic>)),
    ),
    comentariosVenta: json["comentarios_venta"],
    subTotal: Decimal.parse(json["subtotal"]),
    descuento: Decimal.parse(json["descuento"]),
    iva: Decimal.parse(json["iva"]),
    total: Decimal.parse(json["total"]),
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "cliente_id": clienteId,
    "usuario_id": usuarioId,
    "sucursal_id": sucursalId,
    "pedido_pendiente": pedidoPendiente,
    "fecha_entrega": fechaEntrega,
    'detalles': detalles.map((d) => d.toMap()).toList(),
    "comentarios_venta": comentariosVenta,
    "subtotal": subTotal,
    "descuento": descuento,
    "iva": iva,
    "total": total,
  };
}