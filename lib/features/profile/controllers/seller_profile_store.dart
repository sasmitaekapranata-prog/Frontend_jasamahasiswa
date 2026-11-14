import 'dart:typed_data';

import 'package:flutter/foundation.dart';

class SellerProfileStore extends ChangeNotifier {
  SellerProfileStore._();

  static final SellerProfileStore instance = SellerProfileStore._();

  String name = 'Arif Setiawan';
  String phone = '';
  String university = '';
  String program = 'S1 Teknik Informatika';
  String bio = '';
  String nim = '';
  String gpa = '';
  Uint8List? photoBytes;
  String? photoName;
  Uint8List? studentCardBytes;
  String? studentCardName;
  List<String> skills = ['SPSS & R', 'Web Dev', 'Python', 'Skripsi'];
  List<String> customSkills = [];

  void update({
    required String name,
    required String phone,
    required String university,
    required String program,
    required String bio,
    required String nim,
    required String gpa,
    required Uint8List? photoBytes,
    required String? photoName,
    required Uint8List? studentCardBytes,
    required String? studentCardName,
    required List<String> skills,
    required List<String> customSkills,
  }) {
    this.name = name;
    this.phone = phone;
    this.university = university;
    this.program = program;
    this.bio = bio;
    this.nim = nim;
    this.gpa = gpa;
    this.photoBytes = photoBytes;
    this.photoName = photoName;
    this.studentCardBytes = studentCardBytes;
    this.studentCardName = studentCardName;
    this.skills = List.unmodifiable(skills);
    this.customSkills = List.unmodifiable(customSkills);
    notifyListeners();
  }
}
