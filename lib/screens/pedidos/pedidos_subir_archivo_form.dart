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
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pop(context);
      return;
    }
    if (!mounted) return;
    Navigator.pop(context);
    _submit();
  }

  void _submit() async{
    final pedidosService = Provider.of<PedidosService>(context, listen: false);
    await pedidosService.addArchivosToPedido(pedidoId: widget.pedidoId, archivos: _fileSeleccionado);
    if (!mounted) return;
    Navigator.pop(context);
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

    if (pedidosService.isLoading){
      return AlertDialog(
        backgroundColor: AppTheme.containerColor2,
        content: SizedBox(
          width: 200,
          child: Column(
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
        )
      );
    } else {
      return const SizedBox();
    }
    
    
  }
}