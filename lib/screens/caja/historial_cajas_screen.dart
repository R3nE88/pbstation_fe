import 'dart:async';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/logic/capitalizar.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/screens/caja/caja_screen.dart';
import 'package:pbstation_frontend/services/login.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';
import 'package:provider/provider.dart';

class HistorialDeCajas extends StatefulWidget {
  const HistorialDeCajas({super.key});

  @override
  State<HistorialDeCajas> createState() => _HistorialDeCajasState();
}

class _HistorialDeCajasState extends State<HistorialDeCajas> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _buscarController = TextEditingController();
  Timer? _debounce;
  String? _sucursalSeleccionada;
  DateTimeRange? _rangoFechas;
  bool _isAdmin = false;
  
  bool _cajaScreen = false;
  Cajas? _cajaSelected;

  @override
  void initState() {
    super.initState();
    String? sucursalId;
    if (Login.usuarioLogeado.permisos==Permiso.admin || Login.usuarioLogeado.rol == TipoUsuario.administrativo){
      sucursalId = null;
      _isAdmin = true;
    } else {
      sucursalId = SucursalesServices.sucursalActualID;
      _isAdmin = false;
    }
    _sucursalSeleccionada = sucursalId;

    // Detectar scroll para cargar más
    _scrollController.addListener(_onScroll);

    // Cargar primera página cuando se monta el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _cargarDatos();
    });
  }

  void _cargarDatos({bool append = false}) {
    final cajasService = Provider.of<CajasServices>(context, listen: false);
    String? fechaInicio;
    String? fechaFin;

    if (_rangoFechas != null) {
      fechaInicio = DateFormat('yyyy-MM-dd').format(_rangoFechas!.start);
      fechaFin = DateFormat('yyyy-MM-dd').format(_rangoFechas!.end);
    }

    cajasService.cargarHistorialCajas(
      sucursalId: _sucursalSeleccionada,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      folio: _buscarController.text.trim().isNotEmpty ? _buscarController.text.trim() : null,
      append: append,
    );
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {});
        _cargarDatos();
      }
    });
  }

  void _onScroll() {
    // Si está cerca del final, cargar más
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      final cajasService = Provider.of<CajasServices>(context, listen: false);
      cajasService.cargarMasHistorialCajas();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _buscarController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
  
  Widget _buildFilterBar() {
    final sucursalesService = Provider.of<SucursalesServices>(context, listen: false);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.tablaColorHeader, // Mismo color base para consistencia
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.only(bottom: 16, top: 4),
      child: Row(
        children: [

          const Text('Filtrar   ', style: TextStyle(color: AppTheme.letra70, fontWeight: FontWeight.w500)),

          // Búsqueda
          Container(
            height: 32,
            constraints: const BoxConstraints(maxWidth: 205, minWidth: 190),
            child: TextField(
              controller: _buscarController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar por folio...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.letraClara),
                suffixIcon: _buscarController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20, color: AppTheme.letraClara),
                        onPressed: () {
                          setState(() {
                            _buscarController.clear();
                          });
                          _onSearchChanged('');
                        },
                      )
                    : null,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          
          // Filtro por Fecha
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: ElevatedButton(
              onPressed: () async {
                  List<DateTime?> tempDates = _rangoFechas != null 
                      ? [_rangoFechas!.start, _rangoFechas!.end] 
                      : [];
                      
                  final List<DateTime?>? picked = await showDialog<List<DateTime?>>(
                    context: context,
                    builder: (BuildContext context) {
                      return Stack(
                        alignment: Alignment.topRight,
                        children: [
                          AlertDialog(
                            elevation: 6,
                            shadowColor: Colors.black54,
                            backgroundColor: AppTheme.containerColor1,
                            shape: AppTheme.borde,
                            content: SizedBox(
                              width: MediaQuery.of(context).size.height * 0.5,
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  textTheme: const TextTheme(
                                    bodyMedium: TextStyle(color: Colors.white),
                                  ),
                                  colorScheme: ColorScheme.light(
                                    primary: AppTheme.tablaColor2,
                                    onSurface: Colors.white,
                                  ),
                                ),
                                child: CalendarDatePicker2(
                                  config: CalendarDatePicker2Config(
                                    calendarType: CalendarDatePicker2Type.range,
                                  ),
                                  value: tempDates,
                                  onValueChanged: (dates) {
                                    if (dates.length == 2) {
                                      Navigator.pop(context, dates);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                          const WindowBar(overlay: true),
                        ],
                      );
                    },
                  );
                  
                  if (picked != null && picked.length == 2 && picked[0] != null && picked[1] != null) {
                    final newRange = DateTimeRange(start: picked[0]!, end: picked[1]!);
                    if (newRange != _rangoFechas) {
                      setState(() {
                        _rangoFechas = newRange;
                      });
                      _cargarDatos();
                    }
                  }
                },
              child: Row(
                children: [
                  const Icon(Icons.calendar_today),
                  const SizedBox(width: 8),
                  Text(_rangoFechas == null
                      ? 'Fechas'
                      : '${DateFormat('dd/MM/yy').format(_rangoFechas!.start)} - ${DateFormat('dd/MM/yy').format(_rangoFechas!.end)}',
                  ),
                ],
              )
            ),
          ),

          // Filtro de Sucursal (Solo para Admin)
          if (_isAdmin)
            Container(
              height: 34,
              constraints: const BoxConstraints(maxWidth: 260, minWidth: 180, minHeight: 34, maxHeight: 34),
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _sucursalSeleccionada,
                icon: const Icon(Icons.arrow_drop_down, color: AppTheme.letraClara),
                decoration: InputDecoration(
                  iconColor: AppTheme.letraClara,
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                hint: const Text('Todas las sucursales', overflow: TextOverflow.ellipsis),
                items: [
                  const DropdownMenuItem<String>(
                    child: Text('Todas las sucursales', overflow: TextOverflow.ellipsis),
                  ),
                  ...sucursalesService.sucursales.map((sucursal) {
                    return DropdownMenuItem<String>(
                      value: sucursal.id,
                      child: Text(sucursal.nombre, overflow: TextOverflow.ellipsis),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _sucursalSeleccionada = value;
                  });
                  _cargarDatos();
                },
              ),
            ),

          const Spacer(),

          // Botón para limpiar filtros
          if (_rangoFechas != null || _buscarController.text.isNotEmpty || (_isAdmin && _sucursalSeleccionada != null))
            FeedBackButton(
              onPressed: () {
                setState(() {
                  _buscarController.clear();
                  _rangoFechas = null;
                  if (_isAdmin) _sucursalSeleccionada = null;
                });
                _cargarDatos();
              },
              child: const Icon(Icons.clear, color: Colors.red),
            ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if(_cajaScreen){
      return Stack(
        alignment: AlignmentGeometry.topLeft,
        children: [
          CajaScreen(readMode: true, caja: _cajaSelected!),
          Transform.translate(
            offset: const Offset(65, 18),
            child: Transform.scale(
              scale: 0.8,
              child: IconButton(
                onPressed: () {
                  setState(() {_cajaScreen = false;});
                },
                icon: Transform.scale(
                  scale: 2,
                  child: const Icon(Icons.chevron_left)
                ),
                color: AppTheme.primario1,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: const CircleBorder(),
                ),
              ),
            )
          )
        ],
      );
    }

    return BodyPadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [ 
          _buildFilterBar(),

          const Separador(texto: 'Historial de cajas',),

          Expanded(
            child: Consumer<CajasServices>(
              builder: (context, cajasService, child) {
                // Estado de carga inicial
                if (cajasService.historialIsLoading && cajasService.historialCajas.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Error sin datos
                if (cajasService.historialError != null && cajasService.historialCajas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(cajasService.historialError!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => cajasService.cargarHistorialCajas(),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                // Sin cajas
                if (cajasService.historialCajas.isEmpty) {
                  return const Center(child: Text('No hay cajas registradas'));
                }

                // Grid con cajas
                return GridView.builder(
                  controller: _scrollController,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 600,
                    mainAxisExtent: 80,
                  ),
                  itemCount: cajasService.historialCajas.length + 
                            (cajasService.paginacionHistorial?.hasNext ?? false ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Indicador de carga al final
                    if (index == cajasService.historialCajas.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final caja = cajasService.historialCajas[index];
                    return _buildCajaCard(caja, context);
                  },
                );
              },
            ),
          ),
        ],
      )
    );
  }

  Widget _buildCajaCard(Cajas caja, context) {
    // Formatear fecha
    final DateTime fecha = DateTime.parse(caja.fechaApertura);
    final dia = DateFormat('EEEE', 'es_MX').format(fecha);
    final fechaFormateada =  DateFormat('d/MMM/yy', 'es_MX').format(fecha);
    final sucursal = Provider.of<SucursalesServices>(context, listen:false).obtenerNombreSucursalPorId(caja.sucursalId);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.tablaColorHeader,
          borderRadius: const BorderRadius.all(Radius.circular(6))
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(capitalizarPrimeraLetra(dia), style: AppTheme.labelStyle),
                    Text(fechaFormateada, textScaler: const TextScaler.linear(1.15)),
                  ],
                ),
              ),
          
              Expanded(
                flex: 3,
                child: SizedBox(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(sucursal),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Caja: ', style: AppTheme.labelStyle),
                          Text(caja.folio ?? 'N/A', textScaler: const TextScaler.linear(1.15)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Venta', style: AppTheme.labelStyle),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('MXN', style: AppTheme.labelStyle, textScaler: TextScaler.linear(0.8)),
                        Text(Formatos.moneda.format(caja.ventaTotal?.toDouble() ?? 0)),
                      ],
                    ),
                  ],
                ),
              ),
          
              IconButton(
                icon: const Icon(Icons.arrow_right_outlined, color: AppTheme.letraClara),
                onPressed: () {
                  setState(() {
                    _cajaSelected = caja;
                    _cajaScreen = true;  
                  });
                }, 
              )
            ],
          ),
        ),
      ),
    );
  }

}

