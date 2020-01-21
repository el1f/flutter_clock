// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:analog_clock/eye_controller.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter_clock_helper/model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:vector_math/vector_math_64.dart' show radians;

final locationsPhases = {
  "Mountain View, CA": {
    "dawn": {
      "start": "06:51",
      "end": "07:19",
    },
    "noon": {
      "start": "07:20",
      "end": "17:19",
    },
    "twilight": {
      "start": "17:20",
      "end": "17:48",
    },
    "night": {
      "start": "17:48",
      "end": "06:50",
    },
  }
};

final phaseColors = {
  "dawn": Color(0xFFFFD38B),
  "noon": Color(0xFFF8C33D),
  "twilight": Color(0xFFFFAC41),
  "night": Color(0xFFE2A2CD)
};

Map<String, dynamic> getPhase(DateTime time, String location) {
  if (location == null || locationsPhases[location] == null) return null;
  var currentLocationPhases = locationsPhases[location].entries;
  for (var phase in currentLocationPhases) {
    var start = DateTime.parse(
        DateFormat("yyyy-MM-dd ").format(time) + phase.value["start"] + ":00");
    var end = DateTime.parse(
        DateFormat("yyyy-MM-dd ").format(time) + phase.value["end"] + ":00");

    // TODO: Add phase calculation logic

    if (phase.key == "night" &&
        ((time.isAfter(start) && time.isBefore(Jiffy().endOf("day"))) ||
            (time.isBefore(end) && time.isAfter(Jiffy().startOf("day")))))
      return {
        "name": phase.key,
        "duration": (end.add(Duration(days: 1))).difference(start).inSeconds,
        "progress": (time.isAfter(start) && time.isBefore(Jiffy().endOf("day")))
            ? (end.add(Duration(days: 1))).difference(time).inSeconds
            : (end.add(Duration(days: 1))).difference(start).inSeconds -
                end.difference(time).inSeconds
      };
    if (time.isAfter(start) && time.isBefore(end))
      return {
        "name": phase.key,
        "duration": end.difference(start).inSeconds,
        "progress": time.difference(start).inSeconds
      };
  }
}

final radiansPerTick = radians(360 / 60);

/// Total distance traveled by an hour hand, each hour, in radians.
final radiansPerHour = radians(360 / 12);

/// A basic analog clock.
///
/// You can do better than this!
class AnalogClock extends StatefulWidget {
  const AnalogClock(this.model);

  final ClockModel model;

  @override
  _AnalogClockState createState() => _AnalogClockState();
}

class _AnalogClockState extends State<AnalogClock> {
  var _now = DateTime.now();
  Map<String, dynamic> _currentPhase;
  var _temperature = '';
  var _temperatureRange = '';
  var _condition = '';
  var _location = '';
  Timer _timer;

  EyeController _eyeController;
  String _idleAnimation = "idle_cycle_1";

  @override
  void initState() {
    _eyeController = EyeController();
    super.initState();
    widget.model.addListener(_updateModel);
    // Set the initial values.
    _updateTime();
    _updateModel();
  }

  @override
  void didUpdateWidget(AnalogClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.model.removeListener(_updateModel);
    super.dispose();
  }

  void _updateModel() {
    setState(() {
      _temperature = widget.model.temperatureString;
      _temperatureRange = '(${widget.model.low} - ${widget.model.highString})';
      _condition = widget.model.weatherString;
      _location = widget.model.location;
    });
  }

  void _updateTime() {
    setState(() {
      _now = DateTime.now();
      // Update once per second. Make sure to do it at the beginning of each
      // new second, so that the clock is accurate.
      _timer = Timer(
        Duration(seconds: 1) - Duration(milliseconds: _now.millisecond),
        _updateTime,
      );
      _currentPhase = getPhase(_now, _location);
    });
  }

  void _onIdleCycleCompletion(String animationName) {
    Random rng = new Random();
    if (rng.nextBool()) return;
    setState(() {
      this._idleAnimation = this._idleAnimation == "idle_cycle_1"
          ? "idle_cycle_2"
          : "idle_cycle_1";
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isLight = Brightness.light == Theme.of(context).brightness;

    _eyeController.updateTime(
        _now.hour, _now.minute, _now.second, _currentPhase);

    var dayStyle = TextStyle(
      fontSize: 100,
      height: .15,
      color: phaseColors[_currentPhase != null ? _currentPhase["name"] : "dawn"]
          .withAlpha(isLight ? 50 : 100),
      fontFamily: "Poppins",
      fontWeight: FontWeight.w800,
    );

    var monthStyle = TextStyle(
      fontSize: 28,
      height: .8,
      color: isLight ? Colors.grey.shade900 : Colors.grey.shade50,
      fontFamily: "Poppins",
      fontWeight: FontWeight.w800,
    );

    return Stack(
      children: <Widget>[
        Positioned(
          child: Text(DateFormat("DD").format(_now), style: dayStyle),
          bottom: 16,
          left: 16,
        ),
        Positioned(
          child: Text(DateFormat("MMMM").format(_now), style: monthStyle),
          bottom: 16,
          left: 48,
        ),
        Positioned(
          child: new FlareActor(
            "assets/clock.flr",
            alignment: Alignment.center,
            fit: BoxFit.cover,
            callback: _onIdleCycleCompletion,
            controller: _eyeController,
          ),
        ),
      ],
    );
  }
}
