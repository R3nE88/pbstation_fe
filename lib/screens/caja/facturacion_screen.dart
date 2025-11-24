import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/screens/caja/dialog/facturacion_global_dialog.dart';
import 'package:pbstation_frontend/screens/caja/dialog/facturar_venta_dialog.dart';
import 'package:pbstation_frontend/services/cajas_services.dart';
import 'package:pbstation_frontend/services/ventas_services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';
import 'package:provider/provider.dart';

class FacturacionScreen extends StatelessWidget {
  const FacturacionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BodyPadding(
      child: Column(
        children: [
          
          //Header
          Row(
            children: [
              
              const Text(
                'Facturas', style: AppTheme.tituloClaro, textScaler: TextScaler.linear(1.7)
              ), const SizedBox(width: 35),
              
              ElevatedButtonIcon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const Stack(
                    alignment: Alignment.topRight,
                    children: [
                      IngresarFolioDialog(),
                      WindowBar(overlay: true),
                    ],
                  ),
                ),
                text: 'Facturar', 
                icon: Icons.receipt_long, 
                verticalPadding: 0
              ), const Spacer(),
              
              SizedBox(
                height: 34,
                width: 200,
                child: TextFormField(
                  //controller: _searchController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search, color: AppTheme.letraClara),
                    hintText: 'Buscar por Folio',
                  ),
                ),
              ), const SizedBox(width: 15),

              SizedBox(
                height: 34,
                width: 200,
                child: TextFormField(
                  //controller: _searchController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search, color: AppTheme.letraClara),
                    hintText: 'Buscar por RFC',
                  ),
                ),
              ),

            ],
          ), const SizedBox(height: 15),

          //Tabla Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.tablaColorHeader,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15)
              )
            ),
            child: const Row(
              children: [
                Expanded(child: Center(child: Text('Folio'))),
                Expanded(child: Center(child: Text('RFC'))),
                Expanded(child: Center(child: Text('Receptor'))),
                Expanded(child: Center(child: Text('Subtotal'))),
                Expanded(child: Center(child: Text('Impuestos'))),
                Expanded(child: Center(child: Text('Total'))),
                Expanded(child: Center(child: Text('Fecha'))),
              ],
            ),
          ),

          //Tabla body
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15)
              ),
              child: Container(
                color: AppTheme.tablaColor1,
              ),
            ),
          )
        ],
      )
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

  void submited() async{
    setState(() {
      isLoading = true;
    });

    if (_ctrl.text.startsWith('CJ')){
      //Es folio de caja
      final Cajas? caja = await Provider.of<CajasServices>(context, listen: false).searchCajaFolio(_ctrl.text);
      if (caja!=null){
        if (!mounted) return;
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (_) => Stack(
            alignment: Alignment.topRight,
            children: [
              FacturaGlobalDialog(caja: caja),
              const WindowBar(overlay: true),
            ],
          )
        );
      } else {
        setState(() {
          color = Colors.red;
          hint = 'no se encontro';
          isLoading = false;
        });
      }   
    } else {
      //es folio de venta
      final Ventas? venta = await Provider.of<VentasServices>(context, listen: false).searchVentaFolio(_ctrl.text);
      if (venta!=null){
        if (!mounted) return;
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (_) => Stack(
            alignment: Alignment.topRight,
            children: [
              FacturarVentaDialog(venta: venta),
              const WindowBar(overlay: true),
            ],
          )
        );
      } else {
        setState(() {
          color = Colors.red;
          hint = 'no se encontro';
          isLoading = false;
        });
      }   
    }
  }

  @override
  Widget build(BuildContext context) {

    return AlertDialog(
      elevation: 2,
      backgroundColor: AppTheme.containerColor1,
      content: !isLoading ? Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Folio a facturar'),
          const SizedBox(height: 3),
          SizedBox(
            width: 200,
            height: 40,
            child: Form(
              key: _formKey,
              child: TextFormField(
                onChanged: (value) {
                  if (color==Colors.red){
                    setState(() { color = Colors.white; hint='';});
                  }
                },
                decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide(
                      width: 2,
                      color: color,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide(
                      color: color,
                    ),
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
          ), const SizedBox(height: 12),
          hint.isEmpty ? 
            ElevatedButton(
              child: const Text('Continuar'), 
              onPressed: () => submited()
            )
          :
            const Padding(
              padding: EdgeInsets.all(5.5),
              child: Text('No se encontraron resultados'),
            )
        ],
      ) :
       const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Buscando...'),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 25),
            child: CircularProgressIndicator(color: AppTheme.letraClara),
          ),
        ],
      ),
    );
  }
}