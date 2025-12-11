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
    '601': 'Régimen general de ley personas morales',
    '602': 'Régimen simplificado de ley personas morales',
    '603': 'Personas morales con fines no lucrativos',
    '604': 'Régimen de pequeños contribuyentes',
    '605': 'Régimen de sueldos y salarios e ingresos asimilados a salarios',
    '606': 'Régimen de arrendamiento',
    '607': 'Régimen de enajenación o adquisición de bienes',
    '608': 'Régimen de los demás ingresos',
    '609': 'Régimen de consolidación',
    '610': 'Régimen residentes en el extranjero sin establecimiento permanente en México',
    '611': 'Régimen de ingresos por dividendos (socios y accionistas)',
    '612': 'Régimen de las personas físicas con actividades empresariales y profesionales',
    '613': 'Régimen intermedio de las personas físicas con actividades empresariales',
    '614': 'Régimen de los ingresos por intereses',
    '615': 'Régimen de los ingresos por obtención de premios',
    '616': 'Sin obligaciones fiscales',
    '617': 'PEMEX',
    '618': 'Régimen simplificado de ley personas físicas',
    '619': 'Ingresos por la obtención de préstamos',
    '620': 'Sociedades cooperativas de producción que optan por diferir sus ingresos',
    '621': 'Régimen de incorporación fiscal',
    '622': 'Régimen de actividades agrícolas, ganaderas, silvícolas y pesqueras personas morales',
    '623': 'Régimen opcional para grupos de sociedades',
    '624': 'Régimen de los coordinados',
    '625': 'Régimen de las actividades empresariales con ingresos a través de plataformas tecnológicas',
    '626': 'Régimen simplificado de confianza',
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
  '82121500': 'Impresión',
  '82121501': 'Planificación y trazados de producciones gráficas',
  '82121502': 'Tipografía',
  '82121503': 'Impresión digital',
  '82121504': 'Impresión tipográfica o por serigrafía',
  '82121510': 'Impresión textil',
  '82121512': 'Impresión en relieve',
  '82121600': 'Grabado',
  '82121700': 'Fotocopiado',
  '82121701': 'Servicios de copias en blanco y negro o de cotejo',
  '82121702': 'Servicios de copias a color o de cotejo',
  '82141505': 'Servicios de diseño por computador',
  '14111507': 'Papel para impresora o fotocopiadora',
  '14111510': 'Papel para plotter',
  '44122000': 'Carpetas de archivo, carpetas y separadores',
  '45101700': 'Accesorios de imprenta',
  '43211500': 'Computadores',
  '43211503': 'Computadores notebook',
  '82101500': 'Publicidad impresa',
  '81141601': 'Logística',
  '44103103': 'Tóner para impresoras o fax',
  '44103108': 'Reveladores para impresoras o fotocopiadoras',
  '44103109': 'Tambores para impresoras o faxes o fotocopiadoras',
};


  static const Map<String, String> tarjeta = {
    'debito': 'Tarjeta de Débito',
    'credito': 'Tarjeta de Crédito',
  };
}
