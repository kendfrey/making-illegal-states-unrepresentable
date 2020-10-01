"use strict";

const fs = require("fs").promises;
const path = require("path");
const config = require("./literate-to-md.json");
const eol = require("os").EOL;
const { i: input, o: output } = require("yargs").string(["i", "o"]).argv;

literateToMd(input, output);

async function literateToMd(input, output)
{
	if ((await (fs.stat(input))).isDirectory())
		await Promise.all((await fs.readdir(input)).map(i => literateToMd(path.join(input, i), path.join(output, i))));
	else
		await literateToMdFile(input, output);
}

async function literateToMdFile(input, output)
{
	const { dir, name, ext } = path.parse(output);
	const langConfig = config[ext.substr(1)];
	if (langConfig)
	{
		await fs.mkdir(dir, { recursive: true });
		output = path.format({ dir, name, ext: ".md" });
		
		let contents = await fs.readFile(input, "utf8");
		const lang = langConfig.lang || ext.substr(1);
		const open = escape(langConfig.open);
		const close = escape(langConfig.close);

		const startRegex = new RegExp(`^(\\r?\\n)*${open}(\\r?\\n)+`);
		if (startRegex.test(contents))
			contents = contents.replace(startRegex, "");
		else
			contents = "```" + lang + eol + contents;
			
		const endRegex = new RegExp(`(\\r?\\n)+${close}(\\r?\\n)*$`);
		if (endRegex.test(contents))
			contents = contents.replace(endRegex, "");
		else
			contents = contents + eol + "```";

		contents = contents
			.replace(new RegExp(`(\\r?\\n)+${close}(\\r?\\n)+`, "g"), eol + eol + "```" + lang + eol)
			.replace(new RegExp(`(\\r?\\n)+${open}(\\r?\\n)+`, "g"), eol + "```" + eol + eol);

		await fs.writeFile(output, contents, "utf8");
		console.log("%s -> %s", input, output);
	}
}

function escape(str)
{
	return str.replace(/[\\^$*+?.()|[\]{}]/g, "\\$&");
}