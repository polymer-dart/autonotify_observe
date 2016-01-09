// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library autonotify_observe.transformer;

import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;
import 'package:reflectable/transformer.dart';
import 'package:web_components/transformer.dart';
import "package:observe/transformer.dart";
import "package:autonotify_observe/autonotify_transformer.dart";

class AutonotifyObserveTransformerGroup implements TransformerGroup {
  final Iterable<Iterable> phases;

  AutonotifyObserveTransformerGroup(BarbackSettings settings)
      : phases = createDeployPhases(settings);

  AutonotifyObserveTransformerGroup.asPlugin(BarbackSettings settings) : this(settings);
}

/// Create deploy phases for Polymer.
List<List<Transformer>> createDeployPhases(BarbackSettings settings) {
  //print("autonotfy_observe with:${settings.configuration}");
  var options = new TransformOptions(
      _readFileList(settings.configuration['entry_points'])
          .map(_systemToAssetPath)
          .toList(),
      settings.mode == BarbackMode.RELEASE);

  // Only autonotify and observe if no entry points
  if (options.entryPoints==null||options.entryPoints.isEmpty) {
    return [
      [
        new AutonotifyTransformer.asPlugin(new BarbackSettings({},settings.mode))
      ],
      [
        new ObservableTransformer.asPlugin(new BarbackSettings({},settings.mode))
      ]
    ];
  }

  return [
    /// Must happen first, temporarily rewrites <link rel="x-dart-test"> tags to
    /// <script type="application/dart" _was_test></script> tags.
    [new RewriteXDartTestToScript(options.entryPoints)],
    [new ScriptCompactorTransformer(options.entryPoints)],
    [new WebComponentsTransformer(options)],
    [
      new ImportInlinerTransformer(
          options.entryPoints, ['[[', '{{'])
    ],
    [
      new AutonotifyTransformer.asPlugin(new BarbackSettings({},settings.mode))
    ],
    [
      new ObservableTransformer.asPlugin(new BarbackSettings({},settings.mode))
    ],
    [
      new ReflectableTransformer.asPlugin(new BarbackSettings(
          _reflectableConfiguration(settings.configuration), settings.mode))
    ],

    /// Must happen last, rewrites
    /// <script type="application/dart" _was_test></script> tags back to
    /// <link rel="x-dart-test"> tags.
    [new RewriteScriptToXDartTest(options.entryPoints)],
  ];
}

/// Convert system paths to asset paths (asset paths are posix style).
String _systemToAssetPath(String assetPath) {
  if (path.Style.platform != path.Style.windows) return assetPath;
  return path.posix.joinAll(path.split(assetPath));
}

List<String> _readFileList(value) {
  var files = [];
  bool error;
  if (value is List) {
    files = value;
    error = value.any((e) => e is! String);
  } else if (value is String) {
    files = [value];
    error = false;
  } else {
    error = true;
  }
  /*
  if (error) {
    print('no "entry_points" given, running only autonotify and observe.');
  }*/
  return files;
}

Map _reflectableConfiguration(Map originalConfiguration) {
  return {
    'formatted': originalConfiguration['formatted'],
    'supressWarnings': originalConfiguration['supressWarnings'],
    'entry_points': _readFileList(originalConfiguration['entry_points'])
        .map((e) => e.replaceFirst('.html', '.bootstrap.initialize.dart'))
        .toList(),
  };
}
