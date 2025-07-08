import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/models/clientes.dart';
import 'package:pbstation_frontend/models/detalles_venta.dart';
import 'package:pbstation_frontend/models/productos.dart';

class VentasStates {
  static List<VentaTab> tabs = List.generate(3, (_) => VentaTab());
  static int pestanias = 2;
  static int indexSelected = 0;
  static int count = 1;

  static void disposeTab(int index) {
    tabs[index].dispose();
  }

  static void clearTab(int index) {
    tabs[index].clear();
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
  DateTime? fechaEntrega;
  Productos? productoSelected;
  List<Productos> productos;
  List<DetallesVenta> detallesVenta;
  TextEditingController precioController;
  TextEditingController cantidadController;
  TextEditingController anchoController;
  TextEditingController altoController;
  TextEditingController comentarioController;
  TextEditingController descuentoController;
  Decimal descuentoAplicado;
  TextEditingController ivaController;
  TextEditingController productoTotalController;
  TextEditingController comentariosController;
  TextEditingController subtotalController;
  TextEditingController totalDescuentoController;
  TextEditingController totalIvaController;
  TextEditingController totalController;

  VentaTab()
      : clienteSelected = null,
        entregaInmediata = true,
        fechaEntrega = null,
        productos = [],
        detallesVenta = [],
        precioController = TextEditingController(text: Formatos.pesos.format(0)),
        cantidadController = TextEditingController(text: '1'),
        anchoController = TextEditingController(text: '1'),
        altoController = TextEditingController(text: '1'),
        comentarioController = TextEditingController(),
        descuentoController = TextEditingController(text: '0%'),
        descuentoAplicado = Decimal.parse("0"),
        ivaController = TextEditingController(text: Formatos.pesos.format(0)),
        productoTotalController = TextEditingController(text: Formatos.pesos.format(0)),
        comentariosController = TextEditingController(),
        subtotalController = TextEditingController(text: Formatos.pesos.format(0)),
        totalDescuentoController = TextEditingController(text: Formatos.pesos.format(0)),
        totalIvaController = TextEditingController(text: Formatos.pesos.format(0)),
        totalController = TextEditingController(text: Formatos.pesos.format(0));
  

  void dispose() {
    precioController.dispose();
    cantidadController.dispose();
    anchoController.dispose();
    altoController.dispose();
    comentarioController.dispose();
    descuentoController.dispose();
    ivaController.dispose();
    productoTotalController.dispose();
    comentariosController.dispose();
    subtotalController.dispose();
    totalDescuentoController.dispose();
    totalIvaController.dispose();
    totalController.dispose();
  }

  void clear(){
    clienteSelected = null;
    productoSelected = null;
    entregaInmediata = true;
    fechaEntrega = null;
    productos = [];
    detallesVenta = [];
    precioController = TextEditingController(text: Formatos.pesos.format(0));
    cantidadController = TextEditingController(text: '1');
    anchoController = TextEditingController(text: '1');
    altoController = TextEditingController(text: '1');
    comentarioController = TextEditingController();
    descuentoController = TextEditingController(text: '0%');
    descuentoAplicado = Decimal.parse("0");
    ivaController = TextEditingController(text: Formatos.pesos.format(0));
    productoTotalController = TextEditingController(text: Formatos.pesos.format(0));
    comentariosController = TextEditingController();
    subtotalController = TextEditingController(text: Formatos.pesos.format(0));
    totalDescuentoController = TextEditingController(text: Formatos.pesos.format(0));
    totalIvaController = TextEditingController(text: Formatos.pesos.format(0));
    totalController = TextEditingController(text: Formatos.pesos.format(0));
  }
}
