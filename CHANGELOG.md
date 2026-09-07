
# Changelog

## 0.12.0

- `required_ruby_version` is now `>= 4.0`, matching the Ruby version trmnlp actually needs. It has understated the real floor since 0.4.0: both `xdg` (Ruby 4.0 in the 10.x series pinned since 0.8.0) and `trmnl-liquid` (Ruby 4.0 since 0.5.0) require more than the gemspec claimed. RubyGems resolves against the declared value, so `gem install trmnl_preview` on an older Ruby did not fail. It quietly walked backwards to the newest version whose dependency tree resolved, reporting "Successfully installed" for a build up to twenty months old. On Ruby 3.4 that was 0.7.1, and on Ruby 3.3 and below it was 0.3.2, which predates the Thor CLI and offers only `serve`, `build` and `version`. Asking for the current version explicitly (`gem install trmnl_preview -v 0.11.0`) crashed RubyGems inside its own conflict reporting rather than explaining the problem. Installing on an unsupported Ruby now stops with "requires Ruby version >= 4.0".
- Dependencies updated to their current releases. `trmnl-liquid` moves from 0.7.0 to 0.8.2, the only pin that excluded a newer release; every other dependency already resolved to its newest version on a fresh install. The two trmnl-liquid versions ship identical code and identical dependencies, so rendering is unchanged.

## 0.11.0

- `framework_version:` now resolves against the release manifest published by the design system, not only the version list shipped inside the gem, so a framework version released after your trmnlp install can be pinned without upgrading. The manifest is read once per run with a 2 second timeout. If the request fails, or the response is not a version list, the copy bundled in the gem is used and rendering continues. That bundled copy is refreshed here too: `latest` moves from 3.1.1 to 3.2.0.
- `rake framework:sync` reads the published manifest by default. Pass a local design-system checkout (`rake framework:sync[/path/to/repo]`) for the previous behaviour.

## 0.10.0

- Added support for the `description` plugin setting, an optional one-line summary of the plugin. `trmnlp init` scaffolds the key in `src/settings.yml`, `trmnlp lint` reports descriptions longer than 35 characters (the hosted service's limit), and `trmnlp list` shows a DESCRIPTION column when any plugin has one. Only the length is checked. Storing the value needs the matching hosted service release; until then `trmnlp push` drops it, because it rewrites the local `settings.yml` from the server's response.
- `trmnlp push` now offers to delete the server-side transform script when the project has no local `transform.*` file. Previously, deleting the file locally was a silent no-op: the server kept executing its copy and every `trmnlp pull` re-created the file. Answering yes sends `serverless_language: none` in the pushed settings.yml, which the server consumes as an explicit removal request. `--force` pushes skip the question and behave exactly as before; a failed server check never blocks the push.

## 0.9.0

- Added OAuth2 support for local plugin preview (beta). Configure a provider with the flat `oauth_*` keys in `src/settings.yml` (authorize and token URLs, scopes, optional PKCE), which round-trip through `trmnlp push` and `pull`. Set `TRMNL_OAUTH_CLIENT_ID` and `TRMNL_OAUTH_CLIENT_SECRET` in your environment (credentials stay local and are never synced), and register `http://localhost:4567/oauth/callback` as the redirect URI in your OAuth app. `trmnlp serve` shows a Connect banner that runs the authorization code flow in the browser, stores the tokens in the cache directory (never in the project), and refreshes them before they expire. The access token is exposed to polling templates as `{{ oauth_access_token }}`, matching the hosted service. This is a beta feature; please report incorrect behaviour at https://github.com/usetrmnl/trmnlp/issues.

## 0.8.10

- Fixed Python serverless transforms failing on Windows. The local subprocess backend hardcoded `python3`, which the python.org Windows installer does not put on PATH (it installs `python` and the `py` launcher), so every Python transform raised "interpreter not available". The interpreter is now resolved from a per-language list of command candidates (`python3`, then `python`, then the `py` launcher) using a cross-platform PATH lookup, leaving POSIX behavior unchanged. (#116)

## 0.8.9

- Fixed `trmnlp serve` binding to localhost under Podman, which left the dev server unreachable through published ports. Container detection only looked for `/.dockerenv`, which Docker writes but Podman does not, so `serve` fell back to `127.0.0.1`. It now also checks for `/run/.containerenv`, which Podman writes, so the automatic `0.0.0.0` bind works for both runtimes. (#112)

## 0.8.8

- Added a `--server` flag to `trmnlp login` so commands like `trmnlp push` can target a self-hosted (BYOS) server. The chosen URL is saved as `base_url`, and the `user_` API key prefix is only required for trmnl.com; BYOS servers accept their own token formats. A scheme-less `--server` value (such as `localhost:3000`) no longer crashes the host check. (#113)
- `trmnlp list` now shows plugins with a nil `plugin_id`, which BYOS servers like LaraPaper return. (#113)

## 0.8.7

- Fixed `.trmnlp.yml` `variables` overrides under the `trmnl` namespace being dropped. The assembler re-applied the pre-override namespace after the transform, clobbering user overrides like `trmnl.user.time_zone`. (#110)
- Fixed the transform receiving the `trmnl.system` namespace, which the hosted service withholds. Transforms now see only `trmnl.user`, `trmnl.device`, and `trmnl.plugin_settings`, matching production.
- Added `trmnl.user.id` to the user namespace so its shape matches the hosted service.

## 0.8.6

- Fix missing form fields `db/data/form_fields.yml`.

## 0.8.5

- Fixed `pluralize`, `number_with_delimiter`, and `number_to_currency` Liquid filters raising `Liquid error: internal`. `trmnl-liquid` 0.7 moved `RailsHelpers` behind an opt-in `load(:rails)`, but the filters still probed `RailsHelpers.respond_to?` against the now-undefined constant. Stubbing an empty module makes the probe return false so the bundled fallback implementations run. (#105)

## 0.8.4

- Fixed `trmnlp serve` hanging after switching between browser tabs. Live reload now uses `rack.hijack` so SSE connections release their Puma worker thread immediately instead of holding it for the lifetime of the tab.
- Fixed Ctrl-C requiring three presses to stop the dev server. filewatcher 3.0.1 was clobbering Puma's signal handlers with its own `trap('INT') { exit }`.
- Fixed scaffolded plugins silently skipping their transform when `settings.yml` had `serverless_language: ''`. The empty string was treated as truthy in Ruby and short-circuited the file-extension fallback.
- Docker examples in the README now use `--pull always` (and `pull_policy: always` for Compose) so a new release is picked up on the next `docker run` without a manual pull.

## 0.8.3

- `trmnlp init` and `trmnlp clone` now scaffold a `.github/workflows/trmnl.yml` CI workflow and a `.gitignore`, and run `git init -b main`, so a cloned plugin is ready to push to GitHub and deploy on every commit to `main`
- Added `--skip-git` to `trmnlp init` and `trmnlp clone` for projects that manage Git themselves
- The Docker image now ships `git` so the `docker run trmnl/trmnlp clone` flow leaves a ready-to-push project on the host
- View templates now ship canonical `layout` + `title_bar` markup that passes `trmnlp lint`

## 0.8.2

- Fixed `framework_version: latest` rendering against the auto-upgrading `/latest/` asset path instead of the current concrete release, matching the hosted service (#99)
- Cleanup and minor improvements

## 0.8.1

### Added

- `trmnlp build --png` renders a PNG for every view alongside the HTML, with `--width`, `--height`, and `--color-depth` flags to override the defaults (#92)
- Colour-coded the preview's payload-size badge — yellow from 75 KB, red from 100 KB — so an oversized merge-variable payload is visible at a glance (#67)
- Added colour to CLI output — `lint` results, warnings, and errors — suppressed automatically when output is piped or redirected (#33)

### Fixed

- `trmnlp init` no longer produces read-only project files when trmnlp itself is installed read-only, such as on NixOS (#83)
- Non-JSON polling responses (`text/html`, `text/plain`) are exposed to templates as `{{ data }}`, matching the hosted service — previously `{{ text }}` (#81)

### Housekeeping

- Added SimpleCov coverage tracking, gated in CI at a 90% floor, plus dedicated specs for every lint check
- Extracted the headless-Firefox driver into a shared `FirefoxDriver` module used by both `serve` and `build --png`

## 0.8.0

### Housekeeping

- Upgraded the development, CI, and Docker baseline to Ruby 4.0.4
- Replaced the faye-websocket live reload with server-sent events, removing the eventmachine dependency
- Upgraded `filewatcher` to 3.x for Ruby 4.0 support
- Upgraded `mini_magick` to 5.x (ImageMagick 7 only)
- Upgraded `rubyzip` to 3.x
- Upgraded `puma` to 8.x
- Upgraded `oj` and `selenium-webdriver` to their latest releases
- Upgraded `trmnl-liquid` to 0.7 and `xdg` to 10
- Added the `cgi` gem, removed from Ruby's standard library in 4.0
- Dropped the redundant `pathname` gem dependency; Ruby provides `Pathname` built in
- Added `.rspec` configuration and a `Rakefile`

### Refactor

- Refactored screen generation into focused objects: `Screen`, `Screenshot`, `Renderer`, `ImageQuantizer`, `BrowserPool`, `Reporter`, `Watcher`, `Poller`, `UserDataAssembler`
- Added support for `text/html` and `text/plain` polling responses with JSON body sniffing (#81)
- Fixed Liquid conditionals (`{% if %}...{% endif %}`) spanning `polling_headers` values (#79)
- Fixed multi-select custom_fields being coerced into JSON strings — arrays now preserved (#80)
- Fixed `trmnl.device.{width,height}` in user-data so they reflect the picker's selected model (#94)
- Fixed `Permission denied` from `trmnlp clone` on Linux when overwriting template files (#83)
- Fixed deprecated `convert` warning by switching to mini_magick's `Magick` tool (#89)

### Serverless Transforms

- Added `transform_runtime:` config in `.trmnlp.yml` — serverless transforms are enabled by default and run whenever a `src/transform.*` file is present; set to `disabled` to turn them off
- Added `serverless_daemon_url:` override for pointing at a remote transform daemon (production-fidelity testing, shared team daemons)
- Added `serverless_language:` override (`python`, `ruby`, `php`, `node`)
- Added detection of `src/transform.{py,rb,php,js}` with language inferred from extension
- Added `TRMNLP::TransformClient` strategy host that selects `TransformBackend::Subprocess` (default) or `TransformBackend::Http` (when `serverless_daemon_url` is set) via `.from_config`
- Added `TRMNLP::TransformBackend::Subprocess` — local subprocess execution mirroring the hosted serverless wrapper contract verbatim, output flows back via a per-execution tempfile
- Added `python3`, `nodejs`, and `php-cli` to the main `Dockerfile`'s runtime stage alongside the existing `ruby` so all four supported transform languages work out of the box — no sidecar required
- Added transform-error surfacing in the preview UI when execution fails
- Added filewatcher re-poll when transform source changes (hot reload)
- Added `examples/hn-stories/` — a complete worked example fetching Hacker News top stories and rendering across all four sizes

### Framework Picker

- Added `framework_version:` plugin setting in `src/settings.yml` (defaults to `latest`, supports pinning to any released version) — round-trips through `trmnlp push`/`pull` alongside the hosted plugin archive format
- Added `framework_asset_host:` override in `.trmnlp.yml` for offline / mirrored development
- Added `TRMNLP::FrameworkVersion` mirroring the hosted framework versioning
- Added `rake framework:sync` to refresh `db/data/framework_versions.yml` from a local design-system checkout
- Updated `render_html.erb` to derive CSS/JS URLs from the resolved framework version

### FormField & Init Template

- Added FormField schema vendored from the hosted service (`db/data/form_fields.yml`) covering the full field-type allowlist
- Refreshed the `trmnlp init` template to scaffold `framework_version` and transform configuration, including a `transform.py.example`
- Fixed non-portable `/bin/bash` shebang in the generated `bin/trmnlp` (#78)

## 0.7.0

- Switch from Puppeteer + CDP to Selenium + WebDriver BiDi (@SorceressLyra)

## 0.6.1

- Update trmnl-liquid to 0.4.0

## 0.6.0

- Drop trmnl-component in lieu of plain iframe
- Add [trmnl-picker](https://github.com/usetrmnl/trmnl-picker) to support new TRMNL and BYOD screens
- Fix mashup layout previews

## 0.5.10

- Fix interpolation of multi-line polling URLs with custom fields

## 0.5.9

- Add `pathname` dependency

## 0.5.8

- Improve Docker commands in `bin/trmnlp` (@jrand0m, @jbarreiros)

## 0.5.7

- Use the `trmnl-liquid` gem so tags and filters stay up-to-date with the hosted offering

## 0.5.6

- Fixed bug that left blank plugins on server after upload failed
- Fixed bug creating upload.zip after previous upload had failed
- Added support to read API key fromk `TRMNL_API_KEY` environment variable (@andi4000)
- Fixed `init` command in Docker container (@jbarreiros)
- Automatically remove ephemeral Docker container after exit (@andi4000)

## 0.5.5

- Added dark mode (@stephenyeargin)
- Added override for `polling_url` in project config (@heroheman)
- Reworked `bin/dev` into more generic `bin/trmnlp`
- Fixed pull, push, and clone commands on Windows (@eugenio)

## 0.5.4

- Added `shared.liquid` file to template (@mariovisic)
- Stringified custom field values to match production (@mariovisic)
- Optimized image generation (@sd416)
- Fixed preview from growing when JSON data becomes too wide (@stephenyeargin)

## 0.5.3

- Added support for [reusable markup](https://docs.trmnl.com/go/reusing-markup) in `shared.liquid`
- Replaced custom case images with [\<trmnl-frame\> component](https://github.com/usetrmnl/trmnl-component)
- Updated custom Liquid filters
- Added API key validation during `trmnlp login`

## 0.5.2

- Added `time_zone` project config option, which is injected into `trmnl.user` variables
- Fixed time zone to always be UTC, matching trmnl.com servers (#38)

## 0.5.1

- Fixed `trmnl init`

## 0.5.0

- Added `trmlnp init` command
- Added `trmnlp clone` command
- Improved `trmnlp push` to create remote plugin on first publish
- Changed syntax of `trmnlp push` and `trmnlp pull` commands
- Added `oj` gem for JSON parsing (#32)

## 0.4.0

### Plugin Migration Strategy

The plugin directory structure has changed to better align with the [plugin archive format](https://help.trmnl.com/en/articles/10542599-importing-and-exporting-private-plugins#h_581fb988f0). 

Here is a migration strategy for existing plugin repositories:

1. Create `.trmnlp.yml` and bring over preview settings from `config.toml` - [see README](README.md)
2. Rename directory `views/` to `src/`
3. Create `src/settings.yml` and bring over plugin settings from `config.toml` - [see TRMNL docs](https://help.trmnl.com/en/articles/10542599-importing-and-exporting-private-plugins#h_581fb988f0)
4. Delete `config.toml`

### Changes

- Change plugin directory structure (see README for details)
- Add `login`, `push`, and `pull` commands
- Bring up-to-date with latest private plugin features:
  - Add `static` strategy
  - Add polling features: multiple URLs, new verbs, and request body
  - Add settings `dark_mode`, `no_screen_padding`, `custom_fields`
  - Add interpolation of custom fields in `polling\_\*` options
  - Add `{{ trmnl }}` variables 
- Add `watch` config
- Add interpolation of environment variables in `.trmnlp.yml` via `{{ env }}`
- Add auto-reload when `.trmnlp.yml` or `settings.yml` changes
- Add variable display
- Fix crash when #poll_data fails (#12)
- Fix git runtime error in Docker container (#12)



## 0.3.2

- Add bitmap rendering
- Add TRMNL's [custom plugin filters](https://help.trmnl.com/en/articles/10347358-custom-plugin-filters)
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
