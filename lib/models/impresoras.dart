import 'dart:convert';

class Impresoras {
  Impresoras({
    this.id,
    required this.numero,
    required this.modelo,
    required this.serie,
    required this.sucursalId
  });

  String? id;
  int numero;
  String modelo;
  String serie;
  String sucursalId;

  factory Impresoras.fromJson(String str) => Impresoras.fromMap(json.decode(str));
  String toJson() => json.encode(toMap());

  factory Impresoras.fromMap(Map<String, dynamic> json) => Impresoras(
    id: json['id']?.toString(),
    numero: json['numero'],
    modelo: json['modelo'].toString(),
    serie: json['serie'].toString(),
    sucursalId: json['sucursal_id'].toString()
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'numero': numero,
    'modelo': modelo,
    'serie': serie,
    'sucursal_id': sucursalId
  };
}