import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pbstation_frontend/services/usuarios_services.dart';
import 'package:pbstation_frontend/theme/theme.dart';
import 'package:pbstation_frontend/widgets/background.dart';
import 'package:pbstation_frontend/widgets/window_buttons.dart';
import 'package:provider/provider.dart';


class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          resizeToAvoidBottomInset: false,
          body: Background(),
        ),

        Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [

              const BarraW(),

              Flexible(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.rotate(
                        angle: 6.4,
                        child: Text(
                          '(Logo y nombre provisional)', 
                          style: AppTheme.subtituloSecundario.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: Colors.black45
                          ),
                          textAlign: TextAlign.center,
                          textScaler: TextScaler.linear(0.85),
                        ),
                      ),
                      Text(
                        'PBStation', 
                        style: AppTheme.subtituloSecundario.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3
                        ),
                        textAlign: TextAlign.center,
                        textScaler: TextScaler.linear(3),
                      ),
                    ],
                  ),
                )
              ),

              Flexible(
                flex: 9,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical:8.0, horizontal: 90),
                  child: LoginFields(),
                )
              ),

              Padding(
                padding: const EdgeInsets.all(12),
                child: Text('data', style: AppTheme.subtituloPrimario),
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
        color: AppTheme.azulSecundario1,
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
  final TextEditingController _codigo = TextEditingController();
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
            color: AppTheme.backgroundColor
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
            controller: _codigo,
            autofocus: true,
            style: AppTheme.textFormField, 
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: 'Usuario',
              counterText: ""
            ),
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
              child: Icon(Icons.arrow_forward_rounded, color: AppTheme.azulPrimario1,)
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

      final usuariosServices = Provider.of<UsuariosServices>(context, listen: false);
      await usuariosServices.login(_codigo.text, _psw.text);

      //await Future.delayed(const Duration(seconds: 2));

      setState(() {
        loading = false;
      });
    }
  }
}