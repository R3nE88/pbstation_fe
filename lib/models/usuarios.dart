import 'dart:convert';

class Usuarios {
  Usuarios({
    required this.nombre,
    required this.correo,
    required this.rol,
    required this.activo,
  });

  String? id; 
  String nombre;
  String correo;
  String rol;
  bool activo;

  factory Usuarios.fromJson(String str) => Usuarios.fromMap(json.decode(str));
  String toJson() => json.encode(toMap());

  factory Usuarios.fromMap(Map<String, dynamic> json) => Usuarios(
      nombre: json["nombre"],
      correo: json["correo"],
      rol: json["rol"],
      activo: json["activo"],
  );

  Map<String, dynamic> toMap() => {
    "nombre": nombre,
    "correo": correo,
    "rol": rol,
    "activo": activo
  };
}