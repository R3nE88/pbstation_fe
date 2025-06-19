import 'package:flutter/foundation.dart';
import 'package:pbstation_frontend/logic/modulos.dart';

class ModulosProvider extends ChangeNotifier {
  String _moduloSeleccionado;
  int _subModuloSeleccionado;
  final Map<String, List<String>> modulos = Modulos.modulos;

  ModulosProvider({
    String moduloInicial = '',
    int subModuloInicial = 0,
  })  : _moduloSeleccionado = moduloInicial,
        _subModuloSeleccionado = subModuloInicial;

  String get moduloSeleccionado => _moduloSeleccionado;
  int get subModuloSeleccionado => _subModuloSeleccionado;

  List<String> get listaModulos => modulos.keys.toList();
  List<String> get subModulosActuales =>
      modulos[_moduloSeleccionado] ?? <String>[];

  void seleccionarModulo(String modulo) {
    if (_moduloSeleccionado != modulo) {
      _moduloSeleccionado = modulo;
      _subModuloSeleccionado = 0;
      notifyListeners();
    }
  }

  void seleccionarSubModulo(int index) {
    if (index != _subModuloSeleccionado &&
        index < (modulos[_moduloSeleccionado]?.length ?? 0)) {
      _subModuloSeleccionado = index;
      notifyListeners();
    }
  }
}
