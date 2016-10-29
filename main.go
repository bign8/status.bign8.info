package main

//go:generate pub build
//go:generate cp web/main.dart build/web
//go:generate sed -i.bak s#\(.*\)#<style>\1</style># build/web/style.css
//go:generate sed -i.bak -e /stylesheet/{ -e rbuild/web/style.css -e d -e } build/web/index.html
//go:generate sed -i.bak -e /H.kq/d -e /createRuntimeType/d build/web/main.dart.js
//go:generate rm build/web/style.css.bak build/web/style.css build/web/index.html.bak build/web/main.dart.js.bak
//go:generate go-bindata -o build/static.go -pkg build -prefix build/web build/web

import (
	"bytes"
	"crypto/tls"
	"expvar"
	"flag"
	"fmt"
	"image"
	"image/color"
	"image/draw"
	"image/png"
	"io/ioutil"
	"math/rand"
	"net/http"
	_ "net/http/pprof"
	"net/url"
	"runtime"
	"strconv"
	"strings"
	"sync"
	"time"

	"./build" // generated source files for website
)

var (
	port = flag.String("port", ":8081", "port to serve from")
	skip = flag.Bool("skip", true, "should the proxy skip ssl verify")
	tout = flag.Duration("tout", time.Second, "cache expiration timeout")
)

type req struct {
	code int
	body []byte
	head http.Header
	tick *time.Timer
}

type proxy struct {
	client *http.Client
	cache  map[string]*req
	lock   sync.RWMutex
	ctr    *expvar.Int
	act    *expvar.Int
	hit    *expvar.Int
	mis    *expvar.Int
}

func cleanURL(raw string) (string, error) {
	loc, err := url.Parse(raw)
	if err == nil {
		loc.Fragment = ""
		loc.Opaque = ""
		loc.User = nil
		loc.RawQuery = ""
		raw = loc.String()
	}
	return raw, err
}

func (p *proxy) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	url := r.URL.Query().Get("url")
	if url == "" {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte("No URL query provided"))
		return
	}
	url, err := cleanURL(url)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte("Invalid URL in query"))
		return
	}
	p.ctr.Add(1)
	p.lock.RLock()
	obj, ok := p.cache[url]
	p.lock.RUnlock()

	if !ok {
		p.mis.Add(1)
		res, err := p.client.Get(url)
		if err != nil {
			w.WriteHeader(http.StatusBadGateway)
			w.Write([]byte("Error getting: " + err.Error()))
			return
		}
		obj = &req{
			code: res.StatusCode,
			head: res.Header,
			tick: time.AfterFunc(*tout, func() {
				p.lock.Lock()
				delete(p.cache, url)
				p.act.Set(int64(len(p.cache)))
				p.lock.Unlock()
			}),
		}
		obj.body, err = ioutil.ReadAll(res.Body)
		res.Body.Close()
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			w.Write([]byte("Error copying: " + err.Error()))
			return
		}
		p.lock.Lock()
		p.cache[url] = obj
		p.act.Set(int64(len(p.cache)))
		p.lock.Unlock()
	} else {
		p.hit.Add(1)
		obj.tick.Reset(*tout)
	}

	for key, value := range obj.head {
		w.Header()[key] = value
	}
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.WriteHeader(obj.code)
	w.Write(obj.body)
}

func index(w http.ResponseWriter, r *http.Request) {
	uri := r.URL.RequestURI()
	if uri == "/" {
		uri = "/index.html"
	}
	bits, err := build.Asset(uri[1:])
	if err != nil {
		http.NotFound(w, r)
	} else {
		if strings.HasSuffix(uri, ".css") {
			w.Header().Add("Content-Type", "text/css")
		}
		w.Write(bits)
	}
}

func random(w http.ResponseWriter, r *http.Request) {
	switch rand.Intn(10) {
	case 0:
		fallthrough
	case 1:
		w.WriteHeader(http.StatusInternalServerError)
	case 2:
		w.WriteHeader(http.StatusTooManyRequests)
	default:
		w.WriteHeader(http.StatusOK)
	}
	w.Write([]byte(strconv.Itoa(rand.Int())))
}

// https://blog.golang.org/go-imagedraw-package
type circle int

func (c circle) ColorModel() color.Model { return color.AlphaModel }
func (c circle) Bounds() image.Rectangle {
	r := int(c)
	return image.Rect(-r, -r, r, r)
}
func (c circle) At(x, y int) color.Color {
	xx, yy, rr := float64(x)+0.5, float64(y)+0.5, float64(c)
	if v := xx*xx + yy*yy - rr*rr; v < 0 {
		return color.Alpha{255} // inside
	} else if v > rr {
		return color.Alpha{0} // outside
	} else {
		return color.Alpha{uint8(255 * float64(1.0-v/rr))}
	}
}

// http://www.webpagefx.com/web-design/hex-to-rgb/
var colors = map[string][]byte{
	"green": icon(
		&color.RGBA{51, 153, 0, 255},   // #339900
		&color.RGBA{133, 214, 51, 255}, // #85d633
	),
	"red": icon(
		&color.RGBA{167, 27, 25, 255}, // #a71b19
		&color.RGBA{241, 82, 80, 255}, // #f15250
	),
	"yellow": icon(
		&color.RGBA{242, 108, 33, 255}, // #f26c21
		&color.RGBA{252, 189, 69, 255}, // #fcbd45
	),
	"": icon(
		&color.Gray{89},  // #595959
		&color.Gray{178}, // #b2b2b2
	),
}

func icon(ring, fill color.Color) []byte {
	top := image.Point{-8, -8}
	icon := image.NewRGBA(image.Rect(0, 0, 16, 16))
	draw.DrawMask(icon, icon.Bounds(), image.NewUniform(ring), image.ZP, circle(8), top, draw.Src)
	draw.DrawMask(icon, icon.Bounds(), image.NewUniform(fill), image.ZP, circle(7), top, draw.Over)
	bits := bytes.NewBuffer(make([]byte, 0, 255))
	if err := png.Encode(bits, icon); err != nil {
		panic(err)
	}
	return bits.Bytes()
}

func favicon(w http.ResponseWriter, r *http.Request) {
	if bits, ok := colors[r.URL.Query().Get("color")]; !ok {
		w.Write(colors[""])
	} else {
		w.Write(bits)
	}
}

func main() {
	flag.Parse()
	runStat := expvar.NewMap("runtime")
	runStat.Set("routines", expvar.Func(func() interface{} { return runtime.NumGoroutine() }))
	runStat.Set("cgo", expvar.Func(func() interface{} { return runtime.NumCgoCall() }))

	proxier := &proxy{
		client: &http.Client{
			Transport: &http.Transport{
				TLSClientConfig: &tls.Config{
					InsecureSkipVerify: *skip,
				},
			},
		},
		cache: make(map[string]*req),
		ctr:   &expvar.Int{},
		act:   &expvar.Int{},
		hit:   &expvar.Int{},
		mis:   &expvar.Int{},
	}
	proxyStat := expvar.NewMap("proxy")
	proxyStat.Set("total", proxier.ctr)
	proxyStat.Set("miss", proxier.mis)
	proxyStat.Set("size", proxier.act)
	proxyStat.Set("hit", proxier.hit)

	http.Handle("/proxy", proxier)
	http.HandleFunc("/rand", random)
	http.HandleFunc("/favicon.png", favicon)
	http.HandleFunc("/", index)

	if *skip {
		fmt.Println("Serving from " + *port + " skipping SSL validation")
	} else {
		fmt.Println("Serving from " + *port + " validating SSL")
	}
	if err := http.ListenAndServe(*port, nil); err != nil {
		fmt.Println(err.Error())
	}
}
