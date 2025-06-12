import 'package:flutter/material.dart';
import 'package:pbstation_frontend/models/clientes.dart';
import 'package:pbstation_frontend/models/productos.dart';

class VentaTabState {
  static List<VentaTab> tabs = List.generate(3, (_) => VentaTab());

  static void disposeTab(int index) {
    tabs[index].dispose();
  }

  static void disposeAll() {
    for (var tab in tabs) {
      tab.dispose();
    }
  }
}

class VentaTab {
  Clientes? clienteSelected;
  bool entregaInmediata;
  Productos? productoSelected;
  List<Productos> productosSelected;
  TextEditingController precioController;
  TextEditingController cantidadController;
  TextEditingController anchoController;
  TextEditingController altoController;
  TextEditingController comentarioController;
  TextEditingController descuentoController;
  TextEditingController ivaController;
  TextEditingController totalController;
  TextEditingController comentariosController;

  VentaTab()
      : clienteSelected = null,
        entregaInmediata = true,
        productosSelected = [],
        precioController = TextEditingController(text: '0.00\$'),
        cantidadController = TextEditingController(text: '1'),
        anchoController = TextEditingController(),
        altoController = TextEditingController(),
        comentarioController = TextEditingController(),
        descuentoController = TextEditingController(text: '0.00\$'),
        ivaController = TextEditingController(text: '0.00\$'),
        totalController = TextEditingController(text: '0.00\$'),
        comentariosController = TextEditingController();

  void dispose() {
    precioController.dispose();
    cantidadController.dispose();
    anchoController.dispose();
    altoController.dispose();
    comentarioController.dispose();
    descuentoController.dispose();
    ivaController.dispose();
    totalController.dispose();
    comentariosController.dispose();
  }
}
