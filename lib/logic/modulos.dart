import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/screens/screens.dart';
import 'package:pbstation_frontend/theme/theme.dart';

// ============================================================================
// SUBMÓDULO - Representa una pantalla individual del sistema
// ============================================================================
class SubModulo {
  final String nombre;
  final IconData icono;
  final Widget pantalla;
  final Set<Permiso> permisosRequeridos;
  final Set<TipoUsuario> tiposPermitidos;
  final bool onlyCaja;

  const SubModulo({
    required this.nombre,
    required this.icono,
    required this.pantalla,
    this.permisosRequeridos = const {},
    this.tiposPermitidos = const {},
    this.onlyCaja = false,
  });

  /// Verifica si el usuario puede ACCEDER (usar) este submódulo
  bool puedeAcceder({
    required Permiso permiso,
    required TipoUsuario tipoUsuario,
    required bool esCaja,
  }) {
    // Si es admin, tiene acceso absoluto a todo excepto la restricción "onlyCaja".
    if (permiso == Permiso.admin) {
      // Si el submódulo es exclusivo para cajas y esta estación NO es caja -> prohibido.
      if (onlyCaja && !esCaja) return false;
      return true;
    }

    // 1. Verificar tipo de usuario permitido
    if (tiposPermitidos.isNotEmpty && !tiposPermitidos.contains(tipoUsuario)) {
      return false;
    }

    // 2. Verificar permisos requeridos (jerarquía: normal < elevado < admin)
    if (permisosRequeridos.isNotEmpty &&
        !permisosRequeridos.any((req) => permiso.tieneAlMenos(req))) {
      return false;
    }

    // 3. Verificar restricción de caja (onlyCaja = solo para estaciones de caja)
    if (onlyCaja && !esCaja) {
      return false;
    }

    return true;
  }

  /// Verifica si debe MOSTRARSE en el menú (siempre true para mostrar todos)
  bool debeMostrarse({required TipoUsuario tipoUsuario}) => true;
}

// ============================================================================
// MÓDULO - Representa un grupo de submódulos en el menú principal
// ============================================================================
class Modulo {
  final String nombre;
  final IconData iconoPrincipal;
  final List<SubModulo> subModulos;
  final Set<TipoUsuario> tiposPermitidos;

  const Modulo({
    required this.nombre,
    required this.iconoPrincipal,
    required this.subModulos,
    this.tiposPermitidos = const {},
  });

  /// Obtiene submódulos ACCESIBLES (para PageView de pantallas)
  List<SubModulo> getSubModulosPermitidos({
    required Permiso permiso,
    required TipoUsuario tipoUsuario,
    required bool esCaja,
  }) {
    return subModulos
        .where((sub) => sub.puedeAcceder(
              permiso: permiso,
              tipoUsuario: tipoUsuario,
              esCaja: esCaja,
            ))
        .toList();
  }

  bool debesMostrar(TipoUsuario tipoUsuario, {Permiso? permiso}) {
    // Admin ve todo
    if (permiso == Permiso.admin) return true;

    return tiposPermitidos.isEmpty || tiposPermitidos.contains(tipoUsuario);
  }

  /// Obtiene submódulos VISIBLES (para menú, incluye bloqueados)
  List<SubModulo> getSubModulosVisibles({
    required TipoUsuario tipoUsuario,
    Permiso? permiso,
  }) {
    return subModulos.where((sub) {
      // Si es admin, muestro todo
      if (permiso == Permiso.admin) return true;
      return sub.debeMostrarse(tipoUsuario: tipoUsuario);
    }).toList();
  }
}

// ============================================================================
// CONFIGURACIÓN CENTRAL - Define todos los módulos del sistema
// ============================================================================
class ConfiguracionModulos {
  static final List<Modulo> todosLosModulos = [
    // VENTA
    const Modulo(
      nombre: 'venta',
      iconoPrincipal: Icons.attach_money,
      tiposPermitidos: {TipoUsuario.vendedor, TipoUsuario.administrativo},
      subModulos: [
        SubModulo(
          nombre: 'venta',
          icono: Icons.attach_money,
          pantalla: VentaScreen(),
          tiposPermitidos: {TipoUsuario.vendedor, TipoUsuario.administrativo},
        ),
        SubModulo(
          nombre: 'caja',
          icono: Icons.point_of_sale,
          pantalla: CajaScreen(),
          tiposPermitidos: {TipoUsuario.vendedor, TipoUsuario.administrativo},
          onlyCaja: true,
        ),
        SubModulo(
          nombre: 'historial\nde cajas',
          icono: Icons.history,
          pantalla: HistorialDeCajas(),
          permisosRequeridos: {Permiso.elevado},
        ),
        SubModulo(
          nombre: 'adeudos',
          icono: Icons.payments,
          pantalla: AdeudosSCreen(),
        ),
      ],
    ),

    // CATÁLOGO
    const Modulo(
      nombre: 'catalogo',
      iconoPrincipal: Icons.menu_book,
      subModulos: [
        SubModulo(
          nombre: 'productos y\nservicios',
          icono: Icons.design_services,
          pantalla: ProductosScreen(),
        ),
        SubModulo(
          nombre: 'equipo',
          icono: Icons.supervised_user_circle_sharp,
          pantalla: UsuariosScreen(),
          permisosRequeridos: {Permiso.elevado},
        ),
        SubModulo(
          nombre: 'clientes',
          icono: Icons.people,
          pantalla: ClientesScreen(),
        ),
        SubModulo(
          nombre: 'sucursales',
          icono: Icons.house_siding,
          pantalla: SucursalesScreen(),
        ),
      ],
    ),

    // COTIZACIONES
    const Modulo(
      nombre: 'cotizaciones',
      iconoPrincipal: Icons.request_quote,
      tiposPermitidos: {TipoUsuario.vendedor, TipoUsuario.administrativo},
      subModulos: [
        SubModulo(
          nombre: 'cotizaciones',
          icono: Icons.request_quote,
          pantalla: PantallaEnDesarrollo(),
        ),
      ],
    ),

    // INVENTARIO
    const Modulo(
      nombre: 'inventario',
      iconoPrincipal: Icons.inventory_2_outlined,
      tiposPermitidos: {
        TipoUsuario.vendedor,
        TipoUsuario.administrativo,
        TipoUsuario.bodega
      },
      subModulos: [
        SubModulo(
          nombre: 'inventario',
          icono: Icons.inventory_2_outlined,
          pantalla: PantallaEnDesarrollo(),
        ),
      ],
    ),

    // IMPRESORAS
    const Modulo(
      nombre: 'impresoras',
      iconoPrincipal: Icons.print,
      tiposPermitidos: {TipoUsuario.vendedor, TipoUsuario.administrativo},
      subModulos: [
        SubModulo(
          nombre: 'impresoras',
          icono: Icons.print,
          pantalla: ImpresorasScreen(),
        ),
      ],
    ),

    // PEDIDOS
    const Modulo(
      nombre: 'pedidos',
      iconoPrincipal: Icons.receipt_long_outlined,
      tiposPermitidos: {
        TipoUsuario.vendedor,
        TipoUsuario.administrativo,
        TipoUsuario.maquilador
      },
      subModulos: [
        SubModulo(
          nombre: 'pedidos',
          icono: Icons.receipt_long_outlined,
          pantalla: PedidosScreen(),
          tiposPermitidos: {TipoUsuario.vendedor, TipoUsuario.administrativo},
        ),
        SubModulo(
          nombre: 'produccion',
          icono: Icons.production_quantity_limits,
          pantalla: ProduccionScreen(),
          tiposPermitidos: {TipoUsuario.maquilador},
        ),
        SubModulo(
          nombre: 'historial',
          icono: Icons.history,
          pantalla: PantallaEnDesarrollo(),
          tiposPermitidos: {TipoUsuario.maquilador, TipoUsuario.administrativo},
          permisosRequeridos: {Permiso.elevado},
        ),
      ],
    ),

    // REPORTES
    const Modulo(
      nombre: 'reportes',
      iconoPrincipal: Icons.list_alt,
      tiposPermitidos: {TipoUsuario.administrativo},
      subModulos: [
        SubModulo(
          nombre: 'reportes',
          icono: Icons.list_alt,
          pantalla: PantallaEnDesarrollo(),
        ),
      ],
    ),

    // PREFERENCIAS
    const Modulo(
      nombre: 'preferencias',
      iconoPrincipal: Icons.settings,
      subModulos: [
        SubModulo(
          nombre: 'preferencias',
          icono: Icons.settings,
          pantalla: SettingsScreen(),
        ),
      ],
    ),
  ];

  /// Filtra módulos por tipo de usuario
  static List<Modulo> obtenerModulosParaUsuario(
    TipoUsuario tipoUsuario, {
    Permiso? permiso,
  }) {
    return todosLosModulos
        .where((modulo) => modulo.debesMostrar(tipoUsuario, permiso: permiso))
        .toList();
  }
}

// ============================================================================
// CONTEXTO DEL USUARIO - Información del usuario logueado
// ============================================================================
class ContextoUsuario {
  final Permiso permiso;
  final TipoUsuario tipoUsuario;
  final bool esCaja;

  const ContextoUsuario({
    required this.permiso,
    required this.tipoUsuario,
    required this.esCaja,
  });

  /// Crea contexto desde los datos de Login
  factory ContextoUsuario.desdeLogin({
    required Permiso permiso,
    required TipoUsuario tipoUsuario,
    required bool esCaja,
  }) {
    return ContextoUsuario(
      permiso: permiso,
      tipoUsuario: tipoUsuario,
      esCaja: esCaja,
    );
  }
}

// ============================================================================
// GESTOR DE MÓDULOS - Lógica central del sistema de navegación
// ============================================================================
class GestorModulos {
  final ContextoUsuario contexto;
  late final List<Modulo> modulosDisponibles;

  GestorModulos(this.contexto) {
    modulosDisponibles = ConfiguracionModulos.obtenerModulosParaUsuario(
      contexto.tipoUsuario,
      permiso: contexto.permiso,
    );
  }

  /// Módulos accesibles para el usuario actual
  List<Modulo> get modulos => modulosDisponibles;

  /// Todos los módulos del sistema (sin filtrar)
  List<Modulo> get todosLosModulos => ConfiguracionModulos.todosLosModulos;

  /// Verifica si un módulo está bloqueado
  bool moduloBloqueado(Modulo modulo) =>
    !modulo.debesMostrar(contexto.tipoUsuario, permiso: contexto.permiso);

  /// Submódulos ACCESIBLES de un módulo (para PageView)
  List<SubModulo> getSubModulos(String nombreModulo) {
    final modulo = _buscarModulo(nombreModulo);
    return modulo.getSubModulosPermitidos(
      permiso: contexto.permiso,
      tipoUsuario: contexto.tipoUsuario,
      esCaja: contexto.esCaja,
    );
  }

  /// Submódulos VISIBLES de un módulo (para menú con candados)
  List<SubModulo> getSubModulosVisibles(String nombreModulo) {
    final modulo = _buscarModulo(nombreModulo);
    return modulo.getSubModulosVisibles(
      tipoUsuario: contexto.tipoUsuario,
      permiso: contexto.permiso,
    );
  }

  /// Verifica si un submódulo está bloqueado
  bool estaBloqueado(SubModulo subModulo) {
    return !subModulo.puedeAcceder(
      permiso: contexto.permiso,
      tipoUsuario: contexto.tipoUsuario,
      esCaja: contexto.esCaja,
    );
  }

  /// Verifica si puede acceder a un submódulo por nombre
  bool puedeAccederSubModulo(String nombreModulo, String nombreSubModulo) {
    try {
      final subModulos = getSubModulos(nombreModulo);
      return subModulos.any((sub) => sub.nombre == nombreSubModulo);
    } catch (e) {
      return false;
    }
  }

  /// Busca un módulo en los disponibles (helper privado)
  Modulo _buscarModulo(String nombreModulo) {
    return modulosDisponibles.firstWhere(
      (m) => m.nombre == nombreModulo,
      orElse: () => throw Exception('Módulo "$nombreModulo" no encontrado'),
    );
  }
}

// ============================================================================
// PANTALLA EN DESARROLLO - Placeholder para pantallas incompletas
// ============================================================================
class PantallaEnDesarrollo extends StatelessWidget {
  const PantallaEnDesarrollo({super.key});

  static const List<String> _mensajes = [
    'En construcción... favor de no alimentar al programador ⚠️.',
    'Pantalla en construcción... nuestros duendes programadores están en huelga,\nregresamos pronto 🏗️.',
    'Aquí debería haber algo increíble... pero todavía estoy picando código ⌨️.',
    'Pantalla en desarrollo 🚧. No la mires mucho, se pone nerviosa 😅.',
    'Cuando acabe esta pantalla será épico, solo dame una CocaCola más 🥤 y un\npar de líneas de código 💻.',
    'Pantalla en mantenimiento: actualmente luchando contra un bug nivel jefe final 🐞.',
    'Estamos entrenando a un mono para programar esta parte 🐒⌨️, paciencia...',
    'Construyendo esta pantalla con cinta adhesiva y esperanza ✂️✨.',
    'Error temporal en esta pantalla: falta pizza para seguir programando 🍕🔥.',
    '¡Próximamente aquí: una pantalla que sí funcione! 🎬🚀',
    'Pantalla en reparación... con cinta, pegamento y buena fe 🛠️💡.',
    'Estamos trabajando en esta pantalla… aunque parezca que no 👀.',
    'Aún en progreso… como hornear un pastel, no se puede apurar 🎂⏳.',
  ];

  String get _mensajeAleatorio =>
      _mensajes[Random().nextInt(_mensajes.length)];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.isDarkTheme
              ? Colors.white10
              : const Color.fromARGB(14, 0, 0, 0),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Text(
          _mensajeAleatorio,
          style: TextStyle(
            color: AppTheme.colorContraste,
            fontWeight: FontWeight.w400,
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}