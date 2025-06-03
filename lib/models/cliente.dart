import 'dart:convert';

class Cliente {
    Cliente({
        required this.nombre,
        this.correo,
        this.telefono,
        this.rfc,
        //this.usoCfdi,
        this.regimenFiscal,
        this.codigoPostal,
        this.direccion
    });

    String? id; 
    String nombre;
    String? correo;
    String? telefono;
    String? rfc;
    //String? usoCfdi;
    String? regimenFiscal;
    String? codigoPostal;
    String? direccion;

    factory Cliente.fromJson(String str) => Cliente.fromMap(json.decode(str));

    String toJson() => json.encode(toMap());

    factory Cliente.fromMap(Map<String, dynamic> json) => Cliente(
        nombre: json["nombre"],
        correo: json["correo"],
        telefono: json ["telefono"],
        rfc: json["rfc"],
        //usoCfdi: json["uso_cfdi"],
        regimenFiscal: json["regimen_fiscal"],
        codigoPostal: json["codigo_postal"],
        direccion: json["direccion"]

    );

    Map<String, dynamic> toMap() => {
        "nombre": nombre,
        "correo": correo,
        "telefono": telefono,
        "rfc": rfc,
        //"uso_cfdi": usoCfdi,
        "regimen_fiscal": regimenFiscal,
        "codigo_postal": codigoPostal,
        "direccion": direccion
    };
}