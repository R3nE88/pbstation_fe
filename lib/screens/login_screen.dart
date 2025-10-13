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
    bool _loaded = false;
    bool _servicesLoaded = false;

  @override
  Widget build(BuildContext context) {
    final config = Provider.of<Configuracion>(context);
    final caja = Provider.of<CajasServices>(context);
    final suc = Provider.of<SucursalesServices>(context);

    if (config.init == false){ config.loadConfiguracion(); }
    if (caja.forLogininit == false){ caja.initCaja(); }
    if (config.loaded && caja.forLoginloaded){ _loaded = true; }

    Future<void> loadServicesAndProcess() async{
      setState(() { _loading = true; });
      await Provider.of<CajasServices>(context, listen:  false).loadCortesDeCaja();
      if (!context.mounted) return;
      await Provider.of<ClientesServices>(context, listen: false).loadClientes();
      if (!context.mounted) return;
      await Provider.of<CotizacionesServices>(context, listen: false).loadCotizaciones();
      if (!context.mounted) return;
      await Provider.of<ImpresorasServices>(context, listen: false).loadImpresoras(true);
      if (!context.mounted) return;
      await Provider.of<ProductosServices>(context, listen: false).loadProductos();
      if (!context.mounted) return;
      await Provider.of<UsuariosServices>(context, listen: false).loadUsuarios();
      if (!context.mounted) return;
      await Provider.of<VentasEnviadasServices>(context, listen: false).ventasRecibidas();
      if (!context.mounted) return;
      await Provider.of<VentasServices>(context, listen: false).loadVentasDeCaja();
      if (!context.mounted) return;
      await Provider.of<VentasServices>(context, listen: false).loadVentasDeCorteActual();
      _servicesLoaded = true;      
    }

    bool esVersionMayor(String versionNueva, String versionActual) {
      List<int> partsNueva = versionNueva.split('.').map(int.parse).toList();
      List<int> partsActual = versionActual.split('.').map(int.parse).toList();
      
      for (int i = 0; i < 3; i++) {
        if (partsNueva[i] > partsActual[i]) {
          return true;
        } else if (partsNueva[i] < partsActual[i]) {
          return false;
        }
      }
      return false; // Son iguales
    }

    if (esVersionMayor(Configuracion.lastVersion, Constantes.version)) {
      return Stack(
        children: [
          
          Scaffold(
            resizeToAvoidBottomInset: false,
            body: Background(),
          ),

          Scaffold(
            backgroundColor: Colors.transparent,
            body: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const BarraW(),
          
                Flexible(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 25),
                    child: Image.asset(
                      AppTheme.isDarkTheme ? 'assets/images/logo_darkmode.png' : 'assets/images/logo_normal.png',
                      height: 200,
                    ),
                  )
                ),
          
                const Flexible(
                  flex: 6,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 90),
                    child: SizedBox(
                      height: double.infinity,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Hay una version mas reciente de PrinterBoy. Es necesario actualizar el programa: (653)146-3159', textAlign: TextAlign.center),
                          SizedBox(height: 70)
                        ],
                      )
                    ),
                  ),
                ),
                
                
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'PrinterBoy Punto De Venta\nv${Constantes.version}', 
                    style: AppTheme.subtituloPrimario.copyWith(
                      letterSpacing: 1
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              ],
            ),
          )
        ],
      );
    }

    return Stack(
      children: [
        Scaffold(
          resizeToAvoidBottomInset: false,
          body: Background(),
        ),

        Visibility(
          visible: _loading,
          maintainState: true,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
          
                const BarraW(),

                FrameAnimationWidget(
                  onAnimationComplete: () {
                    if (_servicesLoaded){
                      //Cargar Home Screen
                      if (!context.mounted) return;
                      Navigator.of(context).pushReplacement(
                        PageRouteBuilder(
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            return child;
                          },
                        ),
                      );
                    }
                  },
                ),               
          
                const SizedBox(height: 20),
                
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'PrinterBoy Punto De Venta\nv${Constantes.version}', 
                    style: AppTheme.subtituloPrimario.copyWith(
                      letterSpacing: 1
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              ],
            ),
          ),
        ),

        Visibility(
          visible: !_loading,
          maintainState: true,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
          
                const BarraW(),
          
                Flexible(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 25),
                    child: Image.asset(
                      AppTheme.isDarkTheme ? 'assets/images/logo_darkmode.png' : 'assets/images/logo_normal.png',
                      height: 200,
                    ),
                  )
                ),
          
                Flexible(
                  flex: 6,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 90),
                    child: _loaded
                    ? LoginFields(
                      callback: ()=> loadServicesAndProcess(),
                    ) 
                    :  SizedBox(
                      height: double.infinity,
                      child: suc.sucursalError ?
                        const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error de Configuracion. Reinstale el programa o llame a soporte tecnico: (653)146-3159', textAlign: TextAlign.center),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: LinearProgressIndicator(
                                color: Color.fromARGB(255, 255, 191, 42)
                              ),
                            ),
                            SizedBox(height: 70)
                          ],
                        )
                       : const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.letraClara
                        ),
                      ),
                    ),
                  )
                ),
                
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'PrinterBoy Punto De Venta\nv${Constantes.version}', 
                    style: AppTheme.subtituloPrimario.copyWith(
                      letterSpacing: 1
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              ],
            ),
          ),
        ),   
      
        
      ],
    );
  }
}

class BarraW extends StatelessWidget {
  const BarraW({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 35,
      decoration: BoxDecoration(
        color: AppTheme.secundario1,
      ),
      child: const WindowBar(overlay: false)
    );
  }
}

class LoginFields extends StatefulWidget {
  const LoginFields({
    super.key, 
    required this.callback, 
  });
  
  final Function callback;

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
            TextFormField(
              controller: _email,
              autofocus: true,
              style: AppTheme.textFormField, 
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                alignLabelWithHint: false,
                hintText: 'Correo / Telefono',
                counterText: '',
                  errorStyle: TextStyle(
                  fontSize: 0,
                  height: 0,
                ),
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value){
                if (value == null || value.isEmpty) {
                  return 'Campo obligatorio';
                }
                return null;
              },
              onFieldSubmitted: (value) => validar(),
            ),
      
            Container( height: 15),
      
            TextFormField(
              controller: _psw,
              style: AppTheme.textFormField, 
              textAlign: TextAlign.center,
              obscureText: true,
              decoration: const InputDecoration(
                alignLabelWithHint: true,
                hintText: 'Contraseña',
                counterText: '',
                  errorStyle: TextStyle(
                  fontSize: 0,
                  height: 0,
                ),
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value){
                if (value == null || value.isEmpty) {
                  return 'Campo obligatorio';
                }
                return null;
              },
              onFieldSubmitted: (value) => validar(),
            ),
      
            SizedBox(
              height: 25, 
              child: Text(_invalid ? '¡Credenciales Invalidas!' : '', style: AppTheme.tituloClaro)
            ),
            
            GestureDetector(
              onTap: () => validar(),
              child: Container(
                height: 35,
                width: 35,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_forward_rounded, color: AppTheme.primario1,)
              ),
            ),
          ],
        ),
      ),
    );
  }

  void validar() async{
    bool valid = await verificarAcceso();
    setState(() { _invalid = !valid; });
    if (valid) widget.callback();
  }

  Future<bool> verificarAcceso() async {
    if (_formKey.currentState!.validate()) {
      final login = Login();
      bool success = await login.login(_email.text, _psw.text);
      if (success) { return true;
      } else { return false; }
    }
    return false;
  }
}