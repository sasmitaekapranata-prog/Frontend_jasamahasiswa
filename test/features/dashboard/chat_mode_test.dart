import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jasa_mahasiswa/features/dashboard/presentation/chat_detail_screen.dart';
import 'package:jasa_mahasiswa/features/dashboard/presentation/chat_screen.dart';
import 'package:jasa_mahasiswa/features/profile/controllers/user_role_controller.dart';

void main() {
  final roleController = UserRoleController.instance;

  tearDown(() {
    roleController.setRole(UserRole.pembeli);
  });

  testWidgets('chat list and conversation change with account mode', (
    tester,
  ) async {
    roleController.setRole(UserRole.pembeli);
    await tester.pumpWidget(
      const MaterialApp(home: ChatScreen()),
    );

    expect(
        find.text('Mode Pembeli • percakapan dengan Penjual'), findsOneWidget);
    expect(find.text('Budi Setiawan'), findsOneWidget);
    expect(find.text('Ahmad Rizky'), findsNothing);

    roleController.setRole(UserRole.penjual);
    await tester.pumpAndSettle();

    expect(
        find.text('Mode Penjual • percakapan dengan Pembeli'), findsOneWidget);
    expect(find.text('Ahmad Rizky'), findsOneWidget);
    expect(find.text('Budi Setiawan'), findsNothing);
  });

  testWidgets('chat detail identifies the other role in seller mode', (
    tester,
  ) async {
    roleController.setRole(UserRole.penjual);
    await tester.pumpWidget(
      const MaterialApp(home: ChatDetailScreen(chatId: 'sn')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Siti Nabila'), findsOneWidget);
    expect(find.text('Pembeli • Online'), findsOneWidget);
    expect(
      find.text('Halo kak, saya tertarik dengan jasa yang kamu tawarkan.'),
      findsOneWidget,
    );
  });
}
