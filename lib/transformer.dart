// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library autonotify_observe.transformer;

import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;
import "package:observe/transformer.dart";
import "package:polymer_autonotify/transformer.dart";
import "package:polymer/transformer.dart";

class AutonotifyObserveTransformerGroup implements TransformerGroup {
  final Iterable<Iterable> phases;

  AutonotifyObserveTransformerGroup(BarbackSettings settings)
      : phases = createDeployPhases(settings);

  AutonotifyObserveTransformerGroup.asPlugin(BarbackSettings settings)
      : this(settings);
}

/// Create deploy phases for Polymer.
List<List<Transformer>> createDeployPhases(BarbackSettings settings) {
  List<List<Transformer>> phases = [
    [
      new AutonotifyTransformer.asPlugin(new BarbackSettings({}, settings.mode))
    ],
    [new ObservableTransformer.asPlugin(new BarbackSettings({}, settings.mode))]
  ];

  // Only autonotify and observe if no entry points
  if (settings.configuration.containsKey("entry_points")) {
    phases.add([new PolymerTransformerGroup.asPlugin(settings)]);
  }

  return phases;
}
