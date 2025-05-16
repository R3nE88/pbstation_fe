import 'package:flutter/material.dart';

class AppTheme{
  static final Color azulPrimario1 = const Color.fromARGB(255, 78, 175, 255);
  static final Color azulSecundario1 = const Color.fromARGB(255, 54, 134, 233);
  static final Color azulPrimario2 = const Color.fromARGB(255, 93, 182, 255);
  static final Color azulSecundario2 = const Color.fromARGB(255, 5, 77, 186);
  static final Color backgroundColor = const Color.fromARGB(255, 231, 229, 229);

  static final ThemeData customTheme = ThemeData.light().copyWith(
    dialogTheme: DialogTheme(
      surfaceTintColor: Colors.transparent
    ),
     
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.azulSecundario1, // button text color
      ),
    ),

    textTheme: ThemeData.light().textTheme.copyWith(
      bodyLarge: const TextStyle(color: Colors.black),
      bodyMedium: const TextStyle(color: Colors.black),
      bodySmall: const TextStyle(color: Colors.black),
      titleLarge: const TextStyle(color: Colors.black),
      titleMedium: const TextStyle(color: Colors.black),
      titleSmall: const TextStyle(color: Colors.black),
      labelLarge: const TextStyle(color: Colors.black),
      labelMedium: const TextStyle(color: Colors.black),
      labelSmall: const TextStyle(color: Colors.black),
      displayLarge: const TextStyle(color: Colors.black),
      displayMedium: const TextStyle(color: Colors.black),
      displaySmall: const TextStyle(color: Colors.black),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.white
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: azulPrimario1, 
        backgroundColor: Colors.white, //Colors letras
        shape: const StadiumBorder(),
        elevation: 1,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.5
        )
      )
    ),

    inputDecorationTheme: InputDecorationTheme(
      floatingLabelStyle: TextStyle(color: Colors.white, fontSize: 15),

      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
        borderRadius: const BorderRadius.all(Radius.circular(30))
      ),

      disabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
        borderRadius: const BorderRadius.all(Radius.circular(30))
      ),

      hintStyle: const TextStyle(
        color: Color.fromARGB(255, 209, 240, 255),
        fontSize: 15,
      ),

      labelStyle: const TextStyle(
        color: Color.fromARGB(255, 209, 240, 255),
        fontSize: 15,
      ),

      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color.fromARGB(255, 211, 224, 233)),
        borderRadius: BorderRadius.all(Radius.circular(30)),
      ),

      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color.fromARGB(255, 248, 14, 14)),
        borderRadius: BorderRadius.all(Radius.circular(30))
      ),

      focusedErrorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color.fromARGB(255, 248, 14, 14)),
        borderRadius: BorderRadius.all(Radius.circular(30))
      ),

      filled: true,

      fillColor: const Color.fromARGB(33, 255, 255, 255),

      alignLabelWithHint: true,
    )
  );
}