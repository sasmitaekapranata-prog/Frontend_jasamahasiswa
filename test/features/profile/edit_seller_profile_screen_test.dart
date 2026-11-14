import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jasa_mahasiswa/features/profile/controllers/seller_profile_store.dart';
import 'package:jasa_mahasiswa/features/profile/presentation/screens/edit_profile_screen.dart';

void main() {
  final profile = SellerProfileStore.instance;

  tearDown(() {
    profile.update(
      name: 'Arif Setiawan',
      phone: '',
      university: '',
      program: 'S1 Teknik Informatika',
      bio: '',
      nim: '',
      gpa: '',
      photoBytes: null,
      photoName: null,
      studentCardBytes: null,
      studentCardName: null,
      skills: const ['SPSS & R', 'Web Dev', 'Python', 'Skripsi'],
      customSkills: const [],
    );
  });

  testWidgets('seller can select and add skills and save their profile', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/edit-profile',
      routes: [
        GoRoute(
          path: '/edit-profile',
          builder: (_, __) => const EditProfileScreen(isSeller: true),
        ),
        GoRoute(
          path: '/profil',
          builder: (_, __) => Scaffold(
            body: Text('${profile.name}: ${profile.skills.join(', ')}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final codingChip = find.widgetWithText(FilterChip, 'Coding');
    await tester.ensureVisible(codingChip);
    await tester.tap(codingChip);
    await tester.pumpAndSettle();

    final addSkill = find.widgetWithText(ActionChip, 'Tambah sendiri');
    await tester.ensureVisible(addSkill);
    await tester.tap(addSkill);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).last,
      'Ilustrasi Digital',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Tambah'));
    await tester.pumpAndSettle();

    final nameLabel = find.text('Nama Lengkap');
    await tester.ensureVisible(nameLabel);
    await tester.enterText(
      find.byType(TextField).first,
      'Dina Mahasiswa',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Simpan Perubahan'));
    await tester.pumpAndSettle();

    expect(profile.name, 'Dina Mahasiswa');
    expect(profile.skills, contains('Coding'));
    expect(profile.skills, contains('Ilustrasi Digital'));
    expect(find.textContaining('Dina Mahasiswa'), findsOneWidget);
  });
}
