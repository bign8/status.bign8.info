package main

//go:generate pub build
//go:generate cp web/main.dart build/web
//go:generate sass build/web/style.scss:build/web/style.css -C -t compressed --sourcemap=none
//go:generate sed -i.bak s#\(.*\)#<style>\1</style># build/web/style.css
//go:generate sed -i.bak -e /stylesheet/{ -e rbuild/web/style.css -e d -e } build/web/index.html
//go:generate rm build/web/style.scss build/web/style.css.bak build/web/style.css build/web/index.html.bak
//go:generate go-bindata -o static.go -prefix build/web build/web

import (
	"crypto/tls"
	"flag"
	"fmt"
	"io/ioutil"
	"math/rand"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"sync"
	"time"
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
	p.lock.RLock()
	obj, ok := p.cache[url]
	p.lock.RUnlock()

	if !ok {
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
		p.lock.Unlock()
	} else {
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
	bits, err := Asset(uri[1:])
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

func main() {
	flag.Parse()
	http.Handle("/proxy", &proxy{
		client: &http.Client{
			Transport: &http.Transport{
				TLSClientConfig: &tls.Config{
					InsecureSkipVerify: *skip,
				},
			},
		},
		cache: make(map[string]*req),
	})
	http.HandleFunc("/rand", random)
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
