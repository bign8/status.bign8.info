import 'dart:html';
import 'dart:math' show Random;
import 'dart:async';

import 'state.dart';

var _rander = new Random();

class Status {
  Timer last;
  String url;
  int interval;
  DivElement _ele, _spot;
  State _state;

  Status(this.url, this.interval) {
    _spot = new DivElement()
      ..classes.add('status')
      ..onClick.listen((e) => run());

    _ele = new DivElement()
      ..classes.add('wrap')
      ..append(_spot);
  }

  Duration get _jitter => new Duration(seconds: _rander.newxtInt(interval));
  DivElement get element => _ele;
  run() => window.animationFrame.then((x) => check());

  void check() {
    if (last != null) last.cancel();
    _ele.classes.remove(state2class(_state));
    // something with last

    last = new Timer(_jitter, run);
  }
}
