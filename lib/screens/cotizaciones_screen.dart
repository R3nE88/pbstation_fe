import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:provider/provider.dart';

class CotizacionesScreen extends StatefulWidget {
  const CotizacionesScreen({super.key});

  @override
  State<CotizacionesScreen> createState() => _CotizacionesScreenState();
}

class _CotizacionesScreenState extends State<CotizacionesScreen> {
  final TextEditingController _searchController1 = TextEditingController();
  final TextEditingController _searchController2 = TextEditingController();
  Timer? _debounce;

@override
  void initState() {
    super.initState();
    
    final cotizacionesServices = Provider.of<CotizacionesServices>(context, listen: false);
    cotizacionesServices.loadCotizaciones();
    final clienteServices = Provider.of<ClientesServices>(context, listen: false);
    clienteServices.loadClientes();
    final productosServices = Provider.of<ProductosServices>(context, listen: false);
    productosServices.loadProductos();
    final sucursalesServices = Provider.of<SucursalesServices>(context, listen: false);
    sucursalesServices.loadSucursales();

    _searchController1.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 600), () {
        final query = _searchController1.text.toLowerCase();
        cotizacionesServices.filtrarCotizaciones(query, context);
      });
    });
    _searchController2.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 600), () {
        final query = _searchController2.text.toLowerCase();
        cotizacionesServices.filtrarVencidas(query, context);
      });
    });
  }

  @override
  void dispose() {
    _searchController1.dispose();
    _searchController2.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<CotizacionesServices, ClientesServices, ProductosServices, SucursalesServices>(
      builder: (context, cot, cli, prod, suc, _) {
        if (cot.isLoading || cli.isLoading || prod.isLoading || suc.isLoading) {
          return const Center(child: CircularProgressIndicator());
        } else {
          return Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 5, left: 54, right: 0),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.containerColor1,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    _buildHeader(context, true),
                    const SizedBox(height: 10),
                    Expanded(
                      flex: 8,
                      child: _buildTable(cot, true)
                    ),
                    const SizedBox(height: 10),
                    _buildHeader(context, false),
                    const SizedBox(height: 10),
                    Expanded(
                      flex: 7,
                      child: _buildTable(cot, false)
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      }
    );
  }

  Widget _buildHeader(BuildContext context, bool isVigente) {
    final cotizacionesServices = Provider.of<CotizacionesServices>(context, listen: false);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          isVigente ? 'Cotizaciones Vigentes' : 'Cotizaciones Vencidas',
          style: AppTheme.tituloClaro,
          textScaler: TextScaler.linear(1.7),
        ),
        isVigente ? Row(
          children: [
            ElevatedButton(
              onPressed: (){
                
                cotizacionesServices.todasLasSucursales;
                cotizacionesServices.todasLasSucursales = !cotizacionesServices.todasLasSucursales;
                cotizacionesServices.recargarFilters();

              }, 
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.translate(
                    offset: Offset(-3, 0),
                    child: Icon(
                      Icons.filter_list
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(3, -1),
                    child: Text(cotizacionesServices.todasLasSucursales ?  "Todas las sucursales" : "Esta Sucursal"),
                  ),
                ],
              )
            ), const SizedBox(width: 20),

            SizedBox(
              height: 34,
              width: 300,
              child: Tooltip(
                waitDuration: Durations.short4,
                message: 'Folio o Cliente',
                child: TextFormField(
                  controller: isVigente ? _searchController1 : _searchController2,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, color: AppTheme.letraClara),
                    hintText: 'Buscar Cotizacion',
                  ),
                ),
              ),
            ),
          ],
        ) : const SizedBox(),
      ],
    );
  }
  

  Widget _buildTable(CotizacionesServices servicios, bool isVigente) {
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
            children: const [
              Expanded(flex: 2, child: Text('Folio', textAlign: TextAlign.center)),
              Expanded(flex: 2, child: Text('Fecha', textAlign: TextAlign.center)),
              Expanded(flex: 2, child: Text('Sucursal', textAlign: TextAlign.center)),
              Expanded(flex: 3, child: Text('Cliente', textAlign: TextAlign.center)),
              Expanded(flex: 3, child: Text('Productos', textAlign: TextAlign.center)),
              Expanded(flex: 2, child: Text('Total', textAlign: TextAlign.center)),
            ],
          ),
        ),
        TablaListView(cotizaciones: isVigente ? servicios.filteredCotizaciones : servicios.filteredVencidas, vigente: isVigente),
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
               isVigente ?
                '  Total: ${servicios.cotizaciones.length}   '
                :
                '  Total: ${servicios.vencidas.length}   ',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TablaListView extends StatelessWidget {
  const TablaListView({
    super.key, required this.cotizaciones, required this.vigente,
  });

  final List<Cotizaciones> cotizaciones;
  final bool vigente;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        color: cotizaciones.length % 2 == 0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
        child: ListView.builder(
          itemCount: cotizaciones.length,
          itemBuilder: (context, index) => FilaCotizaciones(
            vigente: vigente,
            cotizacion: cotizaciones[index],
            index: index,
            onDelete: () async {
              /*Loading.displaySpinLoading(context);
              await servicios.deleteProducto(servicios.cotizaciones[index].id!);
              if (!context.mounted) return;
              Navigator.pop(context);*/
            },
          ),
        ),
      ),
    );
  }
}

class FilaCotizaciones extends StatelessWidget {
  const FilaCotizaciones({
    super.key,
    required this.cotizacion,
    required this.index,
    required this.onDelete, required this.vigente,
  });

  final Cotizaciones cotizacion;
  final int index;
  final VoidCallback onDelete;
  final bool vigente;

  @override
  Widget build(BuildContext context) {

    void mostrarMenu(BuildContext context, Offset offset) async {
      /*final String? seleccion;
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
            value: 'leer',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, color: AppTheme.letraClara, size: 17),
                Text('  Ver Cotizacion Completa', style: AppTheme.subtituloPrimario),
              ],
            ),
          ),
          vigente 
          ? PopupMenuItem(
            value: 'usar',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.navigate_next, color: AppTheme.letraClara, size: 17),
                 Text('  Utilizar', style: AppTheme.subtituloPrimario)
              ],
            ),
          )
          : PopupMenuItem(
            value: 'renovar',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.repeat, color: AppTheme.letraClara, size: 17),
                 Text('  Renovar', style: AppTheme.subtituloPrimario)
              ],
            ),
          ),
          PopupMenuItem(
            value: 'print',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.print, color: AppTheme.letraClara, size: 17),
                Text('  Imprimir', style: AppTheme.subtituloPrimario),
              ],
            ),
          ),
          PopupMenuItem(
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
      );*/

      /*if (seleccion != null) {
        if (seleccion == 'leer') {
          // Lógica para leer
          if(!context.mounted){ return; }
          showDialog(
            context: context,
            builder: (_) => ProductoFormDialog(prodEdit: producto, onlyRead: true),
          );
        } else if (seleccion == 'editar') {
          // Lógica para editar
          if(!context.mounted){ return; }
          showDialog(
            context: context,
            builder: (_) => ProductoFormDialog(prodEdit: producto),
          );
        } else if (seleccion == 'eliminar') {
          // Lógica para eliminar
          onDelete();
        }
      }*/
    }

    //Conseguir cliente
    final clienteSvc = Provider.of<ClientesServices>(context, listen: false);
    final clienteNombre = clienteSvc.obtenerNombreClientePorId(cotizacion.clienteId);

    //Conseguir Producto
    final productosSvc = Provider.of<ProductosServices>(context, listen: false);
    final detalles = productosSvc.obtenerDetallesComoTexto(cotizacion.detalles);

    //Conseguir Sucursal
    final sucursalSvc = Provider.of<SucursalesServices>(context, listen: false);
    final sucursalNombre = sucursalSvc.obtenerNombreSucursalPorId(cotizacion.sucursalId);

    //fecha
    DateTime dt = DateTime.parse(cotizacion.fechaCotizacion);
    final DateFormat formatter = DateFormat('dd-MM-yyyy');
    final String formatted = formatter.format(dt);


    return GestureDetector(
      onSecondaryTapDown: (details) {
        mostrarMenu(context, details.globalPosition);
      },
      child: Container(
        padding: const EdgeInsets.all(8.0),
        color: index % 2 == 0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
        child: Row(
          children: [
            Expanded(flex: 2, child: Text(cotizacion.folio!, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
            Expanded(flex: 2, child: Text(formatted, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
            Expanded(flex: 2, child: Text(sucursalNombre, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
            Expanded(flex: 3, child: Text(clienteNombre, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
            Expanded(flex: 3, child: Text(detalles, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
            Expanded(flex: 2, child: Text(Formatos.pesos.format(cotizacion.total.toDouble()), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          ],

        ),

      ),

    );

  }

}