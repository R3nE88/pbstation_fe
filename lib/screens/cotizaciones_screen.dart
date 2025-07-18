import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/services/login.dart';
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
    
    print('object');

    final cotizacionesServices = Provider.of<CotizacionesServices>(context, listen: false);
    cotizacionesServices.loadCotizaciones();
    final clienteServices = Provider.of<ClientesServices>(context, listen: false);
    clienteServices.loadClientes();
    final productosServices = Provider.of<ProductosServices>(context, listen: false);
    productosServices.loadProductos();

    _searchController1.addListener(() { //TODO: searchfields
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 600), () {
        final query = _searchController1.text.toLowerCase();
        //TODO: cotizacionesServices.filtrarVigentes(query);
      });
    });
    _searchController2.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 600), () {
        final query = _searchController2.text.toLowerCase();
        //TODO cotizacionesServices.filtrarVencidas(query);
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
    return Consumer3<CotizacionesServices, ClientesServices, ProductosServices>(
      builder: (context, cot, cli, prod, _) {
        if (cot.isLoading || cli.isLoading || prod.isLoading) {
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          isVigente ? 'Cotizaciones Vigentes' : 'Cotizaciones Vencidas',
          style: AppTheme.tituloClaro,
          textScaler: TextScaler.linear(1.7),
        ),
        Row(
          children: [
            ElevatedButton(
              onPressed: (){}, 
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
                    child: Text("Esta Sucursal"), //TODO: filtrar por: esta sucursal / todas las sucursales
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
        ),
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
              Expanded(child: Text('Folio', textAlign: TextAlign.center)),
              Expanded(child: Text('Fecha', textAlign: TextAlign.center)),
              Expanded(flex: 1, child: Text('Cliente', textAlign: TextAlign.center)),
              Expanded(flex: 2, child: Text('Productos', textAlign: TextAlign.center)),
              Expanded(flex: 1, child: Text('Total', textAlign: TextAlign.center)),
            ],
          ),
        ),
        TablaListView(cotizaciones: isVigente ? servicios.cotizaciones : servicios.vencidas),
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
    super.key, required this.cotizaciones,
  });

  final List<Cotizaciones> cotizaciones;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        color: cotizaciones.length % 2 == 0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
        child: ListView.builder( //TODO: acomodar por fecha, mas nuevo arriba siempre
          itemCount: cotizaciones.length,
          itemBuilder: (context, index) => FilaCotizaciones(
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
    required this.onDelete,
  });

  final Cotizaciones cotizacion;
  final int index;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {

    /*void mostrarMenu(BuildContext context, Offset offset) async {
      final String? seleccion;
      if (Login.admin) {
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
                Text('  Datos Completos', style: AppTheme.subtituloPrimario),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'editar',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit, color: AppTheme.letraClara, size: 17),
                Text('  Editar', style: AppTheme.subtituloPrimario),
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
            value: 'leer',
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
    }*/

    //Conseguir cliente
    final clienteSvc = Provider.of<ClientesServices>(context, listen: false);
    final clienteNombre = clienteSvc.obtenerNombreClientePorId(cotizacion.clienteId);

    //Conseguir Producto
    final productosSvc = Provider.of<ProductosServices>(context, listen: false);
    final detalles = productosSvc.obtenerDetallesComoTexto(cotizacion.detalles);

    //fecha
    DateTime dt = DateTime.parse(cotizacion.fechaCotizacion);
    final DateFormat formatter = DateFormat('dd-MM-yyyy');
    final String formatted = formatter.format(dt);


    return GestureDetector(
      onSecondaryTapDown: (details) {
        //TODO: mostrarMenu(context, details.globalPosition);
      },
      child: Container(
        padding: const EdgeInsets.all(8.0),
        color: index % 2 == 0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
        child: Row(
          children: [
            Expanded(child: Text(cotizacion.folio!, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
            Expanded(child: Text(formatted, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
            Expanded(flex: 1,child: Text(clienteNombre, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
            Expanded(flex: 2,child: Text(detalles, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
            Expanded(flex: 1, child: Text(Formatos.pesos.format(cotizacion.total.toDouble()), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          ],

        ),

      ),

    );

  }

}