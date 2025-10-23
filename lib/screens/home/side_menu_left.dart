import 'package:flutter/material.dart';
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/provider/modulos_provider.dart';
import 'package:provider/provider.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';

class SideMenuLeft extends StatelessWidget {
  const SideMenuLeft({super.key});

  @override
  Widget build(BuildContext context) {
    final modProv = context.watch<ModulosProvider>();
    final modulos = modProv.todosLosModulos;  // ← CAMBIAR de gestor.modulos a todosLosModulos

    const double height = 130;

    return HoverSideMenu(
      side: MenuSide.left,
      height: MediaQuery.of(context).size.height,
      enabled: true,
      menuContent: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLogo(height),
          Expanded(
            child: ListView.builder(
              itemCount: modulos.length,
              itemBuilder: (context, i) {
                final modulo = modulos[i];
                final bloqueado = modProv.moduloBloqueado(modulo);  // ← NUEVO
                final selected = modProv.moduloSeleccionado == modulo.nombre;
                
                return _navItem(
                  icon: bloqueado ? Icons.lock : modulo.iconoPrincipal,  // ← CAMBIAR
                  label: modulo.nombre,
                  selected: selected,
                  onTap: bloqueado 
                      ? () {} 
                      : () => modProv.seleccionarModulo(modulo.nombre),  // ← CAMBIAR
                  index: i,
                  inhabilitado: bloqueado,  // ← NUEVO
                );
              }
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text('v${Constantes.version}', style: AppTheme.subtituloPrimario),
          ),
        ],
      ),
      menuContentColapsed: Column(
        children: [
          const SizedBox(height: height + 9, width: 20),
          Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: modulos.map((modulo) {  // ← Ya usa modulos de arriba
                  final bloqueado = modProv.moduloBloqueado(modulo);  // ← NUEVO
                  final selected = modProv.moduloSeleccionado == modulo.nombre;
                  
                  return Padding(
                    padding: const EdgeInsets.only(top: 15, left: 13),
                    child: GestureDetector(
                      onTap: bloqueado 
                          ? null 
                          : () => modProv.seleccionarModulo(modulo.nombre),  // ← CAMBIAR
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected ? AppTheme.letraClara : Colors.transparent,
                          border: Border.all(
                            color: bloqueado ? Colors.white24 : AppTheme.letra70  // ← CAMBIAR
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          bloqueado ? Icons.lock : modulo.iconoPrincipal,  // ← CAMBIAR
                          size: 23,
                          color: bloqueado 
                              ? Colors.white24 
                              : (selected ? AppTheme.primario1 : AppTheme.letra70),  // ← CAMBIAR
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required int index,
    bool inhabilitado = false,  // ← NUEVO parámetro
  }) {
    return MouseRegion(
      cursor: inhabilitado ? SystemMouseCursors.basic : SystemMouseCursors.click,  // ← CAMBIAR
      child: GestureDetector(
        onTap: inhabilitado ? null : onTap,  // ← CAMBIAR
        child: CustomNavigationButton(
          icon: icon,
          label: label[0].toUpperCase() + label.substring(1),
          selected: selected, 
          first: index == 0, 
          inhabilitado: inhabilitado,  // ← CAMBIAR
        ),
      ),
    );
  }

  Widget _buildLogo(height) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Image.asset(
        AppTheme.isDarkTheme ? 'assets/images/logo_darkmode.png' : 'assets/images/logo_normal.png',
        height: height,
        //color: AppTheme.colorContraste,
      ),
    );
  }
}