import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/routes/app_router.dart';
import 'app/theme/app_colors.dart';
import 'app/theme/app_theme.dart';

const double _mobileContentMaxWidth = 480;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  runApp(const JasaMahasiswaApp());
}

class JasaMahasiswaApp extends StatelessWidget {
  const JasaMahasiswaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Jasa Mahasiswa',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
      builder: (context, child) {
        return ColoredBox(
          color: AppColors.background,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth > _mobileContentMaxWidth
                  ? _mobileContentMaxWidth
                  : constraints.maxWidth;

              return Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: width,
                  height: constraints.maxHeight,
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
