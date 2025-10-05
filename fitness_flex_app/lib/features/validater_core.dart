import 'dart:math' as math;

class ValidatorCore {
  // Thresholds (from config.yaml)
  static const double kneeStandingDeg = 155;
  static const double kneeBottomDeg = 115;
  static const List<double> torsoLeanOkDeg = [10, 25];
  static const double valgusMaxDropPct = 15;
  static const double stabilityPelvisCap = 0.06;
  static const double footDriftCap = 0.03;
  static const double torsoLeanCap = 35;
  static const double symmetryCap = 20;

  // ---------- Individual component scoring ----------
  double scoreDepth(double kneeMinDeg) {
    if (kneeMinDeg < 90) return 10;
    if (kneeMinDeg < kneeBottomDeg) return 8;
    return 6;
  }

  double scoreTorso(double torsoLeanBottom) {
    final lo = torsoLeanOkDeg[0], hi = torsoLeanOkDeg[1];
    if (torsoLeanBottom >= lo && torsoLeanBottom <= hi) return 10;
    if (torsoLeanBottom < lo + 10 || torsoLeanBottom > hi - 10) return 8;
    return 6;
  }

  double scoreValgus(double? dropPct, bool isFront) {
    if (!isFront || dropPct == null) return 8;
    if (dropPct < 5) return 10;
    if (dropPct < valgusMaxDropPct) return 8;
    return 6;
  }

  double scoreStability(double pelvisStd, double footDrift) {
    if (pelvisStd < 0.01 && footDrift < 0.05) return 10;
    if (pelvisStd < 0.02 && footDrift < 0.08) return 8;
    if (pelvisStd < 0.05 && footDrift < 0.12) return 6;
    return 4;
  }

  double scoreTempo(double eccMs, double conMs) {
    final ratio = eccMs / math.max(conMs, 1);
    if (ratio >= 1.2 && ratio <= 2.4) return 10;
    if (ratio >= 0.9 && ratio <= 3.0) return 8;
    return 6;
  }

  double scoreRom(double romKnee) {
    if (romKnee > 50) return 10;
    if (romKnee > 35) return 8;
    return 6;
  }

  double scoreSymmetry(double? symPct, bool isSide) {
    if (isSide || symPct == null) return 8;
    if (symPct < 5) return 10;
    if (symPct < 12) return 8;
    return 6;
  }

  // ---------- Weighted overall score ----------
  double overallScore(Map<String, double> comps) {
    const weights = {
      'depth': 0.30,
      'torso': 0.15,
      'valgus': 0.20,
      'symmetry': 0.10,
      'tempo': 0.10,
      'stability': 0.10,
      'rom': 0.05,
    };
    double wSum = 0, sSum = 0;
    for (final k in weights.keys) {
      final w = weights[k]!;
      final s = comps[k] ?? 0;
      wSum += w;
      sSum += w * s;
    }
    final weighted = sSum / wSum;
    final minComp = comps.values.fold(10.0, math.min);
    const lam = 0.4; // bottleneck mix
    return (1 - lam) * weighted + lam * minComp;
  }
}
