# Changelog

## 0.3.5

- Add support for `strategy = "static"` to read data from `sample.json`

## 0.3.4

- Add support for `.env` files to store sensitive information
- Add validation for environment variable names (must use underscores, not hyphens)
- Add more descriptive error messages for environment variable issues

## 0.3.3

- Add version number to usage info
- Add ability to run server from different directories

## 0.3.2

- Add bitmap rendering
- Add TRMNL's [custom plugin filters](https://help.usetrmnl.com/en/articles/10347358-custom-plugin-filters)
- Add support for user-supplied custom filters

## 0.3.1

- Add live render

## 0.3.0

- Add poll button
- Add case image overlays
- Add `trmnlp build` command
- Add support for `url` pointing to a local JSON data file

## 0.2.0

- Add "commands" concept to `trmnlp` executable
- `trmnlp serve` improvements
  - Add argument for plugin directory
  - Add options `-b` and `-p` for host bind and port, respectively
- Add Dockerfile

## 0.1.2

- Initial working release
