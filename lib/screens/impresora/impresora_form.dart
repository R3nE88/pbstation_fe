import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/provider/provider.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:provider/provider.dart';

class ImpresoraForm extends StatelessWidget {
  const ImpresoraForm({super.key, this.edit});
  final Impresoras? edit; 

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    TextEditingController numeroCtrl = TextEditingController();
    TextEditingController modeloCtrl = TextEditingController();
    TextEditingController serieCtrl = TextEditingController();
    TextEditingController contadorCtrl = TextEditingController();
    if (edit!=null){
      numeroCtrl.text = edit!.numero.toString();
      modeloCtrl.text = edit!.modelo;
      serieCtrl.text = edit!.serie;
    }
    
    if(SucursalesServices.sucursalActualID==null){
      return AlertDialog(
        elevation: 2,
        backgroundColor: AppTheme.containerColor2,
        title: Text(
          edit==null?
          'Agregar Impresora al Sistema'
          :
          'Modificar Impresora', 
          textScaler: const TextScaler.linear(0.85), textAlign: TextAlign.center),
        content: SizedBox(
          width: 360,
          child: Form(
            key: formKey,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Necesitas asignar tu sucursal a esta terminal.\nLa impresora que agregues se asociara a esta sucursal.', textAlign: TextAlign.center)
              ]
            )
          )
        )
      );
    }

    return AlertDialog(
      elevation: 2,
      backgroundColor: AppTheme.containerColor2,
      title: Text(
        edit==null?
        'Agregar Impresora al Sistema'
        :
        'Modificar Impresora', 
        textScaler: const TextScaler.linear(0.85)),
      content: SizedBox(
        width: 470,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
          
                  Expanded( //Numero
                    child: TextFormField(
                      controller: numeroCtrl,
                      autofocus: true,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Numero',
                        labelStyle: AppTheme.labelStyle,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese en campo';
                        }
                        return null;
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                  ), const SizedBox(width: 15),
          
                  Expanded( //MODELO
                  flex: 2,
                    child: TextFormField(
                      controller: modeloCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Modelo',
                        labelStyle: AppTheme.labelStyle,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese en campo';
                        }
                        return null;
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                  ),
                ],
              ), const SizedBox(height: 10),
              Row(
                children: [
          
                  Expanded( //Serie
                    child: TextFormField(
                      controller: serieCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Serie',
                        labelStyle: AppTheme.labelStyle,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese en campo';
                        }
                        return null;
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                  ), SizedBox(width: edit==null ? 15 : 0),
          
                  edit==null?Expanded( //CONTADOR
                    child: TextFormField(
                      controller: contadorCtrl,
                      autofocus: true,
                      maxLength: 10,
                      buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                      inputFormatters: [ NumericFormatter() ],
                      decoration: const InputDecoration(
                        labelText: 'Contador Inicial',
                        labelStyle: AppTheme.labelStyle,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese en campo';
                        }
                        return null;
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                  ) : const SizedBox(),
                ],
              ), const SizedBox(height: 10),
          
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () async{
                      if (!formKey.currentState!.validate()){return;} 
                      final loadingSvc = Provider.of<LoadingProvider>(context, listen: false);
                      loadingSvc.show();   

                      if(edit==null){ 
                        //AGREGAR
                        Impresoras impresora = Impresoras( //Subir impresora
                          numero: int.parse(numeroCtrl.text), 
                          modelo: modeloCtrl.text, 
                          serie: serieCtrl.text, 
                          sucursalId: SucursalesServices.sucursalActualID!
                        );
                        final impresoraSvc = Provider.of<ImpresorasServices>(context, listen: false);
                        String impresoraId = await impresoraSvc.createImpresora(impresora);

                        Contadores contador = Contadores( //Crear contador
                          impresoraId: impresoraId, 
                          cantidad: int.parse(contadorCtrl.text.replaceAll(',', '')), 
                        );
                        await impresoraSvc.createContador(contador);

                        if (!context.mounted) return;
                        Navigator.pop(context);
                      } else { 
                        //MODIFICAR
                        Impresoras impresora = Impresoras( //Actualizar impresora
                          numero: int.parse(numeroCtrl.text), 
                          modelo: modeloCtrl.text, 
                          serie: serieCtrl.text, 
                          sucursalId: SucursalesServices.sucursalActualID!
                        );
                        final impresoraSvc = Provider.of<ImpresorasServices>(context, listen: false);
                        await impresoraSvc.updateImpresora(impresora, edit!.id!);

                        if (!context.mounted) return;
                        Navigator.pop(context);
                      }
                      loadingSvc.hide();
                    }, 
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Continuar'),
                        Icon(Icons.navigate_next, size: 25)
                      ],
                    )
                  ),
                ],
              ),
            ],
          ),
        )
      )
    );
  }
}