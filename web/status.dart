import 'dart:html';
import 'dart:math' show Random;
import 'dart:async';

import 'state.dart';

var _rander = new Random();

class Status {
  StreamController<State> _updates = new StreamController.broadcast();
  Timer last;
  String host, url;
  int interval;
  DivElement _ele, _spot;
  State _state;
  bool active;

  static final _load_class = state2class(State.LOADING);

  Stream<State> get onChange => _updates.stream;
  State get state => _state;

  void set state(State s) {
    if (s == State.LOADING) {
      _spot.classes.add(_load_class);
      return;
    }
    if (_spot.classes.contains(_load_class)) _spot.classes.remove(_load_class);
    if (s == _state) return;
    String old = state2class(_state);
    if (_spot.classes.contains(old)) _spot.classes.remove(old);
    _spot.classes.add(state2class(s));
    _state = s;
    _updates.add(s);
  }

  Status(this.host, this.url, this.interval, this.active) {
    _state = State.LOADING;
    _spot = new DivElement()
      ..classes.add('status')
      ..onClick.listen((e) => run());

    _ele = new DivElement()
      ..classes.add('wrap')
      ..append(_spot);

    if (active)
      run(); // TODO (bign8): disable for the no-op things
    else
      state = State.UNKNOWN;
  }

  Duration get _jitter {
    int val = _rander.nextInt(interval);
    return new Duration(seconds: val > 20 ? val : 20);
  }

  DivElement get element => _ele;
  run() => window.animationFrame.then((x) => check());

  void check() {
    if (last != null) last.cancel();
    state = State.LOADING;
    checker().then((int x) {
      state = code2state(x);
      _spot.text = x < 200 ? "err" : x.toString();
      last = new Timer(_jitter, run);
    });
  }

  Future<int> checker() {
    var completer = new Completer<int>();
    new HttpRequest()
      ..open('GET', '$host/proxy?url=$url', async: true)
      ..onLoad.listen((e) => completer.complete(e.target.status))
      ..onError.listen((e) => completer.complete(e.target.status))
      ..send();
    return completer.future;
  }
}
