import 'dart:html';
// import 'dart:async';

import 'settings.dart';
import 'state.dart';
import 'grid.dart';

class Application {
  final _host = window.location.origin.contains("localhost")
      ? "http://localhost:8081"
      : window.location.origin;

  setState(State s) => _icon.href = "$_host/favicon.png?color=${color(s)}";
  final LinkElement _icon = () {
    List<LinkElement> links = document.getElementsByTagName("link");
    for (var link in links) if (link.rel == "icon") return link;
  }();

  SettingsManager options;
  Grid table;

  Application() {
    setState(State.UNKNOWN);
    options = new SettingsManager();
  }

  void init() {
    table = new Grid(_host, options.active);
    options.onChange.listen(table.update);
    table.onChange.listen(setState);
  }

  void run() {
    table.draw();
  }
}

void main() {
  Application app = new Application();
  app.init();
  app.run();
}

// // TODO: make this extend a DivElement so consumption can be simplified
// class StatusElement extends DivElement {
//   StatusElement.created() : super.created();
//
//   factory StatusElement(Settings optz, String env, String svc) {
//     var load = new DivElement(); //..classes.add("loader");
//
//     var obj = new DivElement()
//       ..classes.add("wrap")
//       ..append(load);
//
//     // load.append(new DivElement()..classes.addAll(["spinner", "pie"]));
//     // load.append(new DivElement()..classes.addAll(["filler", "pie"]));
//     // load.append(new DivElement()..classes.add("mask"));
//     // var spinner = new Spinner(load);
//     return obj;
//   }
// }
//
// class Spinner {
//   DivElement loader, spinner, filler, mask;
//   StreamController done = new StreamController.broadcast();
//
//   Spinner(this.loader) {
//     spinner = new DivElement()..classes.addAll(["spinner", "pie"]);
//     filler = new DivElement()..classes.addAll(["filler", "pie"]);
//     mask = new DivElement()..classes.add("mask");
//     this.loader
//       ..append(spinner)
//       ..append(filler)
//       ..append(mask)
//       ..classes.add("loader");
//   }
//
//   start(Duration dur) {}
//
//   Stream get onComplete => done.stream;
// }
