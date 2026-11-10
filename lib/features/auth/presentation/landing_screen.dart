import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/route_names.dart';

const _pageColor = Color(0xFFE3F1FB);
const _navy = Color(0xFF1B2544);
const _blue = Color(0xFF2868F0);
const _skyBlue = Color(0xFF5799F5);

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const _BrandHeader(),
                        const Spacer(),
                        const Text(
                          'HUBUNGKAN\nKEAHLIAN ANDA\nSEKARANG',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _navy,
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'Platform terintegrasi untuk layanan konsultasi '
                            'privat dan transaksi jasa. Pesan layanan atau jual '
                            'keahlian Anda dengan mudah di satu tempat.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF3F4650),
                              fontSize: 12.5,
                              height: 1.25,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(
                          width: 280,
                          height: 230,
                          child: ExcludeSemantics(
                            child: CustomPaint(
                              painter: _LandingIllustrationPainter(),
                            ),
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 204,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () => context.push(Routes.login),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF101828),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: const StadiumBorder(),
                            ),
                            child: const Text(
                              'MASUK APLIKASI',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _blue,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.school_outlined,
            color: Colors.white,
            size: 25,
          ),
        ),
        const SizedBox(width: 12),
        const Text.rich(
          TextSpan(
            style: TextStyle(
              fontFamily: 'Roboto',
              height: 1.05,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
            children: [
              TextSpan(
                text: 'Jasa\n',
                style: TextStyle(color: _navy),
              ),
              TextSpan(
                text: 'Mahasiswa',
                style: TextStyle(color: _blue),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LandingIllustrationPainter extends CustomPainter {
  const _LandingIllustrationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 280, size.height / 230);

    final paleShape = Paint()..color = const Color(0xFFD8EAF8);
    final lightShape = Paint()..color = const Color(0xFFEDF6FC);
    final darkPaint = Paint()..color = _navy;
    final bluePaint = Paint()..color = _blue;
    final skyPaint = Paint()..color = _skyBlue;
    final whitePaint = Paint()..color = Colors.white;

    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(110, 28)
        ..lineTo(0, 78)
        ..close(),
      paleShape,
    );
    canvas.drawPath(
      Path()
        ..moveTo(280, 20)
        ..lineTo(170, 72)
        ..lineTo(280, 126)
        ..close(),
      lightShape,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, 175)
        ..lineTo(75, 135)
        ..lineTo(55, 205)
        ..close(),
      lightShape,
    );
    canvas.drawOval(
      const Rect.fromLTWH(48, 202, 184, 18),
      Paint()..color = const Color(0xFFBFD8EA),
    );

    _drawCube(canvas, const Offset(50, 116), 16, skyPaint);
    _drawCube(canvas, const Offset(207, 96), 15, skyPaint);
    _drawCube(canvas, const Offset(70, 99), 11, bluePaint);
    _drawCube(canvas, const Offset(195, 119), 10, skyPaint);

    const phone = Rect.fromLTWH(96, 7, 88, 132);
    canvas.drawRRect(
      RRect.fromRectAndRadius(phone, const Radius.circular(15)),
      darkPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(100, 11, 80, 124),
        const Radius.circular(12),
      ),
      whitePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(126, 10, 28, 6),
        const Radius.circular(4),
      ),
      darkPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(105, 31, 47, 13),
        const Radius.circular(4),
      ),
      skyPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(107, 50, 66, 39),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFFF0F5FA),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(110, 54, 29, 4),
        const Radius.circular(2),
      ),
      bluePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(110, 63, 53, 3),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFFC7D3E0),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(110, 71, 41, 3),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFFC7D3E0),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(112, 96, 56, 16),
        const Radius.circular(5),
      ),
      bluePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(120, 102, 39, 3),
        const Radius.circular(2),
      ),
      whitePaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(84, 121, 112, 48),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFFE7EEF5),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(89, 126, 102, 36),
        const Radius.circular(4),
      ),
      whitePaint,
    );
    canvas.drawCircle(const Offset(140, 124), 2, darkPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(98, 134, 54, 3),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFFCBD5E1),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(98, 141, 72, 3),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFFCBD5E1),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(122, 151, 22, 7),
        const Radius.circular(2),
      ),
      skyPaint,
    );

    _drawPerson(canvas, const Offset(87, 136), facingRight: true);
    _drawPerson(canvas, const Offset(191, 140), facingRight: false);

    canvas.drawPath(
      Path()
        ..moveTo(206, 14)
        ..lineTo(222, 7)
        ..lineTo(223, 23)
        ..close(),
      skyPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(96, 0)
        ..lineTo(105, 12)
        ..lineTo(90, 12)
        ..close(),
      skyPaint,
    );

    canvas.restore();
  }

  void _drawPerson(
    Canvas canvas,
    Offset origin, {
    required bool facingRight,
  }) {
    final skinPaint = Paint()..color = const Color(0xFFFFC84D);
    final bodyPaint = Paint()..color = facingRight ? _blue : _skyBlue;
    final darkPaint = Paint()..color = _navy;
    final linePaint = Paint()
      ..color = _navy
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(origin + const Offset(9, 6), 5, darkPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(origin.dx + 4, origin.dy + 13, 11, 23),
        const Radius.circular(4),
      ),
      bodyPaint,
    );
    canvas.drawLine(
      origin + const Offset(7, 34),
      origin + const Offset(6, 62),
      linePaint,
    );
    canvas.drawLine(
      origin + const Offset(13, 34),
      origin + const Offset(15, 62),
      linePaint,
    );
    canvas.drawLine(
      origin + const Offset(6, 62),
      origin + const Offset(1, 62),
      linePaint,
    );
    canvas.drawLine(
      origin + const Offset(15, 62),
      origin + const Offset(20, 62),
      linePaint,
    );

    final armStart = origin + const Offset(6, 18);
    final armEnd = origin + Offset(facingRight ? 25 : -7, 29);
    canvas.drawLine(armStart, armEnd, linePaint);
    canvas.drawCircle(armEnd, 2, skinPaint);
    if (facingRight) {
      canvas.drawLine(
        origin + const Offset(14, 18),
        origin + const Offset(22, 27),
        linePaint,
      );
    }
  }

  void _drawCube(Canvas canvas, Offset position, double side, Paint paint) {
    final top = Path()
      ..moveTo(position.dx, position.dy + side * 0.3)
      ..lineTo(position.dx + side * 0.55, position.dy)
      ..lineTo(position.dx + side, position.dy + side * 0.3)
      ..lineTo(position.dx + side * 0.45, position.dy + side * 0.62)
      ..close();
    final left = Path()
      ..moveTo(position.dx, position.dy + side * 0.3)
      ..lineTo(position.dx + side * 0.45, position.dy + side * 0.62)
      ..lineTo(position.dx + side * 0.45, position.dy + side)
      ..lineTo(position.dx, position.dy + side * 0.7)
      ..close();
    final right = Path()
      ..moveTo(position.dx + side * 0.45, position.dy + side * 0.62)
      ..lineTo(position.dx + side, position.dy + side * 0.3)
      ..lineTo(position.dx + side, position.dy + side * 0.7)
      ..lineTo(position.dx + side * 0.45, position.dy + side)
      ..close();

    canvas.drawPath(top, Paint()..color = const Color(0xFF73B2FA));
    canvas.drawPath(left, Paint()..color = _blue);
    canvas.drawPath(right, paint);
  }

  @override
  bool shouldRepaint(covariant _LandingIllustrationPainter oldDelegate) =>
      false;
}
