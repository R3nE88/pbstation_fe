import 'package:flutter/material.dart';
import '../provider/change_theme_provider.dart';

class AppTheme{
  static ChangeTheme? changeThemeInstance;

  static void initialize(ChangeTheme instance) {
    changeThemeInstance = instance;
  }

  static final Color letraClara = Colors.white;
  static final Color letraOscura = Colors.black;
  static final Color letra70 = Colors.white70;

  static Color get primario1 => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(255, 60, 60, 60)
      : const Color.fromARGB(255, 78, 175, 255);
  static Color get secundario1 => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(255, 19, 19, 19)
      : const Color.fromARGB(255, 54, 134, 233);
  static Color get primario2 => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(255, 52, 52, 52)
      : const Color.fromARGB(255, 93, 182, 255);
  static Color get secundario2 => changeThemeInstance?.isDarkTheme == true
      ? Colors.black
      : const Color.fromARGB(255, 5, 77, 186);

  static Color get backgroundColor => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(255, 30, 30, 30)
      : const Color.fromARGB(255, 231, 229, 229);
  static Color get backgroundWidgetColor1 => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(255, 50, 50, 50)
      : const Color.fromARGB(255, 227, 247, 255);
  static Color get backgroundWidgetColor2 => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(255, 40, 40, 40)
      : const Color.fromARGB(255, 160, 201, 255);
  static Color get backgroundWidgetColor3 => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(123, 20, 20, 20)
      : const Color.fromARGB(123, 32, 103, 255);
  static Color get backgroundWidgetColor4 => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(167, 60, 60, 60)
      : const Color.fromARGB(167, 73, 158, 255);

  static Color get backgroundWidgetFormColor1 => changeThemeInstance?.isDarkTheme == true
      ? Color.fromARGB(0, 195, 195, 195)
      : Color.fromARGB(30, 99, 180, 255);
  static Color get backgroundWidgetFormColor2 => changeThemeInstance?.isDarkTheme == true
      ? Color.fromARGB(53, 0, 0, 0)
      : Color.fromARGB(123, 32, 103, 255);
  static Color get backgroundWidgetFormColor3 => changeThemeInstance?.isDarkTheme == true
      ? Color.fromARGB(11, 42, 42, 42)
      : Color.fromARGB(50, 63, 162, 255);
  static Color get backgroundWidgetFormColor4 => changeThemeInstance?.isDarkTheme == true
      ? Color.fromARGB(28, 146, 146, 146)
      : Color.fromARGB(167, 73, 158, 255);

  static bool get isDarkTheme => changeThemeInstance?.isDarkTheme == true
      ? true
      : false;

  static Color get colorContraste => changeThemeInstance?.isDarkTheme == true
      ? letraClara
      : letraOscura;
  
  static final TextStyle subtituloConstraste = TextStyle(
    color: changeThemeInstance?.isDarkTheme == true ? letraClara : letraOscura
  );

  static final TextStyle subtituloPrimario = TextStyle(
    color: letraClara
  );
  static final TextStyle subtituloSecundario = TextStyle(
    color: letraOscura
  );
  
  static final TextStyle textFormField = const TextStyle(fontWeight: FontWeight.w400, color: Colors.white);

  static final ThemeData customTheme = ThemeData.light().copyWith(
    dialogTheme: DialogTheme(
      surfaceTintColor: Colors.transparent
    ),
     
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.secundario1, // button text color
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.white
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: primario1, 
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