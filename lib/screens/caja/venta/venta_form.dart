import 'dart:io';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:decimal/decimal.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/logic/calculos_dinero.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/logic/mostrar_dialog_permiso.dart';
import 'package:pbstation_frontend/logic/venta_state.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/provider/loading_state.dart';
import 'package:pbstation_frontend/screens/caja/venta/procesar_pago.dart';
import 'package:pbstation_frontend/screens/catalogo/forms/clientes_form.dart';
import 'package:pbstation_frontend/services/login.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/busqueda_field.dart';
import 'package:pbstation_frontend/widgets/seleccionador_hora.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';
import 'package:provider/provider.dart';

class VentaForm extends StatefulWidget {
  const VentaForm({super.key, required this.index, required this.rebuild});

  final int index;
  final Function rebuild;

  @override
  State<VentaForm> createState() => _VentaFormState();
}

class _VentaFormState extends State<VentaForm> {
  //Variables
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _checkboxFocus1 = FocusNode();
  final _checkboxFocus2 = FocusNode();
  final _botonFocus = FocusNode();
  final _comentariosFocus = FocusNode();

  late Clientes? _clienteSelected;
  late bool _entregaInmediata;
  late DateTime? _fechaEntrega;
  late List<Productos> _productos;
  late List<DetallesVenta> _detallesVenta;
  late final TextEditingController _comentariosController;

  //Todos estos son para agregar al DetallesVentaelected
  late Productos? _productoSelected;
  late final TextEditingController _precioController;
  late final TextEditingController _cantidadController;
  late final TextEditingController _anchoController;
  late final TextEditingController _altoController;
  late final TextEditingController _comentarioController;
  late final TextEditingController _descuentoController;
  late Decimal _descuentoAplicado;
  late final TextEditingController _ivaController;
  late final TextEditingController _productoTotalController;

  late final TextEditingController _subtotalController;
  late final TextEditingController _totalDescuentoController;
  late final TextEditingController _totalIvaController;
  late final TextEditingController _totalController;

  bool _anchoError = false;
  bool _altoError = false;
  bool _clienteError = false;
  bool _detallesError = false;

  final _f8FocusNode = FocusNode();
  late final bool Function(KeyEvent event) _keyHandler;
  bool _canFocus = true;
  bool _tabPressed = false;

  late bool _permisoDeAdmin;

  //pedidos
  late List<File> _fileSeleccionado;
  late bool _fromVentaEnviada;
  late Map<String, String> _fromVentaEnviadaData;
  late List<String> _pedidosIds;

  final List<DateTime> _dates = [];

  @override
  void initState() {
    super.initState();

    _permisoDeAdmin = VentasStates.tabs[widget.index].permisoDeAdmin;

    _clienteSelected = VentasStates.tabs[widget.index].clienteSelected;
    _entregaInmediata = VentasStates.tabs[widget.index].entregaInmediata;
    _fechaEntrega = VentasStates.tabs[widget.index].fechaEntrega;
    _productos = VentasStates.tabs[widget.index].productos;
    _detallesVenta = VentasStates.tabs[widget.index].detallesVenta;
    _comentariosController =
        VentasStates.tabs[widget.index].comentariosController;

    //Todos estos son para agregar al productoSelected
    _productoSelected = VentasStates.tabs[widget.index].productoSelected;
    _precioController = VentasStates.tabs[widget.index].precioController;
    _cantidadController = VentasStates.tabs[widget.index].cantidadController;
    _anchoController = VentasStates.tabs[widget.index].anchoController;
    _altoController = VentasStates.tabs[widget.index].altoController;
    _comentarioController =
        VentasStates.tabs[widget.index].comentarioController;
    _descuentoController = VentasStates.tabs[widget.index].descuentoController;
    _descuentoAplicado = VentasStates.tabs[widget.index].descuentoAplicado;
    _ivaController = VentasStates.tabs[widget.index].ivaController;
    _productoTotalController =
        VentasStates.tabs[widget.index].productoTotalController;
    _fileSeleccionado = VentasStates.tabs[widget.index].fileSeleccionado;
    _pedidosIds = VentasStates.tabs[widget.index].pedidosIds;
    _fromVentaEnviada = VentasStates.tabs[widget.index].fromVentaEnviada;
    _fromVentaEnviadaData =
        VentasStates.tabs[widget.index].fromVentaEnviadaData;

    _subtotalController = VentasStates.tabs[widget.index].subtotalController;
    _totalDescuentoController =
        VentasStates.tabs[widget.index].totalDescuentoController;
    _totalIvaController = VentasStates.tabs[widget.index].totalIvaController;
    _totalController = VentasStates.tabs[widget.index].totalController;

    _keyHandler = (KeyEvent event) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.f8) {
          if (mounted) {
            if (_canFocus) {
              //if (!_fromVentaEnviada){
              _f8FocusNode.requestFocus(); // Usar el FocusNode proporcionado
              procesarPago();
              //}
            }
          }
        }
      }
      return false; // false para no consumir el evento
    };
    HardwareKeyboard.instance.addHandler(_keyHandler);

    _botonFocus.onKeyEvent = (FocusNode node, KeyEvent event) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.tab) {
          _tabPressed = true;
        }
      }
      return KeyEventResult.ignored;
    };
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _checkboxFocus1.dispose();
    _checkboxFocus2.dispose();
    _botonFocus.dispose();
    _comentariosFocus.dispose();
    _f8FocusNode.dispose();
    HardwareKeyboard.instance.removeHandler(_keyHandler);
    super.dispose();
  }

  //Metodos
  Decimal formatearEntrada(String entrada) {
    return Decimal.parse(entrada.replaceAll('MX\$', '').replaceAll(',', ''));
  }

  void calcularTotalDetalle() {
    if (_productoSelected == null) {
      return;
    }

    Decimal precio = _productoSelected!.precio;
    _precioController.text = Formatos.pesos.format(precio.toDouble());
    int descuento =
        int.tryParse(_descuentoController.text.replaceAll('%', '')) ?? 0;
    int cantidad = 0;
    if (_cantidadController.text.isNotEmpty) {
      cantidad =
          int.tryParse(_cantidadController.text.replaceAll(',', '')) ?? 0;
    } else {
      cantidad = 0;
    }

    CalculosDinero calcular = CalculosDinero();
    late final Map<String, dynamic> resultado;
    if (_productoSelected?.requiereMedida == true &&
        _anchoController.text.isNotEmpty &&
        _altoController.text.isNotEmpty) {
      resultado = calcular.calcularTotalDetalleConMedida(
        precio,
        cantidad,
        Decimal.parse(_anchoController.text),
        Decimal.parse(_altoController.text),
        descuento,
      );
    } else {
      resultado = calcular.calcularTotalDetalle(precio, cantidad, descuento);
    }
    _ivaController.text = Formatos.pesos.format(resultado['iva']);
    _productoTotalController.text = Formatos.pesos.format(resultado['total']);
    _descuentoAplicado = resultado['descuento'];
    VentasStates.tabs[widget.index].descuentoAplicado = _descuentoAplicado;
  }

  void calcularTotal() {
    CalculosDinero calcular = CalculosDinero();
    final Map<String, dynamic> resultado = calcular.calcularTotal(
      _detallesVenta,
    );

    _subtotalController.text = Formatos.pesos.format(resultado['subtotal']);
    _totalDescuentoController.text = Formatos.pesos.format(
      resultado['descuento'],
    );
    _totalIvaController.text = Formatos.pesos.format(resultado['iva']);
    _totalController.text = Formatos.pesos.format(resultado['total']);
  }

  void limpiarCamposProducto() {
    _productoSelected = null;
    VentasStates.tabs[widget.index].productoSelected = _productoSelected;
    _precioController.text = Formatos.pesos.format(0);
    _cantidadController.text = '1';
    _anchoController.text = '1';
    _altoController.text = '1';
    _comentarioController.clear();
    _descuentoController.text = '0%';
    _ivaController.text = Formatos.pesos.format(0);
    _productoTotalController.text = Formatos.pesos.format(0);
    _fileSeleccionado.clear();
    VentasStates.tabs[widget.index].fileSeleccionado.clear();
  }

  Future<void> elegirFecha() async {
    final DateTime? selectedDate = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Stack(
          alignment: Alignment.topRight,
          children: [
            Dialog(
              backgroundColor: AppTheme.containerColor1,
              child: SizedBox(
                //height: MediaQuery.of(context).size.height * 0.5,
                width: MediaQuery.of(context).size.height * 0.5,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    textTheme: const TextTheme(
                      bodyMedium: TextStyle(
                        color: Colors.white,
                      ), // Cambia el color del texto
                    ),
                    colorScheme: ColorScheme.light(
                      primary:
                          AppTheme
                              .tablaColor2, // Color principal (por ejemplo, para el encabezado)
                      onSurface: Colors.white, // Color del texto en general
                    ),
                  ),
                  child: CalendarDatePicker2(
                    config: CalendarDatePicker2Config(),
                    value: _dates,
                    onValueChanged: (selectedDate) {
                      Navigator.pop(context, selectedDate.first);
                    },
                  ),
                ),
              ),
            ),
            const WindowBar(overlay: true),
          ],
        );
      },
    );

    if (!mounted) return;
    final TimeOfDay? selectedTime = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return const Stack(
          alignment: Alignment.topRight,
          children: [SeleccionadorDeHora(), WindowBar(overlay: true)],
        );
      },
    );

    if (selectedDate == null || selectedTime == null) {
      setState(() {
        _entregaInmediata = true;
        _fechaEntrega = null;
        VentasStates.tabs[widget.index].fechaEntrega = null;
        _checkboxFocus1.requestFocus();
      });
      return; // Si no se seleccionó fecha o hora, no hacer nada
    }

    DateTime fechaSeleccionada = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    setState(() {
      _checkboxFocus2.requestFocus();
      _entregaInmediata = false;
      VentasStates.tabs[widget.index].entregaInmediata = false;
      _fechaEntrega = fechaSeleccionada;
      VentasStates.tabs[widget.index].fechaEntrega = fechaSeleccionada;
    });

    if (!mounted) return;
    FocusScope.of(context).nextFocus();
  }

  void retrocederFocus(int veces, c) {
    for (int i = 0; i < veces; i++) {
      FocusScope.of(c).previousFocus();
    }
  }

  void agregarProducto() {
    if (_productoSelected == null) {
      advertir('Seleccione un producto antes de agregarlo.');
      return;
    }

    if (_productoSelected!.requiereMedida == true) {
      bool isValid = true;
      if (_anchoController.text.isEmpty || _anchoController.text == '0') {
        isValid = false;
        setState(() {
          _anchoError = true;
        });
      }
      if (_altoController.text.isEmpty || _altoController.text == '0') {
        isValid = false;
        setState(() {
          _altoError = true;
        });
      }
      if (!isValid) {
        return;
      }
    }

    List<File> archivos = [];
    archivos.addAll(_fileSeleccionado);

    Decimal iva = Decimal.parse(
      _ivaController.text.replaceAll('MX\$', '').replaceAll(',', ''),
    );
    Decimal subtotal =
        Decimal.parse(
          _productoTotalController.text
              .replaceAll('MX\$', '')
              .replaceAll(',', ''),
        ) +
        _descuentoAplicado -
        iva;
    Decimal total = Decimal.parse(
      _productoTotalController.text.replaceAll('MX\$', '').replaceAll(',', ''),
    );

    DetallesVenta detalle = DetallesVenta(
      productoId: _productoSelected!.id!,
      cantidad: int.parse(_cantidadController.text.replaceAll(',', '')),
      ancho:
          _productoSelected!.requiereMedida
              ? double.parse(_anchoController.text)
              : null,
      alto:
          _productoSelected!.requiereMedida
              ? double.parse(_altoController.text)
              : null,
      comentarios:
          _comentarioController.text.isNotEmpty
              ? _comentarioController.text
              : null,
      descuento:
          int.tryParse(
            _descuentoController.text.replaceAll('%', '').replaceAll(',', ''),
          ) ??
          0,
      descuentoAplicado: _descuentoAplicado,
      iva: iva,
      subtotal: subtotal.round(scale: 2),
      total: total,
      archivos: archivos,
    );

    _productos.add(_productoSelected!);
    VentasStates.tabs[widget.index].modificando = false;

    setState(() {
      _detallesError = false;
      _detallesVenta.add(detalle);
      calcularTotal();
      limpiarCamposProducto();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void modificate(ProductosServices productosServices, int index) {
    VentasStates.tabs[widget.index].modificando = true;
    try {
      _productoSelected = productosServices.productos.firstWhere(
        (p) => p.id == _detallesVenta[index].productoId,
      );
    } catch (e) {
      return;
    }

    VentasStates.tabs[widget.index].productoSelected = _productoSelected;
    _precioController.text = _productoSelected!.precio.toString();
    _cantidadController.text = _detallesVenta[index].cantidad.toString();
    _anchoController.text = _detallesVenta[index].ancho.toString();
    _altoController.text = _detallesVenta[index].alto.toString();
    _comentarioController.text =
        _detallesVenta[index].comentarios != null
            ? _detallesVenta[index].comentarios.toString()
            : '';
    _descuentoController.text =
        '${_detallesVenta[index].descuento.toString()}%';
    _ivaController.text = _detallesVenta[index].iva.toString();
    _productoTotalController.text = _detallesVenta[index].total.toString();
    _fileSeleccionado = _detallesVenta[index].archivos ?? [];
    VentasStates.tabs[widget.index].fileSeleccionado = _fileSeleccionado;
    calcularTotalDetalle();

    _detallesVenta.removeAt(index);
    _productos.removeAt(index);
    calcularTotal();
    setState(() {});
  }

  void advertir(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Text(texto),
          ),
        ),
        backgroundColor: Colors.red.withAlpha(100),
      ),
    );
  }

  void procesarPago() async {
    if (!Configuracion.esCaja) return;
    if (_productoSelected != null) {
      advertir(
        'Tienes un producto pendiente. Agrégalo o elimínalo antes de continuar.',
      );
      return;
    }

    if (_detallesVenta.isEmpty || _clienteSelected == null) {
      if (_clienteSelected == null) {
        setState(() {
          _clienteError = true;
        });
      }
      if (_detallesVenta.isEmpty) {
        setState(() {
          _detallesError = true;
        });
      }
      return;
    }

    void afterProcesar({String? ventaId, String? ventaFolio}) async {
      if (ventaId != null) {
        //Esto es para verificar si no cancele el procesar pago
        if (!_entregaInmediata) {
          // si es pedido
          if (!_fromVentaEnviada) {
            //solo crear pedido desde caja si no es venta enviada
            String detallesComentarios = '';
            for (var i = 0; i < _detallesVenta.length; i++) {
              if (_detallesVenta[i].comentarios != null) {
                if (_detallesVenta[i].comentarios!.isNotEmpty) {
                  if (_detallesVenta.length == i + 1) {
                    detallesComentarios += '${_detallesVenta[i].comentarios}';
                  } else {
                    detallesComentarios += '${_detallesVenta[i].comentarios}&&';
                  }
                }
              }
            }

            List<File> archivos = [];
            for (var detalle in _detallesVenta) {
              if (detalle.archivos != null) {
                if (detalle.archivos!.isNotEmpty) {
                  for (var archivo in detalle.archivos!) {
                    archivos.add(archivo);
                  }
                }
              }
            }

            Pedidos pedido = Pedidos(
              clienteId: _clienteSelected!.id!,
              usuarioId: Login.usuarioLogeado.id!,
              sucursalId: SucursalesServices.sucursalActualID!,
              ventaId: ventaId,
              ventaFolio: ventaFolio ?? '',
              fecha: DateTime.now().toIso8601String(),
              fechaEntrega: _fechaEntrega!.toIso8601String(),
              archivos: [],
              descripcion: detallesComentarios,
              estado: archivos.isEmpty ? Estado.enEspera : Estado.pendiente,
            );

            await showDialog(
              barrierDismissible:
                  false, // Evita que se cierre al hacer clic fuera
              context: context,
              builder: (context) {
                return CreandoPedido(pedido: pedido, files: archivos);
              },
            );
          } else {
            //ya una vez pagado y con pedido pendiente, confirmar pedido!
            for (var pedidoId in _pedidosIds) {
              if (!mounted) return;
              final pedidosService = Provider.of<PedidosService>(
                context,
                listen: false,
              );
              await pedidosService.confirmarPedido(
                pedidoId: pedidoId,
                ventaId: ventaId,
                ventaFolio: ventaFolio ?? '',
              );
            }
          }
        }
      }

      _canFocus = true;
    }

    _canFocus = false;
    final x = await showDialog(
      context: context,
      builder: (_) {
        return Stack(
          alignment: Alignment.topRight,
          children: [
            ProcesarPago(
              venta: Ventas(
                clienteId: _clienteSelected!.id!,
                usuarioId:
                    VentasStates.tabs[widget.index].usuarioQueEnvioId != null
                        ? VentasStates.tabs[widget.index].usuarioQueEnvioId!
                        : Login.usuarioLogeado.id!,
                sucursalId: SucursalesServices.sucursalActualID!,
                hasPedido: !_entregaInmediata,
                //fechaEntrega: _entregaInmediata ? null : _fechaEntrega?.toIso8601String(),
                detalles: _detallesVenta,
                comentariosVenta:
                    _comentariosController.text.isNotEmpty
                        ? _comentariosController.text
                        : null,
                subTotal: formatearEntrada(_subtotalController.text),
                descuento: formatearEntrada(_totalDescuentoController.text),
                iva: formatearEntrada(_totalIvaController.text),
                total: formatearEntrada(_totalController.text),
                recibidoTotal: Decimal.zero,
                liquidado: false,
              ),
              afterProcesar:
                  ({String? ventaId, String? ventaFolio}) =>
                      afterProcesar(ventaId: ventaId, ventaFolio: ventaFolio),
            ),
            const WindowBar(overlay: true),
          ],
        );
      },
    );
    if (_fromVentaEnviada) {
      if (!mounted) return;
      Provider.of<VentasEnviadasServices>(
        context,
        listen: false,
      ).eliminarRecibida(
        _fromVentaEnviadaData['id']!,
        _fromVentaEnviadaData['sucursal']!,
      );
    }

    if (x != null) {
      widget.rebuild(widget.index);
    }
    _canFocus = true;
  }

  void procesarEnvio() async {
    if (Configuracion.esCaja) return;
    if (_productoSelected != null) {
      advertir(
        'Tienes un producto pendiente. Agrégalo o elimínalo antes de continuar.',
      );
      return;
    }

    if (_detallesVenta.isEmpty || _clienteSelected == null) {
      if (_clienteSelected == null) {
        setState(() {
          _clienteError = true;
        });
      }
      if (_detallesVenta.isEmpty) {
        setState(() {
          _detallesError = true;
        });
      }
      return;
    }

    final loadingSvc = Provider.of<LoadingProvider>(context, listen: false);
    loadingSvc.show();

    Future<void> enviarHelper(List<String>? value) async {
      //Y luego enviar venta!
      VentasEnviadas venta = VentasEnviadas(
        clienteId: _clienteSelected!.id!,
        usuarioId: Login.usuarioLogeado.id!,
        usuarioNombre: Login.usuarioLogeado.nombre,
        sucursalId: SucursalesServices.sucursalActualID!,
        hasPedido: !_entregaInmediata,
        fechaEntrega:
            _entregaInmediata ? null : _fechaEntrega?.toIso8601String(),
        detalles: _detallesVenta,
        comentariosVenta:
            _comentariosController.text.isNotEmpty
                ? _comentariosController.text
                : null,
        subTotal: formatearEntrada(_subtotalController.text),
        descuento: formatearEntrada(_totalDescuentoController.text),
        iva: formatearEntrada(_ivaController.text),
        total: formatearEntrada(_totalController.text),
        fechaEnvio: DateTime.now().toIso8601String(),
        compu: Configuracion.nombrePC,
        pedidosIds: value,
      );

      final ventaEnviada = Provider.of<VentasEnviadasServices>(
        context,
        listen: false,
      );
      await ventaEnviada.enviarVenta(venta);

      loadingSvc.hide();
      widget.rebuild(widget.index);

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          Future.delayed(const Duration(seconds: 2), () {
            if (!context.mounted) return;
            Navigator.of(
              context,
            ).pop(); // Cierra el cuadro después de 2 segundos
          });

          return Stack(
            alignment: Alignment.topRight,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.containerColor2,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '¡Enviado a caja!',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const WindowBar(overlay: true),
            ],
          );
        },
      );
    }

    _canFocus = false;
    if (!_entregaInmediata) {
      //Si es un pedido
      //Crear pedido primero
      String detallesComentarios = '';
      for (var i = 0; i < _detallesVenta.length; i++) {
        if (_detallesVenta[i].comentarios != null) {
          if (_detallesVenta[i].comentarios!.isNotEmpty) {
            if (_detallesVenta.length == i + 1) {
              detallesComentarios += '${_detallesVenta[i].comentarios}';
            } else {
              detallesComentarios += '${_detallesVenta[i].comentarios}&&';
            }
          }
        }
      }
      List<File> archivos = [];
      for (var detalle in _detallesVenta) {
        if (detalle.archivos != null) {
          if (detalle.archivos!.isNotEmpty) {
            for (var archivo in detalle.archivos!) {
              archivos.add(archivo);
            }
          }
        }
      }

      Pedidos pedido = Pedidos(
        clienteId: _clienteSelected!.id!,
        usuarioId: Login.usuarioLogeado.id!,
        sucursalId: SucursalesServices.sucursalActualID!,
        ventaId: 'esperando',
        ventaFolio: '',
        fecha: DateTime.now().toIso8601String(),
        fechaEntrega: _fechaEntrega!.toIso8601String(),
        archivos: [],
        descripcion: detallesComentarios,
        estado: archivos.isEmpty ? Estado.enEspera : Estado.pendiente,
      );

      await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return CreandoPedido(pedido: pedido, files: archivos);
        },
      ).then((value) async {
        // y luego procesar envio
        await enviarHelper(value);
      });
    } else {
      // si no es un pedido, simplemente enviar
      await enviarHelper(null);
    }

    _canFocus = true;
  }

  void procesarCotizacion() async {
    if (_detallesVenta.isEmpty || _clienteSelected == null) {
      if (_clienteSelected == null) {
        setState(() {
          _clienteError = true;
        });
      }
      if (_detallesVenta.isEmpty) {
        setState(() {
          _detallesError = true;
        });
      }
      return;
    }

    _canFocus = false;
    final bool continuar =
        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: AppTheme.backgroundColor,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '¿Deseas continuar y guardar estos\ndatos de venta como una cotizacion?',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                        child: const Text('Regresar'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                        child: const Text('Continuar'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ) ??
        false;
    if (!continuar) return;

    //Realizar cotizacion///////////////////
    if (!mounted) return;
    final loadingSvc = Provider.of<LoadingProvider>(context, listen: false);
    loadingSvc.show();

    final cotizacionSvc = Provider.of<CotizacionesServices>(
      context,
      listen: false,
    );
    final productoSvc = Provider.of<ProductosServices>(context, listen: false);
    final DateTime now = DateTime.now();

    for (var detalle in _detallesVenta) {
      //Agregar precio actual a la cotizacion
      detalle.cotizacionPrecio =
          productoSvc.productos
              .firstWhere((element) => element.id == detalle.productoId)
              .precio;
    }

    final cotizacion = Cotizaciones(
      clienteId: _clienteSelected!.id!,
      usuarioId: Login.usuarioLogeado.id!,
      sucursalId: SucursalesServices.sucursalActualID!,
      detalles: _detallesVenta,
      fechaCotizacion: now.toIso8601String(),
      comentariosVenta:
          _comentariosController.text.isNotEmpty
              ? _comentariosController.text
              : null,
      subTotal: formatearEntrada(_subtotalController.text),
      descuento: formatearEntrada(_totalDescuentoController.text),
      iva: formatearEntrada(_ivaController.text),
      total: formatearEntrada(_totalController.text),
      vigente: true,
    );

    String folio = await cotizacionSvc.createCotizacion(cotizacion);

    DateTime lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    String vigencia =
        '${lastDayOfMonth.day}/${lastDayOfMonth.month}/${lastDayOfMonth.year}';

    loadingSvc.hide();
    //Realizar cotizacion finalizado ///////////////

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (_) {
        return Stack(
          alignment: Alignment.topRight,
          children: [
            AlertDialog(
              backgroundColor: AppTheme.containerColor2,
              title: const Center(child: Text('  ¡Cotizacion guardada!  ')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'La cotización será válida hasta el último\ndía del mes en curso.',
                    style: TextStyle(color: Colors.white38),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text('Vigencia:', textScaler: TextScaler.linear(1.1)),
                  Text(
                    vigencia,
                    style: AppTheme.tituloClaro,
                    textScaler: const TextScaler.linear(1.25),
                  ),
                  const SizedBox(height: 10),
                  SelectableText(
                    'Folio: $folio',
                    textScaler: const TextScaler.linear(1.1),
                  ),

                  const SizedBox(height: 25),
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(Icons.print, color: Colors.transparent),
                            Transform.translate(
                              offset: const Offset(0, -1.5),
                              child: const Text('  Imprimir'),
                            ),
                            const Icon(Icons.print),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {},
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(Icons.send, color: Colors.transparent),
                            Transform.translate(
                              offset: const Offset(0, -1.5),
                              child: const Text('  Enviar por WhatsApp'),
                            ),
                            const Icon(Icons.send),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {},
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(Icons.email, color: Colors.transparent),
                            Transform.translate(
                              offset: const Offset(0, -1.5),
                              child: const Text('  Enviar por Correo'),
                            ),
                            const Icon(Icons.email),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const WindowBar(overlay: true),
          ],
        );
      },
    ).then((value) {
      //limpiar screen
      widget.rebuild(widget.index);
    });

    _canFocus = true;
  }

  Future<void> seleccionarArchivos() async {
    _canFocus = false;
    final loadingSvc = Provider.of<LoadingProvider>(context, listen: false);
    loadingSvc.show();

    final result = await FilePicker.platform.pickFiles(
      lockParentWindow: true,
      allowMultiple: true,
      dialogTitle: 'Selecciona los archivos para el pedido',
    );
    if (result != null) {
      setState(() {
        _fileSeleccionado = result.paths.map((p) => File(p!)).toList();
        VentasStates.tabs[widget.index].fileSeleccionado = _fileSeleccionado;
      });
    }
    _canFocus = true;
    loadingSvc.hide();
  }

  @override
  Widget build(BuildContext context) {
    final productosServices = Provider.of<ProductosServices>(context);
    final clientesServices = Provider.of<ClientesServices>(context);

    InputDecoration totalDecoration = AppTheme.inputDecorationCustom.copyWith(
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: _detallesError ? Colors.red : AppTheme.letraClara,
        ),
      ),
    );

    if (Configuracion.memoryCorte != null) {
      return Expanded(
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.containerColor1,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(15),
              bottomLeft: Radius.circular(15),
              bottomRight: Radius.circular(15),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning, color: AppTheme.warningStyle.color),
                  Text(
                    ' Acceso temporalmente restringido. Se ha detectado un proceso de cierre de ${Configuracion.memoryCorte!.isCierre ? 'caja' : 'turno'} incompleto. ',
                    textAlign: TextAlign.center,
                    textScaler: const TextScaler.linear(1.15),
                  ),
                  Icon(Icons.warning, color: AppTheme.warningStyle.color),
                ],
              ),
              const Text(
                'Para mantener la consistencia contable y continuar operando, es necesario completar el corte pendiente antes de procesar nuevas ventas.',
                textAlign: TextAlign.center,
                style: AppTheme.labelStyle,
              ),
            ],
          ),
        ),
      );
    }

    return Flexible(
      //Contenido (Body)
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.containerColor1,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(15),
            bottomLeft: Radius.circular(15),
            bottomRight: Radius.circular(15),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Form(
            key: _formKey,

            child: Column(
              children: [
                Flexible(
                  child: FocusScope(
                    canRequestFocus: !_fromVentaEnviada,
                    child: Column(
                      children: [
                        //primera fila
                        IgnorePointer(
                          ignoring: _fromVentaEnviada,
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  //Formulario de clientes
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Tooltip(
                                      message: "Presiona Enter con el campo vacío para asignar 'Público General'.",
                                      child: Text(
                                        '   Cliente *',
                                        style: AppTheme.subtituloPrimario,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: BusquedaField<Clientes>(
                                            items: clientesServices.clientes,
                                            selectedItem: _clienteSelected,
                                            onItemSelected: (
                                              Clientes? selected,
                                            ) {
                                              setState(() {
                                                _clienteSelected = selected;
                                                VentasStates
                                                        .tabs[widget.index]
                                                        .clienteSelected =
                                                    selected; // Actualizar el estado global
                                                if (_clienteSelected != null) {
                                                  _clienteError = false;
                                                }
                                              });
                                            },
                                            onItemUnselected: () {
                                              debugPrint(
                                                'No se selecciono nada!',
                                              );
                                            },
                                            displayStringForOption:
                                                (cliente) => cliente.nombre,
                                            secondaryDisplayStringForOption:
                                                (cliente) =>
                                                    cliente.telefono
                                                                .toString() ==
                                                            'null'
                                                        ? ''
                                                        : cliente.telefono
                                                            .toString(),
                                            showSecondaryFirst: false,
                                            normalBorder: false,
                                            icono: Icons.perm_contact_cal_sharp,
                                            defaultFirst: true,
                                            error: _clienteError,
                                            hintText: 'Buscar Cliente (F1)',
                                            teclaFocus: LogicalKeyboardKey.f1,
                                            onKeyHandler: (KeyEvent event) {
                                              // ← TU CALLBACK PERSONALIZADO
                                              if (event is KeyDownEvent &&
                                                  event.logicalKey ==
                                                      LogicalKeyboardKey.f1) {
                                                return !_canFocus; // true = consumir evento (bloquear), false = permitir
                                              }
                                              return false;
                                            },
                                          ),
                                        ),
                                        Container(
                                          height: 40,
                                          width: 42,
                                          decoration: const BoxDecoration(
                                            color: AppTheme.letraClara,
                                            borderRadius: BorderRadius.only(
                                              topRight: Radius.circular(30),
                                              bottomRight: Radius.circular(30),
                                            ),
                                          ),
                                          child: Center(
                                            child: FeedBackButton(
                                              onPressed: () async {
                                                Clientes?
                                                clienteCreated = await showDialog(
                                                  context: context,
                                                  builder:
                                                      (_) => const Stack(
                                                        alignment:
                                                            Alignment.topRight,
                                                        children: [
                                                          ClientesFormDialog(),
                                                          WindowBar(
                                                            overlay: true,
                                                          ),
                                                        ],
                                                      ),
                                                );
                                                if (clienteCreated != null) {
                                                  setState(() {
                                                    _clienteSelected =
                                                        clienteCreated;
                                                  });
                                                }
                                              },
                                              child: Icon(
                                                Icons.add,
                                                color: AppTheme.containerColor1,
                                                size: 28,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 15),

                              Column(
                                //Fecha de Entrega
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    '  Fecha de Entrega:',
                                    style: AppTheme.subtituloPrimario,
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                        43,
                                        255,
                                        255,
                                        255,
                                      ),
                                      border: Border.all(
                                        color: AppTheme.letraClara,
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(30),
                                        bottomLeft: Radius.circular(30),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(3),
                                      child: Row(
                                        children: [
                                          Checkbox(
                                            focusNode: _checkboxFocus1,
                                            value: _entregaInmediata,
                                            focusColor: AppTheme.focusColor,
                                            onChanged: (value) {
                                              if (_entregaInmediata == true) {
                                                return;
                                              }
                                              setState(() {
                                                _fechaEntrega = null;
                                                VentasStates
                                                    .tabs[widget.index]
                                                    .fechaEntrega = null;
                                                _checkboxFocus1.requestFocus();
                                                _entregaInmediata = value!;
                                                VentasStates
                                                    .tabs[widget.index]
                                                    .entregaInmediata = value;
                                              });
                                            },
                                          ),
                                          const Text('Entrega inmediata   '),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  _fromVentaEnviada
                                      ? Transform.translate(
                                        offset: const Offset(7, -8),
                                        child: const Icon(
                                          Icons.lock,
                                          color: AppTheme.letraClara,
                                        ),
                                      )
                                      : const SizedBox(),

                                  Column(
                                    //Fecha de Entrega otro dia
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          const Text(''),
                                          _entregaInmediata
                                              ? const Text(
                                                '  ¿Es un pedido?',
                                                style: AppTheme.labelStyle,
                                                textScaler: TextScaler.linear(
                                                  0.85,
                                                ),
                                              )
                                              : const Text(
                                                '  Esta venta sera un pedido',
                                                style: AppTheme.labelStyle,
                                                textScaler: TextScaler.linear(
                                                  0.85,
                                                ),
                                              ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: const Color.fromARGB(
                                                43,
                                                255,
                                                255,
                                                255,
                                              ),
                                              border: Border.all(
                                                color: AppTheme.letraClara,
                                              ),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(3),
                                              child: Row(
                                                children: [
                                                  Checkbox(
                                                    focusNode: _checkboxFocus2,
                                                    focusColor:
                                                        AppTheme.focusColor,
                                                    value: !_entregaInmediata,
                                                    onChanged: (value) async {
                                                      await elegirFecha();
                                                    },
                                                  ),
                                                  SizedBox(
                                                    width: 140,
                                                    child:
                                                        _fechaEntrega == null
                                                            ? const Text(
                                                              'Crear pedido  ',
                                                            )
                                                            : Center(
                                                              child: Text(
                                                                //'${_fechaEntrega!.day}/${_fechaEntrega!.month}/${_fechaEntrega!.year}',
                                                                DateFormat(
                                                                      'dd / MMM / yyyy',
                                                                      'es_MX',
                                                                    )
                                                                    .format(
                                                                      _fechaEntrega!,
                                                                    )
                                                                    .toUpperCase(),
                                                                style:
                                                                    AppTheme
                                                                        .tituloClaro,
                                                              ),
                                                            ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Container(
                                            height: 40,
                                            width: 120,
                                            decoration: const BoxDecoration(
                                              color: AppTheme.letraClara,
                                              borderRadius: BorderRadius.only(
                                                topRight: Radius.circular(30),
                                                bottomRight: Radius.circular(
                                                  30,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        right: 8,
                                                      ),
                                                  child: Text(
                                                    _fechaEntrega == null
                                                        ? '--:--:--   '
                                                        : DateFormat(
                                                          'hh:mm a',
                                                          'en_US',
                                                        ).format(
                                                          _fechaEntrega!,
                                                        ),
                                                    style: TextStyle(
                                                      color:
                                                          AppTheme
                                                              .containerColor1,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                Center(
                                                  child: FeedBackButton(
                                                    onPressed: () async {
                                                      await elegirFecha();
                                                    },
                                                    child: Icon(
                                                      Icons.calendar_month,
                                                      color:
                                                          AppTheme
                                                              .containerColor1,
                                                      size: 28,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        //segunda fila
                        IgnorePointer(
                          ignoring: _fromVentaEnviada,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  //Formulario de Producto
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      '   Producto *',
                                      style: AppTheme.subtituloPrimario,
                                    ),
                                    const SizedBox(height: 2),
                                    BusquedaField<Productos>(
                                      items: productosServices.productos,
                                      selectedItem: _productoSelected,
                                      onItemSelected: (Productos? selected) {
                                        setState(() {
                                          _productoSelected = selected;
                                          VentasStates
                                              .tabs[widget.index]
                                              .productoSelected = selected;
                                          calcularTotalDetalle();
                                        });
                                      },
                                      onItemUnselected: () {
                                        limpiarCamposProducto();
                                      },
                                      displayStringForOption:
                                          (producto) => producto.descripcion,
                                      normalBorder: true,
                                      icono: Icons.copy,
                                      defaultFirst: false,
                                      secondaryDisplayStringForOption:
                                          (producto) =>
                                              producto.codigo.toString(),
                                      hintText: 'Buscar Producto (F2)',
                                      teclaFocus: LogicalKeyboardKey.f2,
                                      error: false,
                                      onKeyHandler: (KeyEvent event) {
                                        // ← TU CALLBACK PERSONALIZADO
                                        if (event is KeyDownEvent &&
                                            event.logicalKey ==
                                                LogicalKeyboardKey.f2) {
                                          return !_canFocus; // true = consumir evento (bloquear), false = permitir
                                        }
                                        return false;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 15),

                              Column(
                                //Precio por unidad
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Tooltip(
                                    message: '¡Precio sin IVA!',
                                    child: Text(
                                      ' Precio/Unidad',
                                      style: AppTheme.subtituloPrimario,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  SizedBox(
                                    height: 40,
                                    width: 110,
                                    child: TextFormField(
                                      controller: _precioController,
                                      canRequestFocus: false,
                                      readOnly: true,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 15),

                              Column(
                                //Precio por unidad
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    '   Cantidad',
                                    style: AppTheme.subtituloPrimario,
                                  ),
                                  const SizedBox(height: 2),
                                  SizedBox(
                                    height: 40,
                                    width: 100,
                                    child: Focus(
                                      canRequestFocus: false,
                                      onFocusChange: (value) {
                                        if (value == false &&
                                            _cantidadController.text == '') {
                                          _cantidadController.text = '1';
                                          setState(() {
                                            calcularTotalDetalle();
                                          });
                                        }
                                      },
                                      child: TextFormField(
                                        controller: _cantidadController,
                                        buildCounter:
                                            (
                                              _, {
                                              required int currentLength,
                                              required bool isFocused,
                                              required int? maxLength,
                                            }) => null,
                                        maxLength: 6,
                                        inputFormatters: [NumericFormatter()],
                                        onFieldSubmitted:
                                            (value) => agregarProducto(),
                                        onChanged: (value) {
                                          setState(() {
                                            calcularTotalDetalle();
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ), //const SizedBox(width: 15),

                              _productoSelected?.requiereMedida == true
                                  ? Padding(
                                    padding: const EdgeInsets.only(left: 15),
                                    child: Row(
                                      children: [
                                        Column(
                                          //Precio por unidad
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                              '   Ancho',
                                              style: AppTheme.subtituloPrimario,
                                            ),
                                            const SizedBox(height: 2),
                                            SizedBox(
                                              height: 40,
                                              width: 100,
                                              child: TextFormField(
                                                buildCounter:
                                                    (
                                                      _, {
                                                      required int
                                                      currentLength,
                                                      required bool isFocused,
                                                      required int? maxLength,
                                                    }) => null,
                                                maxLength: 4,
                                                controller: _anchoController,
                                                inputFormatters: [
                                                  DecimalInputFormatter(),
                                                ],
                                                keyboardType:
                                                    const TextInputType.numberWithOptions(
                                                      decimal: true,
                                                    ),
                                                decoration:
                                                    _anchoError
                                                        ? AppTheme.inputError
                                                        : AppTheme.inputNormal,
                                                onFieldSubmitted:
                                                    (value) =>
                                                        agregarProducto(),
                                                onChanged: (value) {
                                                  if (value.isNotEmpty &&
                                                      value != '0') {
                                                    setState(() {
                                                      _anchoError = false;
                                                    });
                                                  } else {
                                                    setState(() {
                                                      _anchoError = true;
                                                    });
                                                  }

                                                  //No exeder el limite de anchura
                                                  if (value.isNotEmpty) {
                                                    if (value == '.') {
                                                      value = '';
                                                      return;
                                                    }
                                                    if (double.parse(
                                                          value.replaceAll(
                                                            ',',
                                                            '',
                                                          ),
                                                        ) >
                                                        Constantes
                                                            .anchoMaximo) {
                                                      _anchoController.text =
                                                          Constantes.anchoMaximo
                                                              .toString();
                                                    }
                                                  }

                                                  if (_anchoController
                                                          .text
                                                          .isNotEmpty &&
                                                      _altoController
                                                          .text
                                                          .isNotEmpty) {
                                                    if (_anchoController.text !=
                                                            '0' &&
                                                        _altoController.text !=
                                                            '0') {
                                                      setState(() {
                                                        calcularTotalDetalle();
                                                      });
                                                    }
                                                  }
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 15),

                                        Column(
                                          //Precio por unidad
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                              '   Alto',
                                              style: AppTheme.subtituloPrimario,
                                            ),
                                            const SizedBox(height: 2),
                                            SizedBox(
                                              height: 40,
                                              width: 100,
                                              child: TextFormField(
                                                buildCounter:
                                                    (
                                                      _, {
                                                      required int
                                                      currentLength,
                                                      required bool isFocused,
                                                      required int? maxLength,
                                                    }) => null,
                                                maxLength: 4,
                                                controller: _altoController,
                                                inputFormatters: [
                                                  DecimalInputFormatter(),
                                                ],
                                                keyboardType:
                                                    const TextInputType.numberWithOptions(
                                                      decimal: true,
                                                    ),
                                                decoration:
                                                    _altoError
                                                        ? AppTheme.inputError
                                                        : AppTheme.inputNormal,
                                                onFieldSubmitted:
                                                    (value) =>
                                                        agregarProducto(),
                                                onChanged: (value) {
                                                  if (value.isNotEmpty &&
                                                      value != '0') {
                                                    setState(() {
                                                      _altoError = false;
                                                    });
                                                  } else {
                                                    setState(() {
                                                      _altoError = true;
                                                    });
                                                  }

                                                  //No exeder el limite de altura
                                                  if (value.isNotEmpty) {
                                                    if (value == '.') {
                                                      value = '';
                                                      return;
                                                    }
                                                    if (double.parse(
                                                          value.replaceAll(
                                                            ',',
                                                            '',
                                                          ),
                                                        ) >
                                                        Constantes.altoMaximo) {
                                                      _altoController.text =
                                                          Constantes.altoMaximo
                                                              .toString();
                                                    }
                                                  }

                                                  if (_anchoController
                                                          .text
                                                          .isNotEmpty &&
                                                      _altoController
                                                          .text
                                                          .isNotEmpty) {
                                                    if (_anchoController.text !=
                                                            '0' &&
                                                        _altoController.text !=
                                                            '0') {
                                                      setState(() {
                                                        calcularTotalDetalle();
                                                      });
                                                    }
                                                  }
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  )
                                  : const SizedBox(),

                              !_entregaInmediata
                                  ? _fileSeleccionado.isEmpty
                                      ? Padding(
                                        padding: const EdgeInsets.only(
                                          left: 15,
                                        ),
                                        child: ElevatedButtonIcon(
                                          text: 'Subir archivo',
                                          icon: Icons.upload,
                                          onPressed:
                                              () => seleccionarArchivos(),
                                        ),
                                      )
                                      : Tooltip(
                                        message: _fileSeleccionado
                                            .map((f) => f.path.split('\\').last)
                                            .join('\n'),
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            left: 15,
                                          ),
                                          child: Container(
                                            width:
                                                _fileSeleccionado.length > 1
                                                    ? 176
                                                    : 156,
                                            decoration: BoxDecoration(
                                              color: AppTheme.letra70,
                                              borderRadius:
                                                  BorderRadius.circular(22),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(10),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    _fileSeleccionado.length > 1
                                                        ? '${_fileSeleccionado.length} Archivos subidos'
                                                        : 'Archivo subido',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color:
                                                          AppTheme
                                                              .containerColor1,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      //fontSize: 12
                                                    ),
                                                  ),
                                                  Transform.translate(
                                                    offset: const Offset(10, 0),
                                                    child: Icon(
                                                      Icons.filter_rounded,
                                                      color: AppTheme.primario1,
                                                      size: 20,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                  : const SizedBox(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        //tercer fila
                        IgnorePointer(
                          ignoring: _fromVentaEnviada,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  //Formulario de Producto
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      '   Comentario',
                                      style: AppTheme.subtituloPrimario,
                                    ),
                                    const SizedBox(height: 2),
                                    TextFormField(
                                      buildCounter:
                                          (
                                            _, {
                                            required int currentLength,
                                            required bool isFocused,
                                            required int? maxLength,
                                          }) => null,
                                      maxLength: 100,
                                      controller: _comentarioController,
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        prefixIcon: Icon(
                                          Icons.comment,
                                          size: 25,
                                          color: AppTheme.letra70,
                                        ),
                                      ),
                                      onFieldSubmitted:
                                          (value) => agregarProducto(),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 15),

                              Expanded(
                                child: Column(
                                  //Formulario de Producto
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      '   % Descuento',
                                      style: AppTheme.subtituloPrimario,
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Focus(
                                            canRequestFocus: false,
                                            onFocusChange: (hasFocus) {
                                              if (!hasFocus) {
                                                if (_descuentoController
                                                    .text
                                                    .isEmpty) {
                                                  _descuentoController.text =
                                                      '0';
                                                  calcularTotalDetalle();
                                                }
                                                _descuentoController.text =
                                                    '${_descuentoController.text.replaceAll('%', '')}%';
                                              } else {
                                                _descuentoController.text = '';
                                                calcularTotalDetalle();
                                              }
                                            },
                                            child: TextFormField(
                                              buildCounter:
                                                  (
                                                    _, {
                                                    required int currentLength,
                                                    required bool isFocused,
                                                    required int? maxLength,
                                                  }) => null,
                                              canRequestFocus: _permisoDeAdmin,
                                              readOnly: !_permisoDeAdmin,
                                              maxLength: 4,
                                              controller: _descuentoController,
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly,
                                              ],
                                              decoration:
                                                  _permisoDeAdmin
                                                      ? const InputDecoration(
                                                        isDense: true,
                                                        prefixIcon: Icon(
                                                          Icons
                                                              .discount_outlined,
                                                          size: 25,
                                                          color:
                                                              AppTheme.letra70,
                                                        ),
                                                      )
                                                      : const InputDecoration(
                                                        isDense: true,
                                                        prefixIcon: Icon(
                                                          Icons
                                                              .discount_outlined,
                                                          size: 25,
                                                          color:
                                                              AppTheme.letra70,
                                                        ),
                                                        enabledBorder: OutlineInputBorder(
                                                          borderSide: BorderSide(
                                                            color:
                                                                AppTheme
                                                                    .letraClara,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.only(
                                                                topLeft:
                                                                    Radius.circular(
                                                                      30,
                                                                    ),
                                                                bottomLeft:
                                                                    Radius.circular(
                                                                      30,
                                                                    ),
                                                              ),
                                                        ),
                                                        focusedBorder: OutlineInputBorder(
                                                          borderSide: BorderSide(
                                                            color:
                                                                AppTheme
                                                                    .letraClara,
                                                            width: 2,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.only(
                                                                topLeft:
                                                                    Radius.circular(
                                                                      30,
                                                                    ),
                                                                bottomLeft:
                                                                    Radius.circular(
                                                                      30,
                                                                    ),
                                                              ),
                                                        ),
                                                      ),
                                              onFieldSubmitted:
                                                  (value) => agregarProducto(),
                                              onChanged: (value) {
                                                if (_descuentoController
                                                    .text
                                                    .isEmpty) {
                                                  _descuentoController.text =
                                                      '0';
                                                }
                                                if (int.parse(
                                                      _descuentoController.text,
                                                    ) >
                                                    100) {
                                                  _descuentoController.text =
                                                      '100';
                                                }
                                                calcularTotalDetalle();
                                              },
                                            ),
                                          ),
                                        ),
                                        _permisoDeAdmin
                                            ? const SizedBox()
                                            : Container(
                                              height: 40,
                                              width: 42,
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.only(
                                                  topRight: Radius.circular(30),
                                                  bottomRight: Radius.circular(
                                                    30,
                                                  ),
                                                ),
                                              ),
                                              child: FocusScope(
                                                canRequestFocus: false,
                                                child: IconButton(
                                                  onPressed: () async {
                                                    bool? permiso =
                                                        await mostrarDialogoPermiso(
                                                          context,
                                                        );
                                                    if (permiso != null) {
                                                      if (permiso == true) {
                                                        setState(() {
                                                          _permisoDeAdmin =
                                                              true;
                                                          VentasStates
                                                                  .tabs[widget
                                                                      .index]
                                                                  .permisoDeAdmin =
                                                              true;
                                                        });
                                                      }
                                                    }
                                                  },
                                                  icon: Transform.translate(
                                                    offset: const Offset(
                                                      -2.5,
                                                      0,
                                                    ),
                                                    child: Icon(
                                                      Icons.lock,
                                                      color:
                                                          AppTheme
                                                              .containerColor2,
                                                      size: 24,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 15),

                              Expanded(
                                child: Column(
                                  //Formulario de Producto
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '   IVA (${Configuracion.iva}%)',
                                      style: AppTheme.subtituloPrimario,
                                    ),
                                    const SizedBox(height: 2),
                                    SizedBox(
                                      height: 40,
                                      child: TextFormField(
                                        buildCounter:
                                            (
                                              _, {
                                              required int currentLength,
                                              required bool isFocused,
                                              required int? maxLength,
                                            }) => null,
                                        maxLength: 3,
                                        controller: _ivaController,
                                        canRequestFocus: false,
                                        readOnly: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 15),

                              Expanded(
                                child: Column(
                                  //Formulario de Producto
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      '   Total',
                                      style: AppTheme.subtituloPrimario,
                                    ),
                                    const SizedBox(height: 2),
                                    SizedBox(
                                      height: 40,
                                      child: TextFormField(
                                        controller: _productoTotalController,
                                        canRequestFocus: false,
                                        readOnly: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 15),

                              ElevatedButton(
                                focusNode: _botonFocus,
                                onFocusChange: (hasFocus) {
                                  if (!hasFocus) {
                                    if (_tabPressed) {
                                      _comentariosFocus.requestFocus();
                                    }
                                    _tabPressed = false;
                                  }
                                },
                                onPressed: () => agregarProducto(),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Stack(
                                    alignment: Alignment.centerLeft,
                                    children: [
                                      Transform.translate(
                                        offset: const Offset(8, 0),
                                        child: Text(
                                          '  Agregar Producto',
                                          style: TextStyle(
                                            color: AppTheme.containerColor1,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Transform.translate(
                                        offset: const Offset(-8, 0),
                                        child: const Icon(Icons.add),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.only(
                            top: 4,
                            bottom: 2,
                            right: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              CajasServices.cajaActual != null
                                  ? Text(
                                    'Precio del dolar: ${Formatos.pesos.format(CajasServices.cajaActual!.tipoCambio.toDouble())}',
                                  )
                                  : const Text(''),
                            ],
                          ),
                        ),

                        //Tabla de detalles
                        Expanded(
                          child: Column(
                            children: [
                              // Cabecera
                              Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(10),
                                    topRight: Radius.circular(10),
                                  ),
                                  color: AppTheme.tablaColorHeader,
                                ),
                                child: const Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Cant.',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 8,
                                      child: Text(
                                        'Producto',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 4,
                                      child: Text(
                                        'Precio/Unidad',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 4,
                                      child: Text(
                                        'Subtotal',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 4,
                                      child: Text(
                                        'Descuento',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        'IVA',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 4,
                                      child: Text(
                                        'Total',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Lista de datos
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(10),
                                    bottomRight: Radius.circular(10),
                                  ),
                                  child:
                                      _detallesVenta.isNotEmpty
                                          ? FocusScope(
                                            canRequestFocus: _canFocus,
                                            child: AbsorbPointer(
                                              absorbing: _fromVentaEnviada,
                                              child: ListView.builder(
                                                controller: _scrollController,
                                                itemCount:
                                                    _detallesVenta.length,
                                                itemBuilder: (context, index) {
                                                  return FilaDetalles(
                                                    index: index,
                                                    detalle:
                                                        _detallesVenta[index],
                                                    producto: _productos[index],
                                                    onDelete: () {
                                                      _detallesVenta.removeAt(
                                                        index,
                                                      );
                                                      _productos.removeAt(
                                                        index,
                                                      );
                                                      calcularTotal();
                                                      setState(() {});
                                                    },
                                                    onModificate: () {
                                                      if (VentasStates
                                                          .tabs[widget.index]
                                                          .modificando)
                                                        return;
                                                      modificate(
                                                        productosServices,
                                                        index,
                                                      );
                                                    },
                                                    isLast:
                                                        _detallesVenta.length ==
                                                        index + 1,
                                                  );
                                                },
                                              ),
                                            ),
                                          )
                                          : const FilaDetalles(
                                            index: -1,
                                            isLast: true,
                                          ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                //Inferior, cometarios, procesar, total.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 5,
                      child: TextFormField(
                        buildCounter:
                            (
                              _, {
                              required int currentLength,
                              required bool isFocused,
                              required int? maxLength,
                            }) => null,
                        maxLength: 250,
                        controller: _comentariosController,
                        focusNode: _comentariosFocus,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText: 'Comentarios de la venta',
                          hintStyle: TextStyle(color: AppTheme.letra70),
                          isDense: true,
                          contentPadding: EdgeInsets.only(left: 10, top: 20),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppTheme.letraClara,
                              width: 3,
                            ),
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                      ),
                    ),

                    Expanded(
                      flex: 8,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Configuracion.esCaja
                                    ? ElevatedButton(
                                      focusNode: _f8FocusNode,
                                      onPressed: () {
                                        procesarPago();
                                      },
                                      style: AppTheme.botonPrincipalStyle,
                                      child: const Text(
                                        '      Procesar Pago  (F8)     ',
                                        style: TextStyle(
                                          color: AppTheme.letraClara,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    )
                                    : ElevatedButton(
                                      focusNode: _f8FocusNode,
                                      onPressed: () {
                                        procesarEnvio();
                                      },
                                      style: AppTheme.botonPrincipalStyle,
                                      child: const Text(
                                        '      Enviar a Caja  (F8)     ',
                                        style: TextStyle(
                                          color: AppTheme.letraClara,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                const SizedBox(height: 10),
                                /*Tooltip(  //TODO: en desarrollo
                                  message: 'Funcion en desarrollo', //TODO: quitar tooltip cuando lo habilite
                                  child: ElevatedButton(
                                    onPressed: (){
                                      //procesarCotizacion(); TODO: deshabilitado
                                    },
                                    child: Text('Guardar como cotizacion', style: TextStyle(color: AppTheme.containerColor1, fontWeight: FontWeight.w700)),
                                  ),
                                ),*/
                              ],
                            ),
                          ),

                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Subtotal:  ',
                                    style: AppTheme.subtituloPrimario,
                                  ),
                                  SizedBox(
                                    height: 32,
                                    width: 150,
                                    child: TextFormField(
                                      controller: _subtotalController,
                                      canRequestFocus: false,
                                      readOnly: true,
                                      decoration: totalDecoration,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const Text(
                                    '- Descuento:  ',
                                    style: AppTheme.subtituloPrimario,
                                  ),
                                  SizedBox(
                                    height: 32,
                                    width: 150,
                                    child: TextFormField(
                                      controller: _totalDescuentoController,
                                      canRequestFocus: false,
                                      readOnly: true,
                                      decoration: totalDecoration,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const Text(
                                    '+ IVA:  ',
                                    style: AppTheme.subtituloPrimario,
                                  ),
                                  SizedBox(
                                    height: 32,
                                    width: 150,
                                    child: TextFormField(
                                      controller: _totalIvaController,
                                      canRequestFocus: false,
                                      readOnly: true,
                                      decoration: totalDecoration,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Total:  ',
                                    style: AppTheme.tituloPrimario,
                                  ),
                                  SizedBox(
                                    height: 36,
                                    width: 150,
                                    child: TextFormField(
                                      controller: _totalController,
                                      canRequestFocus: false,
                                      readOnly: true,
                                      decoration: totalDecoration,
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FilaDetalles extends StatelessWidget {
  const FilaDetalles({
    super.key,
    required this.index,
    this.detalle,
    this.producto,
    this.onDelete,
    this.onModificate,
    required this.isLast,
  });

  final int index;
  final DetallesVenta? detalle;
  final Productos? producto;
  final VoidCallback? onDelete;
  final VoidCallback? onModificate;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    if (index == -1) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: const BorderRadiusGeometry.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(color: AppTheme.tablaColor1),
              child: const Center(
                child: Text(
                  'No hay productos agregados',
                  style: TextStyle(color: Colors.transparent),
                ),
              ),
            ),
          ),
        ],
      );
    }

    String descripcionProducto = producto!.descripcion;
    if (producto!.requiereMedida) {
      descripcionProducto += ' (${detalle!.ancho} x ${detalle!.alto})';
    }

    void mostrarMenu(BuildContext context, Offset offset) async {
      final seleccion = await showMenu(
        context: context,
        position: RelativeRect.fromLTRB(
          offset.dx,
          offset.dy,
          offset.dx,
          offset.dy,
        ),
        color: AppTheme.dropDownColor,
        elevation: 4,
        shadowColor: Colors.black,
        items: [
          const PopupMenuItem(
            value: 'modificar',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit, color: AppTheme.letraClara, size: 17),
                Text('  Modificar', style: AppTheme.subtituloPrimario),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'eliminar',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.clear, color: AppTheme.letraClara, size: 17),
                Text('  Eliminar', style: AppTheme.subtituloPrimario),
              ],
            ),
          ),
        ],
      );

      if (seleccion == 'modificar') {
        // Lógica para modificar
        onModificate!();
      } else if (seleccion == 'eliminar') {
        // Lógica para eliminar
        onDelete!();
      }
    }

    return FeedBackButton(
      onPressed: () {},
      onlyVertical: true,
      child: GestureDetector(
        onSecondaryTapDown: (details) {
          mostrarMenu(context, details.globalPosition);
        },
        child: ClipRRect(
          borderRadius: BorderRadiusGeometry.only(
            bottomLeft: Radius.circular(isLast ? 10 : 0),
            bottomRight: Radius.circular(isLast ? 10 : 0),
          ),
          child: Container(
            padding: const EdgeInsets.all(8.0),
            color: index % 2 == 0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        Formatos.numero.format(detalle!.cantidad.toDouble()),
                        style: AppTheme.subtituloConstraste,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 8,
                      child: Text(
                        descripcionProducto,
                        style: AppTheme.subtituloConstraste,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        Formatos.pesos.format(producto!.precio.toDouble()),
                        style: AppTheme.subtituloConstraste,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        Formatos.pesos.format(detalle!.subtotal.toDouble()),
                        style: AppTheme.subtituloConstraste,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        Formatos.pesos.format(
                          detalle!.descuentoAplicado.toDouble(),
                        ),
                        style: AppTheme.subtituloConstraste,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        Formatos.pesos.format(detalle!.iva.toDouble()),
                        style: AppTheme.subtituloConstraste,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        Formatos.pesos.format(detalle!.total.toDouble()),
                        style: AppTheme.subtituloConstraste,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                detalle!.archivos?.isNotEmpty ?? false
                    ? Icon(
                      Icons.filter_rounded,
                      color:
                          AppTheme.isDarkTheme
                              ? AppTheme.letraClara
                              : AppTheme.primario1,
                      size: 20,
                    )
                    : const SizedBox(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CreandoPedido extends StatefulWidget {
  const CreandoPedido({super.key, required this.pedido, required this.files});

  final Pedidos pedido;
  final List<File> files;

  @override
  State<CreandoPedido> createState() => _CreandoPedidoState();
}

class _CreandoPedidoState extends State<CreandoPedido> {
  int pedidosListos = 1;
  List<String> pedidosIds = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      subirPedido();
    });
  }

  void subirPedido() async {
    final pedidosService = Provider.of<PedidosService>(context, listen: false);
    String pedidoId = await pedidosService.createPedido(
      pedido: widget.pedido,
      archivos: widget.files,
    );
    pedidosIds.add(pedidoId);

    if (!mounted) return;
    Navigator.pop(context, pedidosIds);
  }

  @override
  Widget build(BuildContext context) {
    final pedidosService = Provider.of<PedidosService>(context);
    return AlertDialog(
      title: Center(
        child: Text(widget.files.isNotEmpty ? 'Subiendo archivo...' : ''),
      ),
      backgroundColor: AppTheme.containerColor2,
      content: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: LinearProgressIndicator(
                  value: pedidosService.uploadProgress,
                  minHeight: 10,
                  color: AppTheme.containerColor1.withAlpha(150),
                ),
              ),
              Text(
                '${(pedidosService.uploadProgress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
