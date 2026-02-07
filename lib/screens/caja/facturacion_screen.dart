import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/logic/capitalizar.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/provider/provider.dart';
import 'package:pbstation_frontend/screens/caja/dialog/facturar_venta_dialog.dart';
import 'package:pbstation_frontend/services/login.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';
import 'package:provider/provider.dart';

import 'dialog/facturacion_global_dialog.dart';
import 'dialog/factura_detalle_dialog.dart';

class FacturacionScreen extends StatefulWidget {
  const FacturacionScreen({super.key});

  @override
  State<FacturacionScreen> createState() => _FacturacionScreenState();
}

class _FacturacionScreenState extends State<FacturacionScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchRfcController = TextEditingController();
  String? _lastSearchQuery; // null = nunca se ha buscado

  @override
  void initState() {
    super.initState();

    // Detectar scroll para cargar más
    _scrollController.addListener(_onScroll);

    // Cargar primera página cuando se monta el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ejecutarBusqueda();
    });
  }

  /// Ejecuta búsqueda en servidor si la query cambió
  void _ejecutarBusqueda() {
    final query = _searchRfcController.text.trim();

    // Evitar búsqueda duplicada
    if (query == _lastSearchQuery) return;
    _lastSearchQuery = query;

    String? sucursalId;
    if (Login.usuarioLogeado.permisos == Permiso.admin ||
        Login.usuarioLogeado.rol == TipoUsuario.administrativo) {
      sucursalId = null;
    } else {
      sucursalId = SucursalesServices.sucursalActualID;
    }

    final facturasService = Provider.of<FacturasServices>(
      context,
      listen: false,
    );
    facturasService.cargarHistorialFacturas(
      sucursalId: sucursalId,
      rfc: query.isEmpty ? null : query,
    );
  }

  /// Limpia la búsqueda y recarga todas las facturas
  void _limpiarBusqueda() {
    if (_searchRfcController.text.isEmpty) return;
    _searchRfcController.clear();
    _lastSearchQuery = null;
    _ejecutarBusqueda();
  }

  void _onScroll() {
    // Si está cerca del final, cargar más
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final facturasService = Provider.of<FacturasServices>(
        context,
        listen: false,
      );
      facturasService.cargarMasHistorialFacturas();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchRfcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BodyPadding(
      child: Column(
        children: [
          //Header
          Row(
            children: [
              ElevatedButtonIcon(
                onPressed:
                    () => showDialog(
                      context: context,
                      builder:
                          (_) => const Stack(
                            alignment: Alignment.topRight,
                            children: [
                              IngresarFolioDialog(),
                              WindowBar(overlay: true),
                            ],
                          ),
                    ),
                text: 'Facturar ticket',
                icon: Icons.receipt_long,
                verticalPadding: 0,
              ),
              const SizedBox(width: 15),

              //Boton solo para administradores o admins
              if (Login.usuarioLogeado.rol == TipoUsuario.administrativo ||
                  Login.usuarioLogeado.permisos.tieneAlMenos(Permiso.admin))
                ElevatedButtonIcon(
                  onPressed:
                      () => showDialog(
                        context: context,
                        builder:
                            (_) => const Stack(
                              alignment: Alignment.topRight,
                              children: [
                                FolioMensualDialog(),
                                WindowBar(overlay: true),
                              ],
                            ),
                      ),
                  text: 'Crear factura global',
                  icon: Icons.receipt_long,
                  verticalPadding: 0,
                ),

              const Spacer(),

              // Búsqueda con protección de carga
              Consumer<FacturasServices>(
                builder: (context, facturasService, _) {
                  final isLoading = facturasService.historialIsLoading;

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Campo de búsqueda
                      SizedBox(
                        height: 34,
                        width: 220,
                        child: TextFormField(
                          controller: _searchRfcController,
                          enabled: !isLoading,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(
                              Icons.search,
                              color: AppTheme.letraClara,
                            ),
                            hintText: 'Buscar por RFC',
                          ),
                          onFieldSubmitted:
                              isLoading ? null : (_) => _ejecutarBusqueda(),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Botón buscar
                      SizedBox(
                        height: 34,
                        width: 100,
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : _ejecutarBusqueda,
                          icon:
                              isLoading
                                  ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.letraClara,
                                    ),
                                  )
                                  : const Icon(Icons.search, size: 18),
                          label: const Text('Buscar'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Botón limpiar
                      SizedBox(
                        height: 34,
                        width: 34,
                        child: IconButton(
                          onPressed:
                              isLoading || _searchRfcController.text.isEmpty
                                  ? null
                                  : _limpiarBusqueda,
                          icon: const Icon(Icons.clear, size: 18),
                          tooltip: 'Limpiar búsqueda',
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.tablaColor2,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 15),

          //Tabla Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.tablaColorHeader,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Center(child: Text('Fecha'))),
                Expanded(flex: 3, child: Center(child: Text('Receptor'))),
                Expanded(flex: 3, child: Center(child: Text('Folio de Venta'))),
                Expanded(flex: 3, child: Center(child: Text('Subtotal'))),
                Expanded(flex: 3, child: Center(child: Text('Descuento'))),
                Expanded(flex: 3, child: Center(child: Text('Impuestos'))),
                Expanded(flex: 3, child: Center(child: Text('Total'))),
                Expanded(flex: 2, child: Center(child: Text('¿Es Global?'))),
              ],
            ),
          ),

          //Tabla body
          Expanded(
            child: Consumer<FacturasServices>(
              builder: (context, facturasService, child) {
                final facturas = facturasService.historialFacturas;

                // Estado de carga inicial
                if (facturasService.historialIsLoading && facturas.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Error sin datos
                if (facturasService.historialError != null &&
                    facturas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(facturasService.historialError!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed:
                              () => facturasService.cargarHistorialFacturas(),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                // Sin facturas
                if (facturas.isEmpty) {
                  return const Center(
                    child: Text('No hay facturas que coincidan'),
                  );
                }

                // Tabla con facturas
                return ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                  child: Container(
                    color:
                        facturas.length % 2 == 0
                            ? AppTheme.tablaColor1
                            : AppTheme.tablaColor2,
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: facturas.length,
                      itemBuilder: (context, index) {
                        final factura = facturas[index];
                        return FilaFactura(factura: factura, index: index);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FilaFactura extends StatelessWidget {
  const FilaFactura({super.key, required this.factura, required this.index});

  final Facturas factura;
  final int index;

  @override
  Widget build(BuildContext context) {
    final fecha = DateFormat('MMMM', 'es_MX').format(factura.fecha);
    final fechaDia = capitalizarPrimeraLetra(
      DateFormat('EEEE', 'es_MX').format(factura.fecha),
    );

    return FeedBackButton(
      onPressed:
          () => showDialog(
            context: context,
            builder:
                (_) => Stack(
                  alignment: Alignment.topRight,
                  children: [
                    FacturaDetalleDialog(factura: factura),
                    const WindowBar(overlay: true),
                  ],
                ),
          ),
      onlyVertical: true,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: index % 2 == 0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Center(
                child: Text(
                  '$fechaDia ${factura.fecha.day} de $fecha',
                  style: AppTheme.subtituloConstraste,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Center(
                child: Text(
                  '${factura.receptorNombre} - ${factura.receptorRfc}',
                  style: AppTheme.subtituloConstraste,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Center(
                child: Text(
                  !factura.isGlobal ? factura.folioVenta : '-',
                  style: AppTheme.subtituloConstraste,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Center(
                child: Text(
                  Formatos.moneda.format(factura.subTotal.toDouble()),
                  style: AppTheme.subtituloConstraste,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Center(
                child: Text(
                  Formatos.moneda.format(factura.descuento.toDouble()),
                  style: AppTheme.subtituloConstraste,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Center(
                child: Text(
                  Formatos.moneda.format(factura.impuestos.toDouble()),
                  style: AppTheme.subtituloConstraste,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Center(
                child: Text(
                  Formatos.moneda.format(factura.total.toDouble()),
                  style: AppTheme.subtituloConstraste,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: Icon(
                  factura.isGlobal ? Icons.check_circle : Icons.cancel,
                  color: factura.isGlobal ? Colors.green : Colors.grey,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FolioMensualDialog extends StatefulWidget {
  const FolioMensualDialog({super.key});

  @override
  State<FolioMensualDialog> createState() => _FolioMensualDialogState();
}

class _FolioMensualDialogState extends State<FolioMensualDialog> {
  final List<DateTime> _dates = [];

  void submited(DateTime date) async {
    Navigator.pop(context);

    final loadingSvc = Provider.of<LoadingProvider>(context, listen: false);
    loadingSvc.show('Obteniendo tickets');

    String fecha = date.toString().substring(0, 10);
    final ventaSvc = Provider.of<VentasServices>(context, listen: false);
    List<Ventas> ventasSinFacturar = await ventaSvc
        .obtenerVentasSinFacturarPorDia(fecha);
    loadingSvc.hide();

    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (_) => Stack(
            alignment: Alignment.topRight,
            children: [
              FacturaGlobalDialog(ventas: ventasSinFacturar),
              const WindowBar(overlay: true),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      elevation: 6,
      shadowColor: Colors.black54,
      backgroundColor: AppTheme.containerColor1,
      shape: AppTheme.borde,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.height * 0.5,
            child: Theme(
              data: Theme.of(context).copyWith(
                textTheme: const TextTheme(
                  bodyMedium: TextStyle(
                    color: Colors.white,
                  ), // Cambia el color del texto
                ),
                colorScheme: ColorScheme.light(
                  primary:
                      AppTheme
                          .tablaColor2, // Color principal (por ejemplo, para el encabezado)
                  onSurface: Colors.white, // Color del texto en general
                ),
              ),
              child: CalendarDatePicker2(
                config: CalendarDatePicker2Config(),
                value: _dates,
                onValueChanged: (selectedDate) {
                  submited(selectedDate.first);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class IngresarFolioDialog extends StatefulWidget {
  const IngresarFolioDialog({super.key});

  @override
  State<IngresarFolioDialog> createState() => _IngresarFolioDialogState();
}

class _IngresarFolioDialogState extends State<IngresarFolioDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _ctrl = TextEditingController();
  bool isLoading = false;
  Color color = Colors.white;
  String hint = '';

  void submited() async {
    setState(() {
      isLoading = true;
    });

    //es folio de venta
    final Ventas? venta = await Provider.of<VentasServices>(
      context,
      listen: false,
    ).searchVentaFolio(_ctrl.text);
    if (venta != null) {
      //verificar que no este facturado ya
      if (venta.facturaId != null) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder:
              (_) => const Stack(
                alignment: Alignment.topRight,
                children: [
                  CustomErrorDialog(
                    titulo: 'No valido para facturar',
                    respuesta: 'Esta venta ya se encuentra facturada',
                  ),
                  WindowBar(overlay: true),
                ],
              ),
        );
        setState(() {
          isLoading = false;
        });
      } else {
        if (!mounted) return;
        Navigator.pop(context);
        showDialog(
          context: context,
          builder:
              (_) => Stack(
                alignment: Alignment.topRight,
                children: [
                  FacturarVentaDialog(venta: venta),
                  const WindowBar(overlay: true),
                ],
              ),
        );
      }
    } else {
      setState(() {
        color = Colors.red;
        hint = 'no se encontro';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      elevation: 6,
      shadowColor: Colors.black54,
      backgroundColor: AppTheme.containerColor1,
      shape: AppTheme.borde,
      content:
          !isLoading
              ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Folio a facturar',
                    textScaler: TextScaler.linear(1.1),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 200,
                    height: 40,
                    child: Form(
                      key: _formKey,
                      child: TextFormField(
                        onChanged: (value) {
                          if (color == Colors.red) {
                            setState(() {
                              color = Colors.white;
                              hint = '';
                            });
                          }
                        },
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25.0),
                            borderSide: BorderSide(width: 2, color: color),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25.0),
                            borderSide: BorderSide(color: color),
                          ),
                        ),
                        controller: _ctrl,
                        autofocus: true,
                        textAlign: TextAlign.center,
                        inputFormatters: [
                          TextInputFormatter.withFunction(
                            (oldValue, newValue) => TextEditingValue(
                              text: newValue.text.toUpperCase(),
                              selection: newValue.selection,
                            ),
                          ),
                        ],
                        onFieldSubmitted: (s) => submited(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  hint.isEmpty
                      ? ElevatedButton(
                        child: const Text('Continuar'),
                        onPressed: () => submited(),
                      )
                      : const Padding(
                        padding: EdgeInsets.all(5.5),
                        child: Text('No se encontraron resultados'),
                      ),
                ],
              )
              : const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Buscando...'),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 25),
                    child: CircularProgressIndicator(
                      color: AppTheme.letraClara,
                    ),
                  ),
                ],
              ),
    );
  }
}
