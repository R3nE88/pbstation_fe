import 'package:flutter/material.dart';

class Loading{
  void displaySpinLoading(BuildContext context){
    showDialog(
      barrierDismissible: true,
      context: context, 
      builder: (context){    
        return PopScope(
          canPop: false,
          child: Center(
            child: CircularProgressIndicator(
            ),
          ),
        );
      }
    );
  }

  void loadingCodigo(BuildContext context){
    showDialog(
      barrierDismissible: true,
      context: context, 
      builder: (context){    
        
        return PopScope(
          canPop: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [ 
                //const SizedBox(height: 8),
                CircularProgressIndicator(),
                const SizedBox(height: 8),
                const Text('generando'),
                const Text('codigo de acceso'),
              ],
            ),
          ),
        );
      }
    );
  }

  void loadingQRs(BuildContext context, String cantidad){
    showDialog(
      barrierDismissible: true,
      context: context, 
      builder: (context){    
        
        return PopScope(
          canPop: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [ 
                const Text('Generando todos los códigos QR necesarios.'),

                const SizedBox(height: 8),

                CircularProgressIndicator(),
                
                const SizedBox(height: 8),
                
                const Text('Por favor tenga paciencia, esto puedo demorar algunos minutos.'),

                const SizedBox(height: 4),

                const Text('Puedes verificar en la carpeta asignada como se están creando los QR.', style: TextStyle(
                  fontSize: 12,
                  color:  Color.fromARGB(255, 213, 213, 213),
                )),
              ],
            ),
          ),
        );
      }
    );
  }
}