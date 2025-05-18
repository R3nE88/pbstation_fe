import 'dart:convert';

class Usuarios {
    Usuarios({
        required this.nombre,
        required this.correo,
        required this.rol,
        required this.sucursal_id,
    });

    var id; 
    String nombre;
    String correo;
    var rol;
    int sucursal_id;

    factory Usuarios.fromJson(String str) => Usuarios.fromMap(json.decode(str));

    String toJson() => json.encode(toMap());

    factory Usuarios.fromMap(Map<String, dynamic> json) => Usuarios(
        nombre: json["nombre"].toString(),
        correo: json["correo"].toString(),
        rol: json["rol"].toString(),
        sucursal_id: int.parse(json["sucursal_id"]()),
    );

    Map<String, dynamic> toMap() => {
        "nombre": nombre,
        "correo": correo,
        "rol": rol,
        "sucursal_id": sucursal_id
    };
}