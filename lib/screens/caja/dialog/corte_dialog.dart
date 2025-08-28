import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pbstation_frontend/logic/calculos_dinero.dart';
import 'package:provider/provider.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'dart:async';

enum StepStage { contadores, fondo, esperandoRetiro, conteoPesos, conteoDolares  }

class CorteDialog extends StatefulWidget {
  const CorteDialog({super.key});

  @override
  State<CorteDialog> createState() => _CorteDialogState();
}

class _CorteDialogState extends State<CorteDialog> {
  StepStage stage = StepStage.contadores;

  // Impresoras controllers (uno por impresora)
  final List<TextEditingController> impresoraControllers = [];

  // Controlador del fondo siguiente
  final TextEditingController proximoFondoCtrl = TextEditingController();

  // Denominaciones: ahora con tipo ('billete' | 'moneda') y valor
  final List<Map<String, dynamic>> denominacionesMxn = [
    {'value': 1000.0, 'kind': 'billete'},
    {'value': 500.0, 'kind': 'billete'},
    {'value': 200.0, 'kind': 'billete'},
    {'value': 100.0, 'kind': 'billete'},
    {'value': 50.0, 'kind': 'billete'},
    {'value': 20.0, 'kind': 'billete'}, // billete de 20
    {'value': 20.0, 'kind': 'moneda'},   // moneda de 20 (sí existe)
    {'value': 10.0, 'kind': 'moneda'},
    {'value': 5.0, 'kind': 'moneda'},
    {'value': 2.0, 'kind': 'moneda'},
    {'value': 1.0, 'kind': 'moneda'},
    {'value': 0.5, 'kind': 'moneda'},
  ];
  final List<Map<String, dynamic>> denominacionesDlls = [
    {'value': 100.0, 'kind': 'billete'},
    {'value': 50.0, 'kind': 'billete'},
    {'value': 20.0, 'kind': 'billete'},
    {'value': 10.0, 'kind': 'billete'},
    {'value': 5.0, 'kind': 'billete'},
    {'value': 2.0, 'kind': 'billete'},
    {'value': 1.0, 'kind': 'billete'}, 
    {'value': 0.50, 'kind': 'half dollar'},
    {'value': 0.25, 'kind': 'quarter'},
    {'value': 0.10, 'kind': 'dime'},
    {'value': 0.05, 'kind': 'nickel'},
    {'value': 0.01, 'kind': 'penny'},

  ];

  double efectivoPesos = 0;
  double efectivoDolares = 0;
  double efectivoDolaresAPeso = 0;

  // Controllers para cada denominación (lista paralela a `denominaciones`)
  final List<TextEditingController> denomControllersMxn = [];
  final List<TextEditingController> denomControllersDlls = [];

  bool loadingImpresoras = false;
  bool performingRetiro = false;
  int segundosTotales = 10;
  late int segundosRestantes;

  FocusNode primerFocusDlls = FocusNode();

  @override
  void initState() {
    super.initState();
    // inicializa controladores de denominación (debe coincidir con denominaciones.length)
    for (var _ in denominacionesMxn) {
      denomControllersMxn.add(TextEditingController());
    }
    for (var _ in denominacionesDlls) {
      denomControllersDlls.add(TextEditingController());
    }

    //Segundos para mostrar mensaje
    segundosRestantes = segundosTotales;

    // Cargar impresoras (si tu servicio devuelve async)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final impresoraSvc = Provider.of<ImpresorasServices>(context, listen: false);
      if (impresoraSvc.impresoras.isEmpty) {
        setState(() => loadingImpresoras = true);
        impresoraSvc.loadImpresoras().whenComplete(() {
          _ensureImpresoraControllers(impresoraSvc);
          setState(() => loadingImpresoras = false);
        });
      } else {
        _ensureImpresoraControllers(impresoraSvc);
      }
    });
  }

  void _ensureImpresoraControllers(ImpresorasServices svc) {
    // solo crear si hacen falta (evita recrear en build)
    if (impresoraControllers.length != svc.impresoras.length) {
      impresoraControllers.clear();
      for (var _ in svc.impresoras) {
        impresoraControllers.add(TextEditingController());
      }
    }
  }

  @override
  void dispose() {
    for (var c in impresoraControllers) {
      c.dispose();
    }
    for (var c in denomControllersMxn) {
      c.dispose();
    }
    for (var c in denomControllersDlls) {
      c.dispose();
    }
    proximoFondoCtrl.dispose();
    super.dispose();
  }

  double calculateTotalMxn() {
    double total = 0.0;
    for (var i = 0; i < denomControllersMxn.length; i++) {
      final text = denomControllersMxn[i].text.trim();
      if (text.isEmpty) continue;
      final intCount = int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final value = denominacionesMxn[i]['value'] as double;
      total += intCount * value;
    }
    return total;
  }

  double calculateTotalDolares(){
    double total = 0.0;
    for (var i = 0; i < denomControllersDlls.length; i++) {
      final text = denomControllersDlls[i].text.trim();
      if (text.isEmpty) continue;
      final intCount = int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final value = denominacionesDlls[i]['value'] as double;
      total += intCount * value;
    }
    return total;
  }

  String money(double v) => v.toStringAsFixed(2);

  void _nextStage() async {
    switch (stage) {
      case StepStage.contadores:
        setState(() => stage = StepStage.fondo);
        break;
      case StepStage.fondo:
        if(proximoFondoCtrl.text.isNotEmpty){
          setState(() {
            performingRetiro = true;
            stage = StepStage.esperandoRetiro;
          });
          for (var i = 0; i < segundosTotales; i++) {
            await Future.delayed(const Duration(seconds: 1));
            if (performingRetiro==false){
              return;
            }
            setState(() {
              segundosRestantes--;
            });
          }
          if (performingRetiro==true){
            setState(() {
              performingRetiro = false;
              stage = StepStage.conteoPesos;
            });
          }
        } else {
          setState(() {
            performingRetiro = false;
            stage = StepStage.conteoPesos;
          });
        }
        break;
      case StepStage.esperandoRetiro:
        break;
      case StepStage.conteoPesos:
        setState(() => stage = StepStage.conteoDolares);
        primerFocusDlls.requestFocus();
        break;
      case StepStage.conteoDolares:
        
        break;
    }
  }

  Widget _buildContadores(ImpresorasServices impresoraSvc) {
    if (loadingImpresoras) {
      return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(impresoraSvc.impresoras.length, (i) {
            final modelo = impresoraSvc.impresoras[i].modelo;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: KeyboardListener(
                onKeyEvent: (event) {
                  if (event.logicalKey == LogicalKeyboardKey.enter && event is KeyDownEvent) {
                    _nextStage();
                  }
                },
                focusNode: FocusNode(
                  canRequestFocus: false
                ),
                child: TextFormField(
                  controller: impresoraControllers[i],
                  autofocus: i == 0,
                  decoration: InputDecoration(labelText: modelo),
                  inputFormatters: [NumericFormatter()],
                  textInputAction: TextInputAction.done, 
                  keyboardType: TextInputType.number,
                  maxLength: 12,
                  buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                  onFieldSubmitted: (value) => _nextStage,
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _nextStage, child: const Text('Continuar')),
        ],
      ),
    );
  }

  Widget _buildFondoStep() {
    return SizedBox(
      width: 340,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('¿Cuánto dinero quieres dejar en caja?', style: AppTheme.labelStyle),
          const SizedBox(height: 8),
          KeyboardListener(
            onKeyEvent: (event) {
              if (event.logicalKey == LogicalKeyboardKey.enter && event is KeyDownEvent) {
                _nextStage();
              }
            },
            focusNode: FocusNode(
              canRequestFocus: false
            ),
            child: TextFormField(
              controller: proximoFondoCtrl,
              textAlign: TextAlign.center,
              inputFormatters: [PesosInputFormatter()],
              keyboardType: TextInputType.number,
              maxLength: 11,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Fondo (MXN)'),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _nextStage, child: const Text('Siguiente')),
        ],
      ),
    );
  }

  Widget _buildEsperandoRetiro() {
    final fondo = proximoFondoCtrl.text;
    return SizedBox(
      width: 340,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Wrap(
              //mainAxisAlignment: MainAxisAlignment.center,
              alignment: WrapAlignment.center,
              children: [
                Text('¡No olvides retirar  ', style: AppTheme.labelStyle, textAlign: TextAlign.center,),
                Text(fondo, style: AppTheme.tituloClaro, textAlign: TextAlign.center,),
                Text(' antes de continuar con ', style: AppTheme.labelStyle, textAlign: TextAlign.center,),
                Text('el conteo del corte!', style: AppTheme.labelStyle, textAlign: TextAlign.center,),
              ],
            ),
          ),
          if (performingRetiro) LinearProgressIndicator(color: AppTheme.containerColor1.withAlpha(150)),
          const SizedBox(height: 12),

          ElevatedButton(
            onPressed: (){
              setState(() {
                performingRetiro = false;
                stage = StepStage.conteoPesos;
              });
            }, child: Text('Continuar ($segundosRestantes)')
          )
        ],
      ),
    );
  }

  Widget _buildConteoStep() {
    return SizedBox(
      width: 520,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: List.generate(denominacionesMxn.length, (i) {
              final den = denominacionesMxn[i];
              final ctrl = denomControllersMxn[i];
              final value = den['value'] as double;
              final kind = den['kind'] as String;
              String label;
              if (kind == 'billete') {
                // billetes no tienen decimales (mostrar int)
                label = 'Billetes de \$${value.toInt()}';
              } else {
                // monedas: si es >=1 mostrar sin decimales, si es decimal mostrar el valor tal cual
                label = value >= 1 ? 'Monedas de \$${value.toInt()}' : 'Monedas de \$${value.toString()}';
              }
              return SizedBox(
                width: 240,
                child: TextFormField(
                  controller: ctrl,
                  autofocus: i==0,
                  decoration: InputDecoration(labelText: label),
                  inputFormatters: [NumericFormatter()],
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    if(value.isEmpty){ ctrl.text = "0"; }
                    setState(() { efectivoPesos = calculateTotalMxn(); });
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total contado: MXN\$${money(efectivoPesos)}', style: AppTheme.labelStyle),
              ElevatedButton(onPressed: _nextStage, child: const Text('Continuar')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConteoDolaresStep() {
    return SizedBox(
      width: 520,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: List.generate(denominacionesDlls.length, (i) {
              final den = denominacionesDlls[i];
              final ctrl = denomControllersDlls[i];
              final value = den['value'] as double;
              final kind = den['kind'] as String;
              String label;
              if (kind == 'billete') {
                // billetes no tienen decimales (mostrar int)
                label = 'Billetes de \$${value.toInt()}';
              } else {
                // monedas: si es >=1 mostrar sin decimales, si es decimal mostrar el valor tal cual
                label = '$kind \$${value.toStringAsFixed(2)}';
              }
              
              return SizedBox(
                width: 240,
                child: TextFormField(
                  controller: ctrl,
                  autofocus: i==0,
                  focusNode:  i==0 ? primerFocusDlls : FocusNode(),
                  decoration: InputDecoration(labelText: label),
                  inputFormatters: [NumericFormatter()],
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    if(value.isEmpty){ ctrl.text = "0"; }
                    setState(() {
                      efectivoDolares = calculateTotalDolares();
                      efectivoDolaresAPeso = CalculosDinero().conversionADolar(efectivoDolares);
                    });
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total contado: US\$${money(efectivoDolares)} (MXN\$$efectivoDolaresAPeso)', style: AppTheme.labelStyle),
              ElevatedButton(onPressed: _nextStage, child: const Text('Continuar')),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final impresoraSvc = Provider.of<ImpresorasServices>(context);
    // Aseguramos controladores si impresoras ya cargadas (por si cambia after init)
    if (impresoraControllers.length != impresoraSvc.impresoras.length && !loadingImpresoras) {
      _ensureImpresoraControllers(impresoraSvc);
    }

    Widget content;
    String title = 'Corte de Caja';

    switch (stage) {
      case StepStage.contadores:
        title = 'Registrar Contadores';
        content = _buildContadores(impresoraSvc);
        break;
      case StepStage.fondo:
        title = 'Fondo siguiente';
        content = _buildFondoStep();
        break;
      case StepStage.esperandoRetiro:
        title = '';
        content = _buildEsperandoRetiro();
        break;
      case StepStage.conteoPesos:
        title = 'Conteo de Efectivo (MXN)';
        content = _buildConteoStep();
        break;
      case StepStage.conteoDolares:
        title = 'Conteo de Efectivo (DLLS)';
        content = _buildConteoDolaresStep();
        break;
    }

    return AlertDialog(
      elevation: 2,
      backgroundColor: AppTheme.containerColor2,
      title: title.isNotEmpty ? Text(title) : null,
      content: content,
    );
  }
}
