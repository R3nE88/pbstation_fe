import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pbstation_frontend/forms/clientes_form.dart';
import 'package:pbstation_frontend/logic/capitalizar.dart';
import 'package:pbstation_frontend/models/models.dart';
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
            const SizedBox(width: 15),
            ElevatedButton(
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
            ),
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
                  SizedBox(
                    width: 120,
                    child: Text('Acciones', textAlign: TextAlign.center),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: AppTheme.tablaColorFondo,
                child: ListView.builder(
                  itemCount: servicios.filteredClientes.length,
                  itemBuilder: (context, index) => FilaCliente(
                    cliente: servicios.filteredClientes[index],
                    index: index,
                    onDelete: () async {
                      Loading().displaySpinLoading(context);
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

    return Container(
      padding: const EdgeInsets.all(8.0),
      color: index % 2 == 0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
      child: Row(
        children: [
          Expanded(child: Text(mostrarCampo(cliente.nombre), textAlign: TextAlign.center)),
          Expanded(child: Text(mostrarCampo(cliente.correo), textAlign: TextAlign.center)),
          Expanded(child: Text(mostrarCampo('${cliente.telefono ?? '-'}'), textAlign: TextAlign.center)),
          Expanded(child: Text(mostrarCampo(cliente.rfc), textAlign: TextAlign.center)),
          Expanded(child: Text(mostrarCampo(cliente.direccion), textAlign: TextAlign.center)),
          Expanded(child: Text(mostrarCampo(cliente.razonSocial), textAlign: TextAlign.center)),
          SizedBox(
            width: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FeedBackButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => ClientesFormDialog(cliEdit: cliente, onlyRead: true),
                  ),
                  child: Icon(Icons.info, color: AppTheme.letraClara, shadows: [
                    const Shadow(color: Colors.blue, offset: Offset(1.5, 1.5), blurRadius: 2),
                  ]),
                ),
                const SizedBox(width: 22),
                FeedBackButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => ClientesFormDialog(cliEdit: cliente),
                  ),
                  child: Icon(Icons.edit, color: AppTheme.letraClara, shadows: [
                    const Shadow(color: Colors.orange, offset: Offset(1.5, 1.5), blurRadius: 2),
                  ]),
                ),
                const SizedBox(width: 22),
                FeedBackButton(
                  onPressed: onDelete,
                  child: Icon(Icons.delete, color: AppTheme.letraClara, shadows: [
                    const Shadow(color: Colors.red, offset: Offset(1.5, 1.5), blurRadius: 2),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}