import 'package:flutter/material.dart';
import 'package:pbstation_frontend/screens/screens.dart';

class Modulos{
  static String moduloSelected = 'inicio';
  static int subModuloSelected = 0;

  static const Map<String, List<String>> modulos = {
    'Caja': [
      'Venta',
      'Caja',
      'Historial\nde Ventas'
    ],
    'Catalogo': [
      'Productos y\nServicios',
      'Usuarios',
      'Clientes',
      'Sucursales'
    ],
    'Cotizaciones': [
      'Cotizaciones',
    ],
    'Inventario':[
      'Inventario'
    ],
    'Impresoras':[
      'Impresoras',
    ],
    'Pedidos': [
      'Produccion',
      'Historial',
      'Cuentas por\nCobrar'
    ],
    'Reportes':[
      'Reportes'
    ],
    'Preferencias' : [
      'Preferencias'
    ]
  };

  static const Map<String, List<IconData>> modulosIconos = {
    'Caja' : [
      Icons.point_of_sale,
      Icons.sell,
      Icons.attach_money,
      Icons.history
    ],
    'Catalogo' : [
      Icons.menu_book,
      Icons.design_services,
      Icons.supervised_user_circle_sharp,
      Icons.people,
      Icons.house_siding
    ],
    'Cotizaciones' : [
      Icons.request_quote,
    ],
    'Inventario' : [
      Icons.inventory
    ],
    'Impresoras': [
      Icons.print
    ],
    'Pedidos' : [
      Icons.check_box_outlined,
      Icons.production_quantity_limits,
      Icons.history,
      Icons.monetization_on_outlined
    ],
    'Reportes' : [
      Icons.list_alt
    ],
    'Preferencias' : [
      Icons.settings
    ]
  };

  static const Map<String, List<Widget>> modulosScreens = {
    'Caja': [
      VentaScreen(),
      CajaScreen(),
      SizedBox(), //Falta
    ],
    'Catalogo': [
      ProductosScreen(),
      SizedBox(), //Falta
      ClientesScreen(),
      SizedBox(), //Falta
    ],
    'Cotizaciones': [
      CotizacionesScreen()
    ],
    'Inventario' : [
      SizedBox(), //Falta
    ],
    'Impresoras' : [
      SizedBox(), //Falta
    ],
    'Pedidos' : [
      SizedBox(), //Falta
      SizedBox(), //Falta
      SizedBox(), //Falta
    ],
    'Reportes' : [
      SizedBox(), //Falta
    ],
    'Preferencias' : [
      SettingsScreen()
    ]


  };
}