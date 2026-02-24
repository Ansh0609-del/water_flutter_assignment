import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const WaterScreen(),
    );
  }
}

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> with SingleTickerProviderStateMixin {
  late AnimationController controller;
  double waterLevel = 0.3;
  double tiltX = 0;
  double waveAmplitude = 6;
  double lastMagnitude = 0;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

    accelerometerEvents.listen((event) {
      final magnitude = event.x * event.x + event.y * event.y + event.z * event.z;
      final shake = (magnitude - lastMagnitude).abs();
      lastMagnitude = magnitude;

      setState(() {
        tiltX = tiltX * 0.85 + event.x * 0.15;
        if (shake > 18) {
          waveAmplitude = 24;
        } else {
          waveAmplitude = max(4, waveAmplitude * 0.97);
        }
      });
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: controller,
        builder: (_, __) {
          return CustomPaint(
            size: Size.infinite,
            painter: WaterPainter(
              animation: controller.value,
              tiltX: tiltX,
              waveAmplitude: waveAmplitude,
              level: waterLevel,
            ),
          );
        },
      ),
    );
  }
}

class WaterPainter extends CustomPainter {
  final double animation;
  final double tiltX;
  final double waveAmplitude;
  final double level;

  WaterPainter({
    required this.animation,
    required this.tiltX,
    required this.waveAmplitude,
    required this.level,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final baseHeight = size.height * (1 - level);

    final waterPaint = Paint()..color = Colors.blue.withOpacity(0.85);
    final highlightPaint = Paint()..color = Colors.white.withOpacity(0.25);

    final path = Path();
    path.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x++) {
      final y = baseHeight +
          sin((x / size.width * 2 * pi) + animation * 2 * pi) * waveAmplitude +
          tiltX * 2;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, waterPaint);

    final highlight = Path();
    for (double x = 0; x <= size.width; x++) {
      final y = baseHeight +
          sin((x / size.width * 2 * pi) + animation * 2 * pi + 0.8) * (waveAmplitude * 0.45) +
          tiltX * 1.5 - 6;
      if (x == 0) {
        highlight.moveTo(x, y);
      } else {
        highlight.lineTo(x, y);
      }
    }
    canvas.drawPath(highlight, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant WaterPainter oldDelegate) {
    return oldDelegate.animation != animation ||
        oldDelegate.tiltX != tiltX ||
        oldDelegate.waveAmplitude != waveAmplitude ||
        oldDelegate.level != level;
  }
}
