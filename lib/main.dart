import 'package:flutter/material.dart';
import 'package:netkeep/presentation/shell/shell.screen.dart';
import 'package:netkeep/utils/theme.dart';

void main() {
  runApp(NetKeep());
}

class NetKeep extends StatelessWidget {
  const NetKeep({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NetKeep',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const ShellScreen()
    );
  }
}
