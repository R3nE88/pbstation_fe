import 'dart:convert';

import 'package:decimal/decimal.dart';

class Productos {
  Productos({
    this.id,
    required this.codigo,
    required this.descripcion,
    required this.tipo,
    required this.categoria,
    required this.precio,
    required this.inventariable,
    required this.imprimible,
    required this.valorImpresion,
    required this.requiereMedida,
  });

  String? id;
  int codigo;
  String descripcion;
  String tipo;
  String categoria;
  Decimal precio;
  bool inventariable;
  bool imprimible;
  int valorImpresion;
  bool requiereMedida;

  factory Productos.fromJson(String str) => Productos.fromMap(json.decode(str));
  String toJson() => json.encode(toMap());

  factory Productos.fromMap(Map<String, dynamic> json) => Productos(
    id: json["id"]?.toString(),
    codigo: json["codigo"],
    descripcion: json["descripcion"],
    tipo: json["tipo"].toString(),
    categoria: json["categoria"].toString(),
    precio: Decimal.parse(json["precio"]),
    inventariable: json["inventariable"] as bool,
    imprimible: json["imprimible"] as bool,
    valorImpresion: json["valor_impresion"] as int,
    requiereMedida: json["requiere_medida"] as bool,
  );


  Map<String, dynamic> toMap() => {
    "id": id,
    "codigo": codigo,
    "descripcion": descripcion,
    "tipo": tipo,
    "categoria": categoria,
    "precio": precio,
    "inventariable": inventariable,
    "imprimible": imprimible,
    "valor_impresion": valorImpresion,
    "requiere_medida": requiereMedida,
  };
}