import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jasa_mahasiswa/features/dashboard/presentation/ai_recommendation_chat_screen.dart';

void main() {
  testWidgets('shows chat greeting and suggested questions', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AiRecommendationChatScreen()),
    );

    expect(find.text('Asisten Jasa'), findsOneWidget);
    expect(find.text('Coba tanyakan'), findsOneWidget);
    expect(find.text('Bantu cari jasa coding'), findsOneWidget);
  });

  testWidgets('suggestion returns matching service recommendation', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AiRecommendationChatScreen()),
    );

    await tester.tap(find.text('Bantu cari jasa coding'));
    await tester.pumpAndSettle();

    expect(find.text('Bantu cari jasa coding'), findsOneWidget);
    expect(find.text('Jasa Web React & UI Tailwind'), findsOneWidget);
  });

  testWidgets('asks for clarification when request is not recognized', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AiRecommendationChatScreen()),
    );

    await tester.enterText(
      find.byType(TextField),
      'Saya butuh bantuan untuk tugas',
    );
    await tester.tap(find.byTooltip('Kirim pesan'));
    await tester.pumpAndSettle();

    expect(find.text('Saya butuh bantuan untuk tugas'), findsOneWidget);
    expect(
        find.textContaining('Boleh ceritakan lebih spesifik'), findsOneWidget);
  });
}
