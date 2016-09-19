import 'dart:html';
import 'dart:async';

// TODO: favicon http://stackoverflow.com/questions/260857/changing-website-favicon-dynamically

// TODO: load these from localstorage
Map<String, List<String>> services = {
  "trans": ["translate", "/health"],
  // "lux": ["docsserver", "/api/v1/health"],
};

Map<String, String> envs = {
  "local": "localhost:6070",
  // "dev": "wk-dev.wdesk.org",
  // "stage": "sandbox.wdesk.com",
  // "prod": "app.wdesk.com",
};


void main() {
  DivElement container = document.getElementById("container");

  TableElement table = new TableElement();
  TableRowElement thead = table.createTHead().addRow();
  thead.addCell(); // empty corner
  for (var env in envs.keys) {
    thead.addCell().text = env;
  }
  TableSectionElement tbody = table.createTBody();
  for (var key in services.keys) {
    createRow(tbody.addRow(), key);
  }
  container.children.add(table);

  // Storage store = window.localStorage;
  // if (store.containsKey("status")) {
  //   print("yep");
  // } else {
  //   print("nope");
  // }
  // store["status"] = "here";
}

createRow(TableRowElement row, String svc) {
  row.addCell().text = svc;
  for (var env in envs.keys) {
    DivElement status = new DivElement();
    new Status(status, env, svc);
    row.addCell().append(status);
    // row.addCell().append(new Status(env, svc));
  }
}

// TODO: make this extend a DivElement so consumption can be simplified
class Status {
  DivElement obj;
  String target;
  Timer last;

  Status(this.obj, String env, String svc) {
    obj.classes.addAll(['status', 'status-loading']);
    obj.onClick.listen((e) => run());
    var e = envs[env], s = services[svc];
    this.target = "https://";
    if (e.contains("localhost")) {
      this.target = "http://";
    } else {
      this.target += s[0] + ".";
    }
    this.target += e + s[1];
    run();
  }

  done(int status) {
    if (last != null) last.cancel();
    obj.classes.removeAll(['status-loading', 'status-ok', 'status-warn', 'status-bad']);
    if (200 <= status && status < 300) {
      obj.classes.add('status-ok');
    } else if (status == 429) {
      obj.classes.add('status-warn');
    } else {
      obj.classes.add('status-bad');
    }

    // Set text + timeouts based on response
    var time = new Duration(minutes: 1);
    if (status < 200) {
      obj.text = "err";
      time = new Duration(minutes: 15);
    } else {
      obj.text = status.toString();
    }

    last = new Timer(time, run);
  }

  // after a timeout, wait for an animation frame to actually run things
  run() => window.animationFrame.then((delta) => checker(this.target).then(done));
}

Future<int> checker(String url) {
  var completer = new Completer<int>(), xhr = new HttpRequest();
  xhr.open('GET', "http://localhost:8081/proxy?url=" + url, async: true);
  xhr.onLoad.listen((e) => completer.complete(e.target.status));
  xhr.onError.listen((e) => completer.complete(e.target.status));
  xhr.send();
  return completer.future;
}
