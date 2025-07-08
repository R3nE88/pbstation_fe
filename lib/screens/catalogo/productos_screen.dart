import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/screens/catalogo/forms/productos_form.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';
import 'package:provider/provider.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final productosServices = Provider.of<ProductosServices>(context, listen: false);
    productosServices.loadProductos();

    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 600), () {
        final query = _searchController.text.toLowerCase();
        productosServices.filtrarProductos(query);
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
        Text(
          'Productos & Servicios',
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
                    hintText: 'Buscar Producto',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const ProductoFormDialog(),
              ),
              child: Row(
                children: [
                  Transform.translate(
                    offset: const Offset(-8, 1),
                    child: Icon(Icons.add, color: AppTheme.containerColor1, size: 26),
                  ),
                  Text(
                    'Agregar Producto',
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
    return Consumer<ProductosServices>(
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
                  Expanded(child: Text('Codigo', textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Text('Descripcion', textAlign: TextAlign.center)),
                  Expanded(child: Text('Tipo', textAlign: TextAlign.center)),
                  Expanded(child: Text('Categoria', textAlign: TextAlign.center)),
                  Expanded(child: Text('Precio/Unidad', textAlign: TextAlign.center)),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: AppTheme.tablaColorFondo,
                child: ListView.builder(
                  itemCount: servicios.filteredProductos.length,
                  itemBuilder: (context, index) => FilaProducto(
                    producto: servicios.filteredProductos[index],
                    index: index,
                    onDelete: () async {
                      Loading.displaySpinLoading(context);
                      await servicios.deleteProducto(servicios.filteredProductos[index].id!);
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
                    '  Total: ${servicios.filteredProductos.length}   ',
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

class FilaProducto extends StatelessWidget {
  const FilaProducto({
    super.key,
    required this.producto,
    required this.index,
    required this.onDelete,
  });

  final Productos producto;
  final int index;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {

    void mostrarMenu(BuildContext context, Offset offset) async {
      final seleccion = await showMenu(
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

      if (seleccion != null) {
        if (seleccion == 'leer') {
          // Lógica para leer
          if(!context.mounted){ return; }
          showDialog(
            context: context,
            builder: (_) => ProductoFormDialog(prodEdit: producto, onlyRead: true),
          );
        } else if (seleccion == 'editar') {
          // Lógica para editar
          if(!context.mounted){ return; }
          showDialog(
            context: context,
            builder: (_) => ProductoFormDialog(prodEdit: producto),
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
            Expanded(child: Text(producto.codigo.toString(), textAlign: TextAlign.center)),
            Expanded(flex: 2, child: Text(producto.descripcion, textAlign: TextAlign.center)),
            Expanded(child: Text(Constantes.tipo[producto.tipo]!, textAlign: TextAlign.center)),
            Expanded(child: Text(Constantes.categoria[producto.categoria]!, textAlign: TextAlign.center)),
            Expanded(child: Text('\$${producto.precio}', textAlign: TextAlign.center)),
          ],
        ),
      ),
    );
  }
}