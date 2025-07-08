import 'dart:convert';

import 'package:decimal/decimal.dart';

class DetallesVenta {
  DetallesVenta({
    this.id,
    required this.productoId,
    required this.cantidad,
    required this.ancho,
    required this.alto,
    required this.comentarios,
    required this.descuento,
    required this.descuentoAplicado,
    required this.iva,
    required this.subtotal,
  });

  String? id;
  String productoId;
  int cantidad;
  Decimal ancho;
  Decimal alto;
  String comentarios;
  int descuento;
  Decimal descuentoAplicado;
  Decimal iva;
  Decimal subtotal;

  factory DetallesVenta.fromJson(String str) => DetallesVenta.fromMap(json.decode(str));
  String toJson() => json.encode(toMap());

  factory DetallesVenta.fromMap(Map<String, dynamic> json) => DetallesVenta(
    id: json["id"]?.toString(),
    productoId: json["producto_id"].toString(),
    cantidad: int.parse(json["cantidad"]),
    ancho: Decimal.parse(json["ancho"]),
    alto: Decimal.parse(json["alto"]),
    comentarios: json["comentarios"].toString(),
    descuento: int.parse(json["descuento"]),
    descuentoAplicado: Decimal.parse(json["descuento_aplicado"]),
    iva: Decimal.parse(json["iva"]),
    subtotal: Decimal.parse(json["subtotal"]),
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "producto_id": productoId,
    "cantidad": cantidad,
    "ancho": ancho,
    "alto": alto,
    "comentarios": comentarios,
    "descuento": descuento,
    "descuento_aplicado": descuentoAplicado,
    "iva": iva,
    "subtotal": subtotal,
  };
}