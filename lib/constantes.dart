import 'package:flutter/material.dart';
import 'package:pbstation_frontend/env.dart';

// Enum para tipos de usuario
enum TipoUsuario {
  vendedor,
  maquilador,
  administrativo,
}

// Enum para permisos específicos
enum Permiso {
  normal(1),
  elevado(2),
  admin(3);

  final int nivel;
  const Permiso(this.nivel);

  bool tieneAlMenos(Permiso requerido) => nivel >= requerido.nivel;
}

enum Estado {
  enEspera(Colors.blueGrey),
  pendiente(Colors.red),
  produccion(Colors.amber),
  terminado(Colors.lightBlueAccent),
  enSucursal(Color.fromARGB(255, 76, 170, 175)),
  entregado(Colors.green);

  final Color color;
  const Estado(this.color);
}

class Constantes{
  static final String baseUrl = Env.debug ? '//127.0.0.1:8000/' : '//api.theprinterboy.com/';
  static const double anchoMaximo = 25; //TODO: Agregar esto a ajustes y mover a configuracion
  static const double altoMaximo = 25; //Agregar esto a ajustes? para modificar el valor
  static late final String version;

  static const Map<String, String> regimenFiscal = {
    '601': 'General de Ley Personas Morales',
    '603': 'Personas Morales con Fines no Lucrativos',
    '605': 'Sueldos y Salarios e Ingresos Asimilados a Salarios',
    '610': 'Residentes en el extranjero sin establecimiento permanente en México',
    '616': 'Sin obligaciones fiscales',
  };

  static const Map<String, String> tipo = {
    'producto': 'Producto',
    'servicio': 'Servicio'
  };

  static const Map<String, String> categoria = {
    'general': 'General',
    'impresion': 'Impresión Digital',
    'diseno': 'Diseño',
  };

  static const Map<String, String> tarjeta = {
    'debito': 'Tarjeta de Débito',
    'credito': 'Tarjeta de Crédito'
  };

  /*static const Map<String, String> efectivo = {
    "pesos": "Pesos  ",
    "dolar": "Dolares"
  };*/
}