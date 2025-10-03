import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pbstation_frontend/screens/screens.dart';
import 'package:pbstation_frontend/services/configuracion.dart';
import 'package:pbstation_frontend/services/login.dart';
import 'package:pbstation_frontend/theme/theme.dart';

class Modulos{
  static String moduloSelected = 'inicio';
  static int subModuloSelected = 0;

  static bool deshabilitar(String value){ //Escribir que modulos se deshabilitan para el usuario sin permisos
    if (Login.usuarioLogeado.rol != 'admin') {
      if (value == 'equipo' || value == 'historial\nde cajas'){
        return true;
      }
    }
    if (!Configuracion.esCaja){
      if (value == 'caja'){
        return true;
      }
    }

    return false;
  }

  static const Map<String, List<String>> modulos = {
    'venta': [
      'venta',
      'caja', 
      'historial\nde cajas', //Solo administrador
      'adeudos'
    ],
    'catalogo': [
      'productos y\nservicios',
      'equipo', //Solo administrador
      'clientes',
      'sucursales'
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
    'venta' : [
      Icons.attach_money,
      Icons.attach_money,
      Icons.point_of_sale,
      Icons.history,
      Icons.payments
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
    'venta': [
      VentaScreen(),
      CajaScreen(),
      HistorialDeCajas(),
      AdeudosSCreen(), 
    ],
    'catalogo': [
      ProductosScreen(),
      UsuariosScreen(),
      ClientesScreen(),
      SucursalesScreen(),
    ],
    'cotizaciones': [
      //CotizacionesScreen() //TODO: deshabilitado
      PantallaEnDesarrollo(),
    ],
    'inventario' : [
      PantallaEnDesarrollo(), //Falta
    ],
    'impresoras' : [
      ImpresorasScreen()
    ],
    'pedidos' : [
      PantallaEnDesarrollo(), //Falta
      PantallaEnDesarrollo(), //Falta
      PantallaEnDesarrollo(), //Falta
    ],
    'reportes' : [
      PantallaEnDesarrollo(), //Falta
    ],
    'preferencias' : [
      SettingsScreen()
    ]
  };
}


class PantallaEnDesarrollo extends StatelessWidget {
  const PantallaEnDesarrollo({super.key});

  static final List<String> mensajes = [
    'En construcción... favor de no alimentar al programador ⚠️.',
    'Pantalla en construcción... nuestros duendes programadores están en huelga,\nregresamos pronto 🏗️.',
    'Aquí debería haber algo increíble... pero todavía estoy picando código ⌨️.',
    'Pantalla en desarrollo 🚧. No la mires mucho, se pone nerviosa 😅.',
    'Cuando acabe esta pantalla será épico, solo dame una CocaCola más 🥤 y un\npar de líneas de código 💻.',
    'Pantalla en mantenimiento: actualmente luchando contra un bug nivel jefe final 🐞.',
    'Estamos entrenando a un mono para programar esta parte 🐒⌨️, paciencia...',
    'En construcción... favor de no alimentar al programador ⚠️.',
    'Construyendo esta pantalla con cinta adhesiva y esperanza ✂️✨.',
    'Error temporal en esta pantalla: falta pizza para seguir programando 🍕🔥.',
    '¡Próximamente aquí: una pantalla que sí funcione! 🎬🚀',
    'Pantalla en reparación... con cinta, pegamento y buena fe 🛠️💡.',
    'Estamos trabajando en esta pantalla… aunque parezca que no 👀.',
    'Aún en progreso… como hornear un pastel, no se puede apurar 🎂⏳.',
    'En construcción... favor de no alimentar al programador ⚠️.',
  ];

  String get mensajeAleatorio {
    final random = Random();
    return mensajes[random.nextInt(mensajes.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.isDarkTheme ? Colors.white10 : const Color.fromARGB(14, 0, 0, 0),
          borderRadius: BorderRadius.circular(12)
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            mensajeAleatorio,
            style: TextStyle(color: AppTheme.colorContraste, fontWeight: FontWeight.w400, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}