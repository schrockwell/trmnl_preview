# trmnl_preview

A basic self-hosted web server to ease the development and sharing of [TRMNL](https://usetrmnl.com/) plugins.

[Liquid](https://shopify.github.io/liquid/) templates are rendered locally as HTML, leveraging the [TRMNL Design System](https://usetrmnl.com/framework). This server does NOT generate a rendered BMP file. Hence, this is just a _preview_ of the final rendered dashboard.

The server watches the filesystem for changes to the Liquid templates, seamlessly updating the preview without the need to refresh.

![Screenshot](docs/preview.png)

## Creating a Plugin

This is the structure of a plugin repository.

```
views/
    full.liquid
    half_horizontal.liquid
    half_vertical.liquid
    quadrant.liquid
config.toml
```

See [config.example.toml](config.example.toml) for an example config.

The [trmnl-hello](https://github.com/schrockwell/trmnl-hello) repository is provided as a jumping-off point for creating new plugins. Simply fork the repo, clone it, and start hacking.

## Running the Server (Docker)

```sh
docker run \
    -p 4567:4567 \
    -v /path/to/plugin/on/host:/plugin \
    schrockwell/trmnlp
```

## Running the Server (Local Ruby)

Ruby 3.x is required. In the plugin repository:

```sh
bundle add trmnl_preview    # Creates Gemfile and Gemfile.lock
trmnlp serve                # Starts the server
```

## Usage Notes

Simply refresh the page to re-render.

When the strategy is "polling", the specified URL will be fetched once, when the server starts.

When the strategy is "webhook", payloads can be POSTed to the `/webhook` endpoint. They are saved to `tmp/data.json` for future renders.

## `config.toml` Reference

- `strategy` - Either "polling" or "webhook"
- `url` - The URL from which to fetch JSON data (polling strategy only)
- `live_render` - Set to `false` to disable automatic rendering when Liquid templates change (default `true`)
- `[polling_headers]` - A section of headers to append to the HTTP poll request (polling strategy only)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/schrockwell/trmnl_preview.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
