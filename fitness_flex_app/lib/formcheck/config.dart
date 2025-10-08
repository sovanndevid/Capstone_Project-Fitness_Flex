import 'dart:math' as math;

class FCConfig {
  final String view; // "auto" | "front" | "side"
  final double minRepSec;
  final double maxRepSec;

  final int savgolWindow; // we’ll noop/replace with simple smoothing online
  final int savgolPoly;

  final Map<String, double> scoringWeights;
  final Map<String, double> sideViewWeights;

  final Map<String, dynamic> thresholds; // knee_standing_deg, knee_bottom_deg, torso_lean_ok_deg[], valgus_max_drop_pct
  final Map<String, dynamic> scoring;    // bottleneck_mix, hard_caps{}, cap_score
  final Map<String, dynamic> stability;  // camera_motion_relax_thr

  const FCConfig({
    this.view = "auto",
    this.minRepSec = 0.5,
    this.maxRepSec = 6.0,
    this.savgolWindow = 9,
    this.savgolPoly = 2,
    required this.scoringWeights,
    required this.sideViewWeights,
    required this.thresholds,
    required this.scoring,
    required this.stability,
  });

  factory FCConfig.defaultSquat() => FCConfig(
    view: "auto",
    minRepSec: 0.5,
    maxRepSec: 6.0,
    savgolWindow: 9,
    savgolPoly: 2,
    scoringWeights: const {
      "depth": 0.30,
      "torso_lean": 0.15,
      "knee_valgus": 0.20,
      "symmetry": 0.10,
      "tempo": 0.10,
      "stability": 0.10,
      "rom": 0.05,
    },
    sideViewWeights: const {
      "depth": 0.28,
      "torso_lean": 0.24,
      "symmetry": 0.00,
      "tempo": 0.18,
      "stability": 0.25,
      "rom": 0.05,
    },
    thresholds: const {
      "knee_standing_deg": 155,
      "knee_bottom_deg": 115,
      "torso_lean_ok_deg": [10.0, 25.0],
      "valgus_max_drop_pct": 15.0,
    },
    scoring: const {
      "bottleneck_mix": 0.40,
      "hard_caps": {
        "stability_pelvis": 0.06,
        "foot_drift": 0.03,
        "torso_lean_deg": 35.0,
        "symmetry_pct": 20.0,
      },
      "cap_score": 6.5,
    },
    stability: const {
      "camera_motion_relax_thr": 0.03,
    },
  );
}
