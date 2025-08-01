class Constantes{
  static const String baseUrl = '//127.0.0.1:8000/';
  static const double anchoMaximo = 25; //TODO: Agregar esto a ajustes y mover a configuracion
  static const double altoMaximo = 25; //Agregar esto a ajustes? para modificar el valor

  static const Map<String, String> regimenFiscal = {
    "601": "General de Ley Personas Morales",
    "603": "Personas Morales con Fines no Lucrativos",
    "605": "Sueldos y Salarios e Ingresos Asimilados a Salarios",
    "610": "Residentes en el extranjero sin establecimiento permanente en México",
    "616": "Sin obligaciones fiscales",
  };

  static const Map<String, String> tipo = {
    "producto": "Producto",
    "servicio": "Servicio"
  };

  static const Map<String, String> categoria = {
    "general": "General",
    "impresion": "Impresión Digital",
    "diseno": "Diseño",
  };

  static const Map<String, String> tarjeta = {
    "debito": "Tarjeta de Débito",
    "credito": "Tarjeta de Crédito"
  };

  /*static const Map<String, String> efectivo = {
    "pesos": "Pesos  ",
    "dolar": "Dolares"
  };*/
}