import 'package:flutter/material.dart';
import 'router.dart';
import 'shared/theme/app_theme.dart';

class TrailNotesApp extends StatelessWidget {
  const TrailNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Trail Notes',
      theme: AppTheme.forest,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
