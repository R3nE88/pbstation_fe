import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/services/login.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/loading.dart';
import 'package:provider/provider.dart';

class AbrirCaja extends StatefulWidget {
  const AbrirCaja({
    super.key, 
    this.metodo
  });

  final Function? metodo;

  @override
  State<AbrirCaja> createState() => _AbrirCajaState();
}

class _AbrirCajaState extends State<AbrirCaja> {
  final formKey = GlobalKey<FormState>();
  TextEditingController fondotxt = TextEditingController();
  bool cajaNotFound=false;
  bool fondoReady=false;

  @override
  void initState() {
    super.initState();
    if (CajasServices.cajaActualId == 'buscando'){ cajaNotFound=true; }
    Provider.of<ImpresorasServices>(context, listen: false).loadImpresoras();
  }

  @override
  Widget build(BuildContext context) {
    if(cajaNotFound==true){
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Hubo un problema para encontrar los registros de la caja actual', style: AppTheme.subtituloConstraste),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: const Center(
              child: Icon(Icons.warning_amber ,color: Colors.red)
            ),
          ),
          Text('Reinicia el entorno para volver a intentarlo, si el problema continua', style: AppTheme.subtituloConstraste),
          SizedBox(
            height: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('puede abrir una nueva caja ', style: AppTheme.subtituloConstraste),
                ElevatedButton(
                  onPressed: (){
                    setState(() { cajaNotFound = false; });
                  }, child: 
                  Transform.translate( offset:Offset(0,-3),child: Text('Abrir Nueva Caja', textScaler: TextScaler.linear(0.9)))
                )
              ],
            ),
          ),
          Text('o contacte con soporte tecnico (653-146-3159)', style: AppTheme.subtituloConstraste),
        ],
      );
    }
    
    if (!fondoReady){
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 5, left: 54, right: 52),
        child: Center(
          child: Container(
            height: 230,
            width: 400,
            decoration: BoxDecoration(
              color: AppTheme.containerColor1,
              borderRadius: BorderRadius.circular(15)
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'No hay caja abierta, es necesario abrir antes de continuar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textScaler: TextScaler.linear(1.1),
                    ),
                    Column(
                      children: [
                        Text('¿Con cuánto efectivo empieza la caja?'),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                          child: TextFormField(
                            controller: fondotxt,
                            textAlign: TextAlign.center,
                            inputFormatters: [ PesosInputFormatter() ],
                            buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                            maxLength: 11,
                            autofocus: true,
                            decoration: InputDecoration(
                              labelText: 'Fondo (MXN)',
                              labelStyle: AppTheme.labelStyle,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingrese el fondo';
                              }
                              return null;
                            },
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(),
                    ElevatedButton(
                      onPressed: () async{
                        setState(() {fondoReady=true;});
                      }, 
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.translate(
                            offset: Offset(0, -1),
                            child: Text('Continuar  ')
                          ),
                          Icon(Icons.arrow_forward_rounded)
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      final impresoraSvc = Provider.of<ImpresorasServices>(context);
      List<TextEditingController> controllers = [];
      for (var i = 0; i < impresoraSvc.impresoras.length; i++) {
        controllers.add(TextEditingController());
      }
      
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 5, left: 54, right: 52),
        child: Center(
          child: Container(
            //height: 230,
            width: 400,
            decoration: BoxDecoration(
              color: AppTheme.containerColor1,
              borderRadius: BorderRadius.circular(15)
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      impresoraSvc.impresoras.isNotEmpty ? 
                      'Agrege los contadores iniciales.'
                      :
                      'No se encontraron impresoras para\nagregar el contadores.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textScaler: TextScaler.linear(1.1),
                    ), const SizedBox(height: 8),
                    
                    ...List.generate(impresoraSvc.impresoras.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: TextFormField(
                          controller: controllers[index],
                          autofocus: index==0 ? true : false,
                          decoration: InputDecoration(
                            labelText: impresoraSvc.impresoras[index].modelo
                          ),
                          inputFormatters: [ NumericFormatter() ],
                          buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                          maxLength: 12,
                        ),
                      );
                    }), const SizedBox(height: 8),
                
                
                    ElevatedButton(
                      onPressed: () async{
// Mostrar loading y guardar el context del dialog
late BuildContext dialogContext;
showDialog(
  context: context,
  barrierDismissible: false,
  builder: (ctx) {
    dialogContext = ctx;
    return const Center(child: CircularProgressIndicator());
  },
);

try {
  final cajaSvc = Provider.of<CajasServices>(context, listen: false);

  final contadoresMap = Map.fromIterables(
    impresoraSvc.impresoras.map((impresora) => impresora.id!),
    controllers.map((ctrl) => int.tryParse(ctrl.text.replaceAll(',', '').trim()) ?? 0),
  );

  Cajas nuevaCaja = Cajas(
    usuarioId: Login.usuarioLogeado.id!,
    sucursalId: SucursalesServices.sucursalActualID!,
    fechaApertura: DateTime.now().toString(),
    estado: "abierta",
    //ventasIds: [],
    cortesIds: [],
    tipoCambio: Configuracion.dolar,
  );

  Cortes primerCorte = Cortes(
    usuarioId: Login.usuarioLogeado.id!,
    sucursalId: SucursalesServices.sucursalActualID!,
    fondoInicial: Decimal.parse(fondotxt.text.replaceAll('MX\$', '').replaceAll(',', '')),
    contadoresIniciales: contadoresMap,
    movimientoCaja: [],
    ventasIds: [],
  );

  await cajaSvc.createCaja(nuevaCaja);
  await cajaSvc.createCorte(primerCorte);

  if(widget.metodo!=null) widget.metodo!();

} catch (e) {
  debugPrint('Error al crear corte: $e');
} finally {
  // Cerrar el loading usando el context del dialog
  Navigator.pop(dialogContext);
}

                        
                      }, 
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Abrir Caja  '),
                          Icon(Icons.point_of_sale)
                        ],
                      ),
                    )
                  ]
                ),
              )
            )
          )
        )
      );
    }
  }
}