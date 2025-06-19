import 'dart:convert';

class Clientes {
  Clientes({
    required this.nombre,
    this.correo,
    this.telefono,
    this.razonSocial,
    this.rfc,
    this.regimenFiscal,
    this.codigoPostal,
    this.direccion,
    this.noExt,
    this.noInt,
    this.colonia,
    this.localidad,
  });

  String? id; 
  String nombre;
  String? correo;
  int? telefono;
  String? razonSocial;
  String? rfc;
  String? regimenFiscal;
  int? codigoPostal;
  String? direccion;
  int? noExt;
  int? noInt;
  String? colonia;
  String? localidad;


  factory Clientes.fromJson(String str) => Clientes.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Clientes.fromMap(Map<String, dynamic> json) => Clientes(
    nombre: json["nombre"],
    correo: json["correo"],
    telefono: json ["telefono"] as int?,
    rfc: json["rfc"],
    razonSocial: json["razon_social"],
    regimenFiscal: json["regimen_fiscal"],
    codigoPostal: json["codigo_postal"] as int?,
    direccion: json["direccion"],
    noExt: json["no_ext"] as int?,
    noInt: json["no_int"] as int?,
    colonia: json["colonia"],
    localidad: json["localidad"],
  );

  Map<String, dynamic> toMap() => {
    "nombre": nombre,
    "correo": correo,
    "telefono": telefono,
    "razon_social": razonSocial,
    "rfc": rfc,
    "regimen_fiscal": regimenFiscal,
    "codigo_postal": codigoPostal,
    "direccion": direccion,
    "no_ext":noExt,
    "no_int":noInt,
    "colonia":colonia,
    "localidad":localidad
  };
}