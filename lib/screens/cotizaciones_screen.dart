import 'dart:async';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbstation_frontend/logic/impresiones.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/logic/mensaje_flotante.dart';
import 'package:pbstation_frontend/logic/venta_state.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/provider/modulos_provider.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';
import 'package:provider/provider.dart';

class CotizacionesScreen extends StatefulWidget {
  const CotizacionesScreen({super.key});

  @override
  State<CotizacionesScreen> createState() => _CotizacionesScreenState();
}

class _CotizacionesScreenState extends State<CotizacionesScreen> {
  final TextEditingController _searchController1 = TextEditingController();
  final TextEditingController _searchController2 = TextEditingController();
  late final CotizacionesServices _cotizacionesSvc;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    _cotizacionesSvc = Provider.of<CotizacionesServices>(
      context,
      listen: false,
    );
    _cotizacionesSvc.loadCotizaciones();
    final clienteServices = Provider.of<ClientesServices>(
      context,
      listen: false,
    );
    clienteServices.loadClientes();
    final productosServices = Provider.of<ProductosServices>(
      context,
      listen: false,
    );
    productosServices.loadProductos();
    final sucursalesServices = Provider.of<SucursalesServices>(
      context,
      listen: false,
    );
    sucursalesServices.loadSucursales();

    _searchController1.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 600), () {
        final query = _searchController1.text.toLowerCase();
        _cotizacionesSvc.filtrarCotizaciones(query, context);
      });
    });
    _searchController2.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 600), () {
        final query = _searchController2.text.toLowerCase();
        _cotizacionesSvc.filtrarVencidas(query, context);
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cotizacionesSvc.filteredCotizaciones = _cotizacionesSvc.cotizaciones;
    _cotizacionesSvc.filteredVencidas = _cotizacionesSvc.vencidas;
    _searchController1.dispose();
    _searchController2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<
      CotizacionesServices,
      ClientesServices,
      ProductosServices,
      SucursalesServices
    >(
      builder: (context, cot, cli, prod, suc, _) {
        if (cot.isLoading || cli.isLoading || prod.isLoading || suc.isLoading) {
          return const Center(child: CircularProgressIndicator());
        } else {
          return BodyPadding(
            hasSubModules: false,
            child: Column(
              children: [
                _buildHeader(context, true),
                const SizedBox(height: 10),
                Expanded(flex: 8, child: _buildTable(cot, true)),
                const SizedBox(height: 10),
                _buildHeader(context, false),
                const SizedBox(height: 10),
                Expanded(flex: 7, child: _buildTable(cot, false)),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isVigente) {
    final cotizacionesServices = Provider.of<CotizacionesServices>(
      context,
      listen: false,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          isVigente ? 'Cotizaciones Vigentes' : 'Cotizaciones Vencidas',
          style: AppTheme.tituloClaro,
          textScaler: const TextScaler.linear(1.7),
        ),
        Row(
          children: [
            if (isVigente) ...[
              ElevatedButton(
                onPressed: () {
                  cotizacionesServices.todasLasSucursales =
                      !cotizacionesServices.todasLasSucursales;
                  cotizacionesServices.recargarFilters();
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.translate(
                      offset: const Offset(-3, 0),
                      child: const Icon(Icons.filter_list),
                    ),
                    Transform.translate(
                      offset: const Offset(3, -1),
                      child: Text(
                        cotizacionesServices.todasLasSucursales
                            ? 'Todas las sucursales'
                            : 'Esta Sucursal',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
            ],
            SizedBox(
              height: 34,
              width: 300,
              child: Tooltip(
                waitDuration: Durations.short4,
                message: 'Folio o Cliente',
                child: TextFormField(
                  controller:
                      isVigente ? _searchController1 : _searchController2,
                  decoration: const InputDecoration(
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
    final lista = isVigente ? servicios.filteredCotizaciones : servicios.filteredVencidas;

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
          child: const Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('Folio', textAlign: TextAlign.center),
              ),
              Expanded(
                flex: 2,
                child: Text('Fecha', textAlign: TextAlign.center),
              ),
              Expanded(
                flex: 2,
                child: Text('Sucursal', textAlign: TextAlign.center),
              ),
              Expanded(
                flex: 3,
                child: Text('Cliente', textAlign: TextAlign.center),
              ),
              Expanded(
                flex: 3,
                child: Text('Productos', textAlign: TextAlign.center),
              ),
              Expanded(
                flex: 2,
                child: Text('Total', textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
        TablaListView(cotizaciones: lista, vigente: isVigente, searchController: isVigente ? _searchController1 : _searchController2,),
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
                '  Total: ${lista.length}   ',
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
    super.key,
    required this.cotizaciones,
    required this.vigente,
    required this.searchController,
  });

  final List<Cotizaciones> cotizaciones;
  final bool vigente;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        color:
            cotizaciones.length % 2 == 0
                ? AppTheme.tablaColor1
                : AppTheme.tablaColor2,
        child: ListView.builder(
          itemCount: cotizaciones.length,
          itemBuilder:
              (context, index) => FilaCotizaciones(
                vigente: vigente,
                cotizacion: cotizaciones[index],
                index: index,
                searchController: searchController,
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
    required this.vigente,
    required this.searchController,
  });

  final Cotizaciones cotizacion;
  final int index;
  final bool vigente;
  final TextEditingController searchController;

  void _mostrarMenu(BuildContext context, Offset offset) async {
    final String? seleccion = await showMenu(
      useRootNavigator: true,
      surfaceTintColor: Colors.transparent,
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy,
        offset.dx,
        offset.dy,
      ),
      color: AppTheme.dropDownColor,
      elevation: 0,
      shadowColor: Colors.black,
      items: [
        if (vigente)
          const PopupMenuItem(
            value: 'imprimir',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.print, color: AppTheme.letraClara, size: 17),
                Text('  Imprimir', style: AppTheme.subtituloPrimario),
              ],
            ),
          ),
        if (vigente)
          const PopupMenuItem(
            value: 'usar',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.navigate_next, color: AppTheme.letraClara, size: 17),
                Text('  Utilizar', style: AppTheme.subtituloPrimario),
              ],
            ),
          ),
        if (!vigente)
          const PopupMenuItem(
            value: 'renovar',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.repeat, color: AppTheme.letraClara, size: 17),
                Text('  Renovar', style: AppTheme.subtituloPrimario),
              ],
            ),
          ),
        const PopupMenuItem(
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

    if (seleccion == null) return;
    if (!context.mounted) return;

    switch (seleccion) {
      case 'imprimir':
        Impresiones.imprimirCotizacion(context, cotizacion);
        break;
      case 'usar':
        _utilizarCotizacion(context);
        break;
      case 'renovar':
        _renovarCotizacion(context);
        break;
      case 'eliminar':
        _eliminarCotizacion(context);
        break;
    }
  }

  void _verCotizacionCompleta(BuildContext context) {
    final clienteSvc = Provider.of<ClientesServices>(context, listen: false);
    final productosSvc = Provider.of<ProductosServices>(context, listen: false);
    final sucursalSvc = Provider.of<SucursalesServices>(context, listen: false);
    final usuarioSvc = Provider.of<UsuariosServices>(context, listen: false);

    final clienteNombre = clienteSvc.obtenerNombreClientePorId(
      cotizacion.clienteId,
    );
    final sucursalNombre = sucursalSvc.obtenerNombreSucursalPorId(
      cotizacion.sucursalId,
    );
    final creadorNombre = usuarioSvc.obtenerNombreUsuarioPorId(
      cotizacion.usuarioId,
    );

    DateTime dt = DateTime.parse(cotizacion.fechaCotizacion);
    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    final String formatted = formatter.format(dt);

    showDialog(
      context: context,
      builder: (_) {
        return Stack(
          alignment: Alignment.topRight,
          children: [
            AlertDialog(
              elevation: 8,
              shadowColor: Colors.black87,
              backgroundColor: AppTheme.containerColor1,
              shape: AppTheme.borde,
              titlePadding: const EdgeInsets.only(top: 24, bottom: 8),
              contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              actionsPadding: const EdgeInsets.only(bottom: 16, top: 8),
              title: Column(
                children: [
                  Text(
                    'Cotización #${cotizacion.folio ?? ''}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          vigente
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFC62828),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      vigente ? 'VIGENTE' : 'VENCIDA',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),

                      // ── Sección: Información General ──
                      _seccionTitulo(
                        Icons.description_outlined,
                        'Información General',
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.containerColor2, //.withAlpha(60),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.letraClara.withAlpha(20),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _infoCampo(
                                    'Folio',
                                    cotizacion.folio ?? '-',
                                  ),
                                ),
                                Expanded(child: _infoCampo('Fecha', formatted)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _infoCampo('Cliente', clienteNombre),
                                ),
                                Expanded(
                                  child: _infoCampo('Sucursal', sucursalNombre),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _infoCampo(
                                    'Creado por',
                                    creadorNombre,
                                  ),
                                ),
                                const Expanded(child: SizedBox()),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ── Comentarios (condicional) ──
                      if (cotizacion.comentariosVenta != null &&
                          cotizacion.comentariosVenta!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.containerColor2.withAlpha(35),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.letraClara.withAlpha(15),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.comment_outlined,
                                    size: 14,
                                    color: AppTheme.letraClara.withAlpha(180),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Comentarios',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.letraClara.withAlpha(180),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                cotizacion.comentariosVenta!,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),

                      // ── Sección: Productos ──
                      _seccionTitulo(
                        Icons.inventory_2_outlined,
                        'Detalle de Productos',
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.letraClara.withAlpha(20),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            // Header de tabla
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              color: AppTheme.tablaColorHeader,
                              child: const Row(
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      'Producto',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Cant.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'P. Unit.',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Desc.',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Total',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Filas de productos
                            ...cotizacion.detalles.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final detalle = entry.value;
                              final producto = productosSvc.productos
                                  .firstWhere(
                                    (p) => p.id == detalle.productoId,
                                    orElse:
                                        () => Productos(
                                          codigo: 0,
                                          descripcion: 'Producto no encontrado',
                                          unidadSat: '',
                                          claveSat: '',
                                          precio: Decimal.zero,
                                          inventariable: false,
                                          imprimible: false,
                                          valorImpresion: 0,
                                          requiereMedida: false,
                                        ),
                                  );
                              final precioUnit =
                                  detalle.cotizacionPrecio ?? producto.precio;
                              final tieneMedidas =
                                  detalle.ancho != null && detalle.alto != null;
                              final tieneNota =
                                  detalle.comentarios != null &&
                                  detalle.comentarios!.isNotEmpty;

                              return Container(
                                color:
                                    idx % 2 == 0
                                        ? AppTheme.tablaColor1
                                        : AppTheme.tablaColor2,
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 4,
                                            child: Text(
                                              '${producto.descripcion} ${tieneMedidas ? '(${detalle.ancho} x ${detalle.alto})' : ''}',
                                              style:
                                                  AppTheme.subtituloConstraste,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              '${detalle.cantidad}',
                                              textAlign: TextAlign.center,
                                              style:
                                                  AppTheme.subtituloConstraste,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              Formatos.pesos.format(
                                                precioUnit.toDouble(),
                                              ),
                                              textAlign: TextAlign.right,
                                              style:
                                                  AppTheme.subtituloConstraste,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              detalle.descuento > 0
                                                  ? '${detalle.descuento}%'
                                                  : '-',
                                              textAlign: TextAlign.right,
                                              style:
                                                  AppTheme.subtituloConstraste,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              Formatos.pesos.format(
                                                detalle.total.toDouble(),
                                              ),
                                              textAlign: TextAlign.right,
                                              style:
                                                  AppTheme.subtituloConstraste,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Sublínea: nota
                                    if (tieneNota)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 12,
                                          right: 12,
                                          bottom: 6,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.note_outlined,
                                              size: 12,
                                              color: AppTheme.colorContraste,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                detalle.comentarios!,
                                                style:
                                                    AppTheme
                                                        .subtituloConstraste,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ── Sección: Resumen Financiero ──
                      _seccionTitulo(Icons.receipt_long_outlined, 'Resumen'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.containerColor2, //.withAlpha(60),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.letraClara.withAlpha(20),
                          ),
                        ),
                        child: Column(
                          children: [
                            _resumenRow(
                              'Subtotal',
                              Formatos.pesos.format(
                                cotizacion.subTotal.toDouble(),
                              ),
                            ),
                            if (cotizacion.descuento > Decimal.zero)
                              _resumenRow(
                                'Descuento',
                                '- ${Formatos.pesos.format(cotizacion.descuento.toDouble())}',
                                color: Colors.orange,
                              ),
                            if (cotizacion.iva > Decimal.zero)
                              _resumenRow(
                                'IVA',
                                Formatos.pesos.format(
                                  cotizacion.iva.toDouble(),
                                ),
                              ),
                            Divider(
                              color: AppTheme.letraClara.withAlpha(50),
                              height: 16,
                            ),
                            _resumenRow(
                              'Total',
                              Formatos.pesos.format(
                                cotizacion.total.toDouble(),
                              ),
                              bold: true,
                              fontSize: 16,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              actions: [
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
            const WindowBar(overlay: true),
          ],
        );
      },
    );
  }

  Widget _seccionTitulo(IconData icon, String titulo) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.letraClara.withAlpha(200)),
        const SizedBox(width: 6),
        Text(
          titulo,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.letraClara.withAlpha(200),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _infoCampo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.letraClara.withAlpha(140),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _resumenRow(
    String label,
    String value, {
    bool bold = false,
    Color? color,
    double fontSize = 13,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: color ?? AppTheme.letraClara.withAlpha(200),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _utilizarCotizacion(BuildContext context) async {
    final clienteSvc = Provider.of<ClientesServices>(context, listen: false);
    final productosSvc = Provider.of<ProductosServices>(context, listen: false);

    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppTheme.containerColor1,
            shape: AppTheme.borde,
            content: const Text(
              '¿Deseas cargar esta cotización en la caja\npara procesarla como venta?',
              textAlign: TextAlign.center,
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Ir a Caja'),
                  ),
                ],
              ),
            ],
          ),
    );

    if (confirmar != true) return;
    if (!context.mounted) return;

    // Cargar datos en VentasStates
    final tabIndex = VentasStates.indexSelected;
    final tab = VentasStates.tabs[tabIndex];
    tab.clear();

    // Cliente
    try {
      tab.clienteSelected = clienteSvc.clientes.firstWhere(
        (c) => c.id == cotizacion.clienteId,
      );
    } catch (_) {}

    // Productos y detalles
    for (var detalle in cotizacion.detalles) {
      try {
        final producto = productosSvc.productos.firstWhere(
          (p) => p.id == detalle.productoId,
        );
        tab.productos.add(producto);
      } catch (_) {}
    }
    tab.detallesVenta = List.from(cotizacion.detalles);
    tab.entregaInmediata = true;
    tab.fromCotizacion = true;
    tab.cotizacionFolio = cotizacion.folio;
    tab.cotizacionId = cotizacion.id;
    VentasStates.count++;

    // Totales
    tab.comentariosController.text = cotizacion.comentariosVenta ?? '';
    tab.subtotalController.text = Formatos.pesos.format(
      cotizacion.subTotal.toDouble(),
    );
    tab.totalDescuentoController.text = Formatos.pesos.format(
      cotizacion.descuento.toDouble(),
    );
    tab.totalIvaController.text = Formatos.pesos.format(
      cotizacion.iva.toDouble(),
    );
    tab.totalController.text = Formatos.pesos.format(
      cotizacion.total.toDouble(),
    );

    // Navegar a Caja
    if (!context.mounted) return;
    final modulosProvider = Provider.of<ModulosProvider>(
      context,
      listen: false,
    );
    modulosProvider.seleccionarModulo('venta');
  }

  void _renovarCotizacion(BuildContext context) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppTheme.containerColor1,
            shape: AppTheme.borde,
            content: const Text(
              '¿Deseas renovar esta cotización?\nSe marcará como vigente con la fecha actual y se mantendra el precio de los productos.',
              textAlign: TextAlign.center,
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Renovar'),
                  ),
                ],
              ),
            ],
          ),
    );

    if (confirmar != true) return;
    if (!context.mounted) return;

    final cotSvc = Provider.of<CotizacionesServices>(context, listen: false);
    final resultado = await cotSvc.renovarCotizacion(cotizacion.id!);
    searchController.clear();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          resultado
              ? '¡Cotización renovada!'
              : 'Error al renovar la cotización',
          textAlign: TextAlign.center,
        ),
        backgroundColor: resultado ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _eliminarCotizacion(BuildContext context) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppTheme.containerColor1,
            shape: AppTheme.borde,
            content: Text(
              '¿Estás seguro de eliminar la cotización ${cotizacion.folio ?? ''}?\nEsta acción no se puede deshacer.',
              textAlign: TextAlign.center,
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade800,
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Eliminar', style: AppTheme.tituloClaro),
                  ),
                ],
              ),
            ],
          ),
    );

    if (confirmar != true) return;
    if (!context.mounted) return;

    final cotSvc = Provider.of<CotizacionesServices>(context, listen: false);
    final resultado = await cotSvc.deleteCotizacion(cotizacion.id!);
    searchController.clear();

    if (!context.mounted) return;
    mostrarMensajeFlotante(
      context,
      resultado ? '¡Cotización eliminada!' : 'Error al eliminar la cotización',
    );
  }

  @override
  Widget build(BuildContext context) {
    //Conseguir cliente
    final clienteSvc = Provider.of<ClientesServices>(context, listen: false);
    final clienteNombre = clienteSvc.obtenerNombreClientePorId(
      cotizacion.clienteId,
    );

    //Conseguir Producto
    final productosSvc = Provider.of<ProductosServices>(context, listen: false);
    final detalles = productosSvc.obtenerDetallesComoTexto(cotizacion.detalles);

    //Conseguir Sucursal
    final sucursalSvc = Provider.of<SucursalesServices>(context, listen: false);
    final sucursalNombre = sucursalSvc.obtenerNombreSucursalPorId(
      cotizacion.sucursalId,
    );

    //fecha
    DateTime dt = DateTime.parse(cotizacion.fechaCotizacion);
    final DateFormat formatter = DateFormat('dd-MM-yyyy');
    final String formatted = formatter.format(dt);

    return FeedBackButton(
      onPressed: () => _verCotizacionCompleta(context),
      onlyVertical: true,
      child: GestureDetector(
        onSecondaryTapDown: (details) {
          _mostrarMenu(context, details.globalPosition);
        },
        child: Container(
          padding: const EdgeInsets.all(8.0),
          color: index % 2 == 0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  cotizacion.folio ?? '-',
                  style: AppTheme.subtituloConstraste,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  formatted,
                  style: AppTheme.subtituloConstraste,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  sucursalNombre,
                  style: AppTheme.subtituloConstraste,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  clienteNombre,
                  style: AppTheme.subtituloConstraste,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  detalles,
                  style: AppTheme.subtituloConstraste,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  Formatos.pesos.format(cotizacion.total.toDouble()),
                  style: AppTheme.subtituloConstraste,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
