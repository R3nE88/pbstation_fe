import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pbstation_frontend/screens/catalogo/forms/clientes_form.dart';
import 'package:pbstation_frontend/logic/capitalizar.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/services/login.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';
import 'package:provider/provider.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final clientesServices = Provider.of<ClientesServices>(context, listen: false);
    clientesServices.loadClientes();

    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 600), () {
        final query = _searchController.text.toLowerCase();
        clientesServices.filtrarClientes(query);
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 5, left: 54, right: 52),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.containerColor1,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 10),
              Expanded(child: _buildTable()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Clientes',
          style: AppTheme.tituloClaro,
          textScaler: TextScaler.linear(1.7),
        ),
        Row(
          children: [
            SizedBox(
              height: 34,
              width: 300,
              child: Tooltip(
                waitDuration: Durations.short4,
                message: 'codigo o descripcion',
                child: TextFormField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, color: AppTheme.letraClara),
                    hintText: 'Buscar Cliente',
                  ),
                ),
              ),
            ),
            SizedBox(width: Login.admin ? 15 : 0),
            Login.admin ? ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const ClientesFormDialog(),
              ),
              child: Row(
                children: [
                  Transform.translate(
                    offset: const Offset(-8, 1),
                    child: Icon(Icons.add, color: AppTheme.containerColor1, size: 26),
                  ),
                  Text(
                    'Agregar Cliente',
                    style: TextStyle(
                      color: AppTheme.containerColor1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ) : const SizedBox(),
          ],
        ),
      ],
    );
  }

  Widget _buildTable() {
    return Consumer<ClientesServices>(
      builder: (context, servicios, _) {
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
                  Expanded(child: Text('Nombre', textAlign: TextAlign.center)),
                  Expanded(child: Text('Correo', textAlign: TextAlign.center)),
                  Expanded(child: Text('Telefono', textAlign: TextAlign.center)),
                  Expanded(child: Text('RFC', textAlign: TextAlign.center)),
                  Expanded(child: Text('Direccion', textAlign: TextAlign.center)),
                  Expanded(child: Text('Razon Social', textAlign: TextAlign.center)),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: servicios.filteredClientes.length % 2 == 0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
                child: ListView.builder(
                  itemCount: servicios.filteredClientes.length,
                  itemBuilder: (context, index) => FilaCliente(
                    cliente: servicios.filteredClientes[index],
                    index: index,
                    onDelete: () async {
                      Loading.displaySpinLoading(context);
                      await servicios.deleteCliente(servicios.filteredClientes[index].id!);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
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
                    '  Total: ${servicios.filteredClientes.length}   ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class FilaCliente extends StatelessWidget {
  const FilaCliente({
    super.key,
    required this.cliente,
    required this.index,
    required this.onDelete,
  });

  final Clientes cliente;
  final int index;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    String mostrarCampo(String? valor) => capitalizarPrimeraLetra(valor ?? '-');

    void mostrarMenu(BuildContext context, Offset offset) async {
      
      final String? seleccion;
      if (Login.admin) {
        seleccion = await showMenu(
        context: context,
        position: RelativeRect.fromLTRB(
          offset.dx,
          offset.dy,
          offset.dx,
          offset.dy,
        ),
        color: AppTheme.dropDownColor,
        elevation: 2,
        items: [
          PopupMenuItem(
            value: 'leer',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, color: AppTheme.letraClara, size: 17),
                Text('  Datos Completos', style: AppTheme.subtituloPrimario),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'editar',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit, color: AppTheme.letraClara, size: 17),
                Text('  Editar', style: AppTheme.subtituloPrimario),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'eliminar',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.clear, color: AppTheme.letraClara, size: 17),
                Text('  Eliminar', style: AppTheme.subtituloPrimario),
              ],
            ),
          ),
        ],
      );
      } else {
        seleccion = await showMenu(
        context: context,
        position: RelativeRect.fromLTRB(
          offset.dx,
          offset.dy,
          offset.dx,
          offset.dy,
        ),
        color: AppTheme.dropDownColor,
        elevation: 2,
        items: [
          PopupMenuItem(
            value: 'leer',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, color: AppTheme.letraClara, size: 17),
                Text('  Datos Completos', style: AppTheme.subtituloPrimario),
              ],
            ),
          ),
        ],
      );
      }

      if (seleccion != null) {
        if (seleccion == 'leer') {
          // Lógica para leer
          if(!context.mounted){ return; }
          showDialog(
            context: context,
            builder: (_) => ClientesFormDialog(cliEdit: cliente, onlyRead: true),
          );
        } else if (seleccion == 'editar') {
          // Lógica para editar
          if(!context.mounted){ return; }
          showDialog(
            context: context,
            builder: (_) => ClientesFormDialog(cliEdit: cliente),
          );
        } else if (seleccion == 'eliminar') {
          // Lógica para eliminar
          onDelete();
        }
      }
    }

    return GestureDetector(
      onSecondaryTapDown: (details) {
        mostrarMenu(context, details.globalPosition);
      },
      child: Container(
        padding: const EdgeInsets.all(8.0),
        color: index % 2 == 0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
        child: Row(
          children: [
            Expanded(child: Text(mostrarCampo(cliente.nombre), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
            Expanded(child: Text(mostrarCampo(cliente.correo), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
            Expanded(child: Text(mostrarCampo('${cliente.telefono ?? '-'}'), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
            Expanded(child: Text(mostrarCampo(cliente.rfc), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
            Expanded(child: Text(mostrarCampo(cliente.direccion), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
            Expanded(child: Text(mostrarCampo(cliente.razonSocial), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          ],
        ),
      ),
    );
  }
}