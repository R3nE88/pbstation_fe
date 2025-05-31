import 'package:flutter/material.dart';
import 'package:pbstation_frontend/models/models.dart';
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
  @override
  void initState() { //Init se inicializa siempre que entro
    final productosServices = Provider.of<ProductosServices>(context, listen: false);
    productosServices.loadProductos();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final productosServices = Provider.of<ProductosServices>(context, listen: false);
    
    return Padding(
      padding: const EdgeInsets.only(top:8, bottom: 5, left: 54, right: 52),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.containerColor1,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              
              Row( //Titulo y boton de agregar producto
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Productos & Servicios',
                    style: AppTheme.tituloClaro,
                    textScaler: TextScaler.linear(1.7)
                  ),
                  Row(
                    children: [
                      SizedBox(
                        height: 34,
                        width: 300,
                        child: Tooltip(
                          waitDuration: Durations.short4,
                          message: 'codigo o descripcion',
                          child: TextFormField( //TODO: hacer funcional searhfield
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.search, color: AppTheme.letraClara),
                              hintText: 'Buscar Producto'
                            ),
                          ),
                        )
                      ), SizedBox(width: 15),
                      ElevatedButton(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => ProductoFormDialog(), //Formulario para agregar producto
                        ),
                        child: Row(
                          children: [
                            Transform.translate(
                              offset: const Offset(-8, 1),
                              child: Icon(Icons.add, color: AppTheme.containerColor1, size: 26)
                            ),
                            Text('Agregar Producto', style: TextStyle(color: AppTheme.containerColor1, fontWeight: FontWeight.w700)),
                          ],
                        )
                      ),
                    ],
                  )
                ],
              ), const SizedBox(height: 10),

              Expanded( //Tabla de productos
                child: Column(
                  children: [
                    Container( //Header
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
                          Expanded(flex:2, child: Text('Descripcion', textAlign: TextAlign.center)),
                          Expanded(child: Text('Tipo', textAlign: TextAlign.center)),
                          Expanded(child: Text('Categoria', textAlign: TextAlign.center)),
                          Expanded(child: Text('Precio', textAlign: TextAlign.center)),
                          Expanded(child: Text('Inventariable', textAlign: TextAlign.center)),
                          Expanded(child: Text('Cuenta como impresion', textAlign: TextAlign.center)),
                        ],
                      ),
                    ),
                    Expanded( //Body
                      child: Container(
                        color: AppTheme.tablaColorFondo,
                        child: Consumer<ProductosServices>( //De esta forma el provider solo actualza este widget
                          builder: (context, length, child) {
                            return ListView.builder(
                              itemCount: productosServices.productos.length,
                              itemBuilder: (context, index) => FilaProducto(
                                producto: productosServices.productos[index],
                                index: index,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Container( //Pie
                      height: 45,
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
                          Consumer<ProductosServices>(
                            builder: (context, length, child) {
                              return Text('  Total: ${productosServices.productos.length}   ', style: TextStyle(fontWeight: FontWeight.bold));
                            }
                          ),
                          /*const Text('Pagina 1/1  ', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                            onPressed: (){}, 
                            icon: Transform.translate(
                              offset: const Offset(0, -5),
                              child: const Icon(Icons.navigate_before, color: AppTheme.letraClara)
                            )
                          ),
                          IconButton(
                            onPressed: (){}, 
                            icon: Transform.translate(
                              offset: const Offset(0, -5),
                              child: const Icon(Icons.navigate_next, color: AppTheme.letraClara)
                            )
                          )*/
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FilaProducto extends StatelessWidget {
  const FilaProducto({
    super.key,
    required this.producto, required this.index,
  });

  final Producto producto;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: index % 2 == 0
          ? AppTheme.tablaColor1
          : AppTheme.tablaColor2,
      child: Row(
        children: [
          Expanded(child: Text(producto.codigo.toString(), textAlign: TextAlign.center)),
          Expanded(flex:2, child: Text(producto.descripcion, textAlign: TextAlign.center)),
          Expanded(child: Text(producto.tipo, textAlign: TextAlign.center)),
          Expanded(child: Text(producto.categoria, textAlign: TextAlign.center)),
          Expanded(child: Text('\$${producto.precio}', textAlign: TextAlign.center)),
          Expanded(child: Text(producto.inventariable.toString(), textAlign: TextAlign.center)),
          Expanded(child: Text(producto.imprimible.toString(), textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}