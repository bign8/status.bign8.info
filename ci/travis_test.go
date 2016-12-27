package ci

import (
	"net/http"
	"net/url"
	"testing"
)

func TestTravisVerify(t *testing.T) {
	r, _ := http.NewRequest("POST", "localhost:4000/v1/ci/travis", nil)
	r.Form = url.Values{"payload": []string{"{\"id\":186906634,\"repository\":{\"id\":8394282,\"name\":\"games\",\"owner_name\":\"bign8\",\"url\":\"\"},\"number\":\"41\",\"config\":{\"language\":\"go\",\"go\":\"1.7.x\",\"notifications\":{\"email\":false,\"webhooks\":{\"urls\":[\"http://status.bign8.info/api/ci/travis\"],\"on_success\":\"always\",\"on_failure\":\"always\",\"on_start\":\"always\"}},\"install\":[\"go get github.com/Masterminds/glide\",\"glide install -v\"],\"script\":[\"go test -race -bench=. -benchmem -v $(glide nv)\"],\"cache\":{\"directories\":[\"$HOME/.glide\"]},\".result\":\"configured\",\"group\":\"stable\",\"dist\":\"precise\"},\"status\":0,\"result\":0,\"status_message\":\"Passed\",\"result_message\":\"Passed\",\"started_at\":\"2016-12-27T06:33:23Z\",\"finished_at\":\"2016-12-27T06:34:51Z\",\"duration\":88,\"build_url\":\"https://travis-ci.org/bign8/games/builds/186906634\",\"commit_id\":53377400,\"commit\":\"8fb25af2c7f2344a18ca0e25b82f1830da6d6f19\",\"base_commit\":null,\"head_commit\":null,\"branch\":\"clean\",\"message\":\"Adding webhook and cache to travis.yml\",\"compare_url\":\"https://github.com/bign8/games/compare/68f6a18021b0...8fb25af2c7f2\",\"committed_at\":\"2016-12-27T06:26:54Z\",\"author_name\":\"Nate Woods\",\"author_email\":\"big.nate.w@gmail.com\",\"committer_name\":\"Nate Woods\",\"committer_email\":\"big.nate.w@gmail.com\",\"matrix\":[{\"id\":186906635,\"repository_id\":8394282,\"parent_id\":186906634,\"number\":\"41.1\",\"state\":\"finished\",\"config\":{\"language\":\"go\",\"go\":\"1.7.x\",\"notifications\":{\"email\":false,\"webhooks\":{\"urls\":[\"http://status.bign8.info/api/ci/travis\"],\"on_success\":\"always\",\"on_failure\":\"always\",\"on_start\":\"always\"}},\"install\":[\"go get github.com/Masterminds/glide\",\"glide install -v\"],\"script\":[\"go test -race -bench=. -benchmem -v $(glide nv)\"],\"cache\":{\"directories\":[\"$HOME/.glide\"]},\".result\":\"configured\",\"group\":\"stable\",\"dist\":\"precise\",\"os\":\"linux\"},\"status\":0,\"result\":0,\"commit\":\"8fb25af2c7f2344a18ca0e25b82f1830da6d6f19\",\"branch\":\"clean\",\"message\":\"Adding webhook and cache to travis.yml\",\"compare_url\":\"https://github.com/bign8/games/compare/68f6a18021b0...8fb25af2c7f2\",\"started_at\":\"2016-12-27T06:33:23Z\",\"finished_at\":\"2016-12-27T06:34:51Z\",\"committed_at\":\"2016-12-27T06:26:54Z\",\"author_name\":\"Nate Woods\",\"author_email\":\"big.nate.w@gmail.com\",\"committer_name\":\"Nate Woods\",\"committer_email\":\"big.nate.w@gmail.com\",\"allow_failure\":false}],\"type\":\"push\",\"state\":\"passed\",\"pull_request\":false,\"pull_request_number\":null,\"pull_request_title\":null,\"tag\":null}"}}
	r.Header.Add("Signature", "fpFfYVm/24A2TMj4kSn9eOPIonWoLtuBH/3tGS/qzIjqp6awws4wx/i/UDOfYNk+DkS2ED7c63GJS7AJsg+ArIrqKEdjErLLmCNr1ZYu05Oui0a8tt2DtO7c0IhG/Sr9TrsNJVl41Fi9rYWaXqPu2VXo1eQ5aCRe5Y5UbgMfyUywXnF9Wl6JkSvsnEals9hDm5cIg6f1PnY8hVjB5pjU90smtPiyiChQAsmK3Yxt0Mxx+PPDytMvrGaoHJm1R7y78Toi5Mx1LSHAALPgcZCqpQTuAUZk/kt4dXIsN7Pho5y6aJ4c13zONawKvhQ5kGQcknpSUREHWW99y9cS2x4ySw==")
	Travis.key = `-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvtjdLkS+FP+0fPC09j25
y/PiuYDDivIT86COVedvlElk99BBYTrqNaJybxjXbIZ1Q6xFNhOY+iTcBr4E1zJu
tizF3Xi0V9tOuP/M8Wn4Y/1lCWbQKlWrNQuqNBmhovF4K3mDCYswVbpgTmp+JQYu
Bm9QMdieZMNry5s6aiMA9aSjDlNyedvSENYo18F+NYg1J0C0JiPYTxheCb4optr1
5xNzFKhAkuGs4XTOA5C7Q06GCKtDNf44s/CVE30KODUxBi0MCKaxiXw/yy55zxX2
/YdGphIyQiA5iO1986ZmZCLLW8udz9uhW5jUr3Jlp9LbmphAC61bVSf4ou2YsJaN
0QIDAQAB
-----END PUBLIC KEY-----`
	if err := Travis.Verify(r); err != nil {
		t.Errorf("Should Succeede: %s", err)
	}
}
