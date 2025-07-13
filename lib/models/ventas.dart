import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:pbstation_frontend/models/models.dart';

class Ventas {
  Ventas({
    this.id,
    this.folio,
    required this.clienteId,
    required this.usuarioId,
    required this.sucursalId,
    required this.pedidoPendiente,
    this.fechaEntrega,
    required this.detalles,
    //this.detallesId,
    this.fechaVenta,
    this.tipoPago,
    required this.comentariosVenta,
    required this.subTotal,
    required this.descuento,
    required this.iva,
    required this.total,
    this.recibido,
    this.abonado,
    this.cambio,
    this.liquidado
  });

  String? id; //id automatico de la base de datos
  String? folio; //Folio generado por el sistema backend
  String clienteId; //Cliente que hizo la compra
  String usuarioId; //usuario que realizo la venta
  String sucursalId; //Sucursal donde se hizo lo venta
  bool pedidoPendiente; //determina si es pedido y se entregara en otro momento
  String? fechaEntrega; //fecha establecida para entrega
  List<DetallesVenta> detalles; //todos los detalles de venta
  //List<String>? detallesId;
  String? fechaVenta; //en que momento se realizo la venta (se genera al "imprimir ticket")
  String? tipoPago; //Tarjeta, efectivo, transferencia, mixto (mixto no valido para facturar)
  String comentariosVenta; //Comentario en general de la venta
  Decimal subTotal; //Total sin descuento ni impuestos $
  Decimal descuento; //Total del descuento $
  Decimal iva; //Total de impuestos $
  Decimal total; //Total total

  // vvv Determinar despues esto vvv
  Decimal? recibido; 
  Decimal? abonado;
  Decimal? cambio;
  bool? liquidado;
  


  factory Ventas.fromJson(String str) => Ventas.fromMap(json.decode(str));
  String toJson() => json.encode(toMap());

  factory Ventas.fromMap(Map<String, dynamic> json) => Ventas(
    folio: json["folio"],
    clienteId: json["cliente_id"],
    usuarioId: json["usuario_id"],
    sucursalId: json["sucursal_id"],
    pedidoPendiente: json["pedido_pendiente"],
    fechaEntrega: json["fecha_entrega"],
    detalles: List<DetallesVenta>.from(
      json["detalles"].map((x) => DetallesVenta.fromMap(x as Map<String, dynamic>)),
    ),
    fechaVenta: json["fecha_venta"],
    tipoPago: json["tipo_pago"],
    comentariosVenta: json["comentarios_venta"],
    subTotal: Decimal.parse(json["subtotal"]),
    descuento: Decimal.parse(json["descuento"]),
    iva: Decimal.parse(json["iva"]),
    total: Decimal.parse(json["total"]),
    recibido: Decimal.parse(json["recibido"]),
    abonado: Decimal.parse(json["abonado"]),
    cambio: Decimal.parse(json["cambio"]),
    liquidado: json["liquidado"],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "folio": folio,
    "cliente_id": clienteId,
    "usuario_id": usuarioId,
    "sucursal_id": sucursalId,
    "pedido_pendiente": pedidoPendiente,
    "fecha_entrega": fechaEntrega,
    'detalles': detalles.map((d) => d.toMap()).toList(),
    "fecha_venta": fechaVenta,
    "tipo_pago": tipoPago,
    "comentarios_venta": comentariosVenta,
    "subtotal": subTotal,
    "descuento": descuento,
    "iva": iva,
    "total": total,
    "recibido": recibido,
    "abonado": abonado,
    "cambio": cambio,
    "liquidado":liquidado,
  };
}