import 'dart:math' as math;
import 'package:flutter/material.dart';

double hypot(num a, num b) => math.sqrt(a * a + b * b);

double angle3pts(Offset a, Offset b, Offset c) {
  final v1 = Offset(a.dx - b.dx, a.dy - b.dy);
  final v2 = Offset(c.dx - b.dx, c.dy - b.dy);
  final denom = (v1.distance * v2.distance) + 1e-9;
  var d = ((v1.dx * v2.dx + v1.dy * v2.dy) / denom).clamp(-1.0, 1.0);
  return math.acos(d) * 180.0 / math.pi;
}

double angleToVertical(Offset p1, Offset p2) {
  final v = Offset(p2.dx - p1.dx, p2.dy - p1.dy);
  final n = v.distance;
  if (n < 1e-9) return 0.0;
  final vn = Offset(v.dx / n, v.dy / n);
  final dot = (vn.dx * 0.0 + vn.dy * (-1.0)).clamp(-1.0, 1.0);
  return (math.acos(dot) * 180.0 / math.pi).abs();
}

Offset mid(Offset p, Offset q) => Offset((p.dx + q.dx) / 2.0, (p.dy + q.dy) / 2.0);
