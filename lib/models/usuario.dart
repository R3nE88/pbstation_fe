import 'dart:convert';

class Usuario {
    Usuario({
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

    factory Usuario.fromJson(String str) => Usuario.fromMap(json.decode(str));

    String toJson() => json.encode(toMap());

    factory Usuario.fromMap(Map<String, dynamic> json) => Usuario(
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