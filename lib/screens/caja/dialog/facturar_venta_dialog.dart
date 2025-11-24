import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/screens/catalogo/forms/clientes_form.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/busqueda_field.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';
import 'package:provider/provider.dart';

class FacturarVentaDialog extends StatefulWidget {
  const FacturarVentaDialog({super.key, required this.venta});

  final Ventas venta;

  @override
  State<FacturarVentaDialog> createState() => _FacturarVentaDialogState();
}

class _FacturarVentaDialogState extends State<FacturarVentaDialog> {
  late Clientes? _clienteSelected;
  bool _clienteError = false;

  String? _formaPagoSeleccionado;
  bool _formaPagoEmpty = false;
  final List<DropdownMenuItem<String>> _dropdownItemsFormaPago = [
    const DropdownMenuItem<String>(value: '01', child: Text('Efectivo')),
    const DropdownMenuItem<String>(value: '28', child: Text('Debito')),
    const DropdownMenuItem<String>(value: '04', child: Text('Credito')),
    const DropdownMenuItem<String>(value: '03', child: Text('Transferencia')),
  ];

  String? _usoCfdiSeleccionado;
  bool _usoCfdiEmpty = false;
  late List<DropdownMenuItem<String>> _dropdownItemsCfdiUse;

  late Decimal _descuento;
  late Decimal _impuestos;
  late Decimal _total;

  void facturar() async {
    if (_clienteSelected == null) {
      setState(() {
        _clienteError = true;
      });
      return;
    }

    //verificar que cliente sea apto para facturar
    if (_clienteSelected!.rfc != null){
      if (_clienteSelected!.rfc != 'XAXX010101000'){
        if (
          _clienteSelected!.regimenFiscal == null ||
          _clienteSelected!.codigoPostal == null) {
          setState(() {_clienteError = true;});
          return;
        }
      }
    } else {
      setState(() {_clienteError = true;});
      return;
    }
    

    final factura = Cfdi(
      cfdiType: Constantes.datosDeFacturacion['cfdiType']!,
      expeditionPlace: Constantes.datosDeFacturacion['expeditionPlace']!,
      paymentForm: _formaPagoSeleccionado!,
      paymentMethod: _formaPagoSeleccionado == '04' ? 'PPD' : 'PUE',
      receiver: Receiver(
        rfc: _clienteSelected!.rfc!,
        name: _clienteSelected!.razonSocial!=null ? _clienteSelected!.razonSocial! : _clienteSelected!.nombre,
        cfdiUse: _usoCfdiSeleccionado!,
        fiscalRegime: _clienteSelected!.regimenFiscal!,
        taxZipCode: _clienteSelected!.codigoPostal!.toString(),
      ),
      items: [
        CfdiItem(
          //TODO: por determinar
          productCode: '01010101',
          description: 'Venta mostrador',
          unit: 'Unidad',
          unitCode: 'ACT',
          quantity: 1,
          unitPrice: 100,
          subtotal: 100,
          taxObject: '02',
          taxes: [
            CfdiTax(
              name: 'IVA',
              rate: 0.16,
              total: 16,
              base: 100,
              isRetention: false,
            ),
          ],
          total: 116,
        ),
      ],
    );

    //final s = await FacturasServices().facturarVenta(factura);
    print('facturado');
  }

  @override
  void initState() {
    super.initState();
    final Clientes? cli = Provider.of<ClientesServices>(
      context,
      listen: false,
    ).clientes.cast<Clientes?>().firstWhere(
      (element) => element?.id == widget.venta.clienteId,
      orElse: () => null,
    );
    _clienteSelected = cli;

    //Determinar metodo de pago predefinido
    if ((widget.venta.abonadoMxn != null || widget.venta.abonadoUs != null) &&
        widget.venta.abonadoTarj == null) {
      //Pago con efectivo
      _formaPagoSeleccionado = '01';
    } else if ((widget.venta.abonadoMxn == null &&
            widget.venta.abonadoUs == null) &&
        widget.venta.abonadoTarj != null) {
      //Pago con tarjeta
      if (widget.venta.tipoTarjeta == '28') {
        _formaPagoSeleccionado = '28';
      } else {
        _formaPagoSeleccionado = '04';
      }
    }

    //Calcular descuento, impuestos y total
    _descuento = widget.venta.detalles
        .map((detalle) => detalle.descuentoAplicado)
        .reduce((a, b) => a + b);
    _impuestos = widget.venta.detalles
        .map((detalle) => detalle.iva)
        .reduce((a, b) => a + b);
    _total = widget.venta.detalles
        .map((detalle) => detalle.subtotal)
        .reduce((a, b) => a + b);

    //CFDI Use
    _dropdownItemsCfdiUse =
        Constantes.usoCfdi.entries.map((entry) {
          return DropdownMenuItem<String>(
            value: entry.key,
            child: Text(entry.value),
          );
        }).toList();
    _usoCfdiSeleccionado = _dropdownItemsCfdiUse.first.value;
  }

  @override
  Widget build(BuildContext context) {
    final clientesServices = Provider.of<ClientesServices>(context);

    return AlertDialog(
      elevation: 2,
      backgroundColor: AppTheme.containerColor1,
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Cliente', style: AppTheme.subtituloPrimario),
            const SizedBox(height: 2),

            Row(
              children: [
                Expanded(
                  child: BusquedaField<Clientes>(
                    items: clientesServices.clientes,
                    selectedItem: _clienteSelected,
                    onItemSelected: (Clientes? selected) {
                      setState(() {
                        _clienteSelected = selected;
                        if (_clienteSelected != null) {
                          _clienteError = false;
                        }
                      });
                    },
                    onItemUnselected: () {
                      debugPrint('No se selecciono nada!');
                    },
                    displayStringForOption: (cliente) => cliente.nombre,
                    secondaryDisplayStringForOption:
                        (cliente) =>
                            cliente.telefono.toString() == 'null'
                                ? ''
                                : cliente.telefono.toString(),
                    showSecondaryFirst: false,
                    normalBorder: _clienteSelected != null ? false : true,
                    icono: Icons.perm_contact_cal_sharp,
                    defaultFirst: true,
                    hintText: 'Buscar Cliente',
                    error: _clienteError,
                  ),
                ),
                if (_clienteSelected != null)
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
                    child: FeedBackButton(
                      onPressed: () {
                        if (!context.mounted) {
                          return;
                        }
                        showDialog(
                          context: context,
                          builder:
                              (_) => Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  ClientesFormDialog(
                                    cliEdit: _clienteSelected,
                                    onlyRead: true,
                                  ),
                                  const WindowBar(overlay: true),
                                ],
                              ),
                        );
                      },
                      child: Icon(
                        Icons.info,
                        color: AppTheme.containerColor1,
                        size: 26,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      const Text(
                        'Forma de pago',
                        style: AppTheme.subtituloPrimario,
                      ),
                      const SizedBox(height: 2),
                      CustomDropDown<String>(
                        value: _formaPagoSeleccionado,
                        expanded: true,
                        height: 40,
                        hintText: 'Tipo',
                        empty: _formaPagoEmpty,
                        items: _dropdownItemsFormaPago,
                        onChanged:
                            (val) => setState(() {
                              _formaPagoEmpty = false;
                              _formaPagoSeleccionado = val!;
                            }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      const Text('Uso CFDI', style: AppTheme.subtituloPrimario),
                      const SizedBox(height: 2),
                      CustomDropDown<String>(
                        value: _usoCfdiSeleccionado,
                        height: 40,
                        hintText: 'Uso CFDI',
                        empty: _usoCfdiEmpty,
                        items: _dropdownItemsCfdiUse,
                        onChanged:
                            (val) => setState(() {
                              _usoCfdiEmpty = false;
                              _usoCfdiSeleccionado = val!;
                            }),
                        expanded: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            const Text('Datos de venta', style: AppTheme.subtituloPrimario),
            const SizedBox(height: 2),
            //Tabla header
            Container(
              decoration: BoxDecoration(
                color: AppTheme.tablaColorHeader,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        'Detalles',
                        style: AppTheme.subtituloConstraste,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Descuento',
                        style: AppTheme.subtituloConstraste,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Impuestos',
                        style: AppTheme.subtituloConstraste,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text('Total', style: AppTheme.subtituloConstraste),
                    ),
                  ),
                ],
              ),
            ),

            //Tabla body
            Flexible(
              child: Container(
                color:
                    widget.venta.detalles.length % 2 == 0
                        ? AppTheme.tablaColor1
                        : AppTheme.tablaColor2,
                height: 72,
                child: ListView.builder(
                  itemCount: widget.venta.detalles.length,
                  itemBuilder: (context, index) {
                    return FilaDetallesVenta(
                      detalle: widget.venta.detalles[index],
                      index: index,
                    );
                  },
                ),
              ),
            ),

            //tabla footer
            Container(
              decoration: BoxDecoration(
                color: AppTheme.tablaColorHeader,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text('', style: AppTheme.subtituloConstraste),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        Formatos.pesos.format(_descuento.toDouble()),
                        style: AppTheme.subtituloConstraste,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        Formatos.pesos.format(_impuestos.toDouble()),
                        style: AppTheme.subtituloConstraste,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        Formatos.pesos.format(_total.toDouble()),
                        style: AppTheme.subtituloConstraste,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: () => facturar(),
              child: const Text('Facturar'),
            ),
          ],
        ),
      ),
    );
  }
}

class FilaDetallesVenta extends StatefulWidget {
  const FilaDetallesVenta({
    super.key,
    required this.index,
    required this.detalle,
  });
  final int index;
  final DetallesVenta detalle;

  @override
  State<FilaDetallesVenta> createState() => _FilaDetallesVentaState();
}

class _FilaDetallesVentaState extends State<FilaDetallesVenta> {
  late final Productos? producto;

  @override
  void initState() {
    super.initState();
    producto = Provider.of<ProductosServices>(
      context,
      listen: false,
    ).obtenerProductoPorId(widget.detalle.productoId);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color:
          widget.index % 2 == 0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Text(
                '${widget.detalle.cantidad} ${producto?.descripcion ?? 'No se encontro el producto'}',
                style: AppTheme.subtituloConstraste,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                Formatos.pesos.format(
                  widget.detalle.descuentoAplicado.toDouble(),
                ),
                style: AppTheme.subtituloConstraste,
                textScaler: const TextScaler.linear(0.85),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                Formatos.pesos.format(widget.detalle.iva.toDouble()),
                style: AppTheme.subtituloConstraste,
                textScaler: const TextScaler.linear(0.85),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                Formatos.pesos.format(widget.detalle.subtotal.toDouble()),
                style: AppTheme.subtituloConstraste,
                textScaler: const TextScaler.linear(0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
