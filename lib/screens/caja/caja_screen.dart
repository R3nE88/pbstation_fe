import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/loading.dart';
import 'package:provider/provider.dart';

class CajaScreen extends StatefulWidget {
  const CajaScreen({super.key});

  @override
  State<CajaScreen> createState() => _CajaScreenState();
}

class _CajaScreenState extends State<CajaScreen> {
  bool init = false;
  Cajas caja = CajasServices.cajaActual!;
  Usuarios? usuario;
  late DateTime fechaApertura;
  late String hora; 

  void obtenerUsuarioDeCaja() async{
    final usuarioSvc = Provider.of<UsuariosServices>(context, listen: false); 
    usuario = await usuarioSvc.searchUsuario(caja.usuarioId);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    print('initCaja'); //TODO: ejecutar bien el init state
    obtenerUsuarioDeCaja();
    fechaApertura = DateTime.parse(caja.fechaApertura);
    hora = DateFormat('hh:mm a').format(fechaApertura);
    final ventaSvc = Provider.of<VentasServices>(context, listen: false); 
    ventaSvc.loadVentasDeCaja(caja.id!);
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<CajasServices>(context); 

    if (CajasServices.cajaActual==null){ //Bloquear hasta que se inicie caja en la pantalla de venta, o mostrar misma pantalla
      return Padding(
        padding: const EdgeInsets.all(80),
        child: Container(color: Colors.red),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top:8, bottom: 5, left: 54, right: 52),
      child: Container(
        color: AppTheme.containerColor1,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [

              Row( //Fila superior
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'CAJA: ', 
                    style: AppTheme.tituloClaro,
                    textScaler: TextScaler.linear(1.6),
                  ),
                  Text(
                    caja.folio!,
                    style: AppTheme.subtituloPrimario,
                    textScaler: TextScaler.linear(1.3),
                  ),
                  const Expanded(child: SizedBox()),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: (){}, 
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Icon(Icons.swap_horiz, size: 21),
                            Text(' Movimientos'),
                          ],
                        )
                      ),
                    ],
                  ),        
                ],
              ),

              Row( 
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container( //Tarjeta de datos
                    decoration: BoxDecoration(
                      color: AppTheme.containerColor2,
                      borderRadius: BorderRadius.circular(15)
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: usuario!=null ? Column(
                        children: [
                          Row(
                            children: [
                              Text('Abierta por '),
                              Text(usuario!.nombre),
                            ],
                          ),
                          Row(
                            children: [
                              Text('${fechaApertura.day} de ${fechaApertura.month} del ${fechaApertura.year} a las $hora'),
                            ],
                          ),
                          Row(
                            children: [
                              Text('Fondo: ${Formatos.pesos.format(caja.efectivoApertura.toDouble())}')
                            ],
                          )
                        ],
                      ) : Padding(
                        padding: const EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),

                  Padding( //Total Vendido
                    padding: const EdgeInsets.only(right: 100),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.containerColor2,
                        borderRadius: BorderRadius.circular(15)
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Text('Total Vendido:'),
                            Text('MXN\$12,985.00', textScaler: TextScaler.linear(1.8),) //TODO: calcular verdadero vendido
                          ],
                        ),
                      ),
                    ),
                  ),

                  ElevatedButton( //Cerrar Caja
                    onPressed: (){}, 
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Icon(Icons.point_of_sale, size: 21),
                        Text(' Cerrar Caja'),
                      ],
                    )
                  )
                ],
              ), const SizedBox(height: 10),

              Expanded(child: _buildTable()), //Tabla
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTable() {
    return Consumer<VentasServices>(
      builder: (context, servicios, _) {
        if (servicios.isLoading){
          return Center(child: CircularProgressIndicator());
        }

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
                  Expanded(child: Text('Vendedor', textAlign: TextAlign.center)),
                  Expanded(child: Text('Cliente', textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Text('Detalles', textAlign: TextAlign.center)),
                  Expanded(child: Text('Abonado', textAlign: TextAlign.center)),
                  Expanded(child: Text('Total', textAlign: TextAlign.center)),
                  Expanded(child: Text('Fecha y Hora', textAlign: TextAlign.center)),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: servicios.ventasDeCaja.length % 2 == 0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
                child: ListView.builder(
                  itemCount: servicios.ventasDeCaja.length,
                  itemBuilder: (context, index) => FilaVentas(
                    venta: servicios.ventasDeCaja[index],
                    index: index,
                  ),
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
                    '  Total de ventas: ${servicios.ventasDeCaja.length}   ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        );
      }
    );
  }
}

class FilaVentas extends StatelessWidget {
  const FilaVentas({
    super.key,
    required this.index, required this.venta,
  });

  final int index;
  final Ventas venta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: index % 2 == 0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
      child: Row(
        children: [
          Expanded(child: Text('M76451002', style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          Expanded(child: Text('Carlos Rene Ayala Salazar', style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          Expanded(child: Text('Juan Perez De La Olla', style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text('Tabloide a color(3) - Copia B&N (50)', style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          Expanded(child: Text("MXN\$245.00", style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          Expanded(child: Text("MXN\$245.00", style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          Expanded(child: Text("01/08/2025 - 03:38 p.m", style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}