PATH := node_modules/.bin:$(PATH)

.PHONY: docs md clean

docs: md
	reveal-md md --static docs

md:
	node literate-to-md.js -i src -o md

clean:
	n-clean md docs