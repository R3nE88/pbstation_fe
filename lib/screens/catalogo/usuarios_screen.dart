import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pbstation_frontend/logic/capitalizar.dart';
import 'package:pbstation_frontend/logic/verificar_admin_psw.dart';
import 'package:pbstation_frontend/models/models.dart';
import 'package:pbstation_frontend/screens/catalogo/forms/usuarios_form.dart';
import 'package:pbstation_frontend/screens/catalogo/forms/usuarios_psw.dart';
import 'package:pbstation_frontend/services/login.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';
import 'package:provider/provider.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final usuarioSvc = Provider.of<UsuariosServices>(context, listen: false);
    usuarioSvc.loadUsuarios();

    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 600), () {
        final query = _searchController.text.toLowerCase();
        usuarioSvc.filtrarUsuarios(query);
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
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'Equipo',
              style: AppTheme.tituloClaro,
              textScaler: TextScaler.linear(1.7), 
            ),
            const Text(
              '  (Gestión de todos los que usan la app)',
              style: AppTheme.labelStyle,
              textScaler: TextScaler.linear(1.1), 
            ),
          ],
        ),
        Row(
          children: [
            SizedBox(
              height: 34,
              width: 300,
              child: Tooltip(
                waitDuration: Durations.short4,
                message: 'Nombre',
                child: TextFormField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, color: AppTheme.letraClara),
                    hintText: 'Buscar usuario',
                  ),
                ),
              ),
            ),
            SizedBox(width: Login.admin ? 15 : 0),
            Login.admin ? ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => Stack(
                  alignment: Alignment.topRight,
                  children: [
                    const UsuariosFormDialog(),
                    const WindowBar(overlay: true),
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
                    'Agregar al Equipo',
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
    return Consumer<UsuariosServices>(
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
                  Expanded(flex: 2, child: Text('Permisos Admin', textAlign: TextAlign.center)),
                  Expanded(flex: 4, child: Text('Nombre', textAlign: TextAlign.center)),
                  Expanded(flex: 4, child: Text('Correo', textAlign: TextAlign.center)),
                  Expanded(flex: 4, child: Text('Telefono', textAlign: TextAlign.center)),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: servicios.filteredUsuarios.length % 2 == 0 ? AppTheme.tablaColor1 : AppTheme.tablaColor2,
                child: ListView.builder(
                  itemCount: servicios.filteredUsuarios.length,
                  itemBuilder: (context, index) => FilaUsuario(
                    usuario: servicios.filteredUsuarios[index],
                    index: index,
                    onDelete: () async {
                      Loading.displaySpinLoading(context);
                      await servicios.deleteUsuario(servicios.filteredUsuarios[index].id!);
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
                    '  Total: ${servicios.filteredUsuarios.length}   ',
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

class FilaUsuario extends StatelessWidget {
  const FilaUsuario({
    super.key,
    required this.usuario,
    required this.index,
    required this.onDelete,
  });

  final Usuarios usuario;
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
              value: 'cambiar_psw',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.password, color: AppTheme.letraClara, size: 17),
                  Text('  Cambiar Contraseña', style: AppTheme.subtituloPrimario),
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
            builder: (_) => Stack(
              alignment: Alignment.topRight,
              children: [
                UsuariosFormDialog(usuEdit: usuario, onlyRead: true),
                const WindowBar(overlay: true),
              ],
            ),
          );
        } else if (seleccion == 'cambiar_psw') {
          // Lógica para restablecer psw

          if(!context.mounted){ return; }
          final resp = await verificarAdminPsw(context);

          if (resp==true){
            if(!context.mounted){ return; }
            showDialog(
              context: context,
              builder: (_) => Stack(
                alignment: Alignment.topRight,
                children: [
                  UsuariosPswForm(usuarioId: usuario.id!),
                  const WindowBar(overlay: true),
                ],
              ),
            );
          }

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
                  UsuariosFormDialog(usuEdit: usuario),
                  const WindowBar(overlay: true),
                ],
              ),
            ); 
          }

        }else if (seleccion == 'eliminar') {
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
            Expanded(flex: 2, child: usuario.rol=='admin' ? Icon(Icons.check) : Icon(Icons.close)),
            Expanded(flex: 4, child: Text(mostrarCampo(usuario.nombre), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
            Expanded(flex: 4, child: Text(mostrarCampo(usuario.correo), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
            Expanded(flex: 4, child: Text(mostrarCampo(usuario.telefono!=null ? usuario.telefono.toString() : '-'), style: AppTheme.subtituloConstraste, textAlign: TextAlign.center)),
          ],
        ),
      ),
    );
  }



}