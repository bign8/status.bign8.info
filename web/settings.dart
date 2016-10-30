import 'dart:html';
import 'package:json_object/json_object.dart';

abstract class Options {
  Map<String, String> svcz;
  Map<String, String> envz;
  List<String> noop;
  int span; // update interval in seconds
}

class Settings extends JsonObject implements Options {
  static const String SID = "status-options";

  factory Settings() {
    if (window.localStorage.containsKey(SID)) {
      try {
        return new Settings.fromJsonString(window.localStorage[SID]);
      } catch (e, t) {
        print('Problem Parsing Settings');
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

  factory Settings.fromJsonString(string) =>
      new JsonObject.fromJsonString(string, new Settings._new());

  Duration interval() => new Duration(seconds: span);
}
