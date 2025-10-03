import 'dart:convert';

class Usuarios {
  Usuarios({
    this.id,
    required this.nombre,
    required this.correo,
    this.telefono,
    this.psw,
    required this.rol,
    required this.activo,
  });

  String? id; 
  String nombre;
  String correo;
  int? telefono;
  String? psw;
  String rol;
  bool activo;

  factory Usuarios.fromJson(String str) => Usuarios.fromMap(json.decode(str));
  String toJson() => json.encode(toMap());

  factory Usuarios.fromMap(Map<String, dynamic> json) => Usuarios(
    id: json['id']?.toString(),
    nombre: json['nombre'],
    correo: json['correo'],
    telefono: json['telefono'],
    rol: json['rol'],
    activo: json['activo'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre': nombre,
    'correo': correo,
    'telefono': telefono,
    'psw': psw,
    'rol': rol,
    'activo': activo
  };
}