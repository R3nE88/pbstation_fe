import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';
import 'package:provider/provider.dart';

class PedidosSubirArchivoForm extends StatefulWidget {
  const PedidosSubirArchivoForm({super.key, required this.pedidoId});

  final String pedidoId;

  @override
  State<PedidosSubirArchivoForm> createState() => _PedidosSubirArchivoFormState();
}

class _PedidosSubirArchivoFormState extends State<PedidosSubirArchivoForm> {
  List<File> _fileSeleccionado = [];
  bool uploading = false;

  Future<void> seleccionarArchivos() async {
    Loading.displaySpinLoading(context);
    final result = await FilePicker.platform.pickFiles(
      lockParentWindow: true,
      allowMultiple: true,
      dialogTitle: 'Selecciona los archivos para el pedido',
    );
    if (result != null) {
      setState(() {
        _fileSeleccionado = result.paths.map((p) => File(p!)).toList();
      });
    }
    if (_fileSeleccionado.isEmpty) {
      Navigator.pop(context);
      return;
    }
    Navigator.pop(context);
    _submit();
  }

  void _submit() async{
    final pedidosService = Provider.of<PedidosService>(context, listen: false);
    await pedidosService.addArchivosToPedido(pedidoId: widget.pedidoId, archivos: _fileSeleccionado);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      seleccionarArchivos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pedidosService = Provider.of<PedidosService>(context);
    
    return AlertDialog(
      backgroundColor: AppTheme.containerColor2,
      title: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Completar pedido y enviar', textScaler: TextScaler.linear(0.85)),
        ],
      ),
      content: SizedBox(
        width: 200,
        child: pedidosService.isLoading ? Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Subiendo archivos...'),
            Padding(
              padding: const EdgeInsets.all(16),
              child: LinearProgressIndicator(
                color: AppTheme.containerColor1.withAlpha(150),
                value: pedidosService.uploadProgress,
                minHeight: 6,
              ),
            ),
            Text(
              '${(pedidosService.uploadProgress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        )
        : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [

            _fileSeleccionado.isEmpty ?
              ElevatedButtonIcon(
                text: 'Subir archivos', 
                icon: Icons.upload, 
                onPressed: () => seleccionarArchivos()
              )
            : Tooltip(
            message: _fileSeleccionado
              .map((f) => f.path.split('\\').last)
              .join('\n'),
              child: Container(
                width: 156,
                decoration: BoxDecoration(
                  color: AppTheme.letra70,
                  borderRadius: BorderRadius.circular(22)
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _fileSeleccionado.length > 1 ?
                          '${_fileSeleccionado.length} Archivos subidos'
                          : 
                          'Archivo subido',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.containerColor1,
                          fontWeight: FontWeight.w700,
                          //fontSize: 12
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(10, 0),
                        child: Icon(
                          Icons.filter_rounded, 
                          color: AppTheme.primario1, 
                          size: 20
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),

            _fileSeleccionado.isEmpty ? 
              const SizedBox()
            :
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: ElevatedButton(
                  onPressed: ()=>_submit(), 
                  child: const Text('Enviar pedido')
                ),
              )

          ]
        ),
      )
    );
  }
}