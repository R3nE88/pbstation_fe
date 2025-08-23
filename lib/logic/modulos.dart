import 'package:flutter/material.dart';
import 'package:pbstation_frontend/screens/screens.dart';
import 'package:pbstation_frontend/services/login.dart';

class Modulos{
  static String moduloSelected = 'inicio';
  static int subModuloSelected = 0;

  static bool deshabilitar(String value){ //Escribir que modulos se deshabilitan para el usuario sin permisos
    if (Login.usuarioLogeado.rol == "admin") return false;
    if (value == 'usuarios' || value == 'sucursales' || value == 'historial\nde ventas'){
      return true;
    }
    return false;
  }

  static const Map<String, List<String>> modulos = {
    'caja': [
      'venta',
      'caja', 
      'historial\nde ventas' //Solo administrador
    ],
    'catalogo': [
      'productos y\nservicios',
      'usuarios', //Solo administrador
      'clientes',
      'sucursales' //Solo administrador
    ],
    'cotizaciones': [
      'cotizaciones',
    ],
    'inventario':[
      'inventario'
    ],
    'impresoras':[
      'impresoras',
    ],
    'pedidos': [
      'produccion',
      'historial',
      'cuentas por\ncobrar'
    ],
    'reportes':[
      'reportes'
    ],
    'preferencias' : [
      'preferencias'
    ]
  };

  static const Map<String, List<IconData>> modulosIconos = {
    'caja' : [
      Icons.point_of_sale,
      Icons.sell,
      Icons.attach_money,
      Icons.history
    ],
    'catalogo' : [
      Icons.menu_book,
      Icons.design_services,
      Icons.supervised_user_circle_sharp,
      Icons.people,
      Icons.house_siding
    ],
    'cotizaciones' : [
      Icons.request_quote,
    ],
    'inventario' : [
      Icons.inventory
    ],
    'impresoras': [
      Icons.print
    ],
    'pedidos' : [
      Icons.check_box_outlined,
      Icons.production_quantity_limits,
      Icons.history,
      Icons.monetization_on_outlined
    ],
    'reportes' : [
      Icons.list_alt
    ],
    'preferencias' : [
      Icons.settings
    ]
  };

  static const Map<String, List<Widget>> modulosScreens = {
    'caja': [
      VentaScreen(),
      CajaScreen(),
      SizedBox(), //Falta
    ],
    'catalogo': [
      ProductosScreen(),
      SizedBox(), //Falta
      ClientesScreen(),
      SucursalesScreen(), //Falta
    ],
    'cotizaciones': [
      CotizacionesScreen()
    ],
    'inventario' : [
      SizedBox(), //Falta
    ],
    'impresoras' : [
      SizedBox(), //Falta
    ],
    'pedidos' : [
      SizedBox(), //Falta
      SizedBox(), //Falta
      SizedBox(), //Falta
    ],
    'reportes' : [
      SizedBox(), //Falta
    ],
    'preferencias' : [
      SettingsScreen()
    ]


  };
}