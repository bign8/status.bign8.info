var Settings = function() {
  var KEY = "status-options-2";

  this.options = {
    'rows': {}, // row titles -> substitution strings
    'cols': {}, // col titles -> substitution strings
    'nope': [], // svc env pairs to not load
    'freq': 0, // update interval in seconds
  };

  try {
    this.options = JSON.parse(window.localStorage[KEY]);
  } catch(e) {
    console.log(e);
    console.log("Resetting to default config");
    this.options['rows'] = {
      "Google": "www.google.com",
      "Twitter": "www.twitter.com",
      "Facebook": "www.facebook.com",
      "Github": "github.com",
      "Snapchat": "www.snapchat.com",
      "Instagram": "www.instagram.com",
    };
    this.options['cols'] = {
      "Robots": "https://\$/robots.txt",
      "Humans": "https://\$/humans.txt",
      "service-1": "@/rand#demo",
      "service-2": "@/rand#demo",
      "service-3": "@/rand#demo",
    };
    this.options['nope'] = ["Instagram-Humans", "Snapchat-Humans", "Twitter-Humans"];
    this.span = 90;
  }
};
