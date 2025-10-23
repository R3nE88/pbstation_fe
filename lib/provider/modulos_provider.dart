import 'package:flutter/foundation.dart';
import 'package:pbstation_frontend/logic/modulos.dart';

class ModulosProvider extends ChangeNotifier {
  final GestorModulos _gestor;
  String _moduloSeleccionado;
  int _subModuloSeleccionado;

  ModulosProvider({
    required ContextoUsuario contextoUsuario,
    String moduloInicial = '',
    int subModuloInicial = 0,
  })  : _gestor = GestorModulos(contextoUsuario),
        _moduloSeleccionado = moduloInicial,
        _subModuloSeleccionado = subModuloInicial {
    // Si no hay módulo inicial, seleccionar el primero disponible
    if (_moduloSeleccionado.isEmpty && _gestor.modulos.isNotEmpty) {
      _moduloSeleccionado = _gestor.modulos.first.nombre;
    }
  }

  // Getters
  String get moduloSeleccionado => _moduloSeleccionado;
  int get subModuloSeleccionado => _subModuloSeleccionado;

  // Obtiene lista de nombres de módulos
  List<String> get listaModulos =>
      _gestor.modulos.map((m) => m.nombre).toList();

  // Obtiene los submódulos del módulo actual
  List<SubModulo> get subModulosActuales {
    if (_moduloSeleccionado.isEmpty) return [];
    return _gestor.getSubModulos(_moduloSeleccionado);
  }

  List<SubModulo> get subModulosVisibles {
    if (_moduloSeleccionado.isEmpty) return [];
    return _gestor.getSubModulosVisibles(_moduloSeleccionado);
  }

  // Obtiene el módulo actual completo
  Modulo? get moduloActual {
    return _gestor.modulos.firstWhere(
      (m) => m.nombre == _moduloSeleccionado,
      orElse: () => _gestor.modulos.first,
    );
  }

  // Obtiene el submódulo actual
  SubModulo? get subModuloActual {
    final subs = subModulosActuales;
    if (_subModuloSeleccionado < subs.length) {
      return subs[_subModuloSeleccionado];
    }
    return null;
  }

  // Selecciona un módulo por nombre
  void seleccionarModulo(String nombreModulo) {
    if (_moduloSeleccionado != nombreModulo) {
      _moduloSeleccionado = nombreModulo;
      _subModuloSeleccionado = 0; // Reset al primer submódulo
      notifyListeners();
    }
  }

  // Selecciona un submódulo por índice
  void seleccionarSubModulo(int index) {
    final subModulos = subModulosActuales;
    
    if (index != _subModuloSeleccionado && index >= 0 && index < subModulos.length) {
      _subModuloSeleccionado = index;
      notifyListeners();
    }
  }

  // Selecciona un submódulo por nombre
  void seleccionarSubModuloPorNombre(String nombreSubModulo) {
    final subModulos = subModulosActuales;
    final index = subModulos.indexWhere((sub) => sub.nombre == nombreSubModulo);
    
    if (index != -1) {
      seleccionarSubModulo(index);
    }
  }

  bool estaBloqueado(SubModulo subModulo) {
    return _gestor.estaBloqueado(subModulo);
  }

  // Verifica si se puede acceder a un submódulo específico
  bool puedeAccederSubModulo(String nombreSubModulo) {
    return subModulosActuales.any((sub) => sub.nombre == nombreSubModulo);
  }

  // Obtiene el gestor para acceso directo si se necesita
  GestorModulos get gestor => _gestor;

  List<Modulo> get todosLosModulos => _gestor.todosLosModulos;
  bool moduloBloqueado(Modulo modulo) {
    return _gestor.moduloBloqueado(modulo);
  }
}