import 'package:flutter/material.dart';
import 'ui.dart';

/// Airline logo. Uses assets/images/sia_logo.png when present; otherwise draws
/// a wordmark + gold bird as a stand-in.
class SiaLogo extends StatelessWidget {
  final double height;
  final bool light;
  const SiaLogo({super.key, this.height = 44, this.light = false});

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/images/sia_logo.png',
        height: height,
        errorBuilder: (_, __, ___) => _fallback(),
      );

  Widget _fallback() {
    final c = light ? Colors.white : navy;
    return SizedBox(
      height: height,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('SINGAPORE', style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: height * .36, height: 1, letterSpacing: .4)),
          Text('AIRLINES', style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: height * .36, height: 1.15, letterSpacing: .4)),
          Container(height: 1.5, width: height * 2.1, color: gold, margin: const EdgeInsets.only(top: 2)),
        ]),
        const SizedBox(width: 4),
        SizedBox(width: height * .85, height: height, child: CustomPaint(painter: _BirdPainter())),
      ]),
    );
  }
}

class _BirdPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = gold;
    for (var i = 0; i < 3; i++) {
      final o = i * s.width * .17;
      final path = Path()
        ..moveTo(s.width * .05 + o, s.height * .98)
        ..quadraticBezierTo(s.width * .2 + o, s.height * .35, s.width * .78 + o * .3, s.height * .02)
        ..quadraticBezierTo(s.width * .42 + o, s.height * .38, s.width * .3 + o, s.height * .98)
        ..close();
      c.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Photo from assets/images/<name>.jpg, falling back to a scenic gradient.
class Photo extends StatelessWidget {
  final String name;
  final int c1, c2;
  final double height;
  final double radius;
  final Widget? child;
  const Photo(this.name, {super.key, required this.c1, required this.c2, this.height = 180, this.radius = 0, this.child});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(fit: StackFit.expand, children: [
            Image.asset('assets/images/$name.jpg', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Scenic(c1: c1, c2: c2, height: height, radius: 0)),
            if (child != null) child!,
          ]),
        ),
      );
}
