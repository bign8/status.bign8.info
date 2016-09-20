import 'dart:html';
import 'dart:async';

// TODO: favicon http://stackoverflow.com/questions/260857/changing-website-favicon-dynamically

// TODO: load these from localstorage
Map<String, List<String>> services = {
  "trans": ["translate", "/health"],
  "lux": ["docsserver", "/api/v1/health"],
};

Map<String, String> envs = {
  "dev": "wk-dev.wdesk.org",
  "stage": "sandbox.wdesk.com",
  "prod": "app.wdesk.com",
};

Set<String> skip = new Set<String>()..add('lux-prod');

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
    row.addCell().append(new StatusElement(env, svc));
    // row.addCell().append(new Status(env, svc));
  }
}

// TODO: make this extend a DivElement so consumption can be simplified
class StatusElement extends DivElement {

  StatusElement.created() : super.created() {
    print("Status Created");
  }

  factory StatusElement(String env, String svc) {
    var spot = new DivElement();
    var load = new DivElement();

    var obj = new DivElement()
      ..append(spot)
      ..append(load);

    new Status(spot, env, svc);

    return obj;
  }
}

class Status {
  DivElement obj;
  String target;
  Timer last;

  Status(this.obj, String env, String svc) {
    obj.classes.add('status');
    obj.onClick.listen((e) => run());
    var s = services[svc];
    this.target = "https://" + s[0] + "." + envs[env] + s[1];

    if (skip.contains(env + "-" + svc) || skip.contains(svc + "-" + env)) {
      obj.classes.add('status-ignore');
    } else {
      obj.classes.add('status-loading');
      run();
    }
  }

  done(int status) {
    if (last != null) last.cancel();
    obj.classes.removeAll(['status-loading', 'status-ignore', 'status-ok', 'status-warn', 'status-bad']);
    if (200 <= status && status < 300) {
      obj.classes.add('status-ok');
    } else if (status == 429) {
      obj.classes.add('status-warn');
    } else {
      obj.classes.add('status-bad');
    }

    // Set text + timeouts based on response
    if (status < 200) {
      obj.text = "err";
    } else {
      obj.text = status.toString();
    }
    last = new Timer(new Duration(minutes: 1), run);
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
