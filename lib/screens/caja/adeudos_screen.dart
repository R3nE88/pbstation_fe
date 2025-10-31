import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbstation_frontend/logic/capitalizar.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/logic/search_fields_estaticos.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/screens/caja/dialog/venta_dialog.dart';
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
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  int duracion = 600;//-



  @override
  void initState() {
    super.initState();
    duracion = 100;//-
    final clientesConAdeudo = Provider.of<ClientesServices>(context, listen:false).loadAdeudos();
    final ventasSvc = Provider.of<VentasServices>(context, listen:false);
    
    ventasSvc.adeudoLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ventasSvc.loadAdeudos(clientesConAdeudo, SucursalesServices.sucursalActualID);
    });

    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(Duration(milliseconds: duracion), () {
        final query = _searchController.text.toLowerCase();
        ventasSvc.filtrarDeudas(query);
        duracion = 600;//-
      });
    });

    //SearchField from otra parte //-
    if (SearchFieldStatics.adeudoSearchText.isNotEmpty){
       _searchController.text = SearchFieldStatics.adeudoSearchText;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    SearchFieldStatics.adeudoSearchText=''; //-
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ventaSvc = Provider.of<VentasServices>(context);
    if (ventaSvc.adeudoLoading){
      return const SimpleLoading();
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
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
              textScaler: const TextScaler.linear(1.2),
            ),
          ],
        ),
        SizedBox(
          height: 34,
          width: 250,
          child: TextFormField(
            controller: _searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search, color: AppTheme.letraClara),
              hintText: 'Buscar por Folio',
            ),
          ),
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
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                color: AppTheme.tablaColorHeader,
              ),
              child: Row(
                children: [
                  const Expanded(child: Text('Folio', textAlign: TextAlign.center)),
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
                color: servicios.ventasConDeudaFiltered.length % 2 == 0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
                child: ListView.builder( 
                  itemCount: servicios.ventasConDeudaFiltered.length,
                  itemBuilder: (context, index) {
                    return FilaDeuda(
                      deuda: servicios.ventasConDeudaFiltered[index],
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
                    '  Total: ${servicios.ventasConDeudaFiltered.length}   ',
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
    final fecha = DateFormat('d/MMM/yy hh:mm a', 'es_MX').format(date);
    final fechaDia = DateFormat('EEEE', 'es_MX').format(date);
    final String cliente = Provider.of<ClientesServices>(context, listen: false).obtenerNombreClientePorId(deuda.clienteId);
    final String usuario = Provider.of<UsuariosServices>(context, listen: false).obtenerNombreUsuarioPorId(deuda.usuarioId);
    final String sucursal = Provider.of<SucursalesServices>(context, listen: false).obtenerNombreSucursalPorId(deuda.sucursalId);
    final detalles = Provider.of<ProductosServices>(context, listen: false).obtenerDetallesComoTexto(deuda.detalles);
    Decimal? monto = obtenerMontoPendiente(deuda.id!);
    Decimal abonadoTotal = (deuda.abonadoMxn??Decimal.zero) + (deuda.abonadoUs??Decimal.zero) + (deuda.abonadoTarj??Decimal.zero) + (deuda.abonadoTrans??Decimal.zero);
    final ventaSvc = Provider.of<VentasServices>(context, listen: false);

    bool deudaDeCajaACtual = ventaSvc.ventasDeCaja.any((venta) => venta.id == deuda.id);
    
    return FeedBackButton(
      onlyVertical: true,
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) => Stack(
            alignment: Alignment.topRight,
            children: [
              VentaDialog(venta: deuda, tc: deudaDeCajaACtual ? CajasServices.cajaActual!.tipoCambio : 0, isActive: deudaDeCajaACtual, callback: (){}, fromDeudas: true,),
              const WindowBar(overlay: true),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 2),
        color: index % 2 == 0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
        child: Row(
          children: [
            Expanded(child: Text(deuda.folio??'', style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
            Expanded(child: Text('$fechaDia\n$fecha', style: AppTheme.subtituloConstraste, textAlign: TextAlign.center, textScaler: const TextScaler.linear(0.9),)),
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