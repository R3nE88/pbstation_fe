import 'dart:convert';
import 'package:decimal/decimal.dart';

class VentasPorProducto {
  VentasPorProducto({
    this.id,
    required this.cantidad,
    required this.productoId,
    required this.subTotal,
    required this.iva,
    required this.total
  });

  String? id;
  int cantidad;
  String productoId;
  Decimal subTotal;
  Decimal iva;
  Decimal total;  

  factory VentasPorProducto.fromJson(String str) => VentasPorProducto.fromMap(json.decode(str));
  String toJson() => json.encode(toMap());

  factory VentasPorProducto.fromMap(Map<String, dynamic> json) => VentasPorProducto(
    id: json["id"]?.toString(),
    cantidad: json['cantidad'],
    productoId: json['producto_id'],
    subTotal: Decimal.parse(json["subtotal"].toString()),
    iva: Decimal.parse(json["iva"].toString()),
    total: Decimal.parse(json["total"].toString()),
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "cantidad": cantidad,
    "producto_id": productoId,
    "subtotal": subTotal,
    "iva": iva,
    "total": total,
  };
}