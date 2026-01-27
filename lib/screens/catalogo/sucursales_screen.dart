import 'package:flutter/material.dart';
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/logic/verificar_admin_psw.dart';
import 'package:pbstation_frontend/models/sucursales.dart';
import 'package:pbstation_frontend/provider/provider.dart';
import 'package:pbstation_frontend/screens/catalogo/forms/sucursales_form.dart';
import 'package:pbstation_frontend/services/login.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';
import 'package:provider/provider.dart';

class SucursalesScreen extends StatefulWidget {
  const SucursalesScreen({super.key});

  @override
  State<SucursalesScreen> createState() => _SucursalesScreenState();
}

class _SucursalesScreenState extends State<SucursalesScreen> {

@override
  void initState() {
    super.initState();
    final sucursalesServices = Provider.of<SucursalesServices>(context, listen: false);
    sucursalesServices.loadSucursales();
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
    final sucursalesServices = Provider.of<SucursalesServices>(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sucursales',
          style: AppTheme.tituloClaro,
          textScaler: TextScaler.linear(1.7),
        ),

        Transform.translate(
          offset: const Offset(37, 0),
          child: Container(
            height: 35, 
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppTheme.tablaColorHeader,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    sucursalesServices.sucursalActual != null ? 'Sucursal Asignada  '
                    :'Aún no asignas una sucursal a esta terminal', 
                    style: AppTheme.subtituloPrimario.copyWith(
                      fontWeight: FontWeight.w700
                    ),
                    textScaler: const TextScaler.linear(0.9),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -1),
                    child: Text(
                      sucursalesServices.sucursalActual != null ? sucursalesServices.sucursalActual!.nombre
                      :'', 
                      style: AppTheme.tituloClaro.copyWith(letterSpacing: 1.7, fontSize: 18)
                    ),
                  )
                ],
              ),
            ),
          ),
        ),

        ElevatedButton(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => const Stack(
              alignment: Alignment.topRight,
              children: [
                SucursalesFormDialog(),
                WindowBar(overlay: true),
              ],
            ),
          ),
          child: Row(
            children: [
              Transform.translate(
                offset: const Offset(-8, 1),
                child: Icon(Icons.add, color: AppTheme.containerColor1, size: 26),
              ),
              Text(
                'Agregar Sucursal',
                style: TextStyle(
                  color: AppTheme.containerColor1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildTable() {
    return Consumer<SucursalesServices>(
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
                  Expanded(child: Text('Sucursal', textAlign: TextAlign.center)),
                  Expanded(child: Text('Correo', textAlign: TextAlign.center)),
                  Expanded(child: Text('Telefono', textAlign: TextAlign.center)),
                  Expanded(child: Text('Direccion', textAlign: TextAlign.center)),
                  Expanded(child: Text('Ciudad', textAlign: TextAlign.center)),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: servicios.sucursales.length % 2 == 0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
                child: ListView.builder(
                  itemCount: servicios.sucursales.length,
                  itemBuilder: (context, index) => FilaSucursales(
                    sucursal: servicios.sucursales[index],
                    index: index,
                    onDelete: () async {
                      final loadingSvc = Provider.of<LoadingProvider>(context, listen: false);
                      loadingSvc.show();
                      await servicios.deleteSucursal(servicios.sucursales[index].id!);
                      if(!context.mounted) return;
                      Provider.of<ImpresorasServices>(context, listen:false).clear();
                      loadingSvc.hide();
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
                    '  Total: ${servicios.sucursales.length}   ',
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

class FilaSucursales extends StatelessWidget {
  const FilaSucursales({
    super.key,
    required this.sucursal,
    required this.index,
    required this.onDelete
  });

  final Sucursales sucursal;
  final int index;
  final Function onDelete;

  @override
  Widget build(BuildContext context) {
    final partes = sucursal.localidad.split(',');
    String ciudad = partes[0].trim();
    String estado = partes[1].trim();
    String pais = partes[2].trim();
    String localidad = '$ciudad, ${estado.substring(0, 3)}, ${pais.substring(0, 3)}';

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
          items: [
            sucursal.id != SucursalesServices.sucursalActualID ? const PopupMenuItem(
              value: 'vincular',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: AppTheme.letraClara, size: 17),
                  Text('  Vincular a esta Terminal', style: AppTheme.subtituloPrimario),
                ],
              ),
            )
            :
            const PopupMenuItem(
              value: 'desvincular',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.remove, color: AppTheme.letraClara, size: 17),
                  Text('  Desvincular de esta terminal', style: AppTheme.subtituloPrimario),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'leer',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, color: AppTheme.letraClara, size: 17),
                  Text('  Datos Completos', style: AppTheme.subtituloPrimario),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'editar',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, color: AppTheme.letraClara, size: 17),
                  Text('  Editar', style: AppTheme.subtituloPrimario),
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
          items: [
            const PopupMenuItem(
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
        if (seleccion == 'vincular') {
          // Lógica para asignar
          if (CajasServices.cajaActual== null) { //Si no hay caja abierta
          if(!context.mounted){ return; }
            await  Provider.of<SucursalesServices>(context, listen: false).establecerSucursal(sucursal);
            if(!context.mounted) return;
            await  Provider.of<ImpresorasServices>(context, listen: false).loadImpresoras(true, overLoad: true);
          } else {
            if(!context.mounted){ return; }
            showDialog(
              context: context,
              builder: (_) => const Stack(
                alignment: Alignment.topRight,
                children: [
                  CustomErrorDialog(titulo: 'No puedes cambiar de sucursal.', respuesta: 'Debe cerrar la caja abierta antes de cambiar de sucursal.',),
                  WindowBar(overlay: true),
                ],
              ),
            );
          }
        } else if (seleccion == 'desvincular') {
          // Lógica para desasingar
          if (CajasServices.cajaActual== null) { //Si no hay caja abierta
            if(!context.mounted){ return; }
            await  Provider.of<SucursalesServices>(context, listen: false).desvincularSucursal(true);
            if(!context.mounted) return;
            await  Provider.of<ImpresorasServices>(context, listen: false).loadImpresoras(true, overLoad: true);
          } else {
            if(!context.mounted){ return; }
            showDialog(
              context: context,
              builder: (_) => const Stack(
                alignment: Alignment.topRight,
                children: [
                  CustomErrorDialog(titulo: 'No puedes cambiar de sucursal.', respuesta: 'Debe cerrar la caja abierta antes de cambiar de sucursal.',),
                  WindowBar(overlay: true),
                ],
              ),
            );
          }
        } else if (seleccion == 'leer') {
          // Lógica para leer
          if(!context.mounted){ return; }
          showDialog(
            context: context,
            builder: (_) => Stack(
              alignment: Alignment.topRight,
              children: [
                SucursalesFormDialog(sucEdit: sucursal, onlyRead: true),
                const WindowBar(overlay: true),
              ],
            ),
          );
        } else if (seleccion == 'editar') {
          // Lógica para editar
          if(!context.mounted){ return; }
          final resp = await verificarAdminPsw(context);
          if (resp==true){
            if(!context.mounted){ return; }
            showDialog(
              context: context,
              builder: (_) => Stack(
                alignment: Alignment.topRight,
                children: [
                  SucursalesFormDialog(sucEdit: sucursal),
                  const WindowBar(overlay: true),
                ],
              ),
            );
          }
        } else if (seleccion == 'eliminar') {
          // Lógica para eliminar
          if(!context.mounted){ return; }
          final resp = await verificarAdminPsw(context);
          if (resp==true){
            onDelete();
          }
        }
      }
    }

    return FeedBackButton(
      onlyVertical: true,
      onPressed: (){},
      child: GestureDetector(
        onSecondaryTapDown: (details) {
          mostrarMenu(context, details.globalPosition);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5),
          color: index % 2 == 0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
          child: Row(
            children: [
              Expanded(child: Text(sucursal.nombre, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
              Expanded(child: Text(sucursal.correo, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
              Expanded(child: Text(sucursal.telefono, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
              Expanded(child: Text(sucursal.direccion, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
              Expanded(child: Text(localidad, style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
            ],
          ),
        ),
      ),
    );
  }
}