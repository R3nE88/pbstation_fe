import 'package:decimal/decimal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pbstation_frontend/logic/calculos_dinero.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:print_usb/model/usb_device.dart';
import 'package:print_usb/print_usb.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as imagen;

class Ticket {
  static bool _init = false;
  static late final ProductosServices productoSvc;
  static late final ClientesServices clienteSvc;
  static late final UsuariosServices usuarioSvc;
  static late final VentasServices ventaSvc;
  static late final ImpresorasServices impresoraSvc;   

  /*static Future<List<int>>_generarQR(String data) async {
    // Using default profile
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    String qrData = data;
    const double qrSize = 200;
    try {
      final uiImg = await QrPainter(
        data: qrData,
        version: QrVersions.auto,
      ).toImageData(qrSize);
      final dir = await getTemporaryDirectory();
      final pathName = '${dir.path}/qr_tmp.png';
      final qrFile = File(pathName);
      final imgFile = await qrFile.writeAsBytes(uiImg?.buffer.asUint8List() ?? []);
      final img = imagen.decodeImage(imgFile.readAsBytesSync());

      bytes += generator.image(img!);
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
    return bytes;
  }*/

  static Future<List<int>> _generarTicketDeVenta(BuildContext context, Ventas venta, String folio) async {
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
        styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text('San Luis Rio Colorado, Sonora',
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Av. Jalisco y Calle 7, 83440',
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('RFC: DIOE860426LJA',
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Tel: (653)-534-0142',
        styles: const PosStyles(align: PosAlign.center));

    //Body Header
    bytes += generator.text('Nota de venta',
        styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2,));
    bytes += generator.text('Folio: $folio',
        styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text(formattedDate, //'25/07/2025 04:16p.m.'
        styles: const PosStyles(align: PosAlign.right));
    bytes += generator.text(clienteSvc.obtenerNombreClientePorId(venta.clienteId));

    // Body: Itemized purchase list (using columns)
    bytes += generator.hr(); // horizontal rule
    bytes += generator.row([
      PosColumn(text: 'Cant', styles: const PosStyles(bold: true)),
      PosColumn(text: 'Articulo', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Precio', width: 4, styles: const PosStyles(bold: true)),
    ]);
    
    for (var i = 0; i < venta.detalles.length; i++) {
      Productos? producto = productoSvc.obtenerProductoPorId(venta.detalles[i].productoId);
      bytes += generator.row([
        PosColumn(text: venta.detalles[i].cantidad.toString()),
        PosColumn(text: 
        !producto!.requiereMedida? producto.descripcion : '${producto.descripcion}(${venta.detalles[i].ancho}x${venta.detalles[i].alto})', 
        width: 6),
        PosColumn(text: Formatos.moneda.format(venta.detalles[i].subtotal.toDouble()), width: 4),
      ]);
    }
    bytes += generator.hr(); // horizontal rule

    // Total
    bytes += generator.text('Total: ${Formatos.pesos.format(venta.total.toDouble())}',
        styles: const PosStyles(align: PosAlign.right, bold: true));
    bytes += generator.text('Pago: ${Formatos.pesos.format(venta.abonadoTotal.toDouble())}',
        styles: const PosStyles(align: PosAlign.right, bold: true));
    bytes += generator.text('Su Cambio: ${Formatos.pesos.format(venta.cambio.toDouble())}',
        styles: const PosStyles(align: PosAlign.right, bold: true));
    if (venta.liquidado==false){
      Decimal pendiente = venta.total - venta.recibidoTotal;
    bytes += generator.text('Queda pendiente: ${Formatos.pesos.format(pendiente.toDouble())}',
        styles: const PosStyles(align: PosAlign.right, bold: true));
    }

    // QR Code at the end (e.g., link to survey)
    /*bytes += generator.feed(1);
    bytes += generator.text('¿Necesita Facturar?',
        styles: const PosStyles(align: PosAlign.center));
    bytes += await _generarQR('https://youtu.be/6Y4b25CYkkg?list=RD6Y4b25CYkkg');
    bytes += generator.feed(1);*/

    //Footer
    bytes += generator.text('Atendido por',
        styles: const PosStyles(align: PosAlign.center));
    if (context.mounted){
      String usuario = Provider.of<UsuariosServices>(context, listen: false).obtenerNombreUsuarioPorId(venta.usuarioId);
      bytes += generator.text(usuario,
          styles: const PosStyles(align: PosAlign.center));
    }
    bytes += generator.feed(1);
    bytes += generator.text('¡Gracias Por Su Preferencia!',
        styles: const PosStyles(align: PosAlign.center, bold: true));

    
    // Cut the paper (if supported)
    bytes += generator.feed(1);
    bytes += generator.cut();
    bytes += generator.reset();
    bytes += generator.reset();
    return bytes;
  }

  static Future<List<int>> _generarTicketDeudaPagada(BuildContext context, Ventas venta, String folio, Map<String, double> datosDeuda) async {
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
        styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text('San Luis Rio Colorado, Sonora',
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Av. Jalisco y Calle 7, 83440',
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('RFC: DIOE860426LJA',
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Tel: (653)-534-0142',
        styles: const PosStyles(align: PosAlign.center));

    //Body Header
    bytes += generator.text('Nota de venta',
        styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2,));
    bytes += generator.text('Folio: $folio',
        styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text(formattedDate, //'25/07/2025 04:16p.m.'
        styles: const PosStyles(align: PosAlign.right));
    bytes += generator.text(clienteSvc.obtenerNombreClientePorId(venta.clienteId));
    bytes += generator.text('',);
    bytes += generator.text('Liquidacion de venta',
        styles: const PosStyles(align: PosAlign.center, bold: true));

    // Body: Itemized purchase list (using columns)
    bytes += generator.hr(); // horizontal rule
    bytes += generator.row([
      PosColumn(text: 'Cant', styles: const PosStyles(bold: true)),
      PosColumn(text: 'Articulo', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Precio', width: 4, styles: const PosStyles(bold: true)),
    ]);
    
    for (var i = 0; i < venta.detalles.length; i++) {
      Productos? producto = productoSvc.obtenerProductoPorId(venta.detalles[i].productoId);
      bytes += generator.row([
        PosColumn(text: venta.detalles[i].cantidad.toString()),
        PosColumn(text: 
        !producto!.requiereMedida? producto.descripcion : '${producto.descripcion}(${venta.detalles[i].ancho}x${venta.detalles[i].alto})', 
        width: 6),
        PosColumn(text: Formatos.moneda.format(venta.detalles[i].subtotal.toDouble()), width: 4),
      ]);
    }
    bytes += generator.hr(); // horizontal rule

    // Total
    bytes += generator.text('Total: ${Formatos.pesos.format(venta.total.toDouble())}',
        styles: const PosStyles(align: PosAlign.right, bold: true));
    bytes += generator.text('Pagado Anteriormente: ${Formatos.pesos.format(datosDeuda["anterior_recibido"])}',
        styles: const PosStyles(align: PosAlign.right, bold: true));
    bytes += generator.hr(); // horizontal rule
    bytes += generator.text('Recibido: ${Formatos.pesos.format(datosDeuda["deuda_recibido"])}',
        styles: const PosStyles(align: PosAlign.right, bold: true));
    bytes += generator.text('Pago: ${Formatos.pesos.format(datosDeuda["deuda_total"])}',
        styles: const PosStyles(align: PosAlign.right, bold: true));
    bytes += generator.text('Su Cambio: ${Formatos.pesos.format(datosDeuda["deuda_cambio"])}',
        styles: const PosStyles(align: PosAlign.right, bold: true));

    // QR Code at the end (e.g., link to survey)
    /*bytes += generator.feed(1);
    bytes += generator.text('¿Necesita Facturar?',
        styles: const PosStyles(align: PosAlign.center));
    bytes += await _generarQR('https://youtu.be/6Y4b25CYkkg?list=RD6Y4b25CYkkg');
    bytes += generator.feed(1);*/

    //Footer
    bytes += generator.text('Atendido por',
        styles: const PosStyles(align: PosAlign.center));
    if (context.mounted){
      String usuario = Provider.of<UsuariosServices>(context, listen: false).obtenerNombreUsuarioPorId(venta.usuarioId);
      bytes += generator.text(usuario,
          styles: const PosStyles(align: PosAlign.center));
    }
    bytes += generator.feed(1);
    bytes += generator.text('¡Gracias Por Su Preferencia!',
        styles: const PosStyles(align: PosAlign.center, bold: true));

    
    // Cut the paper (if supported)
    bytes += generator.feed(1);
    bytes += generator.cut();
    bytes += generator.reset();
    bytes += generator.reset();
    return bytes;
  }

  static Future<List<int>> _generarTicketDeCorte(BuildContext context, Cajas caja, Cortes corte, List<Ventas> ventas, Map<String, TextEditingController> impresoraControllers) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);  // 58mm paper width
    DateTime fecha = DateTime.parse(corte.fechaApertura);
    String fechaAperturaFormatted = DateFormat('dd/MMM/yyyy hh:mm a').format(fecha);
    String fechaCorteFormatted = DateFormat('dd/MMM/yyyy hh:mm a').format(DateTime.parse(corte.fechaCorte!));
    String cajeroQueAbrio = usuarioSvc.obtenerNombreUsuarioPorId(corte.usuarioId);
    String cajeroQueCerro = usuarioSvc.obtenerNombreUsuarioPorId(corte.usuarioIdCerro!);
    List<int> bytes = [];

    //Abrir cajon
    bytes.addAll([0x1B, 0x70, 0x00, 0x19, 0xFA]);

    //Header
    bytes += generator.text('Emilio Alberto Diaz Obregon',
        styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text('San Luis Rio Colorado, Sonora',
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Av. Jalisco y Calle 7, 83440',
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('RFC: DIOE860426LJA',
        styles: const PosStyles(align: PosAlign.center));

    //Corte de caja
    bytes += generator.text('CORTE DE CAJA',
        styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text('CAJA: ${caja.folio ?? 'folio no encontrado'}',
        styles: const PosStyles(align: PosAlign.right));
    bytes += generator.text('CORTE: ${corte.folio}',
        styles: const PosStyles(align: PosAlign.right));
    bytes += generator.text('FECHA: ${DateFormat('dd-MMM-yyyy').format(DateTime.parse(corte.fechaCorte!))}',
        styles: const PosStyles(align: PosAlign.right));
    bytes += generator.text('HORA: ${DateFormat('hh:mm a').format(DateTime.parse(corte.fechaCorte!))}',
        styles: const PosStyles(align: PosAlign.right));
    bytes += generator.text('TC: ${caja.tipoCambio}',
        styles: const PosStyles(align: PosAlign.right));
    bytes += generator.text('Abrio: $cajeroQueAbrio');
    bytes += generator.text(fechaAperturaFormatted); //Formatos.pesos.format(corte.fondoInicial.toDouble())
    bytes += generator.text('Fondo: ${Formatos.pesos.format(corte.fondoInicial.toDouble())}');
    bytes += generator.text('Cerro: $cajeroQueCerro',
        styles: const PosStyles(align: PosAlign.right));
    bytes += generator.text(fechaCorteFormatted,
        styles: const PosStyles(align: PosAlign.right));
    bytes += generator.hr(); // horizontal rule

    //Ventas por producto
    bytes += generator.text('ARTICULOS VENDIDOS',
        styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.row([
      PosColumn(text: 'Cant', styles: const PosStyles(bold: true)),
      PosColumn(text: 'Articulo', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Total', width: 4, styles: const PosStyles(bold: true)),
    ]);
    List<VentasPorProducto> ventasPorProducto = ventaSvc.consolidarVentasPorProducto(ventas);
    for (var venta in ventasPorProducto) {
      Productos? producto = productoSvc.obtenerProductoPorId(venta.productoId);
      bytes += generator.row([
        PosColumn(text: venta.cantidad.toString()),
        PosColumn(text: producto!.descripcion, 
        width: 6),
        PosColumn(text: Formatos.moneda.format(venta.total.toDouble()), width: 4),
      ]);
    }
    bytes += generator.hr(); // horizontal rule

    // Ventas canceladas
    final canceladas = [];
    if (canceladas.isNotEmpty) {
      bytes += generator.text('VENTAS CANCELADAS',
          styles: const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.row([
        PosColumn(text: 'Folio', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(text: 'Total', width: 6, styles: const PosStyles(bold: true)),
      ]);
      for (var venta in canceladas) {
        bytes += generator.row([
          PosColumn(text: venta.folio ?? 'S/N', width: 6),
          PosColumn(text: Formatos.moneda.format(venta.total.toDouble()), width: 6),
        ]);
      }
      bytes += generator.hr();
    }

    //Ventas pendientes
    Set<String> idsCorteActual = ventaSvc.ventasDeCorteActual
        .map((v) => v.id)
        .whereType<String>() // Filtra solo los valores no-null
        .toSet();
    List<Ventas> ventasConDeudaEnCorteActual = ventaSvc.ventasConDeuda
        .where((venta) => venta.id != null && idsCorteActual.contains(venta.id))
        .toList();
    if (ventasConDeudaEnCorteActual.isNotEmpty){
      bytes += generator.text('VENTAS CON DEUDA',
        styles: const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.row([
        PosColumn(text: 'Folio', width: 6,  styles: const PosStyles(bold: true)),
        PosColumn(text: 'Deuda', width: 6, styles: const PosStyles(bold: true)),
      ]);
      for (var venta in ventasConDeudaEnCorteActual) {
        bytes += generator.row([
          PosColumn(text: venta.folio??'no se encontro', width: 6),
          PosColumn(text: Formatos.moneda.format((venta.total - venta.abonadoTotal).toDouble()), width: 6),
        ]);
      }
      bytes += generator.hr(); // horizontal rule
    }
   
    //Corte de Caja
    Decimal entrada = Decimal.parse('0');
    Decimal salida = Decimal.parse('0');
    for (var movimiento in corte.movimientosCaja) {
      if (movimiento.tipo=='entrada'){
        entrada += Decimal.parse(movimiento.monto.toString());
      } else if (movimiento.tipo=='retiro'){
        salida += Decimal.parse(movimiento.monto.toString());
      }
    } 

    Decimal total = entrada - salida + (corte.ventaPesos??Decimal.zero) + (corte.ventaDolares??Decimal.zero) + (corte.ventaDebito??Decimal.zero) + (corte.ventaCredito??Decimal.zero) + (corte.ventaTransf??Decimal.zero);
    bytes += generator.text('CORTE DE CAJA',
        styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.row([
      PosColumn(text: 'Movimiento', width: 7, styles: const PosStyles(bold: true)),
      PosColumn(width: 5, styles: const PosStyles(bold: true)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Entrada', width: 7),
      PosColumn(text: '+${Formatos.pesos.format(entrada.toDouble())}', width: 5),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Salida', width: 7),
      PosColumn(text: '-${Formatos.pesos.format(salida.toDouble())}', width: 5),
    ]);
    double mx = corte.ventaPesos?.toDouble()??Decimal.zero.toDouble();
    bytes += generator.row([
      PosColumn(text: 'Efectivo(mxn)', width: 7),
      PosColumn(text: mx<0? Formatos.pesos.format(mx) : '+${Formatos.pesos.format(mx)}', width: 5),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Efectivo(us)', width: 7),
      PosColumn(text: '+${Formatos.pesos.format(corte.ventaDolares?.toDouble()??Decimal.zero.toDouble())}', width: 5),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Tarj Debito', width: 7),
      PosColumn(text: '+${Formatos.pesos.format(corte.ventaDebito?.toDouble()??Decimal.zero.toDouble())}', width: 5),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Tarj Credito', width: 7),
      PosColumn(text: '+${Formatos.pesos.format(corte.ventaCredito?.toDouble()??Decimal.zero.toDouble())}', width: 5),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Transferencia', width: 7),
      PosColumn(text: '+${Formatos.pesos.format(corte.ventaTransf?.toDouble()??Decimal.zero.toDouble())}', width: 5), //total
    ]);
    bytes += generator.row([
      PosColumn(text: 'TOTAL', width: 7, styles: const PosStyles(bold: true)),
      PosColumn(text: Formatos.pesos.format(total.toDouble()), width: 5, styles: const PosStyles(bold: true)),
    ]);

    //Dinero Entregado
    Decimal contadoUsCnv = Decimal.parse(CalculosDinero().dolarAPesos(corte.conteoDolares!.toDouble(), caja.tipoCambio).toString());
    Decimal totalContado = corte.conteoPesos! + contadoUsCnv + corte.conteoDebito! + corte.conteoCredito! + corte.conteoTransf!;
    bytes += generator.row([
      PosColumn(text: 'Dinero Entregado', width: 7, styles: const PosStyles(bold: true)),
      PosColumn(width: 5, styles: const PosStyles(bold: true)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Efectivo(mxn)', width: 7),
      PosColumn(text: '+${Formatos.pesos.format(corte.conteoPesos!.toDouble())}', width: 5),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Efectivo(us)', width: 7),
      PosColumn(text: '+${Formatos.dolares.format(corte.conteoDolares!.toDouble())}', width: 5),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Tarj Debito', width: 7),
      PosColumn(text: '+${Formatos.pesos.format(corte.conteoDebito!.toDouble())}', width: 5),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Tarj Credito', width: 7),
      PosColumn(text: '+${Formatos.pesos.format(corte.conteoCredito!.toDouble())}', width: 5),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Transferencia', width: 7),
      PosColumn(text: '+${Formatos.pesos.format(corte.conteoTransf!.toDouble())}', width: 5),
    ]);
    bytes += generator.row([
      PosColumn(text: 'TOTAL', width: 7, styles: const PosStyles(bold: true)),
      PosColumn(text: Formatos.pesos.format(totalContado.toDouble()), width: 5, styles: const PosStyles(bold: true)),
    ]);
    bytes += generator.text(' ');

    //Diferencia
    Decimal diferencia = total - totalContado;
    bytes += generator.row([
      PosColumn(text: 'Movimientos', width: 7),
      PosColumn(text: Formatos.pesos.format(total.toDouble()), width: 5),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Dinero Entregado', width: 7),
      PosColumn(text: Formatos.pesos.format(totalContado.toDouble()), width: 5),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Diferencia', width: 7, styles: const PosStyles(bold: true)),
      PosColumn(text: Formatos.pesos.format(diferencia.toDouble()).replaceAll('-', ''), width: 5, styles: const PosStyles(bold: true)),
    ]);
    bytes += generator.hr(); // horizontal rule
    
    //Comentario
    if (corte.comentarios!.isNotEmpty){
      bytes += generator.text('Comentarios', styles: const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text(corte.comentarios!, styles: const PosStyles(align: PosAlign.center));
      bytes += generator.hr();
    }

    //Desglose
    bytes += generator.text('DESGLOSE DE DINERO ENTREGADO',
        styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.row([
      PosColumn(text: 'Pesos', width: 7, styles: const PosStyles(bold: true)),
      PosColumn(width: 5, styles: const PosStyles(bold: true)),
    ]);
    if(corte.desglosePesos!.isEmpty){
      bytes += generator.text('n/a');
    } else {
      for (var desglose in corte.desglosePesos!) {
        double total = desglose.denominacion * desglose.cantidad;
        bytes += generator.row([
          PosColumn(text: '${desglose.denominacion}x', width: 4),
          PosColumn(text: '${desglose.cantidad}'),
          PosColumn(text: Formatos.pesos.format(total), width: 6),
        ]);
      }
    }
    bytes += generator.row([
      PosColumn(text: 'Dolares', width: 7, styles: const PosStyles(bold: true)),
      PosColumn(width: 5, styles: const PosStyles(bold: true)),
    ]);
    if(corte.desgloseDolares!.isEmpty){
      bytes += generator.text('n/a');
    } else {
      for (var desglose in corte.desgloseDolares!) {
        double total = desglose.denominacion * desglose.cantidad;
        bytes += generator.row([
          PosColumn(text: '${desglose.denominacion}x', width: 4),
          PosColumn(text: '${desglose.cantidad}'),
          PosColumn(text: Formatos.dolares.format(total), width: 6),
        ]);
      }
    }
    bytes += generator.hr();

    //Contadores
    if (impresoraSvc.impresoras.isNotEmpty){
      bytes += generator.text('CONTADORES', styles: const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.row([
        PosColumn(text: 'Impresora', width: 5, styles: const PosStyles(bold: true)),
        PosColumn(text: 'Calculado', width: 4, styles: const PosStyles(bold: true)),
        PosColumn(text: 'Real', width: 3, styles: const PosStyles(bold: true)),
      ]);
      for (var impresora in impresoraSvc.impresoras) {
        int cantidadAnotada = int.tryParse(impresoraControllers[impresora.id]?.text.replaceAll(',','')??'hubo un problema') ?? 0;
        int cantidadSistema = impresoraSvc.ultimosContadores[impresora.id]?.cantidad ?? 0;
        bytes += generator.row([
          PosColumn(text: impresora.modelo, width: 5),
          PosColumn(text: Formatos.numero.format(cantidadSistema), width: 4),
          PosColumn(text: Formatos.numero.format(cantidadAnotada), width: 3),
        ]);
      }
      bytes += generator.hr();
    }
    
    // Cut the paper (if supported)
    bytes += generator.feed(1);
    bytes += generator.cut();
    bytes += generator.reset();
    bytes += generator.reset();
    return bytes;
  }

  static void imprimirTicketVenta(context, venta, folio) async{
    if (Configuracion.impresora != 'null') {
      bool connected = await PrintUsb.connect(name: Configuracion.impresora);
      UsbDevice device = UsbDevice(
        name: Configuracion.impresora, 
        model: 'x', 
        isDefault: true, 
        available: true
      );
      if (connected) {
        cargarServices(context);
        List<int> bytes = await _generarTicketDeVenta(context, venta, folio);
        await PrintUsb.printBytes(bytes: bytes, device: device);
        // Check success...
        //await PrintUsb.close();
      }
    }
  }

  static void imprimirTicketDeudaPagada(context, venta, folio, datosDeuda) async{
    if (Configuracion.impresora != 'null') {
      bool connected = await PrintUsb.connect(name: Configuracion.impresora);
      UsbDevice device = UsbDevice(
        name: Configuracion.impresora, 
        model: 'x', 
        isDefault: true, 
        available: true
      );
      if (connected) {
        cargarServices(context);
        List<int> bytes = await _generarTicketDeudaPagada(context, venta, folio, datosDeuda);
        await PrintUsb.printBytes(bytes: bytes, device: device);
        // Check success...
        //await PrintUsb.close();
      }
    }
  }

  static void imprimirTicketCorte(context, Cajas caja, Cortes corte, List<Ventas> ventas, Map<String, TextEditingController> impresoraControllers) async{
    if (Configuracion.impresora != 'null') {
      bool connected = await PrintUsb.connect(name: Configuracion.impresora);
      UsbDevice device = UsbDevice(
        name: Configuracion.impresora, 
        model: 'x', 
        isDefault: true, 
        available: true
      );
      if (connected) {
        cargarServices(context);
        List<int> bytes = await _generarTicketDeCorte(context, caja, corte, ventas, impresoraControllers);
        await PrintUsb.printBytes(bytes: bytes, device: device);
      }
    }
  }

  static void cargarServices(context){
    if (_init==false){
      _init=true;
      productoSvc = Provider.of<ProductosServices>(context, listen: false);
      clienteSvc = Provider.of<ClientesServices>(context, listen: false);
      usuarioSvc = Provider.of<UsuariosServices>(context, listen: false);
      ventaSvc = Provider.of<VentasServices>(context, listen: false);
      impresoraSvc = Provider.of<ImpresorasServices>(context, listen: false);
    }
  }
}