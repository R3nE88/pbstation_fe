import 'dart:convert';

class Sucursales {
  Sucursales({
    this.id,
    required this.nombre,
    required this.correo,
    required this.telefono,
    required this.direccion,
    required this.localidad,
    required this.activo,
  });

  String? id; 
  String nombre;
  String correo;
  String telefono;
  String direccion;
  String localidad;
  bool activo;

  factory Sucursales.fromJson(String str) => Sucursales.fromMap(json.decode(str));
  String toJson() => json.encode(toMap());

  factory Sucursales.fromMap(Map<String, dynamic> json) => Sucursales(
      id: json["id"]?.toString(),
      nombre: json["nombre"],
      correo: json["correo"],
      telefono: json["telefono"],
      direccion: json["direccion"],
      localidad: json["localidad"],
      activo: json["activo"],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "nombre": nombre,
    "correo": correo,
    "telefono": telefono,
    "direccion": direccion,
    "localidad": localidad,
    "activo": activo
  };
}