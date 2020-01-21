import 'package:flare_flutter/flare.dart';
import 'package:flare_flutter/flare_controls.dart';
import 'package:flare_dart/math/mat2d.dart';
import 'dart:math' as math;

class EyeController extends FlareControls {
  FlutterActorArtboard _currentArtboard;
  double _elapsedTime = 0.0;
  ActorAnimation _idle1;
  ActorAnimation _blink1;
  Map<String, ActorAnimation> _phaseAnimations = new Map();
  ActorNode _pivot;
  ActorNode _minutesArm;
  ActorNode _hoursArm;

  @override
  void initialize(FlutterActorArtboard artboard) {
    super.initialize(artboard);
    _currentArtboard = artboard;
    _idle1 = artboard.getAnimation("idle_cycle_1");
    _blink1 = artboard.getAnimation("blink_1");
    _phaseAnimations["from_dawn"] = artboard.getAnimation("from_dawn");
    _phaseAnimations["from_noon"] = artboard.getAnimation("from_noon");
    _phaseAnimations["from_twilight"] = artboard.getAnimation("from_twilight");
    _phaseAnimations["from_night"] = artboard.getAnimation("from_night");
    _hoursArm = artboard.getNode("HoursNode");
    _minutesArm = artboard.getNode("MinutesNode");
    _pivot = artboard.getNode("PivotNode");
    play("open");
  }

  @override
  void setViewTransform(Mat2D viewTransform) {}

  @override
  bool advance(FlutterActorArtboard artboard, double elapsed) {
    super.advance(artboard, elapsed);
    _elapsedTime += elapsed;

    if (double.parse(_elapsedTime.toStringAsFixed(2)) %
            double.parse(_idle1.duration.toStringAsFixed(2)) ==
        0) {
      math.Random().nextBool() ? play("idle_cycle_1") : play("idle_cycle_2");
    }
    if (double.parse(_elapsedTime.toStringAsFixed(2)) %
            double.parse(_blink1.duration.toStringAsFixed(2)) ==
        0) {
      math.Random().nextBool() ? play("blink_1") : play("blink_2");
    }

    return true;
  }

  void updateTime(hours, minutes, seconds, currentPhase) {
    if (currentPhase == null)
      currentPhase = {
        "name": "dawn",
        "duration": 100,
        "progress": 0,
      };
    if (_hoursArm == null || _minutesArm == null) return;
    _hoursArm.rotation = math.pi * ((hours % 12) * 60 + minutes) / 720 * 2;
    _minutesArm.rotation = math.pi * ((minutes * 60 + seconds) / 3600 * 2 - 1);
    _pivot.rotation = math.pi * 1.0;

    _phaseAnimations["from_${currentPhase["name"]}"].apply(
        currentPhase["progress"] / currentPhase["duration"],
        _currentArtboard,
        1.0);
  }
}
