import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:pbstation_frontend/constantes.dart';
import 'package:pbstation_frontend/screens/screens.dart';
import 'package:pbstation_frontend/services/login.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
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
      await Provider.of<ClientesServices>(context, listen: false).loadClientes();
      await Provider.of<CotizacionesServices>(context, listen: false).loadCotizaciones();
      await Provider.of<ImpresorasServices>(context, listen: false).loadImpresoras(true);
      await Provider.of<ProductosServices>(context, listen: false).loadProductos();
      await Provider.of<UsuariosServices>(context, listen: false).loadUsuarios();
      await Provider.of<VentasEnviadasServices>(context, listen: false).ventasRecibidas();
      await Provider.of<VentasServices>(context, listen: false).loadVentasDeCaja();
      await Provider.of<VentasServices>(context, listen: false).loadVentasDeCorteActual();

      //Cargar Home Screen
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
        ),
      );
    }

    return Stack(
      children: [
        Scaffold(
          resizeToAvoidBottomInset: false,
          body: Background(),
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
                       
                      callbackLoading: (value) {
                        setState(() { _loading = value; });
                      },
                    ) 
                    :  SizedBox(
                      height: double.infinity,
                      child: suc.sucursalError ?
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error de Configuracion. Reinstale el programa o llame a soporte tecnico: (653)146-3159', textAlign: TextAlign.center),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: LinearProgressIndicator(
                                color: const Color.fromARGB(255, 255, 191, 42)
                              ),
                            ),
                            SizedBox(height: 70)
                          ],
                        )
                       : Center(
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
                    style: AppTheme.subtituloConstraste.copyWith(
                      letterSpacing: 1
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              ],
            ),
          ),
        ),
        
        _loading ?
        Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              const BarraW(),

              Center(
                child: SizedBox(
                  width: 350,
                  child: Image.asset(
                    'assets/loading.gif',
                  ),
                ),
              ),

              const SizedBox(height: 20),
              
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'PrinterBoy Punto De Venta\nv${Constantes.version}', 
                  style: AppTheme.subtituloConstraste.copyWith(
                    letterSpacing: 1
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            ],
          ),
        ) : const SizedBox()
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
      child: WindowTitleBarBox(
        child: Row(
          children: [
            Expanded(child: MoveWindow()),
            WindowButtons()
          ],
        ),
      ),
    );
  }
}

class LoginFields extends StatefulWidget {
  const LoginFields({
    super.key, 
    required this.callback, 
    required this.callbackLoading,
  });
  
  final Function callback;
  final Function(bool) callbackLoading;

  @override
  State<LoginFields> createState() => _LoginFieldsState();
}

class _LoginFieldsState extends State<LoginFields> {
  final _email = TextEditingController();
  final _psw = TextEditingController();
  final _formKey = GlobalKey<FormState>(); 
  //bool _loading = false;
  bool _invalid = false;

  @override
  void dispose() {
    _email.dispose();
    _psw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /*if (_loading == true) {
      return SizedBox(
        height: double.infinity,
        child: Center(
          child: Transform.translate(
            offset: Offset(0, -50),
            child: CircularProgressIndicator(
              color: AppTheme.letraClara
            ),
          ),
        ),
      );
    }*/

    return Padding(
      padding: const EdgeInsets.only(top: 35),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            TextFormField(
              controller: _email,
              autofocus: true,
              style: AppTheme.textFormField, 
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                alignLabelWithHint: false,
                hintText: 'Correo / Telefono',
                counterText: "",
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
                counterText: "",
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
      widget.callbackLoading(true);

      await Future.delayed(const Duration(milliseconds: 350));

      final login = Login();
      bool success = await login.login(_email.text, _psw.text);

      if (success) {
        widget.callbackLoading(false);
        return true;
      } else {
        widget.callbackLoading(false);
        return false;
      }
    }
    return false;
  }
}