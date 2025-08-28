import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/screens/caja/abrir_caja.dart';
import 'package:pbstation_frontend/screens/caja/dialog/cerrar_dialog.dart';
import 'package:pbstation_frontend/screens/caja/dialog/corte_dialog.dart';
import 'package:pbstation_frontend/screens/caja/dialog/movimiento_caja_dialog.dart';
import 'package:pbstation_frontend/services/login.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:provider/provider.dart';

class CajaScreen extends StatefulWidget {
  const CajaScreen({super.key});

  @override
  State<CajaScreen> createState() => _CajaScreenState();
}

class _CajaScreenState extends State<CajaScreen> {
  bool init = false;
  Cajas? caja;
  Usuarios? usuario;
  late DateTime fechaApertura;
  late String hora;
  //bool cajaNotFound=false;
  String? _opcionSeleccionada = 'Venta Total';
  final List<String> _opciones = ['Venta Total'];

  // ============ LÓGICA ============

  Future<void> obtenerUsuarioDeCaja() async {
    final usuarioSvc = Provider.of<UsuariosServices>(context, listen: false);
    usuario = await usuarioSvc.searchUsuario(caja!.usuarioId);
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();

    if (CajasServices.cajaActualId != null && CajasServices.cajaActualId != 'buscando') {
      datosIniciales();
    }
  }

  void datosIniciales(){
    caja = CajasServices.cajaActual;
    obtenerUsuarioDeCaja();
    fechaApertura = DateTime.parse(caja!.fechaApertura);
    hora = DateFormat('hh:mm a').format(fechaApertura);
    Provider.of<VentasServices>(context, listen: false).loadVentasDeCaja(caja!.id!);
    Provider.of<UsuariosServices>(context, listen: false).loadUsuarios();
    Provider.of<CajasServices>(context, listen: false)
        .loadCaja(CajasServices.cajaActualId!);
  }

  // ============ UI ============

  @override
  Widget build(BuildContext context) {
    final cajaSvc = Provider.of<CajasServices>(context);

    if (Configuracion.esCaja && CajasServices.cajaActual==null){
      return AbrirCaja(metodo: datosIniciales);
    }

    return Consumer2<VentasServices, UsuariosServices>(
      builder: (context, ventasSvc, usr, _) {
        if (ventasSvc.isLoading || usr.isLoading || cajaSvc.isLoading) {
          return const _CargandoDatos();
        }

        // Actualizar opciones del dropdown
        _opciones
          ..clear()
          ..add('Venta Total')
          ..addAll(usr.usuarios.map((u) => u.id!));

        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 5, left: 54, right: 52),
          child: Container(
            color: AppTheme.containerColor1,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _buildTable(
                      _opcionSeleccionada != 'Venta Total'
                          ? _opcionSeleccionada
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        _buildTopRow(),
        const SizedBox(height: 8),
        _buildInfoRow(),
      ],
    );
  }

  Widget _buildTopRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('CAJA: ', style: AppTheme.tituloClaro, textScaler: const TextScaler.linear(1.6)),
        Text(caja!.folio!, style: AppTheme.subtituloPrimario, textScaler: const TextScaler.linear(1.3)),
        const Spacer(),
        Row(
          children: [
            _CajaBoton(
              label: 'Movimientos',
              icon: Icons.swap_horiz,
              onTap: () => showDialog(
                context: context,
                builder: (_) => const MovimientoCajaDialog(),
              ),
              cerrar: false,
              disabled: false,
            ),
            const SizedBox(width: 15),
            _CajaBoton(
              label: 'Realizar Corte',
              icon: Icons.price_check,
              onTap: () => showDialog(
                context: context,
                builder: (_) => const CorteDialog(),
              ),
              cerrar: false,
              disabled: !Configuracion.esCaja,
            ),
            const SizedBox(width: 15),
            _CajaBoton(
              label: 'Cerrar Caja',
              icon: Icons.point_of_sale,
              onTap: () => showDialog(
                context: context,
                builder: (_) => const CerrarDialog(),
              ),
              cerrar: true, 
              disabled: !Configuracion.esCaja,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _TarjetaUsuario(usuario: usuario, fecha: fechaApertura, hora: hora, fondo: caja!.efectivoApertura.toDouble()),
        const SizedBox(width: 20),
        _TarjetaTotalVentas(
          opcionSeleccionada: _opcionSeleccionada!,
          onFiltroCambio: (val) => setState(() => _opcionSeleccionada = val),
        ),
      ],
    );
  }

  Widget _buildTable([String? filtrarPorUsuario]) {
    return Consumer<VentasServices>(
      builder: (context, servicios, _) {
        final ventas = _filtrarVentas(servicios.ventasDeCaja, filtrarPorUsuario);

        return Column(
          children: [
            const _TablaHeader(),
            Expanded(
              child: Container(
                color: ventas.length % 2 == 0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
                child: ListView.builder(
                  itemCount: ventas.length,
                  itemBuilder: (context, i) => FilaVentas(venta: ventas[i], index: i),
                ),
              ),
            ),
            _TablaFooter(total: ventas.length),
          ],
        );
      },
    );
  }

  List<Ventas> _filtrarVentas(List<Ventas> ventas, String? usuarioId) {
    if (!Login.admin) {
      return ventas.where((v) => v.usuarioId == Login.usuarioLogeado.id).toList();
    }
    if (usuarioId == null) return ventas;
    return ventas.where((v) => v.usuarioId == usuarioId).toList();
  }
}

// ============ SUBWIDGETS ============

class _CajaBloqueada extends StatelessWidget {
  const _CajaBloqueada();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(80),
      child: ColoredBox(color: Colors.red),
    );
  }
}

class _CargandoDatos extends StatelessWidget {
  const _CargandoDatos();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Cargando datos...', style: TextStyle(color: AppTheme.colorContraste)),
          const SizedBox(height: 10),
          CircularProgressIndicator(color: AppTheme.colorContraste),
        ],
      ),
    );
  }
}

class _CajaBoton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool cerrar;
  final bool disabled;

  const _CajaBoton({required this.label, required this.icon, required this.onTap, required this.cerrar, required this.disabled});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: disabled ? 'Necesitas estar en la Caja' : '',
      waitDuration: Durations.short4,
      child: ElevatedButton(
        style: cerrar 
        ? ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 255, 211, 196),
          disabledBackgroundColor: Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Custom radius
          ),
        ) 
        : ElevatedButton.styleFrom(
          disabledBackgroundColor: Colors.grey
        ),
        onPressed: !disabled ? onTap : null,
        child: Row(
          children: [
            Icon(icon, size: 21),
            Text(' $label'),
          ],
        ),
      ),
    );
  }
}

class _TarjetaUsuario extends StatelessWidget {
  final Usuarios? usuario;
  final DateTime fecha;
  final String hora;
  final double fondo;

  const _TarjetaUsuario({
    required this.usuario,
    required this.fecha,
    required this.hora,
    required this.fondo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _decoracion(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: usuario == null
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Abierta por ${usuario!.nombre}'),
                Text('${fecha.day}/${fecha.month}/${fecha.year} a las $hora'),
                Text('Fondo: ${Formatos.pesos.format(fondo)}'),
              ],
            ),
    );
  }

  BoxDecoration _decoracion() => BoxDecoration(
        color: AppTheme.tablaColorHeader,
        borderRadius: BorderRadius.circular(15),
      );
}

class _TarjetaTotalVentas extends StatelessWidget {
  final String opcionSeleccionada;
  final ValueChanged<String?> onFiltroCambio;

  const _TarjetaTotalVentas({
    required this.opcionSeleccionada,
    required this.onFiltroCambio,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Consumer2<VentasServices, UsuariosServices>(
        builder: (context, service, usr, _) {
          final total = _calcularTotal(service.ventasDeCaja);
          final esAdmin = Login.usuarioLogeado.rol == "admin";

          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateFormat("EEEE, d 'de' MMMM, y", 'es_ES').format(DateTime.now()), style: AppTheme.tituloClaro),
                  const SizedBox(height: 5),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.tablaColorHeader,
                      borderRadius: BorderRadius.circular(15)
                    ),
                    child: Row(
                      children: [
                        Text(
                          _textoTitulo(esAdmin, usr),
                          style: AppTheme.subtituloPrimario,
                        ),
                        Text(Formatos.pesos.format(total.toDouble()), textScaler: const TextScaler.linear(1.3)),
                      ],
                    ),
                  ),
                ],
              ), const SizedBox(width: 20),
              
              const Spacer(),
              if (esAdmin)
              Row(
                children: [
                  Text('Filtrar: '),
                  _DropdownUsuarios(
                    opcionSeleccionada: opcionSeleccionada,
                    opciones: ['Venta Total', ...usr.usuarios.map((u) => u.id!)],
                    usr: usr,
                    onFiltroCambio: onFiltroCambio,
                  ),
                ],
              )
            ],
          );
        },
      ),
    );
  }

  Decimal _calcularTotal(List<Ventas> ventas) {
    Decimal total = Decimal.zero;
    if (Login.usuarioLogeado.rol != "admin") {
      total = ventas
          .where((v) => v.usuarioId == Login.usuarioLogeado.id)
          .fold(Decimal.zero, (acc, v) => acc + v.total);
    } else if (opcionSeleccionada == 'Venta Total') {
      total = ventas.fold(Decimal.zero, (acc, v) => acc + v.total);
    } else {
      total = ventas
          .where((v) => v.usuarioId == opcionSeleccionada)
          .fold(Decimal.zero, (acc, v) => acc + v.total);
    }
    return total;
  }

  String _textoTitulo(bool esAdmin, UsuariosServices usr) {
    if (!esAdmin) return 'Mis Ventas del Turno: ';
    if (opcionSeleccionada == 'Venta Total') return 'Total Vendido: ';
    return 'Ventas de ${usr.obtenerNombreUsuarioPorId(opcionSeleccionada)}: ';
  }
}

class _DropdownUsuarios extends StatelessWidget {
  final String opcionSeleccionada;
  final List<String> opciones;
  final UsuariosServices usr;
  final ValueChanged<String?> onFiltroCambio;

  const _DropdownUsuarios({
    required this.opcionSeleccionada,
    required this.opciones,
    required this.usr,
    required this.onFiltroCambio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.tablaColorHeader,
        borderRadius: BorderRadius.circular(25),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: opcionSeleccionada,
          items: opciones.map((id) {
            return DropdownMenuItem(
              value: id,
              child: Text(id == 'Venta Total' ? id : usr.obtenerNombreUsuarioPorId(id)),
            );
          }).toList(),
          onChanged: onFiltroCambio,
          dropdownColor: AppTheme.containerColor2,
          style: TextStyle(color: AppTheme.letraClara, fontWeight: FontWeight.w500),
          iconEnabledColor: Colors.white,
        ),
      ),
    );
  }
}

class _TablaHeader extends StatelessWidget {
  const _TablaHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.tablaColorHeader,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: const Row(
        children: [
          Expanded(child: Text('Folio', textAlign: TextAlign.center)),
          Expanded(child: Text('Vendedor', textAlign: TextAlign.center)),
          Expanded(child: Text('Cliente', textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text('Detalles', textAlign: TextAlign.center)),
          Expanded(child: Text('Abonado', textAlign: TextAlign.center)),
          Expanded(child: Text('Total', textAlign: TextAlign.center)),
          Expanded(child: Text('Fecha y Hora', textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

class _TablaFooter extends StatelessWidget {
  final int total;

  const _TablaFooter({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.tablaColorHeader,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          const Spacer(),
          Text('  Total de ventas: $total   ', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ============ FILAS ============

class FilaVentas extends StatelessWidget {
  final int index;
  final Ventas venta;

  const FilaVentas({super.key, required this.index, required this.venta});

  @override
  Widget build(BuildContext context) {
    final usuarioSvc = Provider.of<UsuariosServices>(context, listen: false);
    final clienteSvc = Provider.of<ClientesServices>(context, listen: false);
    final productosSvc = Provider.of<ProductosServices>(context, listen: false);

    final vendedorNombre = usuarioSvc.obtenerNombreUsuarioPorId(venta.usuarioId);
    final clienteNombre = clienteSvc.obtenerNombreClientePorId(venta.clienteId);
    final detalles = productosSvc.obtenerDetallesComoTexto(venta.detalles);
    final fecha = DateFormat('dd/MM/yyyy - hh:mm a').format(DateTime.parse(venta.fechaVenta!));

    return Container(
      padding: const EdgeInsets.all(8),
      color: index % 2 == 0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
      child: Row(
        children: [
          Expanded(child: Text(venta.folio!, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          Expanded(child: Text(vendedorNombre, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          Expanded(child: Text(clienteNombre, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text(detalles, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          Expanded(child: Text(Formatos.pesos.format(venta.abonado?.toDouble() ?? 0), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          Expanded(child: Text(Formatos.pesos.format(venta.total.toDouble()), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          Expanded(child: Text(fecha, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}
