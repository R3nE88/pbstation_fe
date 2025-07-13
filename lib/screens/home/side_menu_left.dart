import 'package:flutter/material.dart';
import 'package:pbstation_frontend/provider/modulos_provider.dart';
import 'package:provider/provider.dart';
import 'package:pbstation_frontend/logic/modulos.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';

class SideMenuLeft extends StatelessWidget {
  const SideMenuLeft({super.key});

  @override
  Widget build(BuildContext context) {
    final modProv = context.watch<ModulosProvider>();
    final modulos = modProv.listaModulos;

    const double height = 130;

    return HoverSideMenu(
      side: MenuSide.left,
      height: MediaQuery.of(context).size.height,
      enabled: true,
      menuContent: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          //const SizedBox(height: 20),
          _buildLogo(height),
          Expanded(
            child: ListView.builder(
              itemCount: modulos.length,
              itemBuilder: (context, i) {
                final modulo = modulos[i];
                final selected = modProv.moduloSeleccionado == modulo;
                return _navItem(
                  icon: Modulos.modulosIconos[modulo]![0],
                  label: modulo,
                  selected: selected,
                  onTap: () => modProv.seleccionarModulo(modulo), 
                  index: i,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: const Text('v0.0001', style: AppTheme.subtituloPrimario), //TODO: version
          ),
        ],
      ),
      menuContentColapsed: Column(
        children: [
          const SizedBox(height: height+9, width: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: modulos.map((modulo) {
                  final selected = modProv.moduloSeleccionado == modulo;
                  return Padding(
                    padding: const EdgeInsets.only(top: 15, left: 13),
                    child: GestureDetector(
                      onTap: () => modProv.seleccionarModulo(modulo),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected ? AppTheme.letraClara : Colors.transparent,
                          border: Border.all(color: AppTheme.letra70),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Modulos.modulosIconos[modulo]![0],
                          size: 23,
                          color: selected ? AppTheme.primario1 : AppTheme.letra70,
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
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: CustomNavigationButton(
          icon: icon,
          label: label[0].toUpperCase() + label.substring(1),
          selected: selected, 
          first: index==0, 
          inhabilitado: false,
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