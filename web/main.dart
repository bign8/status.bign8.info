import 'dart:html';
import 'dart:async';
import 'dart:convert';

// TODO: favicon http://stackoverflow.com/questions/260857/changing-website-favicon-dynamically

/*
{
  "svcz": {
    "trans": "translate.$domain/health",
    "lux": "docsserver.$domain/api/v1/health"
  },
  "envz": {
    "dev": "wk-dev.wdesk.org",
    "stage": "sandbox.wdesk.com",
    "prod": "app.wdesk.com"
  },
  "skip": ["lux-prod"]
}
 */

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
  options.onChange.listen((e) => draw(table, options));
  draw(table, options);
}

draw(TableElement table, Settings optz) {
  table.setInnerHtml(''); // clear
  TableRowElement thead = table.createTHead().addRow();
  thead.addCell(); // empty corner
  for (var env in optz.envz.keys) {
    thead.addCell().text = env;
  }
  TableSectionElement tbody = table.createTBody();
  for (var key in optz.svcz.keys) {
    createRow(optz, tbody.addRow(), key);
  }
}

createRow(Settings optz, TableRowElement row, String svc) {
  row.addCell().text = svc;
  for (var env in optz.envz.keys) {
    row.addCell().append(new StatusElement(optz, env, svc));
  }
}

// TODO: make this extend a DivElement so consumption can be simplified
class StatusElement extends DivElement {

  StatusElement.created() : super.created() {
    print("Status Created");
  }

  factory StatusElement(Settings optz, String env, String svc) {
    var spot = new DivElement();
    var load = new DivElement()..classes.add("loader");

    var obj = new DivElement()
      ..classes.add("wrap")
      ..append(spot)
      ..append(load);

    load.append(new DivElement()..classes.addAll(["spinner", "pie"]));
    load.append(new DivElement()..classes.addAll(["filler", "pie"]));
    load.append(new DivElement()..classes.add("mask"));

    new Status(optz, spot, env, svc);

    return obj;
  }
}

class Status {
  DivElement obj;
  String target;
  Timer last;

  Status(Settings optz, this.obj, String env, String svc) {
    obj.classes.add('status');
    obj.onClick.listen((e) => run());
    this.target = "https://" + optz.svcz[svc].replaceFirst("\$domain", optz.envz[env]);

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
