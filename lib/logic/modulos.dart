import 'package:flutter/material.dart';
import 'package:pbstation_frontend/screens/caja_screen.dart';
import 'package:pbstation_frontend/screens/cotizaciones_screen.dart';
import 'package:pbstation_frontend/screens/productos_screen.dart';
import 'package:pbstation_frontend/screens/venta_screen.dart';

class Modulos{
  static String moduloSelected = 'inicio';
  static int subModuloSelected = 0;

  static final Map<String, List<String>> modulos = {
    'caja': [
      'venta',
      'caja',
    ],
    'catalogo': [
      'productos',
      'servicios',
      'usuarios',
      'clientes',
    ],
    'cotizaciones': [
      'cotizaciones',
    ]
  };

  static final Map<String, List<IconData>> modulosIconos = {
    'caja' : [
      Icons.point_of_sale,
      Icons.sell,
      Icons.attach_money,
    ],
    'catalogo' : [
      Icons.menu_book,
      Icons.align_horizontal_left,
      Icons.design_services,
      Icons.supervised_user_circle_sharp,
      Icons.people,
    ],
    'cotizaciones' : [
      Icons.request_quote,
    ]
  };

  static final Map<String, List<Widget>> modulosScreens = {
    'caja': [
      VentaScreen(),
      CajaScreen()
    ],
    'catalogo': [
      ProductosScreen(),
    ],
    'cotizaciones': [
      CotizacionesScreen()
    ]
  };

}