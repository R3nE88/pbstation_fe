import 'package:flutter/material.dart';
import 'package:pbstation_frontend/provider/change_theme_provider.dart';
import 'package:provider/provider.dart';
// import 'package:pbstation_frontend/screens/home_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final changeTheme = Provider.of<ChangeTheme>(context);

    return Center(
      child: Switch(value: changeTheme.isDarkTheme, onChanged: ( value ){
        changeTheme.isDarkTheme = value;
      })
    );
  }
}