import 'package:flutter/material.dart';
import 'package:pbstation_frontend/screens/caja_screen.dart';
import 'package:pbstation_frontend/screens/cotizaciones_screen.dart';
import 'package:pbstation_frontend/screens/productos_screen.dart';
import 'package:pbstation_frontend/screens/venta_screen.dart';

class Modulos{
  static String moduloSelected = 'login';
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

  static final Map<String, IconData> modulosIconos = {
    'caja' : Icons.point_of_sale,
    'catalogo' : Icons.menu_book,
    'cotizaciones' : Icons.request_quote,
  };

  static final Map<String, List<Widget>> modulosScreens = {
    'caja': [
      VentaScreen(),
      CajaScreen()
    ],
    'catalogo': [
      ProductosScreen(),
      ProductosScreen(),
      ProductosScreen(),
      ProductosScreen(),
    ],
    'cotizaciones': [
      CotizacionesScreen()
    ]
  };

}