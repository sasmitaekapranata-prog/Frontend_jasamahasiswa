import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jasa_mahasiswa/app/theme/app_theme.dart';
import 'package:jasa_mahasiswa/features/profile/presentation/screens/withdraw_saldo_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets(
    'confirms withdrawal without layout or locale errors on a short viewport',
    (tester) async {
      tester.view.physicalSize = const Size(440, 320);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const WithdrawSaldoScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Konfirmasi & Tarik Saldo'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Konfirmasi Penarikan'), findsNWidgets(2));

      final confirmButton = find.widgetWithText(
        FilledButton,
        'Konfirmasi Penarikan',
      );
      await tester.ensureVisible(confirmButton);
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Permintaan Penarikan Dicatat'), findsOneWidget);
    },
  );
}
