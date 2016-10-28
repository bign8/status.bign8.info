package main

import (
	"image/color"
	"net/http"
	"net/http/httptest"
	"testing"
)

func BenchmarkIcon(b *testing.B) {
	for i := 0; i < b.N; i++ {
		icon(&color.RGBA{167, 27, 25, 255}, &color.RGBA{241, 82, 80, 255})
	}
}

func TestFavicon(t *testing.T) {
	w := httptest.NewRecorder()
	r, _ := http.NewRequest("GET", "/favicon.png", nil)
	r.URL.Query().Add("color", "red")
	favicon(w, r)
}
