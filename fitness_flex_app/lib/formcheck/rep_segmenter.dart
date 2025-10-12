// lib/formcheck/rep_segmenter.dart
class RepEvent {
  final int start, bottom, end;
  RepEvent({required this.start, required this.bottom, required this.end});
}

/// Matches Python FSM semantics but uses milliseconds so it's robust to variable FPS.
class RepSegmenter {
  final double minMs;
  final double maxMs;
  final double standDeg;
  final double bottomDeg;

  String _state = "STAND";
  int? _startF, _bottomF;
  double? _startTms, _bottomTms;

  RepSegmenter({
    required double minSec,
    required double maxSec,
    required this.standDeg,
    required this.bottomDeg,
  })  : minMs = minSec * 1000.0,
        maxMs = maxSec * 1000.0;

  void _reset() {
    _startF = _bottomF = null;
    _startTms = _bottomTms = null;
  }

  /// Update with frame index, timestamp (ms), and knee angle (min L/R).
  RepEvent? update({required int fidx, required double tMs, required double kneeDeg}) {
    switch (_state) {
      case "STAND":
        if (kneeDeg < standDeg) {
          _state = "DOWN";
          _startF = fidx;
          _startTms = tMs;
        }
        break;

      case "DOWN":
        if (kneeDeg < bottomDeg) {
          _state = "BOTTOM";
          _bottomF = fidx;
          _bottomTms = tMs;
        }
        if (_startTms != null && (tMs - _startTms!) > maxMs) {
          _state = "STAND";
          _reset();
        }
        break;

      case "BOTTOM":
        if (kneeDeg > standDeg && _bottomF != null && _startF != null && _startTms != null) {
          final durMs = tMs - _startTms!;
          if (durMs >= minMs && durMs <= maxMs) {
            final evt = RepEvent(start: _startF!, bottom: _bottomF!, end: fidx);
            _state = "STAND";
            _reset();
            return evt;
          } else {
            _state = "STAND";
            _reset();
          }
        }
        break;
    }
    return null;
  }
}
