import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jasa_mahasiswa/features/dashboard/presentation/seller_profile_screen.dart';

void main() {
  testWidgets('seller profile shows seller details and offered service', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SellerProfileScreen(serviceId: 'web-react'),
      ),
    );

    expect(find.text('Profil Penjual'), findsOneWidget);
    expect(find.text('Andi Pratama'), findsOneWidget);
    expect(find.text('Informatika UI'), findsOneWidget);
    expect(find.text('Tentang Penjual'), findsOneWidget);
    expect(find.text('Jasa yang Ditawarkan'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Jasa Pembuatan Web React & Tailwind'),
      200,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Jasa Pembuatan Web React & Tailwind'), findsWidgets);
    expect(find.text('Chat Penjual'), findsOneWidget);
    expect(find.text('Pesan Jasa'), findsOneWidget);
  });
}
