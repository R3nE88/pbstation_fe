import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/logic/capitalizar.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/services/auth_service.dart';
import 'package:pbstation_frontend/theme/theme.dart';

class FacturaDetalleDialog extends StatefulWidget {
  const FacturaDetalleDialog({super.key, required this.factura});

  final Facturas factura;

  @override
  State<FacturaDetalleDialog> createState() => _FacturaDetalleDialogState();
}

class _FacturaDetalleDialogState extends State<FacturaDetalleDialog> {
  bool _isDownloading = false;
  String? _downloadingType;

  Future<void> _descargarArchivo(String tipo) async {
    setState(() {
      _isDownloading = true;
      _downloadingType = tipo;
    });

    try {
      final extension = tipo == 'pdf' ? 'pdf' : 'xml';
      final url = Uri.parse(
        'http:${Constantes.baseUrl}facturacion/$tipo/${widget.factura.uuid}',
      );

      final response = await http.get(
        url,
        headers: AuthService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        // Pedir ubicación de descarga
        final path = await FilePicker.platform.saveFile(
          dialogTitle: 'Guardar $tipo',
          fileName: '${widget.factura.uuid}.$extension',
          type: FileType.custom,
          allowedExtensions: [extension],
        );

        if (path != null) {
          final file = File(path);
          await file.writeAsBytes(response.bodyBytes);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${tipo.toUpperCase()} guardado exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al descargar: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadingType = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fecha = DateFormat('MMMM', 'es_MX').format(widget.factura.fecha);
    final fechaDia = capitalizarPrimeraLetra(
      DateFormat('EEEE', 'es_MX').format(widget.factura.fecha),
    );
    final fechaCompleta =
        '$fechaDia ${widget.factura.fecha.day} de $fecha, ${widget.factura.fecha.year}';

    return AlertDialog(
      elevation: 8,
      shadowColor: Colors.black54,
      backgroundColor: AppTheme.containerColor1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppTheme.letraClara.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primario1.withValues(alpha: 0.2),
              AppTheme.primario2.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primario1.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.receipt_long,
                color: AppTheme.letraClara,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Detalles de Factura',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.letraClara,
                ),
              ),
            ),
            if (widget.factura.isGlobal)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade700, Colors.green.shade500],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.public, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'GLOBAL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // UUID Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.tablaColor2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.letraClara.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.fingerprint,
                        size: 16,
                        color: AppTheme.primario1,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'UUID',
                        style: TextStyle(
                          color: AppTheme.letraClara,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    widget.factura.uuid,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Info Grid
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    Icons.calendar_today,
                    'Fecha',
                    fechaCompleta,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    Icons.person,
                    'Receptor',
                    widget.factura.receptorNombre,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    Icons.badge,
                    'RFC',
                    widget.factura.receptorRfc,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Montos
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.tablaColor2, AppTheme.tablaColor1],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.letraClara.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMontoItem(
                      'Subtotal',
                      widget.factura.subTotal.toDouble(),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppTheme.letraClara.withValues(alpha: 0.2),
                  ),
                  Expanded(
                    child: _buildMontoItem(
                      'Impuestos',
                      widget.factura.impuestos.toDouble(),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppTheme.letraClara.withValues(alpha: 0.2),
                  ),
                  Expanded(
                    child: _buildMontoTotal(
                      'Total',
                      widget.factura.total.toDouble(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        Row(
          children: [
            Expanded(
              child: _buildDownloadButton(
                icon: Icons.picture_as_pdf,
                label: 'PDF',
                color: Colors.red,
                onPressed:
                    _isDownloading ? null : () => _descargarArchivo('pdf'),
                isLoading: _downloadingType == 'pdf',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDownloadButton(
                icon: Icons.code,
                label: 'XML',
                color: Colors.orange,
                onPressed:
                    _isDownloading ? null : () => _descargarArchivo('xml'),
                isLoading: _downloadingType == 'xml',
              ),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.tablaColor2.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: AppTheme.letraClara.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.letraClara.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMontoItem(String label, double monto) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.letraClara.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          Formatos.moneda.format(monto),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildMontoTotal(String label, double monto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primario1.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.letraClara,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Formatos.moneda.format(monto),
            style: TextStyle(
              color: AppTheme.primario1,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
    required bool isLoading,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.15),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
        elevation: 0,
      ),
      child:
          isLoading
              ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
              : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
    );
  }
}
