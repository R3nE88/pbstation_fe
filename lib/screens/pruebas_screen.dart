import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/services/login.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:provider/provider.dart';

class PruebasScreen extends StatefulWidget {
  const PruebasScreen({super.key});

  @override
  State<PruebasScreen> createState() => _PruebasScreenState();
}

class _PruebasScreenState extends State<PruebasScreen> {
  List<File> archivosSeleccionados = [];

  Future<void> seleccionarArchivos() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      dialogTitle: 'Selecciona los archivos para el pedido',
    );
    
    if (result != null) {
      setState(() {
        archivosSeleccionados = result.paths.map((p) => File(p!)).toList();
      });
    }
  }
  
  void subirArchivos() async {
    await seleccionarArchivos();

    if (archivosSeleccionados.isEmpty) return;

    if (!mounted) return;
    final pedidosService = Provider.of<PedidosService>(context, listen: false);

    final Pedidos pedido = Pedidos(
      clienteId: '68c05a56842ab97689a854da',
      usuarioId: Login.usuarioLogeado.id!,
      sucursalId: SucursalesServices.sucursalActualID!,
      ventaId: 'ventaID_TODO: CAMBIAR ESTO XD',
      descripcion: 'Pedido de prueba',
      archivos: [],
      fecha: DateTime.now().toIso8601String(), 
      fechaEntrega: DateTime.now().toIso8601String(), 
    );
    
    final resultado = await pedidosService.createPedido(
      pedido: pedido,
      archivos: archivosSeleccionados,
    );

    if (!mounted) return;
    
    if (resultado == 'exito') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Archivos subidos correctamente')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ $resultado')),
      );
    }
    
    setState(() {
      archivosSeleccionados = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final pedidosService = Provider.of<PedidosService>(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Pruebas de archivos')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 📤 SUBIR ARCHIVOS
            if (!pedidosService.isLoading)
              ElevatedButton.icon(
                onPressed: subirArchivos,
                icon: const Icon(Icons.upload_file),
                label: const Text('Seleccionar y subir archivos'),
              )
            else
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Subiendo archivos...'),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: LinearProgressIndicator(
                      value: pedidosService.uploadProgress,
                      minHeight: 6,
                    ),
                  ),
                  Text(
                    '${(pedidosService.uploadProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            
            const SizedBox(height: 50),
            const Divider(),
            const SizedBox(height: 20),
            
            // 📥 DESCARGAR ARCHIVOS (ZIP)
            ElevatedButton.icon(
              onPressed: pedidosService.isDownloading ? null : () async {
                final archivo = await pedidosService.descargarArchivos(
                  pedidoId: '68f01e9566e0b63a11ad53c9',
                );

                if (!mounted) return;
                
                if (archivo != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Archivos descargados en:\n${archivo.path}'),
                      action: SnackBarAction(
                        label: 'Abrir carpeta',
                        onPressed: () {
                          Process.run('explorer', [archivo.parent.path]);
                        },
                      ),
                      duration: const Duration(seconds: 5),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('❌ Error al descargar archivos')),
                  );
                }
              },
              icon: const Icon(Icons.download),
              label: const Text('Descargar archivos del pedido'),
            ),
            
            const SizedBox(height: 20),
            
            // Barra de progreso de descarga
            if (pedidosService.isDownloading)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Descargando archivos...'),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: LinearProgressIndicator(
                      value: pedidosService.downloadProgress,
                      minHeight: 6,
                    ),
                  ),
                  Text(
                    '${(pedidosService.downloadProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}