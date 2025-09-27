import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbstation_frontend/logic/capitalizar.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/screens/caja/venta/procesar_pago.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';
import 'package:provider/provider.dart';

class AdeudosSCreen extends StatefulWidget {
  const AdeudosSCreen({super.key});

  @override
  State<AdeudosSCreen> createState() => _AdeudosSCreenState();
}

class _AdeudosSCreenState extends State<AdeudosSCreen> {

  @override
  void initState() {
    super.initState();
    final clientesConAdeudo = Provider.of<ClientesServices>(context, listen:false).loadAdeudos();
    Provider.of<VentasServices>(context, listen:false).adeudoLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VentasServices>(context, listen:false).loadAdeudos(clientesConAdeudo, SucursalesServices.sucursalActualID);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ventaSvc = Provider.of<VentasServices>(context);
    if (ventaSvc.adeudoLoading){
      return SimpleLoading();
    }

    return BodyPadding(
      child: Column(
        children: [
          _buildHeader(context),
          const SizedBox(height: 10),
          Expanded(child: _buildTable()),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    String? sucursal;
    if (SucursalesServices.sucursalActualID!=null){
      sucursal = Provider.of<SucursalesServices>(context, listen:false).obtenerNombreSucursalPorId(SucursalesServices.sucursalActualID!);
    }
     
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'Adeudos de clientes   ',
          style: AppTheme.tituloClaro,
          textScaler: TextScaler.linear(1.7),
        ),
        Text(
          sucursal ?? '',
          style: AppTheme.labelStyle,
          textScaler: TextScaler.linear(1.2),
        ),
      ],
    );
  }

  Widget _buildTable() {
    return Consumer<VentasServices>(
      builder: (context, servicios, _) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                color: AppTheme.tablaColorHeader,
              ),
              child: Row(
                children: [
                  const Expanded(child: Text('Fecha', textAlign: TextAlign.center)),
                  const Expanded(child: Text('Cliente', textAlign: TextAlign.center)),
                  const Expanded(child: Text('Atendio', textAlign: TextAlign.center)),
                  Expanded(child: Text(SucursalesServices.sucursalActualID==null ? 'Sucursal' : 'Detalles', textAlign: TextAlign.center)),
                  const Expanded(child: Text('Abonado', textAlign: TextAlign.center)),
                  const Expanded(child: Text('Deuda', textAlign: TextAlign.center)),
                  const Expanded(child: Text('Total', textAlign: TextAlign.center)),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: servicios.ventasConDeuda.length % 2 == 0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
                child: ListView.builder( 
                  itemCount: servicios.ventasConDeuda.length,
                  itemBuilder: (context, index) {
                    return FilaDeuda(
                      deuda: servicios.ventasConDeuda[index],
                      index: index,
                    );
                  } 
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                color: AppTheme.tablaColorHeader,
              ),
              child: Row(
                children: [
                  const Spacer(),
                  Text(
                    '  Total: ${servicios.ventasConDeuda.length}   ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}


class FilaDeuda extends StatelessWidget {
  const FilaDeuda({
    super.key,
    required this.deuda,
    required this.index,
  });

  final Ventas deuda;
  final int index;

  @override
  Widget build(BuildContext context) {
    String mostrarCampo(String? valor) => capitalizarPrimeraLetra(valor ?? '-');

    Decimal? obtenerMontoPendiente(String ventaId) {
      final clientesService = Provider.of<ClientesServices>(context, listen: false);
      
      // Búsqueda temprana con return
      for (var cliente in clientesService.clientesConAdeudo) {
        for (var adeudo in cliente.adeudos) {
          if (adeudo.ventaId == ventaId) {
            return adeudo.montoPendiente;
          }
        }
      }
      return null; // No encontrado
    }
    
    final DateTime date = DateTime.parse(deuda.fechaVenta!);
    final fecha = DateFormat('E d/MMM/yy hh:mm a', 'es_MX').format(date);
    final String cliente = Provider.of<ClientesServices>(context, listen: false).obtenerNombreClientePorId(deuda.clienteId);
    final String usuario = Provider.of<UsuariosServices>(context, listen: false).obtenerNombreUsuarioPorId(deuda.usuarioId);
    final String sucursal = Provider.of<SucursalesServices>(context, listen: false).obtenerNombreSucursalPorId(deuda.sucursalId);
    final detalles = Provider.of<ProductosServices>(context, listen: false).obtenerDetallesComoTexto(deuda.detalles);
    Decimal? monto = obtenerMontoPendiente(deuda.id!);
    Decimal abonadoTotal = (deuda.abonadoMxn??Decimal.zero) + (deuda.abonadoUs??Decimal.zero) + (deuda.abonadoTarj??Decimal.zero) + (deuda.abonadoTrans??Decimal.zero);

    void mostrarMenu(BuildContext context, Offset offset) async {
      late final String? seleccion;

      if (Configuracion.esCaja) {
        seleccion = await showMenu(
          context: context,
          position: RelativeRect.fromLTRB(
            offset.dx,
            offset.dy,
            offset.dx,
            offset.dy,
          ),
          color: AppTheme.dropDownColor,
          elevation: 2,
          items: [
            PopupMenuItem(
              value: 'pagar',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.attach_money, color: AppTheme.letraClara, size: 17),
                  Text('  Pagar', style: AppTheme.subtituloPrimario),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'ver_completo',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, color: AppTheme.letraClara, size: 17),
                  Text('  Datos Completos', style: AppTheme.subtituloPrimario),
                ],
              ),
            ),
            PopupMenuItem( //TODO eliminar 
              value: 'eliminar',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete, color: AppTheme.letraClara, size: 17),
                  Text('  Eliminar Deuda', style: AppTheme.subtituloPrimario),
                ],
              ),
            ),
          ],
        );
      } else {
        seleccion = await showMenu(
          context: context,
          position: RelativeRect.fromLTRB(
            offset.dx,
            offset.dy,
            offset.dx,
            offset.dy,
          ),
          color: AppTheme.dropDownColor,
          elevation: 2,
          items: [
            PopupMenuItem(
              value: 'ver_completo',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, color: AppTheme.letraClara, size: 17),
                  Text('  Datos Completos', style: AppTheme.subtituloPrimario),
                ],
              ),
            ),
          ],
        );
      }
      
      
      if (seleccion != null) {
        if (seleccion == 'ver_completo') {
          // Lógica para leer //TODO ver completo
        } else if (seleccion == 'pagar') {
          // Lógica para pagar
          if(!context.mounted){ return; }
          showDialog(
            context: context,
            builder: (_) => Stack(
              alignment: Alignment.topRight,
              children: [
                ProcesarPago(
                  venta: deuda,
                  rebuild: (){},
                  isDeuda: true,
                  deudaMonto: monto?.toDouble() ?? 0,
                ),
                const WindowBar(overlay: true),
              ],
            ),
          );
        }
      }
    }

    return GestureDetector(
      onSecondaryTapDown: (details) {
        mostrarMenu(context, details.globalPosition);
      },
      child: Container(
        padding: const EdgeInsets.all(8.0),
        color: index % 2 == 0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
        child: Row(
          children: [
            Expanded(child: Text(fecha, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
            Expanded(child: Text(mostrarCampo(cliente), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
            Expanded(child: Text(mostrarCampo(usuario), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
            Expanded(child: Text(SucursalesServices.sucursalActualID!=null ? detalles : sucursal, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
            Expanded(child: Text(Formatos.pesos.format(abonadoTotal.toDouble()), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
            Expanded(child: Text(Formatos.pesos.format(monto!=null ? monto.toDouble() : 0), style: AppTheme.warningStyle, textAlign: TextAlign.center)),
            Expanded(child: Text(Formatos.pesos.format(deuda.total.toDouble()), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          ],
        ),
      ),
    );
  }
}