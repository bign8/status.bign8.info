package ci

import "net/http"

type Verifier interface {
	Verify(*http.Request) error
}

func bind(v Verifier) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if err := v.Verify(r); err != nil {
			w.WriteHeader(http.StatusUnauthorized)
			w.Write([]byte("Unauthorized"))
			return
		}
		w.Write([]byte("OK"))
		// TODO: actually process response
	}
}

func Bind() {
	http.HandleFunc("/api/ci/travis", bind(Travis))
	// http.HandleFunc("/api/ci/circle", bind(Circle))
}
