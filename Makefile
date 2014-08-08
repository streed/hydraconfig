PATH := ./node_modules/.bin:${PATH}

.PHONY: test clean

init:
	npm install

test:
	npm test

clean: 
	rm -rf lib/

build:
	coffee -o lib/ -c src/
	cp -R src/public lib/
	cp -R src/views lib/
