import 'dart:convert';

import 'package:decimal/decimal.dart';

class Facturas {
  Facturas({
    this.id,
    required this.facturaId,
    required this.ventaId,
    required this.uuid,
    required this.fecha,
    required this.receptorRfc,
    required this.receptorNombre,
    required this.subTotal,
    required this.impuestos,
    required this.total
  });

  String? id;
  String facturaId;
  String ventaId;
  String uuid;
  DateTime fecha;
  String receptorRfc;
  String receptorNombre;
  Decimal subTotal;
  Decimal impuestos;
  Decimal total;

  factory Facturas.fromJson(String str) => Facturas.fromMap(json.decode(str));
  String toJson() => json.encode(toMap());

  factory Facturas.fromMap(Map<String, dynamic> json) => Facturas(
    id: json['id']?.toString(),
    facturaId: json['factura_id'],
    ventaId: json['venta_id'].toString(),
    uuid: json['uuid'].toString(),
    fecha: DateTime.parse(json['fecha']),
    receptorRfc: json['receptor_rfc'],
    receptorNombre: json['receptor_nombre'],
    subTotal: Decimal.parse(json['subtotal'].toString()),
    impuestos: Decimal.parse(json['impuestos'].toString()),
    total: Decimal.parse(json['total'].toString())
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'factura_id': facturaId,
    'venta_id': ventaId,
    'uuid': uuid,
    'fecha': fecha.toString(),
    'receptor_rfc': receptorRfc,
    'receptor_nombre': receptorNombre,
    'subtotal': subTotal,
    'impuestos': impuestos,
    'total': total
  };
}