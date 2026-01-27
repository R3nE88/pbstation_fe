import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/provider/loading_state.dart';
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
  final Map<String, String> _dropdownItemsFormaPago = {
    '01':'Efectivo',
    '28':'Debito',
    '04':'Credito',
    '03':'Transferencia'
  };

  String? _usoCfdiSeleccionado;
  bool _usoCfdiEmpty = false;

  late Decimal _descuento;
  late Decimal _impuestos;
  late Decimal _total;

  Future<String> facturar() async {
    if (_clienteSelected == null) {
      setState(() {
        _clienteError = true;
      });
      return jsonEncode({'Message':'No seleccionaste un cliente'});
    }

    if (_usoCfdiSeleccionado == null) {
      setState(() {
        _usoCfdiEmpty = true;
      });
      return jsonEncode({'Message':'No seleccionaste uso CFDI'});
    }

    //verificar que cliente sea apto para facturar
    if (_clienteSelected!.rfc != null){
      if (_clienteSelected!.rfc != 'XAXX010101000'){
        if (
          _clienteSelected!.regimenFiscal == null ||
          _clienteSelected!.codigoPostal == null) {
          setState(() {_clienteError = true;});
          return jsonEncode({'Message':'El cliente seleccionado no cumple con los requisitos para facturar.'});
        }
      }
    } else {
      setState(() {_clienteError = true;});
      return jsonEncode({'Message':'El cliente seleccionado no cumple con los requisitos para facturar.'});
    }

    //Loading
    final loadingSvc = Provider.of<LoadingProvider>(context, listen: false);
    loadingSvc.show();

    //Items
    List<CfdiItem> items = [];
    final productosSvc = Provider.of<ProductosServices>(context, listen: false);
    for (DetallesVenta item in widget.venta.detalles) {
      Productos? producto =  productosSvc.obtenerProductoPorId(item.productoId);
      if (producto==null) {
        loadingSvc.hide();
        return jsonEncode({'Message':'Hubo un problema para encontrar un producto'});
      }

      final qty = item.cantidad.toDouble();
      final unitPrice = producto.precio.toDouble();
      final descuento = item.descuentoAplicado.toDouble();

      final subtotalOriginal = qty * unitPrice;
      final subtotalFiscal = subtotalOriginal - descuento;

      final iva = subtotalFiscal * 0.08;
      final totalFiscal = subtotalFiscal + iva;

      items.add(CfdiItem(
        productCode: producto.claveSat,
        description: producto.descripcion,
        unit: Constantes.unidadesSat[producto.unidadSat]!,
        unitCode: producto.unidadSat,
        quantity: qty,
        unitPrice: unitPrice,
        subtotal: double.parse(subtotalOriginal.toStringAsFixed(6)), //((item.subtotal + item.descuentoAplicado) - item.iva).toDouble(),
        discount: descuento,
        taxObject: '02',
        taxes: [
          CfdiTax(
            name: 'IVA',
            rate: (Configuracion.iva/100).toDouble(),
            total: double.parse(iva.toStringAsFixed(6)),
            base: double.parse(subtotalFiscal.toStringAsFixed(6)), //((item.subtotal + item.descuentoAplicado) - item.iva).toDouble(),
            isRetention: false,
          ),
        ],
        total: double.parse(totalFiscal.toStringAsFixed(6)),// item.subtotal.toDouble(),
      ));
    }

    //print(json.encode(items[0]));
    
    //crear objeto Factura
    final cfdi = Cfdi(
      cfdiType: Constantes.datosDeFacturacion['cfdiType']!,
      expeditionPlace: Constantes.datosDeFacturacion['expeditionPlace']!,
      paymentForm: _formaPagoSeleccionado!,
      paymentMethod: 'PUE',
      receiver: Receiver(
        rfc: _clienteSelected!.rfc!, 
        name: _clienteSelected!.razonSocial!=null ? _clienteSelected!.razonSocial! : _clienteSelected!.nombre,
        cfdiUse: _usoCfdiSeleccionado!,
        fiscalRegime: _clienteSelected!.regimenFiscal ?? '616',
        taxZipCode: _clienteSelected!.codigoPostal?.toString() ?? Constantes.datosDeFacturacion['expeditionPlace']!,
      ),
      items: items
    );

    //Facturar
    final facturasSvc = Provider.of<FacturasServices>(context, listen: false);
    final s = await facturasSvc.facturarVenta(cfdi);
    final Map<String, dynamic> msg = jsonDecode(s);
    if (msg.containsKey('exito')){
      Facturas factura = Facturas(
        facturaId: msg['Id'], 
        ventaId: widget.venta.id!, 
        uuid: msg['Complement']['TaxStamp']['Uuid'], 
        fecha: DateTime.now(), 
        receptorRfc: _clienteSelected!.rfc!, 
        receptorNombre: _clienteSelected!.nombre, 
        subTotal: widget.venta.subTotal, 
        impuestos: widget.venta.iva, 
        total: widget.venta.total
      );
      final facturaId = await facturasSvc.createFactura(factura);
      if (facturaId!=null){
        if (!mounted) return 'exito';
        await Provider.of<VentasServices>(context, listen: false).facturar([widget.venta.folio!], facturaId);
      }
      
      loadingSvc.hide();
      return 'exito';
    } else {
      loadingSvc.hide();
      return s;
    }
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
        .map((detalle) => detalle.total)
        .reduce((a, b) => a + b);
  }

  @override
  Widget build(BuildContext context) {
    final clientesServices = Provider.of<ClientesServices>(context);

    return AlertDialog(
      elevation: 4,
      shadowColor: Colors.black,
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
                      SearchableDropdown(
                        searchMoreInfo: false,
                        value: _formaPagoSeleccionado,
                        items: _dropdownItemsFormaPago,
                        empty: _formaPagoEmpty,
                        hint: 'Tipo de pago',
                        onChanged:
                        (val) => setState(() {
                          _formaPagoEmpty = false;
                          _formaPagoSeleccionado = val!;
                        }),
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      const Text('Uso CFDI', style: AppTheme.subtituloPrimario),
                      const SizedBox(height: 2),

                      SearchableDropdown(
                        showMoreInfo: true,
                        value: _usoCfdiSeleccionado,
                        items: Constantes.usoCfdi,
                        empty: _usoCfdiEmpty,
                        hint: 'Uso CFDI',
                        onChanged:
                        (val) => setState(() {
                          _usoCfdiEmpty = false;
                          _usoCfdiSeleccionado = val!;
                        }),
                      )

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
            ), const SizedBox(height: 15),

            ElevatedButton(
              onPressed: () async{
                final msg = await facturar();
                if (msg!='exito'){
                  if (!context.mounted) {return;}

                    final error = jsonDecode(msg);
                    final errores = Provider.of<FacturasServices>(context, listen: false).extraerErrores(error);
                    final texto = errores.join('\n'); 

                  showDialog(
                    context: context,
                    builder: (_) => Stack(
                      alignment: Alignment.topRight,
                      children: [
                        CustomErrorDialog(
                          titulo: 'Hubo un problema', 
                          respuesta: texto,
                        ),
                        const WindowBar(overlay: true),
                      ],
                    ),
                  );
                } else {
                  if (!context.mounted) {return;}
                  Navigator.pop(context);
                }
              },
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
                Formatos.pesos.format(widget.detalle.total.toDouble()),
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
