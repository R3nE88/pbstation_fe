import 'dart:convert';

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
  double ancho;
  double alto;
  String comentarios;
  int descuento;
  double descuentoAplicado;
  double iva;
  double subtotal;

  factory DetallesVenta.fromJson(String str) => DetallesVenta.fromMap(json.decode(str));
  String toJson() => json.encode(toMap());

  factory DetallesVenta.fromMap(Map<String, dynamic> json) => DetallesVenta(
        // 3) Leer el id directamente si viene en el objeto
        id: json["id"]?.toString(),
        productoId: json["producto_id"].toString(),
        cantidad: json["cantidad"] as int,
        ancho: (json["ancho"] as num).toDouble(),
        alto: (json["alto"] as num).toDouble(),
        comentarios: json["comentarios"].toString(),
        descuento: json["descuento"] as int,
        descuentoAplicado: (json["descuento_aplicado"] as num).toDouble(),
        iva: (json["iva"] as num).toDouble(),
        subtotal: (json["subtotal"] as num).toDouble(),
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