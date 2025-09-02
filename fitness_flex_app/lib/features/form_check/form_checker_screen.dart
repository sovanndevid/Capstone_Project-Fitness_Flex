import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class FormCheckerScreen extends StatefulWidget {
  const FormCheckerScreen({super.key});

  @override
  State<FormCheckerScreen> createState() => _FormCheckerScreenState();
}

class _FormCheckerScreenState extends State<FormCheckerScreen> {
  CameraController? _cam;
  late PoseDetector _poseDetector;

  // live state
  bool _busy = false;
  int _reps = 0;
  String _cue = '';
  bool _good = false;
  String _fsm = 'top'; // top -> down -> top (rep)

  // smoothing store
  final Map<String, Offset> _smoothed = {};
  Offset _smooth(String key, double x, double y, {double alpha = 0.5}) {
    final prev = _smoothed[key] ?? Offset(x, y);
    final cur = Offset(
      alpha * x + (1 - alpha) * prev.dx,
      alpha * y + (1 - alpha) * prev.dy,
    );
    _smoothed[key] = cur;
    return cur;
  }

  // summary stats
  int _goodFrames = 0;
  int _totalFrames = 0;
  final Map<String, int> _cueCounts = {
    'Keep chest up / back straighter': 0,
    'Go deeper (hip below knee)': 0,
    'Control knees over toes': 0,
  };

  @override
  void initState() {
    super.initState();
    _poseDetector = PoseDetector(options: PoseDetectorOptions());
    _initCamera();
  }

  @override
  void dispose() {
    () async {
      try {
        if (_cam != null) {
          if (_cam!.value.isStreamingImages) {
            await _cam!.stopImageStream();
          }
          await _cam!.dispose();
        }
      } catch (_) {}
      try {
        await _poseDetector.close();
      } catch (_) {}
    }();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) {
        setState(() => _cue = 'No cameras found');
        return;
      }
      final back = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );

      _cam = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup:
            Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.yuv420,
      );
      await _cam!.initialize();

      if (!_cam!.value.isStreamingImages) {
        await _cam!.startImageStream(_onImage);
      }
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _cue = 'Camera error: $e');
    }
  }

  // throttle frames (every 3rd) for stability
  int _skip = 0;
  Future<void> _onImage(CameraImage img) async {
    if ((_skip++ % 3) != 0) return;
    await _processFrame(img);
  }

  double _angle(Offset A, Offset B, Offset C) {
    final bax = A.dx - B.dx, bay = A.dy - B.dy;
    final bcx = C.dx - B.dx, bcy = C.dy - B.dy;
    final dot = bax * bcx + bay * bcy;
    final mag1 = math.sqrt(bax * bax + bay * bay);
    final mag2 = math.sqrt(bcx * bcx + bcy * bcy);
    final denom = (mag1 * mag2).clamp(1e-6, double.infinity);
    final cosv = (dot / denom).clamp(-1.0, 1.0);
    return math.acos(cosv) * 180 / math.pi;
  }

  void _updateRepState(double depth) {
    // hysteresis so we don’t double-count
    const downThresh = 0.022;   // 2.2% below knee -> "down"
    const upThresh   = -0.006;  // 0.6% above knee -> count rep
    if (_fsm == 'top' && depth > downThresh) _fsm = 'down';
    if (_fsm == 'down' && depth < upThresh) {
      _fsm = 'top';
      _reps++;
    }
  }

  Future<void> _processFrame(CameraImage img) async {
    if (_busy) return;
    _busy = true;
    try {
      final plane = img.planes.first;

      final rotation = InputImageRotationValue.fromRawValue(
            _cam?.description.sensorOrientation ?? 0,
          ) ??
          InputImageRotation.rotation0deg;

      final inputImage = InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(img.width.toDouble(), img.height.toDouble()),
          rotation: rotation,
          format: Platform.isIOS ? InputImageFormat.bgra8888 : InputImageFormat.nv21,
          bytesPerRow: plane.bytesPerRow,
        ),
      );

      final poses = await _poseDetector.processImage(inputImage);
      if (poses.isEmpty) {
        _busy = false;
        return;
      }

      final lm = poses.first.landmarks;

      final S = lm[PoseLandmarkType.leftShoulder];
      final H = lm[PoseLandmarkType.leftHip];
      final K = lm[PoseLandmarkType.leftKnee];
      final A = lm[PoseLandmarkType.leftAnkle];
      final T = lm[PoseLandmarkType.leftFootIndex];
      if (S == null || H == null || K == null || A == null || T == null) {
        _busy = false;
        return;
      }

      // normalize to frame size for device-independent thresholds
      final W = img.width.toDouble(), Ht = img.height.toDouble();
      double nx(double v) => v / W;
      double ny(double v) => v / Ht;

      final s = _smooth('s', nx(S.x), ny(S.y), alpha: 0.45);
      final h = _smooth('h', nx(H.x), ny(H.y), alpha: 0.45);
      final k = _smooth('k', nx(K.x), ny(K.y), alpha: 0.45);
      final a = _smooth('a', nx(A.x), ny(A.y), alpha: 0.45);
      final t = _smooth('t', nx(T.x), ny(T.y), alpha: 0.45);

      // posture checks
      final backAng = _angle(s, h, a); // shoulder-hip-ankle
      final depth = (h.dy - k.dy);     // positive means hip below knee
      final depthOk = depth > 0.015;   // ~1.5% of frame height
      final shinLen = (k - a).distance.clamp(1e-6, 1.0);
      final kneeOverToe = (k.dx - t.dx) > 0.25 * shinLen;

      final good = (backAng >= 155) && depthOk && !kneeOverToe;

      String cue = '';
      if (backAng < 155) {
        cue = 'Keep chest up / back straighter';
      } else if (!depthOk) {
        cue = 'Go deeper (hip below knee)';
      } else if (kneeOverToe) {
        cue = 'Control knees over toes';
      }

      // summary counters
      _totalFrames++;
      if (good) _goodFrames++;
      if (cue.isNotEmpty && _cueCounts.containsKey(cue)) {
        _cueCounts[cue] = (_cueCounts[cue] ?? 0) + 1;
      }

      _updateRepState(depth);

      if (mounted) {
        setState(() {
          _good = good;
          _cue = cue;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _cue = 'Processing error: $e');
    } finally {
      _busy = false;
    }
  }

  Future<void> _switchCamera() async {
    try {
      final cams = await availableCameras();
      if (_cam == null || cams.isEmpty) return;
      final isFront =
          _cam!.description.lensDirection == CameraLensDirection.front;
      final next = cams.firstWhere(
        (c) => c.lensDirection ==
            (isFront ? CameraLensDirection.back : CameraLensDirection.front),
        orElse: () => cams.first,
      );
      if (_cam!.value.isStreamingImages) await _cam!.stopImageStream();
      await _cam!.dispose();
      _cam = CameraController(
        next,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup:
            Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.yuv420,
      );
      await _cam!.initialize();
      await _cam!.startImageStream(_onImage);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _cue = 'Switch camera error: $e');
    }
  }

  void _endSession() async {
    try {
      if (_cam != null && _cam!.value.isStreamingImages) {
        await _cam!.stopImageStream();
      }
    } catch (_) {}

    final total = _totalFrames == 0 ? 1 : _totalFrames;
    final goodPct =
        ((_goodFrames / total) * 100).clamp(0, 100).toStringAsFixed(0);

    String topCue = '—';
    int topCount = 0;
    _cueCounts.forEach((k, v) {
      if (v > topCount) {
        topCount = v;
        topCue = k;
      }
    });

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 48,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Session Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.repeat, size: 20),
                  const SizedBox(width: 8),
                  Text('Total reps: $_reps',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, size: 20),
                  const SizedBox(width: 8),
                  Text('Good-form time: $goodPct%',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.tips_and_updates, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Most frequent cue: $topCue',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context); // close summary
                    Navigator.pop(context); // leave form screen
                  },
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ready = _cam != null && _cam!.value.isInitialized;

    return Scaffold(
      body: !ready
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // camera
                CameraPreview(_cam!),

                // small top-left rep counter
                Positioned(
                  left: 16,
                  top: 48,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'SQUAT • Reps: $_reps',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // camera switch
                Positioned(
                  right: 8,
                  top: 44,
                  child: IconButton(
                    onPressed: _switchCamera,
                    icon: const Icon(Icons.cameraswitch, color: Colors.white),
                    tooltip: 'Switch camera',
                  ),
                ),

                // BIG bottom coaching panel (the empty space in your screenshot)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height:
                        MediaQuery.of(context).size.height * 0.28, // ~28% screen
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: const [
                        BoxShadow(
                            blurRadius: 16,
                            color: Colors.black26,
                            offset: Offset(0, -4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // main coaching text (BIG)
                        Expanded(
                          child: Center(
                            child: Text(
                              _cue.isEmpty
                                  ? 'Step back so I can see hips, knees, and ankles'
                                  : _cue,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22, // make 26–28 if you want bigger
                                fontWeight: FontWeight.w700,
                                color: _good
                                    ? Colors.green[700]
                                    : Colors.red[700],
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // small status + reps
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _good
                                      ? Icons.check_circle
                                      : Icons.error_rounded,
                                  color: _good
                                      ? Colors.green
                                      : Colors.red,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _good
                                      ? 'Good form'
                                      : 'Needs adjustment',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _good
                                        ? Colors.green[800]
                                        : Colors.red[800],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Reps: $_reps',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // End session -> summary
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _endSession,
                            child: const Text('End Session'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
//test commit #2