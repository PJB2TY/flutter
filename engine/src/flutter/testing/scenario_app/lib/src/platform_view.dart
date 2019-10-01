// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';

import 'scenario.dart';

List<int> _to32(int value) {
  final Uint8List temp = Uint8List(4);
  temp.buffer.asByteData().setInt32(0, value, Endian.little);
  return temp;
}

List<int> _to64(num value) {
  final Uint8List temp = Uint8List(15);
  if (value is double) {
    temp.buffer.asByteData().setFloat64(7, value, Endian.little);
  } else if (value is int) {
    temp.buffer.asByteData().setInt64(7, value, Endian.little);
  }
  return temp;
}

/// A simple platform view.
class PlatformViewScenario extends Scenario
    with _BasePlatformViewScenarioMixin {
  /// Creates the PlatformView scenario.
  ///
  /// The [window] parameter must not be null.
  PlatformViewScenario(Window window, String text, {int id = 0})
      : assert(window != null),
        super(window) {
    constructScenario(window, text, id);
  }

  @override
  void onBeginFrame(Duration duration) {
    final SceneBuilder builder = SceneBuilder();

    builder.pushOffset(0, 0);

    finishBuilderByAddingPlatformViewAndPicture(builder, 0);
  }
}

/// Platform view with clip rect.
class PlatformViewClipRectScenario extends Scenario
    with _BasePlatformViewScenarioMixin {
  /// Constructs a platform view with clip rect scenario.
  PlatformViewClipRectScenario(Window window, String text, {int id = 0})
      : assert(window != null),
        super(window) {
    constructScenario(window, text, id);
  }

  @override
  void onBeginFrame(Duration duration) {
    final SceneBuilder builder = SceneBuilder();
    builder.pushOffset(0, 0);
    builder.pushClipRect(const Rect.fromLTRB(100, 100, 400, 400));
    finishBuilderByAddingPlatformViewAndPicture(builder, 1);
  }
}

/// Platform view with clip rrect.
class PlatformViewClipRRectScenario extends PlatformViewScenario {
  /// Constructs a platform view with clip rrect scenario.
  PlatformViewClipRRectScenario(Window window, String text, {int id = 0})
      : super(window, text, id: id);

  @override
  void onBeginFrame(Duration duration) {
    final SceneBuilder builder = SceneBuilder();

    builder.pushOffset(0, 0);
    builder.pushClipRRect(
      RRect.fromLTRBAndCorners(
        100,
        100,
        400,
        400,
        topLeft: const Radius.circular(15),
        topRight: const Radius.circular(50),
        bottomLeft: const Radius.circular(50),
      ),
    );
    finishBuilderByAddingPlatformViewAndPicture(builder, 2);
  }
}

/// Platform view with clip path.
class PlatformViewClipPathScenario extends PlatformViewScenario {
  /// Constructs a platform view with clip rrect scenario.
  PlatformViewClipPathScenario(Window window, String text, {int id = 0})
      : super(window, text, id: id);

  @override
  void onBeginFrame(Duration duration) {
    final SceneBuilder builder = SceneBuilder();

    builder.pushOffset(0, 0);

    // Create a path of rectangle with width of 200 and height of 300, starting from (100, 100).
    //
    // Refer to "../../ios/Scenarios/Scenarios/ScenariosUITests/golden_platform_view_clippath_iPhone SE_simulator.png" for the exact path after clipping.
    Path path = Path();
    path.moveTo(100, 100);
    path.quadraticBezierTo(50, 250, 100, 400);
    path.lineTo(350, 400);
    path.cubicTo(400, 300, 300, 200, 350, 100);
    path.close();
    builder.pushClipPath(path);

    finishBuilderByAddingPlatformViewAndPicture(builder, 3);
  }
}

/// Platform view with transform.
class PlatformViewTransformScenario extends PlatformViewScenario {
  /// Constructs a platform view with transform scenario.
  PlatformViewTransformScenario(Window window, String text, {int id = 0})
      : super(window, text, id: id);

  @override
  void onBeginFrame(Duration duration) {
    final SceneBuilder builder = SceneBuilder();

    builder.pushOffset(0, 0);
    final Matrix4 matrix4 = Matrix4.identity()
      ..rotateZ(1)
      ..scale(0.5, 0.5, 1.0)
      ..translate(1000.0, 100.0, 0.0);

    builder.pushTransform(matrix4.storage);

    finishBuilderByAddingPlatformViewAndPicture(builder, 4);
  }
}

/// Platform view with opacity.
class PlatformViewOpacityScenario extends PlatformViewScenario {
  /// Constructs a platform view with transform scenario.
  PlatformViewOpacityScenario(Window window, String text, {int id = 0})
      : super(window, text, id: id);

  @override
  void onBeginFrame(Duration duration) {
    final SceneBuilder builder = SceneBuilder();

    builder.pushOffset(0, 0);
    builder.pushOpacity(150);

    finishBuilderByAddingPlatformViewAndPicture(builder, 5);
  }
}

mixin _BasePlatformViewScenarioMixin on Scenario {
  int _textureId;

  /// Construct the platform view related scenario
  ///
  /// It prepare a TextPlatformView so it can be added to the SceneBuilder in `onBeginFrame`.
  /// Call this method in the constructor of the platform view related scenarios
  /// to perform necessary set up.
  void constructScenario(Window window, String text, int id) {
    const int _valueInt32 = 3;
    const int _valueFloat64 = 6;
    const int _valueString = 7;
    const int _valueUint8List = 8;
    const int _valueMap = 13;
    final Uint8List message = Uint8List.fromList(<int>[
      _valueString,
      'create'.length, // this won't work if we use multi-byte characters.
      ...utf8.encode('create'),
      _valueMap,
      if (Platform.isIOS)
        3, // 3 entries in map for iOS.
      if (Platform.isAndroid)
        6, // 6 entries in map for Android.
      _valueString,
      'id'.length,
      ...utf8.encode('id'),
      _valueInt32,
      ..._to32(id),
      _valueString,
      'viewType'.length,
      ...utf8.encode('viewType'),
      _valueString,
      'scenarios/textPlatformView'.length,
      ...utf8.encode('scenarios/textPlatformView'),
      if (Platform.isAndroid) ...<int>[
        _valueString,
        'width'.length,
        ...utf8.encode('width'),
        _valueFloat64,
        ..._to64(500.0),
        _valueString,
        'height'.length,
        ...utf8.encode('height'),
        _valueFloat64,
        ..._to64(500.0),
        _valueString,
        'direction'.length,
        ...utf8.encode('direction'),
        _valueInt32,
        ..._to32(0), // LTR
      ],
      _valueString,
      'params'.length,
      ...utf8.encode('params'),
      _valueUint8List,
      text.length,
      ...utf8.encode(text),
    ]);

    window.sendPlatformMessage(
      'flutter/platform_views',
      message.buffer.asByteData(),
      (ByteData response) {
        if (Platform.isAndroid) {
          _textureId = response.getInt64(2);
        }
      },
    );
  }

  // Add a platform view and a picture to the scene, then finish the `sceneBuilder`.
  void finishBuilderByAddingPlatformViewAndPicture(SceneBuilder sceneBuilder, int viewId) {
    if (Platform.isIOS) {
      sceneBuilder.addPlatformView(viewId, width: 500, height: 500);
    } else if (Platform.isAndroid && _textureId != null) {
      sceneBuilder.addTexture(_textureId,
          offset: const Offset(150, 300), width: 500, height: 500);
    } else {
      throw UnsupportedError(
          'Platform ${Platform.operatingSystem} is not supported');
    }
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.drawCircle(
      const Offset(50, 50),
      50,
      Paint()..color = const Color(0xFFABCDEF),
    );
    final Picture picture = recorder.endRecording();
    sceneBuilder.addPicture(const Offset(300, 300), picture);
    final Scene scene = sceneBuilder.build();
    window.render(scene);
    scene.dispose();
  }
}
