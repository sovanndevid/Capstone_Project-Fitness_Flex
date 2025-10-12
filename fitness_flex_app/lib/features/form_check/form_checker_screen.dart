import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'package:fitness_flex_app/navigation/app_router.dart';

// Analyzer stack
import 'package:fitness_flex_app/formcheck/config.dart';
import 'package:fitness_flex_app/formcheck/analyzer.dart';
import 'package:fitness_flex_app/formcheck/storage.dart';

class FormCheckerScreen extends StatefulWidget {
  const FormCheckerScreen({super.key});

  @override
  State<FormCheckerScreen> createState() => _FormCheckerScreenState();
}

class _FormCheckerScreenState extends State<FormCheckerScreen> {
  CameraController? _cam;
  late final PoseDetector _pose;
  late final FormAnalyzer _an;

  String _exerciseName = 'Exercise';

  bool _busy = false;
  int _reps = 0;           // ← comes from analyzer.onRep
  String _cue = '';
  bool _good = false;

  // live-cue mini FSM (for text only, not counting)
  String _fsm = 'top';

  final Map<String, Offset> _smoothed = {};
  Offset _smooth(String key, double x, double y, {double alpha = 0.45}) {
    final prev = _smoothed[key] ?? Offset(x, y);
    final cur = Offset(alpha * x + (1 - alpha) * prev.dx, alpha * y + (1 - alpha) * prev.dy);
    _smoothed[key] = cur;
    return cur;
  }

  int _goodFrames = 0;
  int _totalFrames = 0;
  final Map<String, int> _cueCounts = {
    'Keep chest up / back straighter': 0,
    'Go deeper (hip below knee)': 0,
    'Control knees over toes': 0,
  };
  final List<String> _timeline = [];

  // frame index + real-time clock (for tempo)
  int _fidx = -1;
  final Stopwatch _sw = Stopwatch();
  bool _swStarted = false;

  InputImage _buildInputImage(CameraImage img, int sensorOrientation) {
    final rotation = InputImageRotationValue.fromRawValue(sensorOrientation) ??
        InputImageRotation.rotation0deg;

    if (Platform.isIOS) {
      final plane = img.planes.first; // BGRA
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(img.width.toDouble(), img.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.bgra8888,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } else {
      // ANDROID: simplest + most compatible path (NV21 using Y plane)
      final yPlane = img.planes.first;
      return InputImage.fromBytes(
        bytes: yPlane.bytes,
        metadata: InputImageMetadata(
          size: Size(img.width.toDouble(), img.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: yPlane.bytesPerRow,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    _an = FormAnalyzer(
      cfg: FCConfig.defaultSquat(),
      fps: 30.0, // used for sampling; tempo uses real timestamps
      onRep: (_) {
        if (!mounted) return;
        setState(() {
          _reps = _an.reps.length;   // ✅ source of truth
        });
      },
    );

    _pose = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: PoseDetectionModel.base,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = (ModalRoute.of(context)?.settings.arguments ?? {}) as Map?;
      setState(() => _exerciseName = (args?['exercise'] ?? 'Exercise') as String);
    });

    _initCamera();
  }

  @override
  void dispose() {
    () async {
      try {
        if (_cam != null) {
          if (_cam!.value.isStreamingImages) await _cam!.stopImageStream();
          await _cam!.dispose();
        }
      } catch (_) {}
      try { await _pose.close(); } catch (_) {}
      try { _sw..stop()..reset(); } catch (_) {}
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
        imageFormatGroup: Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.yuv420,
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

  // throttle: process every 3rd frame
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

  // live-cue-only fsm (does not change _reps)
  void _updateLiveCueState(double depth) {
    const downThresh = 0.022;
    const upThresh = -0.006;
    if (_fsm == 'top' && depth > downThresh) _fsm = 'down';
    if (_fsm == 'down' && depth < upThresh) _fsm = 'top';
  }

  Future<void> _processFrame(CameraImage img) async {
    if (_busy) return;
    _busy = true;
    try {
      final input = _buildInputImage(img, _cam?.description.sensorOrientation ?? 0);

      final poses = await _pose.processImage(input);
      if (poses.isEmpty) {
        _busy = false;
        return;
      }

      // ---------- FEED ANALYZER (real timestamp) ----------
      if (!_swStarted) { _swStarted = true; _sw.start(); }
      final double tMs = _sw.elapsedMilliseconds.toDouble();

      final pose = poses.first;
      _an.addFrame(fidx: ++_fidx, tMs: tMs, pose: pose);

      // ---------- LIVE CUES (left side quick heuristic) ----------
      final lm = pose.landmarks;
      final S = lm[PoseLandmarkType.leftShoulder];
      final Hh = lm[PoseLandmarkType.leftHip];
      final K = lm[PoseLandmarkType.leftKnee];
      final A = lm[PoseLandmarkType.leftAnkle];
      final T = lm[PoseLandmarkType.leftFootIndex];
      if (S == null || Hh == null || K == null || A == null || T == null) {
        _busy = false;
        return;
      }

      final W = img.width.toDouble(), Ht = img.height.toDouble();
      double nx(double v) => v / W; double ny(double v) => v / Ht;

      final s = _smooth('s', nx(S.x), ny(S.y));
      final h = _smooth('h', nx(Hh.x), ny(Hh.y));
      final k = _smooth('k', nx(K.x), ny(K.y));
      final a = _smooth('a', nx(A.x), ny(A.y));
      final t = _smooth('t', nx(T.x), ny(T.y));

      final backAng = _angle(s, h, a);
      final depth = (h.dy - k.dy);
      final shinLen = (k - a).distance.clamp(1e-6, 1.0);
      final kneeOverToe = (k.dx - t.dx) > 0.25 * shinLen;

      final backOk = backAng >= 155;
      final depthOk = depth > 0.015;
      final kneeOk = !kneeOverToe;
      final good = backOk && depthOk && kneeOk;

      String cue = '';
      if (!backOk) cue = 'Keep chest up / back straighter';
      else if (!depthOk) cue = 'Go deeper (hip below knee)';
      else if (!kneeOk) cue = 'Control knees over toes';

      _totalFrames++;
      if (good) { _goodFrames++; _timeline.add('G'); }
      else {
        _timeline.add('B');
        if (cue.isNotEmpty && _cueCounts.containsKey(cue)) {
          _cueCounts[cue] = (_cueCounts[cue] ?? 0) + 1;
        }
      }

      _updateLiveCueState(depth);

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
      final isFront = _cam!.description.lensDirection == CameraLensDirection.front;
      final next = cams.firstWhere(
        (c) => c.lensDirection == (isFront ? CameraLensDirection.back : CameraLensDirection.front),
        orElse: () => cams.first,
      );
      if (_cam!.value.isStreamingImages) await _cam!.stopImageStream();
      await _cam!.dispose();
      _cam = CameraController(
        next,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.yuv420,
      );
      await _cam!.initialize();
      await _cam!.startImageStream(_onImage);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _cue = 'Switch camera error: $e');
    }
  }

  Future<void> _endSession() async {
    try { if (_cam?.value.isStreamingImages == true) await _cam!.stopImageStream(); } catch (_) {}
    try { if (_swStarted && _sw.isRunning) _sw.stop(); } catch (_) {}

    final session = _an.buildSessionJson(videoName: "live_camera");
    final file = await FCStorage.writeSessionJson(session, filename: "squat_validation.json");

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exported JSON: ${file.path}')),
    );

    Navigator.pushNamed(
      context,
      AppRouter.formCheckSummary,
      arguments: {
        'exercise': _exerciseName,
        'reps': _reps,
        'goodFrames': _goodFrames,
        'scoredFrames': _totalFrames,
        'overallScore': session['overall_score_mean'],
        'components': session['reps'] is List && (session['reps'] as List).isNotEmpty
            ? (session['reps'] as List).last['score_components']
            : {},
        'fails': {
          'back': _cueCounts['Keep chest up / back straighter'] ?? 0,
          'depth': _cueCounts['Go deeper (hip below knee)'] ?? 0,
          'knee': _cueCounts['Control knees over toes'] ?? 0,
        },
        'timeline': _timeline.take(200).toList(),
        'jsonPath': file.path,
        'sessionJson': session,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ready = _cam != null && _cam!.value.isInitialized;

    return Scaffold(
      appBar: AppBar(
        title: Text('$_exerciseName'),
        actions: [
          IconButton(icon: const Icon(Icons.ios_share), onPressed: _endSession, tooltip: 'End & Export')
        ],
      ),
      body: !ready
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                CameraPreview(_cam!),

                // status
                Positioned(
                  left: 16,
                  top: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_exerciseName • Reps: $_reps',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                // switch camera
                Positioned(
                  right: 8,
                  top: 12,
                  child: IconButton(
                    onPressed: _switchCamera,
                    icon: const Icon(Icons.cameraswitch, color: Colors.white),
                    tooltip: 'Switch camera',
                  ),
                ),

                // bottom coach panel
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.28,
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: const [BoxShadow(blurRadius: 16, color: Colors.black26, offset: Offset(0, -4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Center(
                            child: Text(
                              _cue.isEmpty ? 'Step back so I can see hips, knees, and ankles' : _cue,
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(_good ? Icons.check_circle : Icons.error_rounded,
                                    color: _good ? Colors.green : Colors.red, size: 18),
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
                            Text('Reps: $_reps', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(onPressed: _endSession, child: const Text('End Session')),
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
