import 'dart:io';
import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:print_usb/model/usb_device.dart';
import 'package:print_usb/print_usb.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image/image.dart' as imagen;

class Ticket {

  static Future<List<int>>qr() async {
    //final List<int> bytes = [];
    // Using default profile
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    String qrData = "https://youtu.be/6Y4b25CYkkg?list=RD6Y4b25CYkkg";
    const double qrSize = 200;
    try {
      final uiImg = await QrPainter(
        data: qrData,
        version: QrVersions.auto,
        gapless: false,
      ).toImageData(qrSize);
      final dir = await getTemporaryDirectory();
      final pathName = '${dir.path}/qr_tmp.png';
      final qrFile = File(pathName);
      final imgFile = await qrFile.writeAsBytes(uiImg?.buffer.asUint8List() ?? []);
      final img = imagen.decodeImage(imgFile.readAsBytesSync());

      bytes += generator.image(img!);
    } catch (e) {
      print(e);
    }
    return bytes;
  }

  static Future<List<int>> generateReceiptBytes(BuildContext context, Ventas venta) async {
    // Load default capability profile (includes font and code page info)
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);  // 58mm paper width
    String formattedDate = DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.parse(venta.fechaVenta!));
    List<int> bytes = [];

    //Abrir cajon
    bytes.addAll([0x1B, 0x70, 0x00, 0x19, 0xFA]);

    //imagen
    final ByteData data = await rootBundle.load('assets/images/logo_bn3.png');
    final Uint8List imageBytes = data.buffer.asUint8List();
    final imagen.Image? image = imagen.decodeImage(imageBytes);
    bytes += generator.image(image!);

    //Header
    bytes += generator.text('Emilio Alberto Diaz Obregon',
        styles: PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text('San Luis Rio Colorado, Sonora',
        styles: PosStyles(align: PosAlign.center, bold: false));
    bytes += generator.text('Av. Jalisco y Calle 7, 83440',
        styles: PosStyles(align: PosAlign.center, bold: false));
    bytes += generator.text('RFC: DIOE860426LJA',
        styles: PosStyles(align: PosAlign.center, bold: false));
    bytes += generator.text('Tel: (653)-534-0142',
        styles: PosStyles(align: PosAlign.center, bold: false));

    //Body Header
    bytes += generator.text('Nota de venta',
        styles: PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2,));
    bytes += generator.text('Folio: ${venta.folio}',
        styles: PosStyles(align: PosAlign.left, bold: true));
    bytes += generator.text(formattedDate, //'25/07/2025 04:16p.m.'
        styles: PosStyles(align: PosAlign.right, bold: false));
    bytes += generator.text('Publico en General',
        styles: PosStyles(align: PosAlign.left, bold: false));

    // Body: Itemized purchase list (using columns)
    bytes += generator.hr(); // horizontal rule
    bytes += generator.row([
      PosColumn(text: 'Articulo', width: 6, styles: PosStyles(bold: true)),
      PosColumn(text: 'Cant', width: 2, styles: PosStyles(bold: true)),
      PosColumn(text: 'Precio', width: 4, styles: PosStyles(bold: true)),
    ]);
    final productos = Provider.of<ProductosServices>(context, listen: false);
    for (var i = 0; i < venta.detalles.length; i++) {
      Productos? producto = productos.obtenerProductoPorId(venta.detalles[i].productoId);
      bytes += generator.row([
        PosColumn(text: producto?.descripcion ?? ' - ', width: 6),
        PosColumn(text: venta.detalles[i].cantidad.toString(), width: 2),
        PosColumn(text: Formatos.moneda.format(venta.detalles[i].subtotal.toDouble()), width: 4),
      ]);
    }
    bytes += generator.hr(); // horizontal rule

    // Total
    bytes += generator.text('Total: ${Formatos.pesos.format(venta.total.toDouble())}',
        styles: PosStyles(align: PosAlign.right, bold: true));
    bytes += generator.text('Pago: ${Formatos.pesos.format(venta.recibido?.toDouble() ?? 0)}',
        styles: PosStyles(align: PosAlign.right, bold: true));
    bytes += generator.text('Su Cambio: ${Formatos.pesos.format(venta.cambio?.toDouble() ?? 0)}',
        styles: PosStyles(align: PosAlign.right, bold: true));


    // QR Code at the end (e.g., link to survey)
    bytes += generator.feed(1);
    bytes += generator.text('¿Necesita Facturar?',
        styles: PosStyles(align: PosAlign.center, bold: false));
    bytes += await qr();
    bytes += generator.feed(1);

    //Footer
    bytes += generator.text('Atendido por',
        styles: PosStyles(align: PosAlign.center, bold: false));
    bytes += generator.text('Carlos Rene Ayala Salazar',
        styles: PosStyles(align: PosAlign.center, bold: false));
    bytes += generator.feed(1);
    bytes += generator.text('¡Gracias Por Su Preferencia!',
        styles: PosStyles(align: PosAlign.center, bold: true));

    
    // Cut the paper (if supported)
    bytes += generator.feed(1);
    bytes += generator.cut();
    bytes += generator.reset();
    bytes += generator.reset();
    return bytes;
  }

  static void imprimirTicket(context, venta) async{
      List<UsbDevice> devices = await PrintUsb.getList();
      for (var device in devices) {
        print(device.name);
      }
      if (devices.isNotEmpty) {
        bool connected = await PrintUsb.connect(name: devices[0].name);
        if (connected) {
          List<int> bytes = await generateReceiptBytes(context, venta);
          bool success = await PrintUsb.printBytes(bytes: bytes, device: devices[0]);
          // Check success...
          //await PrintUsb.close();

        }
      }
  }
}