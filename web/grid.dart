import 'dart:html';
import 'dart:async' show StreamController, Stream;

import 'settings.dart';
import 'state.dart';
import 'status.dart';

class Grid {
  StreamController<State> _state = new StreamController.broadcast();
  Settings active;
  String host;
  TableElement table;
  List<Status> statuses;

  Grid(this.host, this.active) {
    statuses = new List<Status>();
    table = new TableElement();
    document.body.append(table);
  }

  Stream<State> get onChange => _state.stream;

  void update(Settings options) {
    // TODO: do clean update between old and new settings
  }

  void _ping(State s) {
    State val = s;
    for (Status stat in statuses) val = maxState(val, stat.state);
    _state.add(val);
  }

  void draw() {
    table.setInnerHtml('');
    TableRowElement thead = table.createTHead().addRow();
    thead.addCell(); // empty corner
    for (var env in active.envz.keys) thead.addCell().text = env;
    TableSectionElement tbody = table.createTBody();
    for (var key in active.svcz.keys) {
      TableRowElement row = tbody.addRow();
      row.addCell().text = key;
      for (var env in active.envz.keys) {
        String server = active.svcz[key]
            .replaceFirst("\$", active.envz[env])
            .replaceFirst("@", host);
        bool noop = active.noop.contains(env + "-" + key) ||
            active.noop.contains(key + "-" + env);
        Status nxt = new Status(host, server, active.span, !noop);
        row.addCell().append(nxt.element);
        statuses.add(nxt);
        nxt.onChange.listen(_ping);
      }
    }
  }
}
