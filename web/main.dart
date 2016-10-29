import 'dart:html';
import 'dart:math';
import 'dart:async';
import 'dart:convert';

// TODO: favicon http://stackoverflow.com/questions/260857/changing-website-favicon-dynamically

final host = () {
  if (window.location.origin.contains("localhost")) {
    return "http://localhost:8081";
  }
  return window.location.origin;
}();

class Settings {
  static final Settings _singleton = new Settings._internal();
  factory Settings() => _singleton;

  Map<String, String> svcz = new Map<String, String>();
  Map<String, String> envz = new Map<String, String>();
  Set<String> skip = new Set<String>();
  HtmlElement dialog, open, close, save;
  TextAreaElement input;
  JsonEncoder encoder;
  StreamController updates = new StreamController.broadcast();

  Settings._internal() {
    open = new ButtonElement()
      ..classes.addAll(['click', 'open'])
      ..setInnerHtml('&#x2699;')
      ..onClick.listen(openFn);
    close = new ButtonElement()
      ..classes.addAll(['click', 'close'])
      ..setInnerHtml('&times;')
      ..onClick.listen(closeFn);
    save = new ButtonElement()
      ..classes.addAll(['click', 'save'])
      ..setInnerHtml('&#x1f4be;')
      ..onClick.listen(saveFn);
    input = new TextAreaElement();
    dialog = new DivElement()
      ..classes.addAll(['cover', 'hide'])
      ..append(
        new DivElement()
          ..classes.add('cover-content')
          ..append(close)
          ..append(save)
          ..append(input)
      );
    document.body.append(dialog);
    document.body.append(open);

    // Setup JSON parser + initilize with localStorage data
    encoder = new JsonEncoder.withIndent(' ');
    if (window.localStorage.containsKey('status'))
      assign(window.localStorage['status']);
    else
      assign("""{
       "envz": {
        "Google": "www.google.com",
        "Twitter": "www.twitter.com",
        "Facebook": "www.facebook.com",
        "Github": "github.com",
        "Snapchat": "www.snapchat.com",
        "Instagram": "www.instagram.com"
       },
       "svcz": {
        "Robots": "https://\$/robots.txt",
        "Humans": "https://\$/humans.txt",
        "service-1": "@/rand#demo-only",
        "service-2": "@/rand#demo-only",
        "service-3": "@/rand#demo-only"
       },
       "skip": [
        "Instagram-Humans",
        "Snapchat-Humans",
        "Twitter-Humans"
       ]
      }""");
  }

  assign(String blob, {bool again: false}) {
    var before = json();
    try {
      Map optz = JSON.decode(blob);
      envz = optz['envz'];
      svcz = optz['svcz'];
      List s = optz['skip'];
      skip = s.toSet();
      window.localStorage['status'] = JSON.encode(json());
      updates.add('updated');
    } catch (e, t) {
      String suffix = again ? '(double-fail)' : '(reverting)';
      print('Problem Parsing Settings ' + suffix);
      print(e);
      print(t);
      if (!again) assign(JSON.encode(before), again: true);
    }
  }

  void openFn(MouseEvent e) {
    input.value = encoder.convert(json());
    dialog.classes.remove('hide');
  }

  void saveFn(MouseEvent e) {
    assign(input.value);
    closeFn(e);
  }

  Map json() => {'envz': envz, 'svcz': svcz, 'skip': skip.toList()};
  closeFn(MouseEvent e) => dialog.classes.add('hide');
  Stream get onChange => updates.stream;
}

void main() {
  Settings options = new Settings();
  TableElement table = new TableElement();
  document.body.append(table);
  new Monitor(table, options);
}

class Monitor {
  TableElement table;
  Settings opts;
  List<StatusElement> statuses;
  Map<String, int> status;

  Monitor(this.table, this.opts) {
    statuses = new List<StatusElement>();
    status = new Map<String, int>();
    opts.onChange.listen((e) => draw());
    draw();
  }

  draw() {
    // TODO(bign8): teardown existing items in statuses
    // TODO(bign8): do this intelligently... don't re-draw things that already exist
    table.setInnerHtml('');
    TableRowElement thead = table.createTHead().addRow();
    thead.addCell(); // empty corner
    for (var env in opts.envz.keys) {
      thead.addCell().text = env;
    }
    TableSectionElement tbody = table.createTBody();
    for (var key in opts.svcz.keys) {
      TableRowElement row = tbody.addRow();
      row.addCell().text = key;
      for (var env in opts.envz.keys) {
        StatusElement nxt = new StatusElement(opts, env, key, this);
        statuses.add(nxt);
        row.addCell().append(nxt);
      }
    }
  }

  setState(String slug, int val) {
    status[slug] = val;
    int active = val;
    for (var val in status.values) {
      if (active == 200) {
        active = val;
      } else if (val == 0){
        active = 500;
      } else if (val > active){
        active = val;
      }
    }
    var color = "gray";
    if (active == 200) {
      color = "green";
    } else if (active == 429) {
      color = "yellow";
    } else {
      color = "red";
    }
    List<Node> links = document.getElementsByTagName("link");
    for (var link in links) {
      if (link.attributes["rel"] == "icon") {
        link.attributes["href"] = "$host/favicon.png?color=$color";
      }
    }
  }
}

// TODO: make this extend a DivElement so consumption can be simplified
class StatusElement extends DivElement {

  StatusElement.created() : super.created() {
    print("Status Created");
  }

  factory StatusElement(Settings optz, String env, String svc, Monitor mon) {
    var spot = new DivElement();
    var load = new DivElement();//..classes.add("loader");

    var obj = new DivElement()
      ..classes.add("wrap")
      ..append(spot)
      ..append(load);

    // load.append(new DivElement()..classes.addAll(["spinner", "pie"]));
    // load.append(new DivElement()..classes.addAll(["filler", "pie"]));
    // load.append(new DivElement()..classes.add("mask"));

    var spinner = new Spinner(load);
    new Status(optz, spot, env, svc, spinner, mon);

    return obj;
  }
}

var _rander = new Random();

// Produce a value between 30s - 1m30s
Duration jittered() {
  var val = _rander.nextInt(60);
  return new Duration(seconds: val + 30);
}

class Status {
  DivElement obj;
  String target;
  Timer last;
  Spinner spin;
  Monitor mon;
  String slug;

  Status(Settings optz, this.obj, String env, String svc, this.spin, this.mon) {
    slug = "$svc-$env";
    obj.classes.add('status');
    obj.onClick.listen((e) => run());
    this.target = optz.svcz[svc].replaceFirst("\$", optz.envz[env]);
    this.target = this.target.replaceFirst("@", host);

    if (optz.skip.contains(env + "-" + svc) || optz.skip.contains(svc + "-" + env)) {
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
    mon.setState(slug, status);

    // Set text + timeouts based on response
    if (status < 200) {
      obj.text = "err";
    } else {
      obj.text = status.toString();
    }
    last = new Timer(jittered(), run);
  }

  // after a timeout, wait for an animation frame to actually run things
  run() => window.animationFrame.then((delta) => checker(this.target).then(done));
}

Future<int> checker(String url) {
  var completer = new Completer<int>(), xhr = new HttpRequest();
  xhr.open('GET', host + "/proxy?url=" + url, async: true);
  xhr.onLoad.listen((e) => completer.complete(e.target.status));
  xhr.onError.listen((e) => completer.complete(e.target.status));
  xhr.send();
  return completer.future;
}

class Spinner {
  DivElement loader, spinner, filler, mask;
  StreamController done = new StreamController.broadcast();

  Spinner(this.loader) {
    spinner = new DivElement()..classes.addAll(["spinner", "pie"]);
    filler = new DivElement()..classes.addAll(["filler", "pie"]);
    mask = new DivElement()..classes.add("mask");
    this.loader..append(spinner)..append(filler)..append(mask)..classes.add("loader");
  }

  start(Duration dur) {

  }

  Stream get onComplete => done.stream;
}
