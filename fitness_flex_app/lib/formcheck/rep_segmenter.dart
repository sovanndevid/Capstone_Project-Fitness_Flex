
class RepEvent {
  final int start;
  final int bottom;
  final int end;
  RepEvent({required this.start, required this.bottom, required this.end});
}

class RepSegmenter {
  final double minMs;
  final double maxMs;
  final double standDeg;
  final double bottomDeg;

  String _state = "STAND";
  int? _startF;
  int? _bottomF;
  double? _startT;   // ms
  double? _bottomT;  // ms

  RepSegmenter({
    required double minSec,
    required double maxSec,
    required this.standDeg,
    required this.bottomDeg,
  })  : minMs = minSec * 1000.0,
        maxMs = maxSec * 1000.0;

  void _reset() {
    _startF = null;
    _bottomF = null;
    _startT = null;
    _bottomT = null;
  }

  /// Update with current frame index, timestamp (ms since session start),
  /// and knee angle (min of L/R). Returns RepEvent when a rep completes.
  RepEvent? update(int fidx, double tMs, double kneeDeg) {
    switch (_state) {
      case "STAND":
        if (kneeDeg < standDeg) {
          _state = "DOWN";
          _startF = fidx;
          _startT = tMs;
        }
        break;

      case "DOWN":
        if (kneeDeg < bottomDeg) {
          _state = "BOTTOM";
          _bottomF = fidx;
          _bottomT = tMs;
        }
        // timeout
        if (_startT != null && (tMs - _startT!) > maxMs) {
          _state = "STAND";
          _reset();
        }
        break;

      case "BOTTOM":
        if (kneeDeg > standDeg && _bottomF != null && _startF != null && _startT != null) {
          final endF = fidx;
          final endT = tMs;
          final durMs = endT - _startT!;
          if (durMs >= minMs && durMs <= maxMs) {
            final evt = RepEvent(start: _startF!, bottom: _bottomF!, end: endF);
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
