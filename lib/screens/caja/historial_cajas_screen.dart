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
  bool _cajaScreen = false;
  Cajas? _cajaSelected;

  @override
  void initState() {
    super.initState();
    String? sucursalId;
    if (Login.usuarioLogeado.permisos==Permiso.admin || Login.usuarioLogeado.rol == TipoUsuario.administrativo){
      sucursalId = null;
    } else {
      sucursalId = SucursalesServices.sucursalActualID;
    }

    // Cargar primera página cuando se monta el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cajasService = Provider.of<CajasServices>(context, listen: false);
      cajasService.cargarHistorialCajas(sucursalId: sucursalId);
    });

    // Detectar scroll para cargar más
    _scrollController.addListener(_onScroll);
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
    super.dispose();
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
        children: [ 

          /*const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
          
              Tooltip( //TODO: en desarrollo
                message: 'En desarrollo...',
                verticalOffset: 10,
                child: ElevatedButton(
                  onPressed: (){
                  }, 
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.translate(
                        offset: const Offset(-3, 0),
                        child: const Icon(
                          Icons.search
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(3, -1),
                        child: const Text('Buscar Caja'),
                      ),
                    ],
                  )
                ),
              ),*/
              
              /*Tooltip( //TODO: en desarrollo
                message: 'Proximamente podras filtrar por sucursales...',
                child: ElevatedButton( //TODO: si no tengo sucursal activa, desactivar este filtro y siempre mostrar todas, y cambiar esto por un dropdownmenu
                  onPressed: (){
                  }, 
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.translate(
                        offset: const Offset(-3, 0),
                        child: const Icon(
                          Icons.filter_list
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(3, -1),
                        child: const Text('Mostrando de todas las sucursales'),
                      ),
                    ],
                  )
                ),
              ),
            ],
          ),*/

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

