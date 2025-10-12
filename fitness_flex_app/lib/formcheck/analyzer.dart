// lib/formcheck/analyzer.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'config.dart';
import 'math_utils.dart';
import 'rep_segmenter.dart';

class FrameFeatures {
  final int fidx;
  final double tMs;
  final double kneeL, kneeR;
  final double torsoLean;
  final Offset hip, ankle;
  final double? valgusRatio;
  final double spanSh, spanKn, spanAn;
  final double dzSh, dzKn, dzAn;
  final double signZSum;
  final double visSh, visHip, visKnee, visAnk;

  FrameFeatures({
    required this.fidx,
    required this.tMs,
    required this.kneeL,
    required this.kneeR,
    required this.torsoLean,
    required this.hip,
    required this.ankle,
    required this.valgusRatio,
    required this.spanSh,
    required this.spanKn,
    required this.spanAn,
    required this.dzSh,
    required this.dzKn,
    required this.dzAn,
    required this.signZSum,
    required this.visSh,
    required this.visHip,
    required this.visKnee,
    required this.visAnk,
  });
}

class RepSummary {
  final int id;
  final int start, bottom, end;
  final String view;
  final double viewConf;
  final Map<String, dynamic> metrics;
  final Map<String, double> confidences;
  final double score;
  final Map<String, double> compScores;
  final Map<String, double> effWeights;
  final List<String> faults;

  RepSummary({
    required this.id,
    required this.start,
    required this.bottom,
    required this.end,
    required this.view,
    required this.viewConf,
    required this.metrics,
    required this.confidences,
    required this.score,
    required this.compScores,
    required this.effWeights,
    required this.faults,
  });
}

class FormAnalyzer {
  final FCConfig cfg;
  final double fps;

  final List<FrameFeatures> _frames = [];
  int _repCount = 0;
  final List<RepSummary> _reps = [];
  late final RepSegmenter _seg;

  // stance reference (updated lazily)
  double? _stanceHipYMean;
  double? _stanceScale;
  double? _stanceValgusRatio;

FormAnalyzer({required this.cfg, required this.fps}) {
  _seg = RepSegmenter(
    minSec: cfg.minRepSec,
    maxSec: cfg.maxRepSec,
    standDeg: (cfg.thresholds["knee_standing_deg"] as num).toDouble(),
    bottomDeg: (cfg.thresholds["knee_bottom_deg"] as num).toDouble(),
  );
}


  // ----- helpers -----
  double _asDouble(Object? v, [double fallback = 0.0]) =>
      (v is num) ? v.toDouble() : fallback;

  double _ema(double? prev, double val, double a) =>
      (prev == null) ? val : (a * val + (1 - a) * prev);

  double _dist(Offset a, Offset b) => hypot(a.dx - b.dx, a.dy - b.dy);

  // ---- per-frame extraction (from ML Kit pose) ----
  FrameFeatures? addFrame({
    required int fidx,
    required double tMs,
    required Pose pose,
  }) {
    final Map<PoseLandmarkType, PoseLandmark> L = pose.landmarks;
    PoseLandmark? T(PoseLandmarkType t) => L[t];

    if (!L.containsKey(PoseLandmarkType.leftHip) ||
        !L.containsKey(PoseLandmarkType.rightHip) ||
        !L.containsKey(PoseLandmarkType.leftKnee) ||
        !L.containsKey(PoseLandmarkType.rightKnee) ||
        !L.containsKey(PoseLandmarkType.leftAnkle) ||
        !L.containsKey(PoseLandmarkType.rightAnkle) ||
        !L.containsKey(PoseLandmarkType.leftShoulder) ||
        !L.containsKey(PoseLandmarkType.rightShoulder)) {
      return null;
    }

    Offset o(PoseLandmark lm) => Offset(lm.x, lm.y);

    final shL = T(PoseLandmarkType.leftShoulder)!;
    final shR = T(PoseLandmarkType.rightShoulder)!;
    final hipL = T(PoseLandmarkType.leftHip)!;
    final hipR = T(PoseLandmarkType.rightHip)!;
    final knL = T(PoseLandmarkType.leftKnee)!;
    final knR = T(PoseLandmarkType.rightKnee)!;
    final anL = T(PoseLandmarkType.leftAnkle)!;
    final anR = T(PoseLandmarkType.rightAnkle)!;

    final shMid = mid(o(shL), o(shR));
    final hipMid = mid(o(hipL), o(hipR));
    final anMid = mid(o(anL), o(anR));

    final kneeL = angle3pts(o(hipL), o(knL), o(anL));
    final kneeR = angle3pts(o(hipR), o(knR), o(anR));
    final torsoLean = angleToVertical(hipMid, shMid);

    final kneeSpanX = (o(knL).dx - o(knR).dx).abs();
    final ankleSpanX = (o(anL).dx - o(anR).dx).abs();
    final valgusRatio = ankleSpanX > 1e-6 ? kneeSpanX / ankleSpanX : null;

    final spanSh = (o(shL).dx - o(shR).dx).abs();
    final spanKn = kneeSpanX;
    final spanAn = ankleSpanX;

    final dzSh = (shL.z - shR.z).abs();
    final dzKn = (knL.z - knR.z).abs();
    final dzAn = (anL.z - anR.z).abs();
    final signZSum =
        (shL.z - shR.z).sign + (knL.z - knR.z).sign + (anL.z - anR.z).sign;

    // ML Kit → likelihood
    final visSh = (shL.likelihood + shR.likelihood) * 0.5;
    final visHip = (hipL.likelihood + hipR.likelihood) * 0.5;
    final visK = (knL.likelihood + knR.likelihood) * 0.5;
    final visAn = (anL.likelihood + anR.likelihood) * 0.5;

    final ff = FrameFeatures(
      fidx: fidx,
      tMs: tMs,
      kneeL: kneeL,
      kneeR: kneeR,
      torsoLean: torsoLean,
      hip: hipMid,
      ankle: anMid,
      valgusRatio: valgusRatio,
      spanSh: spanSh,
      spanKn: spanKn,
      spanAn: spanAn,
      dzSh: dzSh,
      dzKn: dzKn,
      dzAn: dzAn,
      signZSum: signZSum.toDouble(),
      visSh: visSh,
      visHip: visHip,
      visKnee: visK,
      visAnk: visAn,
    );

    _frames.add(ff);
    _updateStance(ff);
    _trySegment(ff);
    return ff;
  }

  void _updateStance(FrameFeatures f) {
    final kneeMean = (f.kneeL + f.kneeR) / 2.0;
    final thStand = (cfg.thresholds["knee_standing_deg"] as num).toDouble();
    if (kneeMean >= thStand) {
      final scale = _dist(f.hip, f.ankle);
      _stanceScale = _ema(_stanceScale, scale, 0.2);
      _stanceHipYMean = _ema(_stanceHipYMean, f.hip.dy, 0.2);
      if (f.valgusRatio != null) {
        _stanceValgusRatio = _ema(_stanceValgusRatio, f.valgusRatio!, 0.2);
      }
    }
  }

  // ---- view classification (raw)
  (String, double) _classifyView(FrameFeatures f) {
    final xSpan = (f.spanSh + f.spanKn + f.spanAn) / 3.0;
    final zDiff = (f.dzSh + f.dzKn + f.dzAn) / 3.0;
    final ratio = xSpan / (zDiff + 1e-6);

    String label;
    if (ratio >= 1.35) {
      label = "front";
    } else if (ratio <= 0.65) {
      label = "side";
    } else {
      label = "oblique";
    }
    if (label == "side") {
      final s = f.signZSum;
      if (s < -0.5) label = "side_left";
      else if (s > 0.5) label = "side_right";
    }

    final confBase =
        (ratio <= 1 ? (1 / math.max(ratio, 1e-6)) : ratio); // farther from 1 → higher conf
    final conf = math.min(1.0, math.log(confBase) / math.log(1.3));
    return (label, conf.isFinite ? conf.abs() : 0.5);
  }
  void _trySegment(FrameFeatures f) {
  final kneeMin = math.min(f.kneeL, f.kneeR);
  final evt = _seg.update(f.fidx, f.tMs, kneeMin); // pass timestamp!
  if (evt != null) {
    _repCount += 1;
    final rep = _buildRep(evt, _repCount);
    _reps.add(rep);
  }
}


  RepSummary _buildRep(RepEvent evt, int id) {
    final slice =
        _frames.where((x) => x.fidx >= evt.start && x.fidx <= evt.end).toList();

    // view majority + conf avg
    final views = <String, int>{};
    double confSum = 0;
    int confN = 0;
    for (final fr in slice) {
      final (lab, cf) = _classifyView(fr);
      views[lab] = (views[lab] ?? 0) + 1;
      confSum += cf;
      confN += 1;
    }
    String top = "unknown";
    int best = -1;
    views.forEach((k, v) {
      if (v > best) {
        best = v;
        top = k;
      }
    });
    final viewConf = confN == 0 ? 0.0 : (confSum / confN);

    final metrics = _computeMetrics(slice, evt, top);
    final confidences = _metricConfidences(slice, metrics, top);
    final (score, comp, eff, faults) = _score(metrics, confidences, top);

    return RepSummary(
      id: id,
      start: evt.start,
      bottom: evt.bottom,
      end: evt.end,
      view: top,
      viewConf: viewConf,
      metrics: metrics,
      confidences: confidences.map((k, v) => MapEntry(k, v)),
      score: score,
      compScores: comp.map((k, v) => MapEntry(k, v)),
      effWeights: eff.map((k, v) => MapEntry(k, v)),
      faults: faults,
    );
  }

  Map<String, dynamic> _computeMetrics(
      List<FrameFeatures> slice, RepEvent evt, String view) {
    final kneeMinL = slice.map((e) => e.kneeL).reduce(math.min);
    final kneeMaxL = slice.map((e) => e.kneeL).reduce(math.max);
    final kneeMinR = slice.map((e) => e.kneeR).reduce(math.min);
    final kneeMaxR = slice.map((e) => e.kneeR).reduce(math.max);
    final kneeMin = math.min(kneeMinL, kneeMinR);
    final kneeMax = math.max(kneeMaxL, kneeMaxR);
    final rom = kneeMax - kneeMin;

    // bottom idx by min mean knee
    double best = 1e9;
    int bottomIdx = evt.bottom;
    for (final fr in slice) {
      final meanK = (fr.kneeL + fr.kneeR) / 2.0;
      if (meanK < best) {
        best = meanK;
        bottomIdx = fr.fidx;
      }
    }
    final torsoBottom =
        _frames.firstWhere((f) => f.fidx == bottomIdx).torsoLean;

    final scale = (_stanceScale ?? 1.0).clamp(1e-6, 1e9);
    final hipYMean = _stanceHipYMean;

    double? hipDepthNorm;
    if (hipYMean != null) {
      final hipMaxY = slice.map((e) => e.hip.dy).reduce(math.max);
      hipDepthNorm = (hipMaxY - hipYMean) / scale;
    }

    // tempo
    final eccMs = (bottomIdx - evt.start) * 1000.0 / fps;
    final conMs = (evt.end - bottomIdx) * 1000.0 / fps;

    // camera motion
    final ax = _std(slice.map((e) => e.ankle.dx));
    final ay = _std(slice.map((e) => e.ankle.dy));
    final cameraMotionNorm = hypot(ax, ay) / scale;

    // pelvis stability relative to feet
    final px = _std(slice.map((e) => e.hip.dx - e.ankle.dx));
    final py = _std(slice.map((e) => e.hip.dy - e.ankle.dy));
    final pelvisStdNorm = hypot(px, py) / scale;

    // foot drift
    final spans = slice.map((e) => e.spanAn).toList();
    final mu =
        spans.isEmpty ? 1e-6 : (spans.reduce((a, b) => a + b) / spans.length);
    final footDriftNorm =
        spans.isEmpty ? cameraMotionNorm : (_std(spans) / (mu == 0 ? 1e-6 : mu));

    // symmetry (front only)
    double? symPct;
    if (view.startsWith("side")) {
      symPct = null;
    } else {
      final romL = kneeMaxL - kneeMinL;
      final romR = kneeMaxR - kneeMinR;
      symPct =
          ((romL - romR).abs() / (math.max(romL, math.max(romR, 1e-6)))) * 100.0;
    }

    // valgus (front only)
    double? valgusDropPct;
    if (view.startsWith("front") && _stanceValgusRatio != null) {
      final fBottom = _frames.firstWhere((f) => f.fidx == bottomIdx);
      final vrb = fBottom.valgusRatio;
      if (vrb != null && _stanceValgusRatio! > 1e-6) {
        valgusDropPct =
            math.max(0.0, (_stanceValgusRatio! - vrb) / _stanceValgusRatio!) *
                100.0;
      }
    }

    // smoothness (simple jerk proxy)
    final k = slice.map((e) => (e.kneeL + e.kneeR) / 2.0).toList();
    final jerk = (k.length >= 5) ? _meanAbsSecondDiff(k) : 0.0;

    return {
      "knee_angle_min": kneeMin,
      "knee_angle_max": kneeMax,
      "rom_knee": rom,
      "torso_lean_bottom_deg": torsoBottom,
      "hip_depth_norm": hipDepthNorm,
      "tempo_ms": {"eccentric": eccMs, "concentric": conMs},
      "stability": {
        "pelvis_std_norm": pelvisStdNorm,
        "foot_drift_norm": footDriftNorm,
        "camera_motion_norm": cameraMotionNorm,
      },
      "symmetry_rom_diff_pct": symPct,
      "valgus_drop_pct": valgusDropPct,
      "smoothness_jerk": jerk,
      "bottom_idx": bottomIdx,
    };
  }

  Map<String, double> _metricConfidences(
      List<FrameFeatures> slice, Map<String, dynamic> metrics, String view) {
    double visMean(List<double> xs) =>
        xs.isEmpty ? 0.6 : xs.reduce((a, b) => a + b) / xs.length;

    final depthC =
        visMean(slice.map((e) => (e.visKnee + e.visHip + e.visAnk) / 3.0).toList());
    final torsoC =
        visMean(slice.map((e) => (e.visSh + e.visHip) / 2.0).toList());
    final tempoC =
        visMean(slice.map((e) => (e.visKnee + e.visAnk) / 2.0).toList());
    var stabilityC =
        visMean(slice.map((e) => (e.visHip + e.visAnk) / 2.0).toList());
    final romC = depthC;
    var valgusC =
        visMean(slice.map((e) => (e.visKnee + e.visAnk) / 2.0).toList());
    if (!view.startsWith("front")) valgusC = 0.0;

    // relax if camera moving
    final cam = _asDouble(metrics["stability"] is Map
        ? (metrics["stability"] as Map)["camera_motion_norm"]
        : null);
    final relaxThr =
        (cfg.stability["camera_motion_relax_thr"] as num).toDouble();
    if (cam >= relaxThr) stabilityC *= 0.3;

    return {
      "depth": depthC,
      "torso_lean": torsoC,
      "knee_valgus": valgusC,
      "symmetry": view.startsWith("side") ? 0.0 : depthC,
      "tempo": tempoC,
      "stability": stabilityC,
      "rom": romC,
    };
  }

  (double, Map<String, double>, Map<String, double>, List<String>) _score(
      Map<String, dynamic> m, Map<String, double> conf, String view) {
    final th = cfg.thresholds;
    final baseW = Map<String, double>.from(cfg.scoringWeights);
    final sideW = Map<String, double>.from(cfg.sideViewWeights);
    final w = (view.startsWith("side") ? sideW : baseW);

    // ------ values from metrics (safe typed reads) ------
    final mStab = (m["stability"] as Map?) ?? const {};
    final mTempo = (m["tempo_ms"] as Map?) ?? const {};

    final pj = _asDouble(mStab["pelvis_std_norm"]);
    final fd = _asDouble(mStab["foot_drift_norm"]);
    final tl = _asDouble(m["torso_lean_bottom_deg"]);
    final ecc = _asDouble(mTempo["eccentric"]);
    final con = _asDouble(mTempo["concentric"], 1.0).clamp(1.0, double.infinity);
    final ratio = ecc / con;

    final vd = m["valgus_drop_pct"] as num?;
    final sym = m["symmetry_rom_diff_pct"] as num?;
    final depth = _asDouble(m["knee_angle_min"]);
    final rom = _asDouble(m["rom_knee"]);

    // ------ component scores ------
    final bottomOk = (depth < 90)
        ? 10.0
        : (depth < (th["knee_bottom_deg"] as num).toDouble() ? 8.0 : 6.0);

    final lo = (th["torso_lean_ok_deg"] as List).first.toDouble();
    final hi = (th["torso_lean_ok_deg"] as List).last.toDouble();
    final torsoS = (tl >= lo && tl <= hi)
        ? 10.0
        : ((tl >= 0 && tl < lo + 10) || (tl > hi - 10 && tl <= 60) ? 8.0 : 6.0);

    double valgusS;
    if (vd == null) {
      valgusS = 8.0;
      w["knee_valgus"] = 0.0;
    } else {
      final vdd = vd.toDouble();
      valgusS = (vdd < 5)
          ? 10.0
          : (vdd < (th["valgus_max_drop_pct"] as num).toDouble() ? 8.0 : 6.0);
    }

    double symS;
    if (view.startsWith("side") || sym == null) {
      symS = 8.0;
      w["symmetry"] = 0.0;
    } else {
      final s = sym.toDouble();
      symS = (s < 5) ? 10.0 : (s < 12 ? 8.0 : 6.0);
    }

    final stableS = (pj < 0.01 && fd < 0.05)
        ? 10.0
        : (pj < 0.02 && fd < 0.08)
            ? 8.0
            : (pj < 0.05 && fd < 0.12)
                ? 6.0
                : 4.0;

    final tempoS = (ratio >= 1.2 && ratio <= 2.4)
        ? 10.0
        : (ratio >= 0.9 && ratio <= 3.0 ? 8.0 : 6.0);

    final romS = (rom > 50) ? 10.0 : (rom > 35 ? 8.0 : 6.0);

    final comp = <String, double>{
      "depth": bottomOk,
      "torso_lean": torsoS,
      "valgus": valgusS,
      "symmetry": symS,
      "tempo": tempoS,
      "stability": stableS,
      "rom": romS,
    };

    // camera-motion relaxer: if camera pans a lot, reduce stability impact
    final cam = _asDouble(mStab["camera_motion_norm"]);
    final relaxThr =
        (cfg.stability["camera_motion_relax_thr"] as num).toDouble();
    var stabilityCapsOff = false;
    if (cam >= relaxThr) {
      comp["stability"] = math.max(comp["stability"]!, 6.0);
      stabilityCapsOff = true;
    }

    // effective weights (confidence-aware)
    final eff = <String, double>{};
    double sum = 0.0;
    for (final k in w.keys) {
      final c = conf[k] ?? 1.0;
      eff[k] = w[k]! * c;
      sum += eff[k]!;
    }
    if (sum == 0) sum = 1.0;
    for (final k in eff.keys) {
      eff[k] = eff[k]! / sum;
    }

    // weighted mean + bottleneck mix
    double weighted = 0.0;
    weighted += (eff["depth"] ?? 0) * (comp["depth"] ?? 0);
    weighted += (eff["torso_lean"] ?? 0) * (comp["torso_lean"] ?? 0);
    weighted += (eff["knee_valgus"] ?? 0) * (comp["valgus"] ?? 0);
    weighted += (eff["symmetry"] ?? 0) * (comp["symmetry"] ?? 0);
    weighted += (eff["tempo"] ?? 0) * (comp["tempo"] ?? 0);
    weighted += (eff["stability"] ?? 0) * (comp["stability"] ?? 0);
    weighted += (eff["rom"] ?? 0) * (comp["rom"] ?? 0);

    final minComp = comp.values.reduce(math.min);
    final lam = (cfg.scoring["bottleneck_mix"] as num).toDouble();
    var overall = (1 - lam) * weighted + lam * minComp;

    // --- hard caps (typed) ---
    final caps = Map<String, num>.from(cfg.scoring["hard_caps"]);
    final capScore = (cfg.scoring["cap_score"] as num).toDouble();

    final capPelvis = (caps["stability_pelvis"] ?? 1e9).toDouble();
    final capFoot = (caps["foot_drift"] ?? 1e9).toDouble();
    final capTorso = (caps["torso_lean_deg"] ?? 1e9).toDouble();
    final capSym = (caps["symmetry_pct"] ?? 1e9).toDouble();

    final faults = <String>[];
    if (!stabilityCapsOff && pj >= capPelvis) {
      faults.add("pelvis_jitter_high:${pj.toStringAsFixed(3)}");
      overall = math.min(overall, capScore);
    }
    if (!stabilityCapsOff && fd >= capFoot) {
      faults.add("foot_drift_high:${fd.toStringAsFixed(3)}");
      overall = math.min(overall, capScore);
    }
    if (tl >= capTorso) {
      faults.add("torso_lean_high:${tl.toStringAsFixed(1)}");
      overall = math.min(overall, capScore);
    }
    if (sym != null && sym.toDouble() >= capSym) {
      faults.add("symmetry_high:${sym.toStringAsFixed(1)}%");
      overall = math.min(overall, capScore);
    }

    return (double.parse(overall.toStringAsFixed(2)), comp, eff, faults);
  }

  double _std(Iterable<double> xs) {
    final list = xs.toList();
    if (list.length < 2) return 0.0;
    final mu = list.reduce((a, b) => a + b) / list.length;
    final v =
        list.map((x) => (x - mu) * (x - mu)).reduce((a, b) => a + b) / list.length;
    return math.sqrt(v);
  }

  double _meanAbsSecondDiff(List<double> xs) {
    double s = 0.0;
    int n = 0;
    for (int i = 2; i < xs.length; i++) {
      final d2 = (xs[i] - 2 * xs[i - 1] + xs[i - 2]).abs();
      s += d2;
      n++;
    }
    return n == 0 ? 0.0 : s / n;
  }

  List<RepSummary> get reps => List.unmodifiable(_reps);

  // ---------- Build Python-style session JSON ----------
  Map<String, dynamic> buildSessionJson({required String videoName}) {
    final scores = _reps.map((r) => r.score).toList();
    final mean =
        scores.isEmpty ? 0.0 : scores.reduce((a, b) => a + b) / scores.length;
    final stdev = scores.length < 2
        ? 0.0
        : () {
            final mu = mean;
            final v = scores
                    .map((s) => (s - mu) * (s - mu))
                    .reduce((a, b) => a + b) /
                scores.length;
            return math.sqrt(v);
          }();

    final step = math.max(1, (fps / 2).round()); // ~0.5s
    final labels = <String>[];
    for (int i = 0; i < _frames.length; i += step) {
      final (lab, _) = _classifyView(_frames[i]);
      labels.add(lab);
    }

    return {
      "video": videoName,
      "fps": fps,
      "num_frames": _frames.isEmpty ? 0 : (_frames.last.fidx + 1),
      "reps_detected": _reps.length,
      "overall_score_mean": double.parse(mean.toStringAsFixed(2)),
      "overall_score_stdev": double.parse(stdev.toStringAsFixed(2)),
      "stance_ref": {
        "hip_y_mean": _stanceHipYMean,
        "scale": _stanceScale ?? 1.0,
        "valgus_ratio_stance": _stanceValgusRatio,
        "camera_motion_relax_thr":
            (cfg.stability["camera_motion_relax_thr"] as num).toDouble(),
      },
      "reps": _reps
          .map((r) => {
                "rep_id": r.id,
                "frames": [r.start, r.end],
                "bottom_frame": r.bottom,
                "view": {
                  "label": r.view,
                  "confidence": double.parse(r.viewConf.toStringAsFixed(3)),
                  "mixed_view": false,
                },
                "metrics": r.metrics,
                "metric_confidence": r.confidences
                    .map((k, v) => MapEntry(k, double.parse(v.toStringAsFixed(3)))),
                "score": r.score,
                "score_components": r.compScores,
                "score_effective_weights": r.effWeights
                    .map((k, v) => MapEntry(k, double.parse(v.toStringAsFixed(3)))),
                "faults": r.faults,
              })
          .toList(),
      "view_timeline_sample": {
        "every_n_frames": step,
        "labels": labels,
      }
    };
  }
}
