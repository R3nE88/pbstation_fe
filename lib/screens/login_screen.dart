import 'package:flutter/material.dart';
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/screens/screens.dart';
import 'package:pbstation_frontend/services/login.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/frame_animation_widget.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;
  bool _servicesLoaded = false;

  @override
  Widget build(BuildContext context) {
    final config = Provider.of<Configuracion>(context);
    final caja = Provider.of<CajasServices>(context);
    final suc = Provider.of<SucursalesServices>(context);

    if (!config.init) config.loadConfiguracion();
    if (!caja.forLogininit) caja.initCaja();

    final isDataLoaded = config.loaded && caja.forLoginloaded;
    final needsUpdate = _esVersionMayor(
      Configuracion.lastVersion,
      Constantes.version,
    );

    return Stack(
      children: [
        // Background animado
        const Scaffold(
          resizeToAvoidBottomInset: false,
          body: AnimatedBackground(),
        ),

        // Contenido principal
        Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _BarraW(),

              // Contenido central basado en estado
              Expanded(
                child: _buildContent(
                  isLoading: _loading,
                  isDataLoaded: isDataLoaded,
                  needsUpdate: needsUpdate,
                  sucursalError: suc.sucursalError,
                ),
              ),

              const _VersionFooter(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent({
    required bool isLoading,
    required bool isDataLoaded,
    required bool needsUpdate,
    required bool sucursalError,
  }) {
    // Estado: Necesita actualización
    if (needsUpdate) {
      return _buildUpdateRequiredContent();
    }

    // Estado: Cargando servicios (animación)
    if (isLoading) {
      return _buildLoadingContent();
    }

    // Estado: Login form o cargando datos iniciales
    return _buildLoginContent(
      isDataLoaded: isDataLoaded,
      sucursalError: sucursalError,
    );
  }

  Widget _buildUpdateRequiredContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 90),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            AppTheme.isDarkTheme
                ? 'assets/images/logo_darkmode.png'
                : 'assets/images/logo_normal.png',
            height: 200,
          ),
          const SizedBox(height: 40),
          const Text(
            'Hay una version mas reciente de PrinterBoy. Es necesario actualizar el programa: (653)146-3159',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FrameAnimationWidget(
          onAnimationComplete: () {
            if (_servicesLoaded && mounted) {
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                  pageBuilder:
                      (context, animation, secondaryAnimation) =>
                          const HomeScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) => child,
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildLoginContent({
    required bool isDataLoaded,
    required bool sucursalError,
  }) {
    return Column(
      children: [
        const SizedBox(height: 25),
        Image.asset(
          AppTheme.isDarkTheme
              ? 'assets/images/logo_darkmode.png'
              : 'assets/images/logo_normal.png',
          height: 200,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 90),
            child:
                isDataLoaded
                    ? LoginFields(callback: _loadServicesAndProcess)
                    : _buildInitialLoadingState(sucursalError),
          ),
        ),
      ],
    );
  }

  Widget _buildInitialLoadingState(bool sucursalError) {
    if (sucursalError) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Error de Configuracion. Reinstale el programa o llame a soporte tecnico: (653)146-3159',
            textAlign: TextAlign.center,
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: LinearProgressIndicator(
              color: Color.fromARGB(255, 255, 191, 42),
            ),
          ),
          SizedBox(height: 70),
        ],
      );
    }

    return const Center(
      child: CircularProgressIndicator(color: AppTheme.letraClara),
    );
  }

  Future<void> _loadServicesAndProcess() async {
    setState(() => _loading = true);

    final providers = [
      () =>
          Provider.of<CajasServices>(context, listen: false).loadCortesDeCaja(),
      () =>
          Provider.of<ClientesServices>(context, listen: false).loadClientes(),
      () =>
          Provider.of<CotizacionesServices>(
            context,
            listen: false,
          ).loadCotizaciones(),
      () => Provider.of<ImpresorasServices>(
        context,
        listen: false,
      ).loadImpresoras(true),
      () =>
          Provider.of<ProductosServices>(
            context,
            listen: false,
          ).loadProductos(),
      () =>
          Provider.of<UsuariosServices>(context, listen: false).loadUsuarios(),
      () =>
          Provider.of<VentasEnviadasServices>(
            context,
            listen: false,
          ).ventasRecibidas(),
      () =>
          Provider.of<VentasServices>(
            context,
            listen: false,
          ).loadVentasDeCaja(),
      () =>
          Provider.of<VentasServices>(
            context,
            listen: false,
          ).loadVentasDeCorteActual(),
      () => Provider.of<PedidosService>(context, listen: false).loadPedidos(),
    ];

    for (final load in providers) {
      if (!mounted) return;
      await load();
    }

    _servicesLoaded = true;
  }

  bool _esVersionMayor(String versionNueva, String versionActual) {
    final partsNueva = versionNueva.split('.').map(int.parse).toList();
    final partsActual = versionActual.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      if (partsNueva[i] > partsActual[i]) return true;
      if (partsNueva[i] < partsActual[i]) return false;
    }
    return false;
  }
}

// ============================================================================
// Widgets auxiliares reutilizables
// ============================================================================

class _BarraW extends StatelessWidget {
  const _BarraW();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 35,
      decoration: BoxDecoration(color: AppTheme.secundario1),
      child: const WindowBar(overlay: false),
    );
  }
}

class _VersionFooter extends StatelessWidget {
  const _VersionFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        'PrinterBoy Punto De Venta\nv${Constantes.version}',
        style: AppTheme.subtituloPrimario.copyWith(letterSpacing: 1),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ============================================================================
// Login Form Widget
// ============================================================================

class LoginFields extends StatefulWidget {
  const LoginFields({super.key, required this.callback});

  final VoidCallback callback;

  @override
  State<LoginFields> createState() => _LoginFieldsState();
}

class _LoginFieldsState extends State<LoginFields> {
  final _email = TextEditingController();
  final _psw = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _invalid = false;

  @override
  void dispose() {
    _email.dispose();
    _psw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 35),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildTextField(
              controller: _email,
              hintText: 'Correo / Telefono',
              autofocus: true,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _psw,
              hintText: 'Contraseña',
              obscureText: true,
            ),
            SizedBox(
              height: 25,
              child: Text(
                _invalid ? '¡Credenciales Invalidas!' : '',
                style: AppTheme.tituloClaro,
              ),
            ),
            _buildLoginButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool autofocus = false,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      obscureText: obscureText,
      style: AppTheme.textFormField,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        alignLabelWithHint: true,
        hintText: hintText,
        counterText: '',
        errorStyle: const TextStyle(fontSize: 0, height: 0),
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator:
          (value) =>
              (value == null || value.isEmpty) ? 'Campo obligatorio' : null,
      onFieldSubmitted: (_) => _validar(),
    );
  }

  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: _validar,
      child: Container(
        height: 35,
        width: 35,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.arrow_forward_rounded, color: AppTheme.primario1),
      ),
    );
  }

  Future<void> _validar() async {
    final valid = await _verificarAcceso();
    setState(() => _invalid = !valid);
    if (valid) widget.callback();
  }

  Future<bool> _verificarAcceso() async {
    if (_formKey.currentState!.validate()) {
      final login = Login();
      return await login.login(_email.text, _psw.text);
    }
    return false;
  }
}
