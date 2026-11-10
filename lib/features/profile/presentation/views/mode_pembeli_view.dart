import 'package:flutter/material.dart';

class ModePembeliView extends StatelessWidget {
  const ModePembeliView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Mode pembeli aktif'),
      ),
    );
  }
}
