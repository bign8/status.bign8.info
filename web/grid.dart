import 'dart:html';
import 'dart:async' show StreamController, Stream;

import 'settings.dart';
import 'state.dart';

class Grid {
  StreamController<State> _state = new StreamController.broadcast();
  Settings active;
  String host;
  TableElement table;

  Grid(this.host, this.active) {
    table = new TableElement();
    document.body.append(table);
  }

  Stream<State> get onChange => _state.stream;

  void update(Settings options) {
    // TODO: do clean update between old and new settings
  }

  void draw() {
    print('Drawing Grid!');
  }
}
