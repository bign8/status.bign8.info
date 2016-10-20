package main

//go:generate pub build
//go:generate cp web/main.dart build/web
//go:generate go-bindata -o static.go -prefix build/web build/web

import (
	"crypto/tls"
	"flag"
	"fmt"
	"io"
	"math/rand"
	"net/http"
	"strings"
)

var (
	port = flag.String("port", ":8081", "port to serve from")
	skip = flag.Bool("skip", true, "should the proxy skip ssl verify")
)

type proxy struct {
	client *http.Client
}

func (p *proxy) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	url := r.URL.Query().Get("url")
	if url == "" {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte("No URL query provided"))
		return
	}
	res, err := p.client.Get(url)
	if err != nil {
		w.WriteHeader(http.StatusBadGateway)
		w.Write([]byte("Error getting: " + err.Error()))
		return
	}
	for key, value := range res.Header {
		w.Header()[key] = value
	}
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.WriteHeader(res.StatusCode)
	defer res.Body.Close()
	io.Copy(w, res.Body)
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
}

func main() {
	flag.Parse()

	tr := &http.Transport{
		TLSClientConfig: &tls.Config{InsecureSkipVerify: *skip},
	}
	client := &http.Client{Transport: tr}
	http.Handle("/proxy", &proxy{client: client})
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
