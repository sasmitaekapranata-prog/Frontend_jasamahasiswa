import 'package:flutter/material.dart';

class ModePenjualView extends StatelessWidget {
  const ModePenjualView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Mode penjual aktif'),
      ),
    );
  }
}
