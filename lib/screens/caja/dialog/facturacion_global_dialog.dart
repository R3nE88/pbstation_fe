import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/provider/provider.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';
import 'package:provider/provider.dart';

class FacturaGlobalDialog extends StatefulWidget {
  const FacturaGlobalDialog({super.key, required this.ventas});

  final List<Ventas> ventas;

  @override
  State<FacturaGlobalDialog> createState() => _FacturaGlobalDialogState();
}

class _FacturaGlobalDialogState extends State<FacturaGlobalDialog> {
  Future<String> facturar() async {
    //Loading
    final loadingSvc = Provider.of<LoadingProvider>(context, listen: false);
    loadingSvc.show();

    Decimal subtotal = Decimal.zero;
    Decimal impuestos = Decimal.zero;
    Decimal total = Decimal.zero;
    List<String> ventaFolios = [];

    //Items
    List<CfdiItem> items = [];
    final productosSvc = Provider.of<ProductosServices>(context, listen: false);
    for (var i = 0; i < widget.ventas.length; i++) {
      subtotal += widget.ventas[i].subTotal;
      impuestos += widget.ventas[i].iva;
      total += widget.ventas[i].total;
      ventaFolios.add(widget.ventas[i].folio!);

      for (DetallesVenta item in widget.ventas[i].detalles) {
        Productos? producto = productosSvc.obtenerProductoPorId(
          item.productoId,
        );
        if (producto == null) {
          loadingSvc.hide();
          return jsonEncode({
            'Message': 'Hubo un problema para encontrar un producto',
          });
        }

        final qty = item.cantidad.toDouble();
        final unitPrice = producto.precio.toDouble();
        final descuento = item.descuentoAplicado.toDouble();

        final subtotalOriginal = qty * unitPrice;
        final subtotalFiscal = subtotalOriginal - descuento;

        final iva = subtotalFiscal * 0.08;
        final totalFiscal = subtotalFiscal + iva;

        items.add(
          CfdiItem(
            productCode: producto.claveSat,
            description: producto.descripcion,
            unit: Constantes.unidadesSat[producto.unidadSat]!,
            unitCode: producto.unidadSat,
            quantity: qty,
            unitPrice: unitPrice,
            subtotal: double.parse(
              subtotalOriginal.toStringAsFixed(6),
            ), //((item.subtotal + item.descuentoAplicado) - item.iva).toDouble(),
            discount: descuento,
            taxObject: '02',
            taxes: [
              CfdiTax(
                name: 'IVA',
                rate: (Configuracion.iva / 100).toDouble(),
                total: double.parse(iva.toStringAsFixed(6)),
                base: double.parse(
                  subtotalFiscal.toStringAsFixed(6),
                ), //((item.subtotal + item.descuentoAplicado) - item.iva).toDouble(),
                isRetention: false,
              ),
            ],
            total: double.parse(
              totalFiscal.toStringAsFixed(6),
            ), // item.subtotal.toDouble(),
          ),
        );
      }
    }

    final cfdi = Cfdi(
      cfdiType: Constantes.datosDeFacturacion['cfdiType']!,
      expeditionPlace: Constantes.datosDeFacturacion['expeditionPlace']!,
      paymentForm: '01',
      paymentMethod: 'PUE',
      receiver: Receiver(
        rfc: 'XAXX010101000',
        name: 'Publico General',
        cfdiUse: 'S01',
        fiscalRegime: '616',
        taxZipCode: Constantes.datosDeFacturacion['expeditionPlace']!,
      ),
      items: items,
    );

    //Facturar
    final facturasSvc = Provider.of<FacturasServices>(context, listen: false);
    final s = await facturasSvc.facturarVenta(cfdi);
    final Map<String, dynamic> msg = jsonDecode(s);
    if (msg.containsKey('exito')) {
      Facturas factura = Facturas(
        facturaId: msg['Id'],
        folioVenta: DateTime.now().toIso8601String(), //widget.venta.id!,
        uuid: msg['Complement']['TaxStamp']['Uuid'],
        fecha: DateTime.now(),
        receptorRfc: 'XAXX010101000',
        receptorNombre: 'Publico General',
        subTotal: subtotal,
        impuestos: impuestos,
        total: total,
        isGlobal: true,
      );
      final facturaId = await facturasSvc.createFactura(factura);
      if (facturaId != null) {
        if (!mounted) return 'exito';
        await Provider.of<VentasServices>(
          context,
          listen: false,
        ).facturar(ventaFolios, facturaId);
      }

      loadingSvc.hide();
      return 'exito';
    } else {
      loadingSvc.hide();
      return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.all(15),
      elevation: 4,
      shadowColor: Colors.black,
      backgroundColor: AppTheme.containerColor1,
      content: ClipRRect(
        borderRadius: BorderRadiusGeometry.circular(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: AppTheme.tablaColorHeader,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Text('Se encontraron '),
                          Text(
                            widget.ventas.length.toString(),
                            textScaler: const TextScaler.linear(1.3),
                          ),
                          const Text(' ventas sin facturar'),
                        ],
                      ),
                    ),

                    ElevatedButton(
                      onPressed: () async {
                        final msg = await facturar();
                        if (msg != 'exito') {
                          if (!context.mounted) {
                            return;
                          }

                          final error = jsonDecode(msg);
                          final errores = Provider.of<FacturasServices>(
                            context,
                            listen: false,
                          ).extraerErrores(error);
                          final texto = errores.join('\n');

                          showDialog(
                            context: context,
                            builder:
                                (_) => Stack(
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
                          if (!context.mounted) {
                            return;
                          }
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Facturar'),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: 750,
              height: 400,
              color:
                  widget.ventas.length % 2 == 0
                      ? AppTheme.tablaColor1
                      : AppTheme.tablaColor2,
              child: ListView.builder(
                itemCount: widget.ventas.length + 1,
                itemBuilder: (context, index) {
                  if (index != 0) {
                    return FilaVentasSinFacturar(
                      ventas: widget.ventas,
                      index: index - 1,
                    );
                  }

                  //Header
                  return Container(
                    decoration: BoxDecoration(
                      color: AppTheme.tablaColorHeaderSelected,
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          child: Center(
                            child: Text(
                              'Folio de venta',
                              style: AppTheme.tituloPrimario,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'SubTotal',
                              style: AppTheme.tituloPrimario,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Descuento',
                              style: AppTheme.tituloPrimario,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Impuestos',
                              style: AppTheme.tituloPrimario,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Total',
                              style: AppTheme.tituloPrimario,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FilaVentasSinFacturar extends StatelessWidget {
  const FilaVentasSinFacturar({
    super.key,
    required this.ventas,
    required this.index,
  });

  final List<Ventas> ventas;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: index % 2 == 0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Center(
                child: Text(
                  ventas[index].folio ?? 'na',
                  style: AppTheme.subtituloConstraste,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  Formatos.pesos.format(ventas[index].subTotal.toDouble()),
                  style: AppTheme.subtituloConstraste,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  Formatos.pesos.format(ventas[index].descuento.toDouble()),
                  style: AppTheme.subtituloConstraste,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  Formatos.pesos.format(ventas[index].iva.toDouble()),
                  style: AppTheme.subtituloConstraste,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  Formatos.pesos.format(ventas[index].total.toDouble()),
                  style: AppTheme.subtituloConstraste,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
