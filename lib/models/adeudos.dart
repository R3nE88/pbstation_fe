import 'dart:convert';
import 'package:decimal/decimal.dart';

class Adeudos {
  Adeudos({
    required this.ventaId,
    required this.montoPendiente,
  });

  String ventaId;
  Decimal montoPendiente;

  factory Adeudos.fromJson(String str) => Adeudos.fromMap(json.decode(str));
  String toJson() => json.encode(toMap());

  factory Adeudos.fromMap(Map<String, dynamic> json) => Adeudos(
    ventaId: json['venta_id'],
    montoPendiente: Decimal.parse(json['monto_pendiente']),
  );

  Map<String, dynamic> toMap() => {
    'venta_id': ventaId,
    'monto_pendiente': montoPendiente,
  };
}