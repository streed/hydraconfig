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

dist: clean init test build

publish: dist
	npm publish
