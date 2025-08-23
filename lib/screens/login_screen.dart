import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:pbstation_frontend/screens/screens.dart';
import 'package:pbstation_frontend/services/login.dart';
import 'package:pbstation_frontend/services/services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/widgets.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = Provider.of<Configuracion>(context);
    final caja = Provider.of<CajasServices>(context);
    bool loaded = false;

    if (config.init == false){
      config.loadConfiguracion();
      Provider.of<SucursalesServices>(context, listen: false); //Eejcutar constructor de sucursalesServices
    }
    if (caja.init == false){
      caja.initCaja();
    }

    if (config.loaded && caja.loaded){
      loaded = true;
    }

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
                child: Image.asset(
                  AppTheme.isDarkTheme ? 'assets/images/logo_darkmode.png' : 'assets/images/logo_normal.png',
                  height: 200,
                )
              ),

              Flexible(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical:8.0, horizontal: 90),
                  child: loaded
                  ? LoginFields() 
                  :  SizedBox(
                    height: double.infinity,
                    child: Center(
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
                  'PrinterBoy Punto De Venta\nv0.0001', 
                  style: AppTheme.subtituloConstraste.copyWith(
                    letterSpacing: 1
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            ],
          ),
        )
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
  });

  @override
  State<LoginFields> createState() => _LoginFieldsState();
}

class _LoginFieldsState extends State<LoginFields> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _psw = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); 
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    if (loading == true) {
      return SizedBox(
        height: double.infinity,
        child: Center(
          child: CircularProgressIndicator(
            color: AppTheme.letraClara
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextFormField(
            controller: _email,
            autofocus: true,
            style: AppTheme.textFormField, 
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: 'Correo / Telefono',
              counterText: ""
            ),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value){
              if (value == null || value.isEmpty) {
                return 'Campo obligatorio';
              }
              return null;
            },
          ),
    
          Container(
            height: 15,
          ),
    
          TextFormField(
            controller: _psw,
            style: AppTheme.textFormField, 
            textAlign: TextAlign.center,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Contraseña',
              counterText: ""
            ),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value){
              if (value == null || value.isEmpty) {
                return 'Campo obligatorio';
              }
              return null;
            },
            onFieldSubmitted: (value) {
              verificarAcceso();
            },
          ),

          SizedBox(
            height: 15,
          ),

          GestureDetector(
            onTap: (){
              verificarAcceso();
            },
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

          SizedBox(
            height: 90,
          ),
        ],
      ),
    );
  }

  void verificarAcceso() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        loading = true;
      });

      final login = Login();
      bool success = await login.login(_email.text, _psw.text);

      if (success && mounted) {
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

      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }
}