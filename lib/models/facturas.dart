import 'dart:convert';

import 'package:decimal/decimal.dart';

class Facturas {
  Facturas({
    this.id,
    required this.facturaId,
    required this.folioVenta,
    required this.uuid,
    required this.fecha,
    required this.receptorRfc,
    required this.receptorNombre,
    required this.subTotal,
    required this.impuestos,
    required this.total,
    this.isGlobal = false,
  });

  String? id;
  String facturaId;
  String folioVenta;
  String uuid;
  DateTime fecha;
  String receptorRfc;
  String receptorNombre;
  Decimal subTotal;
  Decimal impuestos;
  Decimal total;
  bool isGlobal;

  factory Facturas.fromJson(String str) => Facturas.fromMap(json.decode(str));
  String toJson() => json.encode(toMap());

  factory Facturas.fromMap(Map<String, dynamic> json) => Facturas(
    id: json['id']?.toString(),
    facturaId: json['factura_id'],
    folioVenta: json['folio_venta'].toString(),
    uuid: json['uuid'].toString(),
    fecha: DateTime.parse(json['fecha']),
    receptorRfc: json['receptor_rfc'],
    receptorNombre: json['receptor_nombre'],
    subTotal: Decimal.parse(json['subtotal'].toString()),
    impuestos: Decimal.parse(json['impuestos'].toString()),
    total: Decimal.parse(json['total'].toString()),
    isGlobal: json['is_global'] ?? false,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'factura_id': facturaId,
    'folio_venta': folioVenta,
    'uuid': uuid,
    'fecha': fecha.toString(),
    'receptor_rfc': receptorRfc,
    'receptor_nombre': receptorNombre,
    'subtotal': subTotal,
    'impuestos': impuestos,
    'total': total,
    'is_global': isGlobal,
  };
}
