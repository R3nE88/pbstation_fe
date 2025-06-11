import 'package:flutter/material.dart';
import 'package:pbstation_frontend/models/clientes.dart';
import 'package:pbstation_frontend/models/productos.dart';

class VentaTabState {
  static List<Clientes?> clienteSelected = [null, null, null];
  static List<bool> entregaInmediata = [true, true, true];
  static List<List<Producto>> productosSelected = [[],[],[]];
  static List<TextEditingController> precioController = [TextEditingController(),TextEditingController(),TextEditingController()];
  static List<TextEditingController> cantidadController = [TextEditingController(),TextEditingController(),TextEditingController()];
  static List<TextEditingController> anchoController = [TextEditingController(),TextEditingController(),TextEditingController()];
  static List<TextEditingController> altoController = [TextEditingController(),TextEditingController(),TextEditingController()];
  static List<TextEditingController> comentarioController = [TextEditingController(),TextEditingController(),TextEditingController()];
  static List<TextEditingController> descuentoController = [TextEditingController(),TextEditingController(),TextEditingController()];
  static List<TextEditingController> ivaController = [TextEditingController(),TextEditingController(),TextEditingController()];
  static List<TextEditingController> totalController = [TextEditingController(),TextEditingController(),TextEditingController()];
  static List<TextEditingController> comentariosController = [TextEditingController(),TextEditingController(),TextEditingController()];

}