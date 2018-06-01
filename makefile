status:
	go generate
	docker build -t bign8/status .
.PHONY : status
