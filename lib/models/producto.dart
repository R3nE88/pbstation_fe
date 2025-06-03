import 'dart:convert';

class Producto {
  Producto({
    this.id,
    required this.codigo,
    required this.descripcion,
    required this.tipo,
    required this.categoria,
    required this.precio,
    required this.inventariable,
    required this.imprimible,
    required this.valorImpresion,
  });

  String? id;
  int codigo;
  String descripcion;
  String tipo;
  String categoria;
  double precio;
  bool inventariable;
  bool imprimible;
  int valorImpresion;

  factory Producto.fromJson(String str) => Producto.fromMap(json.decode(str));
  String toJson() => json.encode(toMap());

  factory Producto.fromMap(Map<String, dynamic> json) => Producto(
        // 3) Leer el id directamente si viene en el objeto
        id: json["id"]?.toString(),
        codigo: json["codigo"],
        descripcion: json["descripcion"],
        tipo: json["tipo"].toString(),
        categoria: json["categoria"].toString(),
        precio: (json["precio"] as num).toDouble(),
        inventariable: json["inventariable"] as bool,
        imprimible: json["imprimible"] as bool,
        valorImpresion: json["valor_impresion"] as int,
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
      };
}