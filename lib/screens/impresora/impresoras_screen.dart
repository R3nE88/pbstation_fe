import 'package:flutter/material.dart';
import 'package:pbstation_frontend/logic/input_formatter.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/screens/impresora/impresora_form.dart';
import 'package:pbstation_frontend/services/impresoras_services.dart';
import 'package:pbstation_frontend/services/login.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';
import 'package:provider/provider.dart';

class ImpresorasScreen extends StatelessWidget {
  const ImpresorasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double screenSize = MediaQuery.of(context).size.width;
    final imprSvc = Provider.of<ImpresorasServices>(context, listen: false);
    imprSvc.loadImpresoras(true);

    return BodyPadding(
      hasSubModules: false,
      child: Column(
        children: [
          _buildHeader(),
          Consumer<ImpresorasServices>(
            builder: (context, value, child) {  
              return Expanded(
                child: GridView.count(
                  crossAxisCount: screenSize < 1300 ? 3 : 4,
                  childAspectRatio: 3,
                  children: List.generate(
                    value.impresoras.length + (Login.isAdmin ? 1 : 0), (index) {
                      if (index==0 && Login.isAdmin){
                        return const AgregarImpresora();
                      } else {
                        print(index);
                        final contador = value.ultimosContadores[value.impresoras[index-1].id];
                        return ImpresorasCards(impresora: value.impresoras[index-1], contador: contador?.cantidad ?? 0,);
                      }
                    }
                  )
                ),
              );
            },
          )
        ],
      )
    );
  }

  Row _buildHeader() {
    return const Row( //Header
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Impresoras',
          style: AppTheme.tituloClaro,
          textScaler: TextScaler.linear(1.7),
        ),
      ]
    );
  }
}

class AgregarImpresora extends StatefulWidget {
  const AgregarImpresora({super.key});

  @override
  State<AgregarImpresora> createState() => _AgregarImpresoraState();
}

class _AgregarImpresoraState extends State<AgregarImpresora> {
  bool isEnter = false;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (event) {
          setState(() {isEnter=true;});
        },
        onExit: (event) {
          setState(() {isEnter=false;});
        },
        child: Transform.scale(
          scale: isEnter ? 1.03 : 1,
          child: GestureDetector(
            onTap: () => showDialog(
              context: context, 
              builder: ( _ ) => const Stack(
                alignment: Alignment.topRight,
                children: [
                  ImpresoraForm(),
                  WindowBar(overlay: true),
                ],
              )
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppTheme.letraClara, width: 3),
                color: AppTheme.letraClara.withAlpha(10)
              ),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Añadir impresora '),
                    Icon(Icons.add, color: AppTheme.letraClara, size: 50),
                  ],
                )
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ImpresorasCards extends StatelessWidget {
  const ImpresorasCards({
    super.key, required this.impresora, required this.contador,
  });

  final Impresoras impresora;
  final int contador;

  

  @override
  Widget build(BuildContext context) {
    void delete()async{
      bool result = await showDialog(
        context: context, 
        builder: ( _ ) => Stack(
          alignment: Alignment.topRight,
          children: [
            AlertDialog(
              backgroundColor: AppTheme.containerColor1,
              title: const Center(child: Text('¿Desea continuar?', textScaler: TextScaler.linear(0.85))),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Si continua se eliminara cualquier registro de esta impresora', textAlign: TextAlign.center),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Aceptar', style: TextStyle(color: AppTheme.letraClara, fontWeight: FontWeight.w700))
                )
              ],
            ),
            const WindowBar(overlay: true),
          ],
        )
      ) ?? false;
      if (result == true){ 
        //if (!context.mounted) return;
        if (!context.mounted) return;
        final navigator = Navigator.of(context);
        Loading.displaySpinLoading(context);
        await Provider.of<ImpresorasServices>(context, listen: false).deleteImpresora(impresora.id!);
        navigator.pop();
      }
    }

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
          const PopupMenuItem(
            value: 'modificar',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit, color: AppTheme.letraClara, size: 17),
                Text('  Modificar', style: AppTheme.subtituloPrimario),
              ],
            ),
          ),
          const PopupMenuItem(
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

      if (seleccion == 'modificar') {
        // Lógica para modificar
        if (!context.mounted)return;
        showDialog(
          context: context, 
          builder: ( _ ) => Stack(
            alignment: Alignment.topRight,
            children: [
              ImpresoraForm(edit: impresora),
              const WindowBar(overlay: true),
            ],
          )
        );
      } else if (seleccion == 'eliminar') {
        // Lógica para eliminar
        if (!context.mounted)return;
        delete();
      }
    }
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.secundario1,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(impresora.modelo, style: AppTheme.tituloClaro, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Serie: ', style: TextStyle(color: AppTheme.letra70)),
                      Text(impresora.serie, style: const TextStyle(letterSpacing: 1)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Contador: ', style: TextStyle(color: AppTheme.letra70)),
                      Text(Formatos.numero.format(contador), style: const TextStyle(letterSpacing: 1)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(top:4, right: 4, left: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('#${impresora.numero}', style: AppTheme.tituloClaro, textScaler: const TextScaler.linear(1.15)),
                Login.isAdmin ? MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTapDown: (details) {
                      mostrarMenu(context, details.globalPosition);
                    },
                    child: const Icon(Icons.more_vert, color: AppTheme.letraClara, size: 20)
                  )
                ) : const SizedBox(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}