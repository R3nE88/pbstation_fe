import 'dart:convert';

class Contadores {
  Contadores({
    this.id,
    required this.impresoraId,
    required this.cantidad,
  });

  String? id;
  String impresoraId;
  int cantidad;

  factory Contadores.fromJson(String str) => Contadores.fromMap(json.decode(str));
  String toJson() => json.encode(toMap());

  factory Contadores.fromMap(Map<String, dynamic> json) => Contadores(
    id: json["id"]?.toString(),
    impresoraId: json["impresora_id"],
    cantidad: json["cantidad"],
  );


  Map<String, dynamic> toMap() => {
    "id": id,
    "impresora_id": impresoraId,
    "cantidad": cantidad,
  };
}