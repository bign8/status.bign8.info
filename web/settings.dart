import 'dart:html';
import 'dart:async' show StreamController, Stream;
import 'dart:convert' show json, JsonEncoder;

class Settings {
  static const String SID = "status-options";

  Map<String, String> svcz;
  Map<String, String> envz;
  List<String> noop;
  int span; // update interval in seconds

  factory Settings() {
    if (window.localStorage.containsKey(SID)) {
      try {
        return new Settings.fromJsonString(window.localStorage[SID]);
      } catch (e, t) {
        print('Problem Parsing Settings : (reverting to defaults)');
        print(e);
        print(t);
        return new Settings._init();
      }
    } else {
      return new Settings._init();
    }
  }

  Settings._new() {
    svcz = new Map<String, String>();
    envz = new Map<String, String>();
    noop = new List<String>();
  }

  factory Settings._init() {
    return new Settings._new()
      ..envz.addAll({
        "Google": "www.google.com",
        "Twitter": "www.twitter.com",
        "Facebook": "www.facebook.com",
        "Github": "github.com",
        "Snapchat": "www.snapchat.com",
        "Instagram": "www.instagram.com"
      })
      ..svcz.addAll({
        "Robots": "https://\$/robots.txt",
        "Humans": "https://\$/humans.txt",
        "service-1": "@/rand#demo",
        "service-2": "@/rand#demo",
        "service-3": "@/rand#demo"
      })
      ..noop.addAll(["Instagram-Humans", "Snapchat-Humans", "Twitter-Humans"])
      ..span = 90;
  }

  factory Settings.fromJsonString(string) {
    dynamic obj = json.decode(string);
    return new Settings._new()
      ..envz = obj["envz"] as Map<String, String>
      ..svcz = obj["svcz"] as Map<String, String>
      ..noop = obj["noop"] as List<String>
      ..span = obj["span"] as int;
  }

  void save() {
    window.localStorage[SID] = json.encode(this);
  }

  Duration interval() => new Duration(seconds: span);
}

class SettingsManager {
  StreamController<Settings> _updates = new StreamController.broadcast();
  Settings active;
  DivElement dialog;
  TextAreaElement input;
  JsonEncoder encoder;

  SettingsManager() {
    active = new Settings();
    encoder = new JsonEncoder.withIndent(' ');

    document.body.append(new ButtonElement()
      ..classes.addAll(['click', 'open'])
      ..setInnerHtml('&#x2699;')
      ..onClick.listen(open));

    input = new TextAreaElement();

    dialog = new DivElement()
      ..classes.addAll(['cover', 'hide'])
      ..onClick.listen(close)
      ..append(new DivElement()
        ..classes.add('cover-content')
        ..onClick.listen(swallow) // only background clicks close
        ..append(new ButtonElement()
          ..classes.addAll(['click', 'close'])
          ..setInnerHtml('&times;')
          ..onClick.listen(close))
        ..append(new ButtonElement()
          ..classes.addAll(['click', 'save'])
          ..setInnerHtml('&#x1f4be;')
          ..onClick.listen(save))
        ..append(input));

    document.body.append(dialog);
  }

  void swallow(final MouseEvent e) {
    e.preventDefault();
    e.stopPropagation();
  }

  void open(final MouseEvent e) {
    input.value = encoder.convert(active);
    dialog.classes.remove('hide');
  }

  void close(final MouseEvent e) {
    dialog.classes.add('hide');
  }

  void save(final MouseEvent e) {
    try {
      active = new Settings.fromJsonString(input.value);
    } on FormatException catch (e) {
      window.alert(e.toString().replaceFirst("FormatException: ", ""));
      return;
    } catch (e, t) {
      window.alert('Failed to parse options\n$e');
      print("$e\n$t");
      return;
    }
    active.save();
    close(e);
    _updates.add(active);
  }

  Stream<Settings> get onChange => _updates.stream;
}
