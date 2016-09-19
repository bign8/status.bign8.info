package main

//go:generate pub build
//go:generate go-bindata -o static.go -prefix build/web build/web

import (
	"crypto/tls"
	"fmt"
	"io"
	"net/http"
	"strings"
)

// TODO: serve static files

func main() {
	tr := &http.Transport{
		TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
	}
	client := &http.Client{Transport: tr}

	http.HandleFunc("/proxy", func(w http.ResponseWriter, r *http.Request) {
		url := r.URL.Query().Get("url")
		if url == "" {
			w.WriteHeader(http.StatusBadRequest)
			w.Write([]byte("No URL query provided"))
			return
		}
		res, err := client.Get(url)
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
	})
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
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
	})
	fmt.Println("Serving from :8081")
	http.ListenAndServe(":8081", nil)
}
