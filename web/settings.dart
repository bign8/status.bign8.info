import 'dart:html';
import 'dart:async' show StreamController, Stream;
import 'dart:convert' show json, JsonEncoder;

import 'package:json_annotation/json_annotation.dart';

part 'settings.g.dart';

@JsonSerializable(nullable: false)
class Settings {
  static const String SID = "status-options";

  final Map<String, String> svcz;
  final Map<String, String> envz;
  final List<String> noop;
  final int span;
  Settings({this.svcz, this.envz, this.noop, this.span});
  factory Settings.fromJson(Map<String, dynamic> json) => _$SettingsFromJson(json);
  Map<String, dynamic> toJson() => _$SettingsToJson(this);

  factory Settings.fromEnv() {
    if (window.localStorage.containsKey(SID)) {
      try {
        return new Settings.fromJson(json.decode(window.localStorage[SID]));
      } catch (e, t) {
        print('Problem Parsing Settings : (reverting to defaults)');
        print(e);
        print(t);
      }
    }
    return Settings.defaults();
  }
  factory Settings.defaults() {
    return Settings(
      envz: {
        "Google": "www.google.com",
        "Twitter": "www.twitter.com",
        "Facebook": "www.facebook.com",
        "Github": "github.com",
        "Snapchat": "www.snapchat.com",
        "Instagram": "www.instagram.com"
      },
      svcz: {
        "Robots": "https://\$/robots.txt",
        "Humans": "https://\$/humans.txt",
        "service-1": "@/rand#demo",
        "service-2": "@/rand#demo",
        "service-3": "@/rand#demo"
      },
      noop: ["Instagram-Humans", "Snapchat-Humans", "Twitter-Humans"],
      span: 90,
    );
  }
  void save() {
    window.localStorage[SID] = json.encode(this.toJson());
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
    active = new Settings.fromEnv();
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
      active = new Settings.fromJson(json.decode(input.value));
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
