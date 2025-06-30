import 'package:flutter/material.dart';

class Loading{

  static void displaySpinLoading(BuildContext context){
    showDialog(
      barrierDismissible: true,
      context: context, 
      builder: (context){    
        return PopScope(
          canPop: false,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }
    );
  }

}