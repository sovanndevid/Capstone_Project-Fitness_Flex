import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:fitness_flex_app/navigation/app_router.dart';

class FormCheckerScreen extends StatefulWidget {
  const FormCheckerScreen({super.key});

  @override
  State<FormCheckerScreen> createState() => _FormCheckerScreenState();
}

class _FormCheckerScreenState extends State<FormCheckerScreen> {
  CameraController? _cam;
  late PoseDetector _poseDetector;

  // nav/context
  String _exerciseName = 'Exercise';

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
  final List<String> _timeline = []; // 'G' or 'B' per scored frame

  @override
  void initState() {
    super.initState();
    _poseDetector = PoseDetector(options: PoseDetectorOptions());

    // Read route args after first frame so ModalRoute is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          (ModalRoute.of(context)?.settings.arguments ?? {}) as Map<dynamic, dynamic>;
      setState(() {
        _exerciseName = (args['exercise'] ?? 'Exercise') as String;
      });
    });

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

      // use sensor orientation; portrait-only MVP
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
      final Hh = lm[PoseLandmarkType.leftHip];
      final K = lm[PoseLandmarkType.leftKnee];
      final A = lm[PoseLandmarkType.leftAnkle];
      final T = lm[PoseLandmarkType.leftFootIndex];
      if (S == null || Hh == null || K == null || A == null || T == null) {
        _busy = false;
        return;
      }

      // normalize to frame size for device-independent thresholds
      final W = img.width.toDouble(), Ht = img.height.toDouble();
      double nx(double v) => v / W;
      double ny(double v) => v / Ht;

      final s = _smooth('s', nx(S.x), ny(S.y), alpha: 0.45);
      final h = _smooth('h', nx(Hh.x), ny(Hh.y), alpha: 0.45);
      final k = _smooth('k', nx(K.x), ny(K.y), alpha: 0.45);
      final a = _smooth('a', nx(A.x), ny(A.y), alpha: 0.45);
      final t = _smooth('t', nx(T.x), ny(T.y), alpha: 0.45);

      // posture checks
      final backAng = _angle(s, h, a); // shoulder-hip-ankle
      final depth = (h.dy - k.dy);     // + means hip below knee (image y grows downward)
      final depthOk = depth > 0.015;   // ~1.5% of frame height
      final shinLen = (k - a).distance.clamp(1e-6, 1.0);
      final kneeOverToe = (k.dx - t.dx) > 0.25 * shinLen;

      final backOk  = backAng >= 155;
      final kneeOk  = !kneeOverToe;
      final good    = backOk && depthOk && kneeOk;

      String cue = '';
      if (!backOk) {
        cue = 'Keep chest up / back straighter';
      } else if (!depthOk) {
        cue = 'Go deeper (hip below knee)';
      } else if (!kneeOk) {
        cue = 'Control knees over toes';
      }

      // summary counters
      _totalFrames++;
      if (good) {
        _goodFrames++;
        _timeline.add('G');
      } else {
        _timeline.add('B');
        if (cue.isNotEmpty && _cueCounts.containsKey(cue)) {
          _cueCounts[cue] = (_cueCounts[cue] ?? 0) + 1;
        }
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

  Future<void> _endSession() async {
    try {
      if (_cam != null && _cam!.value.isStreamingImages) {
        await _cam!.stopImageStream();
      }
    } catch (_) {}

    // Navigate straight to summary page
    if (!mounted) return;
    Navigator.pushNamed(
      context,
      AppRouter.formCheckSummary,
      arguments: {
        'exercise': _exerciseName,
        'reps': _reps,
        'goodFrames': _goodFrames,
        'scoredFrames': _totalFrames,
        'fails': {
          'back': _cueCounts['Keep chest up / back straighter'] ?? 0,
          'depth': _cueCounts['Go deeper (hip below knee)'] ?? 0,
          'knee':  _cueCounts['Control knees over toes'] ?? 0,
        },
        'timeline': _timeline.take(200).toList(), // cap for UI
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

                // top-left exercise + reps badge
                Positioned(
                  left: 16,
                  top: 48,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_exerciseName • Reps: $_reps',
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

                // bottom coaching panel
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.28, // ~28% screen
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 16,
                          color: Colors.black26,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // main coaching text
                        Expanded(
                          child: Center(
                            child: Text(
                              _cue.isEmpty
                                  ? 'Step back so I can see hips, knees, and ankles'
                                  : _cue,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: _good ? Colors.green[700] : Colors.red[700],
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // tiny status + reps
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _good ? Icons.check_circle : Icons.error_rounded,
                                  color: _good ? Colors.green : Colors.red,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _good ? 'Good form' : 'Needs adjustment',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _good ? Colors.green[800] : Colors.red[800],
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