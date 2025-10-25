import 'package:flutter/material.dart';
import '../provider/change_theme_provider.dart';

class AppTheme{
  static ChangeTheme? changeThemeInstance;

  static void initialize(ChangeTheme instance) {
    changeThemeInstance = instance;
  }

  static const Color letraClara = Colors.white;
  static const Color letraOscura = Colors.black;
  static const Color letra70 = Colors.white70;
  static final Color focusColor = letraClara.withAlpha(88);
  static const Color filledColor = Color.fromARGB(33, 255, 255, 255);

  static Color get primario1 => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(255, 60, 60, 60)
      : const Color.fromARGB(255, 52, 163, 254);
  static Color get secundario1 => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(255, 16, 16, 16)
      : const Color.fromARGB(255, 54, 134, 233);
  static Color get primario2 => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(255, 43, 43, 43)
      : const Color.fromARGB(255, 93, 182, 255);
  static Color get secundario2 => changeThemeInstance?.isDarkTheme == true
      ? Colors.black
      : const Color.fromARGB(255, 5, 77, 186);

  static Color get backgroundColor => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(255, 32, 32, 32)
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

  static Color get containerColor1 => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(255, 43, 43, 43)
      : const Color.fromARGB(255, 101, 178, 251);
    
  static Color get containerColor2 => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(255, 60, 60, 60)
      : const Color.fromARGB(255, 75, 164, 248);

  static Color get backgroundWidgetFormColor1 => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(0, 195, 195, 195)
      : const Color.fromARGB(30, 99, 180, 255);
  static Color get backgroundWidgetFormColor2 => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(53, 0, 0, 0)
      : const Color.fromARGB(123, 32, 103, 255);
  static Color get backgroundWidgetFormColor3 => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(11, 42, 42, 42)
      : const Color.fromARGB(50, 63, 162, 255);
  static Color get backgroundWidgetFormColor4 => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(28, 146, 146, 146)
      : const Color.fromARGB(167, 73, 158, 255);
    
  static Color get botonPrincipal => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(255, 89, 89, 89)
      : Colors.blue;

  static Color get botonPrincipalFocus => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(255, 61, 61, 61)
      : const Color.fromARGB(255, 31, 139, 227);
    
  static Color get _botonSecundario => changeThemeInstance?.isDarkTheme == true
      ? AppTheme.letraClara
      : AppTheme.letraClara;

  static Color get _botonSecundarioFocus => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(255, 165, 165, 165)
      : const Color.fromARGB(255, 220, 238, 255);

  static Color get tablaColorHeader => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(255, 78, 78, 78)
      : const Color.fromARGB(255, 39, 141, 236);

  static Color get tablaColor1 => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(255, 115, 115, 115)
      : const Color.fromARGB(255, 228, 228, 228);
    
  static Color get tablaColor2 => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(255, 103, 103, 103)
      : const Color.fromARGB(255, 204, 204, 204);

  /*static Color get tablaColorFondo => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(255, 57, 57, 57)
      : const Color.fromARGB(255, 239, 242, 243);*/

  static bool get isDarkTheme => changeThemeInstance?.isDarkTheme == true
      ? true
      : false;

  static Color get colorContraste => changeThemeInstance?.isDarkTheme == true
      ? letraClara
      : letraOscura;

  static Color get colorError => changeThemeInstance?.isDarkTheme == true
      ? const Color.fromARGB(255, 228, 15, 0)
      : const Color.fromRGBO(235, 16, 0, 1);

  static const Color colorError2 = Color.fromARGB(255, 241, 85, 38);
  
  static TextStyle get subtituloConstraste => TextStyle(
    color: changeThemeInstance?.isDarkTheme == true ? letraClara : const Color.fromARGB(255, 38, 38, 38)
  );

  static const TextStyle subtituloPrimario = TextStyle(
    color: letraClara
  );
  static const TextStyle subtituloSecundario = TextStyle(
    color: letraOscura
  );
   static const TextStyle tituloPrimario = TextStyle(
    color: letraClara,
    fontWeight: FontWeight.w600
  );
   static const TextStyle tituloClaro = TextStyle(
    color: letraClara,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2
  );

  static final TextStyle goodStyle = TextStyle(
    color: changeThemeInstance?.isDarkTheme == true ? 
    const Color.fromARGB(255, 87, 222, 91) : Colors.green, 
    fontWeight: FontWeight.bold
  );

  static final TextStyle errorStyle = TextStyle(
    color: colorError.withAlpha(180),
    fontSize: 13,
  );

  static final TextStyle warningStyle = TextStyle( //Color.fromARGB(255, 228, 138, 3), 
    color: changeThemeInstance?.isDarkTheme == true ? 
    const Color.fromARGB(255, 255, 155, 4) : const Color.fromARGB(255, 228, 138, 3), 
    fontWeight: FontWeight.bold
  );

  static const TextStyle warningStyle2 = TextStyle(
    color: Color.fromARGB(255, 255, 180, 4), 
    fontWeight: FontWeight.bold
  );

  static const TextStyle labelStyle = TextStyle(
    color: Colors.white70
  );

  static final botonPrincipalStyle = ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.focused)) {
        return AppTheme.botonPrincipalFocus;// Color cuando está enfocado
      }
      return AppTheme.botonPrincipal; // Color normal
    }),
    foregroundColor: WidgetStateProperty.all(AppTheme.containerColor1),
  );


  static final ButtonStyle botonGuardar = ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.focused)) {
        return AppTheme.letra70; // Color cuando está enfocado
      }
      return AppTheme.letraClara; // Color normal
    }),
    foregroundColor: WidgetStateProperty.all(AppTheme.containerColor1),
  );
  
  static const TextStyle textFormField = TextStyle(fontWeight: FontWeight.w400, color: Colors.white);

  static const InputDecoration inputDecorationCustom = InputDecoration(
    contentPadding: EdgeInsets.only(left: 10),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white),
      borderRadius: BorderRadius.all(Radius.circular(12))
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white),
      borderRadius: BorderRadius.all(Radius.circular(12))
    ),
  );

  static const InputDecoration inputDecorationWaring = InputDecoration(
    contentPadding: EdgeInsets.only(left: 10),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Color.fromARGB(255, 255, 200, 34), width: 2),
      borderRadius: BorderRadius.all(Radius.circular(12))
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Color.fromARGB(255, 255, 200, 34), width: 2),
      borderRadius: BorderRadius.all(Radius.circular(12))
    ),
  );

  static const InputDecoration inputDecorationWaringGrave = InputDecoration(
    contentPadding: EdgeInsets.only(left: 10),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.red, width: 2),
      borderRadius: BorderRadius.all(Radius.circular(12))
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.red, width: 2),
      borderRadius: BorderRadius.all(Radius.circular(12))
    ),
  );

  static const InputDecoration inputDecorationSeccess = InputDecoration(
    contentPadding: EdgeInsets.only(left: 10),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Color.fromARGB(255, 66, 255, 45), width: 2),
      borderRadius: BorderRadius.all(Radius.circular(12))
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Color.fromARGB(255, 66, 255, 45), width: 2),
      borderRadius: BorderRadius.all(Radius.circular(12))
    ),
  );

  static const InputDecoration inputError = InputDecoration(
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red),
        borderRadius: BorderRadius.all(Radius.circular(30))
      ),
    );

  static const InputDecoration inputNormal = InputDecoration(
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white),
      borderRadius: BorderRadius.all(Radius.circular(30))
    ),
  );

  static Color get dropDownColor => changeThemeInstance?.isDarkTheme == true
      ? backgroundColor
      : const Color.fromARGB(255, 49, 145, 235);






  static final ThemeData customTheme = ThemeData.light().copyWith(
    progressIndicatorTheme: ProgressIndicatorThemeData(color: primario1),

    checkboxTheme: CheckboxThemeData(
      side: const BorderSide(color: AppTheme.letraClara),
      checkColor: WidgetStateProperty.all(AppTheme.containerColor1),
      fillColor: WidgetStateProperty.all(AppTheme.letraClara),
    ),

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppTheme.primario2, // Cambia aquí tu color base
    ),

    dialogTheme: const DialogThemeData(
      surfaceTintColor: Colors.transparent
    ),
     
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.secundario1, // button text color
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.white
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.focused)) {
            return AppTheme._botonSecundarioFocus; // Color cuando está enfocado
          }
          return AppTheme._botonSecundario; // Color normal
        }),
        foregroundColor: WidgetStateProperty.all(AppTheme.containerColor1),
        shape: WidgetStateProperty.all(const StadiumBorder()),
        elevation: WidgetStateProperty.all(1),
        textStyle: WidgetStateProperty.all(
          const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.5
          )
        ),
      ),
    ),

    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: AppTheme.letraClara), // texto principal del campo
    ),

    inputDecorationTheme: const InputDecorationTheme(
      contentPadding: EdgeInsets.only(left: 10),
      floatingLabelStyle: TextStyle(color: Colors.white, fontSize: 15),

      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
        borderRadius: BorderRadius.all(Radius.circular(30))
      ),

      disabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
        borderRadius: BorderRadius.all(Radius.circular(30))
      ),

      hintStyle: TextStyle(
        color: Color.fromARGB(255, 209, 240, 255),
        fontSize: 15,
      ),

      labelStyle: TextStyle(
        color: Color.fromARGB(255, 209, 240, 255),
        fontSize: 15,
      ),

      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppTheme.letraClara, width: 3),
        borderRadius: BorderRadius.all(Radius.circular(30)),
      ),

      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color.fromARGB(255, 248, 14, 14)),
        borderRadius: BorderRadius.all(Radius.circular(30))
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color.fromARGB(255, 248, 14, 14)),
        borderRadius: BorderRadius.all(Radius.circular(30))
      ),

      filled: true,

      fillColor: filledColor,

      alignLabelWithHint: true,
    )
  );

  static final ThemeData customThemeDark = ThemeData.dark().copyWith(
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: letraClara),

    checkboxTheme: CheckboxThemeData(
      side: const BorderSide(color: AppTheme.letraClara),
      checkColor: WidgetStateProperty.all(AppTheme.containerColor1),
      fillColor: WidgetStateProperty.all(AppTheme.letraClara),
    ),

    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.white // Cambia aquí tu color base
    ),

    dialogTheme: const DialogThemeData(
      surfaceTintColor: Colors.transparent
    ),
     
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.secundario1, // button text color
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.white
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.focused)) {
            return AppTheme._botonSecundarioFocus; // Color cuando está enfocado
          }
          return AppTheme._botonSecundario; // Color normal
        }),
        foregroundColor: WidgetStateProperty.all(AppTheme.containerColor1),
        shape: WidgetStateProperty.all(const StadiumBorder()),
        elevation: WidgetStateProperty.all(1),
        textStyle: WidgetStateProperty.all(
          const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.5
          )
        ),
      ),
    ),

    textSelectionTheme: const TextSelectionThemeData(
      selectionColor: Color.fromARGB(65, 255, 255, 255),// Fondo de selección
      cursorColor: Colors.white, // Cursor (también se puede poner individualmente en cada TextField)
    ),

    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppTheme.filledColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(AppTheme.primario1), // Fondo del menú
        elevation: const WidgetStatePropertyAll(4), // Sombra
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        )), // Bordes redondeados
      ),
    ),

    inputDecorationTheme: const InputDecorationTheme(
      contentPadding: EdgeInsets.only(left: 10),
      floatingLabelStyle: TextStyle(color: Colors.white, fontSize: 15),

      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
        borderRadius: BorderRadius.all(Radius.circular(30))
      ),

      disabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
        borderRadius: BorderRadius.all(Radius.circular(30))
      ),

      hintStyle: TextStyle(
        color: Color.fromARGB(255, 224, 224, 224),
        fontSize: 15,
      ),

      labelStyle: TextStyle(
        color: Color.fromARGB(255, 209, 240, 255),
        fontSize: 15,
      ),

      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppTheme.letraClara, width: 3),
        borderRadius: BorderRadius.all(Radius.circular(30)),
      ),

      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color.fromARGB(255, 248, 14, 14)),
        borderRadius: BorderRadius.all(Radius.circular(30))
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color.fromARGB(255, 248, 14, 14)),
        borderRadius: BorderRadius.all(Radius.circular(30))
      ),

      filled: true,

      fillColor: filledColor,

      alignLabelWithHint: true,
    )
  );
}