class RepEvent { final int start, bottom, end; RepEvent(this.start, this.bottom, this.end); }

class RepSegmenter {
  final double fps;
  final int minF, maxF;
  final double standDeg, bottomDeg;

  String _state = "STAND";
  int? _startF;
  int? _bottomF;

  RepSegmenter({
    required this.fps,
    required double minSec,
    required double maxSec,
    required this.standDeg,
    required this.bottomDeg,
  })  : minF = (minSec * fps).toInt(),
        maxF = (maxSec * fps).toInt();

  void _reset() { _startF = null; _bottomF = null; }

  RepEvent? update(int fidx, double kneeDegMinBoth) {
    switch (_state) {
      case "STAND":
        if (kneeDegMinBoth < standDeg) { _state = "DOWN"; _startF = fidx; }
        break;
      case "DOWN":
        if (kneeDegMinBoth < bottomDeg) { _state = "BOTTOM"; _bottomF = fidx; }
        if (_startF != null && fidx - _startF! > maxF) { _state = "STAND"; _reset(); }
        break;
      case "BOTTOM":
        if (kneeDegMinBoth > standDeg && _bottomF != null && _startF != null) {
          final endF = fidx;
          final dur = endF - _startF!;
          final ok = dur >= minF && dur <= maxF;
          final rep = ok ? RepEvent(_startF!, _bottomF!, endF) : null;
          _state = "STAND"; _reset();
          return rep;
        }
        break;
    }
    return null;
  }
}
