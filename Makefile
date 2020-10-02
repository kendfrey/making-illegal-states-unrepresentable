PATH := node_modules/.bin:$(PATH)

.PHONY: docs md clean

docs: md
	reveal-md md --static docs
	n-concat .nojekyll > docs/_assets/.nojekyll

md:
	node literate-to-md.js -i src -o md

clean:
	n-clean md docs