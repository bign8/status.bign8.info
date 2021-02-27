status:
	docker build -t bign8/status:latest .
.PHONY : status

hacks:
	dart compile js -m -o web/main.dart.js
