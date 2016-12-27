package ci

import (
	"crypto"
	"crypto/rsa"
	"crypto/sha1"
	"crypto/x509"
	"encoding/base64"
	"encoding/json"
	"encoding/pem"
	"errors"
	"net/http"
)

type travis struct {
	key string
}

var Travis = &travis{}

func (t *travis) Verify(r *http.Request) error {
	r.ParseForm()

	// Parse data from request
	msg := []byte(r.FormValue("payload"))
	sig, _ := base64.StdEncoding.DecodeString(r.Header.Get("Signature"))
	hashed := sha1.Sum(msg)

	// Download key if not available
	if t.key == "" {
		if err := t.load(); err != nil {
			return errors.New("failed to load key from travis-ci: " + err.Error())
		}
	}

	// Parse Block
	block, _ := pem.Decode([]byte(t.key))
	if block == nil {
		return errors.New("failed to parse PEM block containing the public key")
	}

	// Parse key
	pub, err := x509.ParsePKIXPublicKey(block.Bytes)
	if err != nil {
		return errors.New("failed to parse DER encoded public key: " + err.Error())
	}

	// Verify type
	switch pub := pub.(type) {
	case *rsa.PublicKey:
		return rsa.VerifyPKCS1v15(pub, crypto.SHA1, hashed[:], sig)
	default:
		return errors.New("unknown type of public key")
	}
}

func (t *travis) load() error {
	// TODO: parse .org or .com from "build_url" of post data
	r, err := http.Get("https://api.travis-ci.org/config")
	if err != nil {
		return err
	}
	if r.StatusCode != http.StatusOK {
		return errors.New("Non-200 response code")
	}
	obj := struct {
		Config struct {
			Notifications struct {
				Webhook struct {
					PublicKey string `json:"public_key"`
				} `json:"webhook"`
			} `json:"notifications"`
		} `json:"config"`
	}{}
	err = json.NewDecoder(r.Body).Decode(&obj)
	if err == nil {
		t.key = obj.Config.Notifications.Webhook.PublicKey
	}
	return err
}
