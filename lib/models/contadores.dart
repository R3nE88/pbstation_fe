import 'dart:convert';

class Contadores {
  Contadores({
    this.id,
    required this.impresoraId,
    required this.cantidad,
    //required this.fecha,
  });

  String? id;
  String impresoraId;
  int cantidad;
  //String fecha;

  factory Contadores.fromJson(String str) => Contadores.fromMap(json.decode(str));
  String toJson() => json.encode(toMap());

  factory Contadores.fromMap(Map<String, dynamic> json) => Contadores(
    id: json["id"]?.toString(),
    impresoraId: json["impresora_id"],
    cantidad: json["cantidad"],
    //fecha: json["fecha"].toString(),
  );


  Map<String, dynamic> toMap() => {
    "id": id,
    "impresora_id": impresoraId,
    "cantidad": cantidad,
    //"fecha": fecha,
  };
}