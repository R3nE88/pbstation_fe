import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/logic/calculos_dinero.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/logic/verificar_admin_psw.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/provider/provider.dart';
import 'package:pbstation_frontend/screens/catalogo/forms/productos_form.dart';
import 'package:pbstation_frontend/services/login.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';
import 'package:provider/provider.dart';

// Constantes de menú para evitar reconstrucciones
const _menuItemLeer = PopupMenuItem(
  value: 'leer',
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.info_outline, color: AppTheme.letraClara, size: 17),
      Text('  Datos Completos', style: AppTheme.subtituloPrimario),
    ],
  ),
);
const _menuItemEditar = PopupMenuItem(
  value: 'editar',
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.edit, color: AppTheme.letraClara, size: 17),
      Text('  Editar', style: AppTheme.subtituloPrimario),
    ],
  ),
);
const _menuItemEliminar = PopupMenuItem(
  value: 'eliminar',
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.clear, color: AppTheme.letraClara, size: 17),
      Text('  Eliminar', style: AppTheme.subtituloPrimario),
    ],
  ),
);

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
    final productosServices = Provider.of<ProductosServices>(
      context,
      listen: false,
    );
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
    return BodyPadding(
      child: Column(
        children: [
          _buildHeader(context),
          const SizedBox(height: 10),
          Expanded(child: _buildTable()),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
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
                message: 'Codigo o Descripcion',
                child: TextFormField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search, color: AppTheme.letraClara),
                    hintText: 'Buscar Producto',
                  ),
                ),
              ),
            ),
            SizedBox(
              width:
                  Login.usuarioLogeado.permisos.tieneAlMenos(Permiso.elevado)
                      ? 15
                      : 0,
            ),
            Login.usuarioLogeado.permisos.tieneAlMenos(Permiso.elevado)
                ? ElevatedButton(
                  onPressed:
                      () => showDialog(
                        context: context,
                        builder:
                            (_) => const Stack(
                              alignment: Alignment.topRight,
                              children: [
                                ProductoFormDialog(),
                                WindowBar(overlay: true),
                              ],
                            ),
                      ),
                  child: Row(
                    children: [
                      Transform.translate(
                        offset: const Offset(-8, 1),
                        child: Icon(
                          Icons.add,
                          color: AppTheme.containerColor1,
                          size: 26,
                        ),
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
                )
                : const SizedBox(),
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
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                color: AppTheme.tablaColorHeader,
              ),
              child: const Row(
                children: [
                  Expanded(child: Text('Codigo', textAlign: TextAlign.center)),
                  Expanded(
                    flex: 2,
                    child: Text('Descripcion', textAlign: TextAlign.center),
                  ),
                  Expanded(child: Text('Unidad', textAlign: TextAlign.center)),
                  Expanded(
                    child: Text('Categoria', textAlign: TextAlign.center),
                  ),
                  //Expanded(child: Text('Precio sin Iva', textAlign: TextAlign.center)),
                  Expanded(
                    child: Text('Precio con Iva', textAlign: TextAlign.center),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color:
                    servicios.filteredProductos.length % 2 == 0
                        ? AppTheme.tablaColor1
                        : AppTheme.tablaColor2,
                child: ListView.builder(
                  itemExtent: 32, // Altura fija para optimizar scroll
                  itemCount: servicios.filteredProductos.length,
                  itemBuilder:
                      (context, index) => RepaintBoundary(
                        child: FilaProducto(
                          producto: servicios.filteredProductos[index],
                          index: index,
                          onDelete: () async {
                            final loadingSvc = Provider.of<LoadingProvider>(
                              context,
                              listen: false,
                            );
                            loadingSvc.show();
                            await servicios.deleteProducto(
                              servicios.filteredProductos[index].id!,
                            );
                            loadingSvc.hide();
                          },
                        ),
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

  // Instancia estática para evitar recreación
  static final _calculos = CalculosDinero();

  @override
  Widget build(BuildContext context) {
    // Usa método existente para calcular precio con IVA
    final precioConIva = _calculos.calcularConIva(producto.precio);

    void mostrarMenu(BuildContext context, Offset offset) async {
      final String? seleccion;
      if (Login.usuarioLogeado.permisos.tieneAlMenos(Permiso.elevado)) {
        seleccion = await showMenu(
          context: context,
          position: RelativeRect.fromLTRB(
            offset.dx,
            offset.dy,
            offset.dx,
            offset.dy,
          ),
          color: AppTheme.dropDownColor,
          elevation: 4,
          shadowColor: Colors.black,
          items: const [_menuItemLeer, _menuItemEditar, _menuItemEliminar],
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
          elevation: 4,
          shadowColor: Colors.black,
          items: const [_menuItemLeer],
        );
      }

      if (seleccion != null) {
        if (seleccion == 'leer') {
          // Lógica para leer
          if (!context.mounted) {
            return;
          }
          showDialog(
            context: context,
            builder:
                (_) => Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ProductoFormDialog(prodEdit: producto, onlyRead: true),
                    const WindowBar(overlay: true),
                  ],
                ),
          );
        } else if (seleccion == 'editar') {
          // Lógica para editar
          if (!context.mounted) {
            return;
          }
          final resp = await verificarAdminPsw(context);
          if (resp == true) {
            if (!context.mounted) {
              return;
            }
            showDialog(
              context: context,
              builder:
                  (_) => Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ProductoFormDialog(prodEdit: producto),
                      const WindowBar(overlay: true),
                    ],
                  ),
            );
          }
        } else if (seleccion == 'eliminar') {
          // Lógica para eliminar
          if (!context.mounted) {
            return;
          }
          final resp = await verificarAdminPsw(context);
          if (resp == true) {
            onDelete();
          }
        }
      }
    }

    return FeedBackButton(
      onlyVertical: true,
      onPressed: () {},
      child: GestureDetector(
        onSecondaryTapDown: (details) {
          mostrarMenu(context, details.globalPosition);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5),
          color: index % 2 == 0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  producto.codigo.toString(),
                  style: AppTheme.subtituloConstraste,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  producto.descripcion,
                  style: AppTheme.subtituloConstraste,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  Constantes.unidadesSat[producto.unidadSat]!,
                  style: AppTheme.subtituloConstraste,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  Constantes.clavesSat[producto.claveSat] ?? 'no se encontro',
                  style: AppTheme.subtituloConstraste,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  Formatos.pesos.format(precioConIva.toDouble()),
                  textScaler: const TextScaler.linear(1.1),
                  style: AppTheme.subtituloConstraste,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
