import 'package:flutter/material.dart';
import 'package:pbstation_frontend/env.dart';

// Enum para tipos de usuario
enum TipoUsuario { vendedor, maquilador, administrativo }

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
  enSucursal(Color.fromARGB(255, 38, 169, 138)),
  entregado(Colors.green),
  cancelado(Colors.red);

  final Color color;
  const Estado(this.color);
}

class Constantes {
  static final String baseUrl =
      Env.debug ? '//127.0.0.1:8000/' : '//api.theprinterboy.com/';
  static const double anchoMaximo =
      25; //TODO: Agregar esto a ajustes y mover a configuracion
  static const double altoMaximo =
      25; //Agregar esto a ajustes? para modificar el valor
  static late final String version;

  static const Map<String, String> datosDeFacturacion = {
    'cfdiType': 'I',
    'expeditionPlace': '83440',
  };

  static const Map<String, String> regimenFiscal = {
    '601': 'General de Ley Personas Morales',
    '603': 'Personas Morales con Fines no Lucrativos',
    '605': 'Sueldos y Salarios e Ingresos Asimilados a Salarios',
    '610': 'Residentes en el extranjero sin establecimiento permanente en México',
    '616': 'Sin obligaciones fiscales',
  };

  static const Map<String, String> usoCfdi = {
    'G03': 'Gastos en general',
    'G01': 'Adquisición de mercancías',
    'G02': 'Devoluciones, descuento o bonificaciones',
    'I01': 'Construcciones',
    'I02': 'Mobiliario y equipo de oficina para inversiones',
    'I03': 'Equipo de transporte',
    'I04': 'Equipo de cómputo y accesorios',
    'I05': 'Dados, troqueles, moldes, matrices y herramental',
    'I06': 'Comunicaciones telefónicas',
    'I07': 'Comunicaciones satelitales',
    'I08': 'Otra máquina y equipo',
    'D01': 'Honorarios médicos, dentales y hospitalarios',
    'D02': 'Gastos médicos por incapacidad o discapacidad',
    'D03': 'Gastos funerales',
    'D04': 'Donativos',
    'D05': 'Intereses reales pagados por créditos hipotecarios',
    'D06': 'Aportaciones voluntarias al SAR',
    'D07': 'Primas de seguros de gastos médicos',
    'D08': 'Gastos de transportación escolar obligatoria',
    'D09': 'Depósitos en cuentas para el ahorro, primas que tengan como base planes de pensiones',
    'D10': 'Pagos por servicios educativos (colegiaturas)',
    'S01': 'Sin efectos fiscales',
    'CP01': 'Pagos',
    'CN01': 'Nómina',
  };

  static const Map<String, String> unidadesSat = {
    'H87': 'Pieza',
    'ACT': 'Actividad',
    'E48': 'Servicio',
    'HUR': 'Hora',
    'E51': 'Trabajos',
    'XBX': 'Caja',
    'XRO': 'Rollo',
    'LTR': 'Litro',
    'KGM': 'Kilogramo',
    'MTR': 'Metro',
    'SMI': 'Centímetro',
    'GRM': 'Gramo',
  };

static const Map<String, String> clavesSat = {
  '01010101': 'Productos genéricos',
  '50202300': 'Servicios de impresión',
  '82141600': 'Servicios de diseño gráfico',
  '82121500': 'Servicios de copiado',
  '82131600': 'Servicios de encuadernación',
  '55101500': 'Servicios de rotulación / señalización',
  '73151900': 'Servicios de publicidad',
  '44120000': 'Artículos de oficina',
  '44103100': 'Papel para impresión',
  '44103000': 'Cuadernos y libretas',
  '44121700': 'Plumas y bolígrafos',
  '44122000': 'Carpetas',
  '44102900': 'Hojas blancas',
  '44122100': 'Tinta y toner',
  '43212100': 'Software',
  '43211500': 'Impresoras',
  '43211700': 'Accesorios de impresora',
  '43201800': 'Cables y adaptadores',
  '43202200': 'Memorias USB',
  '60121100': 'Calculadoras',
  '60141000': 'Lonas',
  '60141100': 'Playeras personalizadas',
  '60141300': 'Calcomanías / stickers',
  '60141400': 'Viniles',
  '42142900': 'Cajas y empaques',
  '52131500': 'Herramientas pequeñas',
  '50161800': 'Limpieza (spray, paños)',
  '52151800': 'Accesorios varios',
  '52161500': 'Material escolar',
  '93151500': 'Servicios de mantenimiento menor',
  '85101700': 'Servicios de instalación básica',
};


  static const Map<String, String> tarjeta = {
    'debito': 'Tarjeta de Débito',
    'credito': 'Tarjeta de Crédito',
  };
}
