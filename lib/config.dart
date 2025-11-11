import 'package:flutter/material.dart';

class GameConfig {

  static const double playerSpeedNormal = 100;
  static const double playerSpeedRun = 160;
  static const double playerSpeedSlow = 60;

  static const double frameDuration = 0.12;
  static const int framesPerRow = 8;

  static const double playerSize = 80;


  static const double cameraZoom = 2.5;
  static const double cameraFollowSpeed = 200;


  static const double joystickKnobRadius = 30;
  static const double joystickBackgroundRadius = 60;
  static final Color joystickKnobColor = Colors.blue.shade200;
  static final Color joystickBackgroundColor = Colors.grey.shade200;
}
