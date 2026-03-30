import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/provider/provider.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class Impresiones {
  
  static void imprimirCotizacion(BuildContext ctx, Cotizaciones cotizacion) async {
    final loadingSvc = Provider.of<LoadingProvider>(ctx, listen: false);
    loadingSvc.show();
    
    try {
      // Load Logo
      final ByteData logoData = await rootBundle.load('assets/images/logo_normal.png');
      final Uint8List logoBuffer = logoData.buffer.asUint8List();
      final pw.MemoryImage logo = pw.MemoryImage(logoBuffer);

      // Load Fonts for Unicode support (accents, symbols)
      final font = await PdfGoogleFonts.robotoRegular();
      final fontBold = await PdfGoogleFonts.robotoBold();
      final fontItalic = await PdfGoogleFonts.robotoItalic();
      final fontBoldItalic = await PdfGoogleFonts.robotoBoldItalic();

      final doc = pw.Document(
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
          italic: fontItalic,
          boldItalic: fontBoldItalic,
        ),
      );

      // Services
      if (!ctx.mounted) return;
      final clienteSvc = Provider.of<ClientesServices>(ctx, listen: false);
      final productosSvc = Provider.of<ProductosServices>(ctx, listen: false);
      final sucursalesSvc = Provider.of<SucursalesServices>(ctx, listen: false);
      final usuariosSvc = Provider.of<UsuariosServices>(ctx, listen: false);

      final cliente = clienteSvc.clientes.firstWhere(
        (c) => c.id == cotizacion.clienteId, 
      );
      final sucursal = sucursalesSvc.sucursales.firstWhere(
        (s) => s.id == cotizacion.sucursalId, 
      );
      final usuario = usuariosSvc.usuarios.firstWhere(
        (u) => u.id == cotizacion.usuarioId, 
      );

      final fecha = DateTime.parse(cotizacion.fechaCotizacion);
      final DateTime lastDayOfMonth = DateTime(fecha.year, fecha.month + 1, 0);

      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Página ${context.pageNumber} de ${context.pagesCount}', style: pw.TextStyle(fontSize: 8, font: font)),
                  pw.Text('Printerboy - San Luis Rio Colorado, Sonora', style: pw.TextStyle(fontSize: 8, font: font)),
                ],
              ),
            ],
          );
        },
        header: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Image(logo, width: 80),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Emilio Alberto Diaz Obregon', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, font: fontBold)),
                      pw.Text('San Luis Rio Colorado, Sonora', style: pw.TextStyle(fontSize: 10, font: font)),
                      pw.Text('Av. Jalisco y Calle 7, 83440', style: pw.TextStyle(fontSize: 10, font: font)),
                      pw.Text('RFC: DIOE860426LJA', style: pw.TextStyle(fontSize: 10, font: font)),
                      pw.Text('Tel: (653)-534-0142', style: pw.TextStyle(fontSize: 10, font: font)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1.5, color: PdfColors.blue900),
              pw.SizedBox(height: 10),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('COTIZACIÓN', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900, font: fontBold)),
                    pw.SizedBox(height: 4),
                    pw.Text('Válida hasta: ${DateFormat('dd MMMM yyyy', 'es_MX').format(lastDayOfMonth)}', style: pw.TextStyle(fontSize: 10, font: font)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Folio: ${cotizacion.folio ?? 'S/N'}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, font: fontBold)),
                    pw.Text('Fecha: ${DateFormat('dd/MMMM/yyyy', 'es_MX').format(fecha)} ${DateFormat('hh:mm').format(fecha)} ${fecha.hour < 12 ? 'a.m.' : 'p.m.'}', style: pw.TextStyle(fontSize: 10, font: font)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 15),
            
            // General Info Box
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                color: PdfColors.grey100,
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    children: [
                      pw.Expanded(child: _pdfInfoField('CLIENTE', cliente.nombre, regularFont: font, boldFont: fontBold)),
                      pw.Expanded(child: _pdfInfoField('SUCURSAL', sucursal.nombre, regularFont: font, boldFont: fontBold)),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    children: [
                      pw.Expanded(child: _pdfInfoField('ATENDIÓ', usuario.nombre, regularFont: font, boldFont: fontBold)),
                      pw.Expanded(child: _pdfInfoField('TELÉFONO SUCURSAL', sucursal.telefono.toString(), regularFont: font, boldFont: fontBold)),
                    ],
                  ),
                ],
              ),
            ),
            
            if (cotizacion.comentariosVenta != null && cotizacion.comentariosVenta!.isNotEmpty) ...[
              pw.SizedBox(height: 15),
              pw.Text('NOTAS ADICIONALES:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.blue900, font: fontBold)),
              pw.Text(cotizacion.comentariosVenta!, style: pw.TextStyle(fontSize: 10, font: font)),
            ],

            pw.SizedBox(height: 20),
            
            // Products Table
            pw.TableHelper.fromTextArray(
              context: context,
              border: null,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10, font: fontBold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              cellStyle: pw.TextStyle(fontSize: 10, font: font),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
              columnWidths: {
                0: const pw.FlexColumnWidth(4.5),
                1: const pw.FlexColumnWidth(),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(1.2),
                4: const pw.FlexColumnWidth(2),
              },
              headers: ['Descripción del Producto', 'Cant.', 'P. Unitario', 'Desc.', 'Monto Total'],
              data: cotizacion.detalles.map((d) {
                final prod = productosSvc.productos.firstWhere(
                  (p) => p.id == d.productoId, 
                  orElse: () => Productos(codigo: 0, descripcion: 'Error', unidadSat: '', claveSat: '', precio: Decimal.zero, inventariable: false, imprimible: false, valorImpresion: 0, requiereMedida: false)
                );
                final pUnit = d.cotizacionPrecio ?? prod.precio;
                
                String desc = prod.descripcion;
                if (d.ancho != null && d.alto != null) {
                  desc += '\n(${d.ancho} x ${d.alto})';
                }
                if (d.comentarios != null && d.comentarios!.isNotEmpty) {
                  desc += '\nNota: ${d.comentarios}';
                }

                return [
                  desc,
                  d.cantidad.toString(),
                  Formatos.pesos.format(pUnit.toDouble()),
                  d.descuento > 0 ? '${d.descuento}%' : '-',
                  Formatos.pesos.format(d.total.toDouble()),
                ];
              }).toList(),
            ),
            
            pw.SizedBox(height: 20),
            
            // Totals and Footer Note
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('TÉRMINOS Y CONDICIONES:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, font: fontBold)),
                      pw.Text('- Los precios están expresados en Moneda Nacional.', style: pw.TextStyle(fontSize: 8, font: font)),
                      pw.Text('- Esta cotización no garantiza la existencia de inventario.', style: pw.TextStyle(fontSize: 8, font: font)),
                      pw.Text('- Los precios pueden variar sin previo aviso después de la fecha de vigencia.', style: pw.TextStyle(fontSize: 8, font: font)),
                    ],
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Container(
                    child: pw.Column(
                      children: [
                        _pdfResumenRow('Subtotal:', Formatos.pesos.format(cotizacion.subTotal.toDouble()), font: font),
                        if (cotizacion.descuento > Decimal.zero)
                          _pdfResumenRow('Descuento Total:', '- ${Formatos.pesos.format(cotizacion.descuento.toDouble())}', color: PdfColors.red800, font: font),
                        if (cotizacion.iva > Decimal.zero)
                          _pdfResumenRow('IVA (16%):', Formatos.pesos.format(cotizacion.iva.toDouble()), font: font),
                        pw.Divider(color: PdfColors.blue800, thickness: 1),
                        _pdfResumenRow('TOTAL NETO:', Formatos.pesos.format(cotizacion.total.toDouble()), bold: true, fontSize: 13, color: PdfColors.blue900, font: fontBold),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            pw.SizedBox(height: 30),
            pw.Center(
              child: pw.Text('¡GRACIAS POR SU PREFERENCIA!', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900, font: fontBold)),
            ),
          ];
        },
      ));

      final bytes = await doc.save();
      await Printing.sharePdf(bytes: bytes, filename: 'Cotizacion_${cotizacion.folio ?? "S_N"}.pdf');
    } catch (e) {
      debugPrint('Error al generar PDF: $e');
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Error al generar el PDF de la cotización')));
    } finally {
      loadingSvc.hide();
    }
  }

  static pw.Widget _pdfInfoField(String label, String value, {pw.Font? regularFont, pw.Font? boldFont}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold, font: boldFont)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.normal, font: regularFont)),
      ],
    );
  }

  static pw.Widget _pdfResumenRow(String label, String value, {bool bold = false, double fontSize = 10, PdfColor? color, pw.Font? font}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: fontSize, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color, font: font)),
          pw.Text(value, style: pw.TextStyle(fontSize: fontSize, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color, font: font)),
        ],
      ),
    );
  }

}