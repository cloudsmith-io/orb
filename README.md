# Cloudsmith Orb for CircleCI

CircleCI orb for publishing packages to (and interacting with) Cloudsmith repositories.

Version 3 installs the standalone Cloudsmith CLI binary — no Python, pip, or `jq` required — and authenticates natively via CircleCI OIDC or an API key. The pinned installer is bundled with the published orb and verifies every download against its SHA-256 checksum.

See [onsite documentation](https://circleci.com/orbs/registry/orb/cloudsmith/cloudsmith) for further details.

## Commands

### `install-cli`

Installs the standalone Cloudsmith CLI binary on Linux or macOS executors and adds it to `PATH` for subsequent steps (via `$BASH_ENV`). Optional parameters configure the CLI via `~/.cloudsmith/config.ini`.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `cli-version` | string | `"latest"` | Exact CLI version to install (e.g. `"1.19.2"`), or `"latest"` |
| `install-path` | string | `""` | Absolute path to the root directory for versioned CLI installations. Empty uses `$XDG_DATA_HOME/cloudsmith-cli` or `$HOME/.local/share/cloudsmith-cli` |
| `api-host` | string | `""` | Override `api_host` in config.ini (default: `api.cloudsmith.io`) |
| `api-proxy` | string | `""` | HTTP/HTTPS proxy (`api_proxy` in config.ini) |
| `api-ssl-verify` | boolean | `true` | Enable/disable SSL verification (`api_ssl_verify` in config.ini) |
| `api-user-agent` | string | `""` | Custom user-agent (`api_user_agent` in config.ini) |

### `configure-oidc`

Configures the Cloudsmith CLI to authenticate with CircleCI's OIDC token. Exports `CLOUDSMITH_ORG` and `CLOUDSMITH_SERVICE_SLUG` for subsequent steps; the CLI exchanges the OIDC token itself when the first authenticated command runs. No API token is exchanged or exported by this command.

The job must use at least one [context](https://circleci.com/docs/contexts/), otherwise CircleCI does not issue an OIDC token.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `organization` | string | *required* | Cloudsmith organization (workspace) slug |
| `service-account` | string | *required* | Cloudsmith service account slug used for the token exchange |
| `verify-auth` | boolean | `false` | Run `cloudsmith whoami` to verify authentication (requires `install-cli` first) |

### `ensure-api-key`

Validates that the `CLOUDSMITH_API_KEY` environment variable is set. Fails the build immediately if it is missing.

## Executor

The `default` executor uses the `cimg/base` convenience image (default tag `current`). The standalone CLI has no Python or other runtime requirements, so any Linux or macOS executor with `bash` and `curl` (or `wget`) works.

## Usage

### Recommended — OIDC authentication

```yaml
version: 2.1

orbs:
  cloudsmith: cloudsmith/cloudsmith@3.0.0

workflows:
  publish:
    jobs:
      - publish:
          context: my-context

jobs:
  publish:
    executor: cloudsmith/default
    steps:
      - checkout
      - cloudsmith/install-cli
      - cloudsmith/configure-oidc:
          organization: my-org
          service-account: my-service-account
          verify-auth: true
      - run:
          name: Publish package
          command: cloudsmith push raw my-org/my-repo dist/app.tar.gz
```

### API key authentication

```yaml
version: 2.1

orbs:
  cloudsmith: cloudsmith/cloudsmith@3.0.0

jobs:
  publish:
    executor: cloudsmith/default
    steps:
      - checkout
      - cloudsmith/ensure-api-key
      - cloudsmith/install-cli
      - run:
          name: Publish package
          command: cloudsmith push raw my-org/my-repo dist/app.tar.gz
```

## Migrating from v2

| v2 | v3 |
|---|---|
| `install-cli` downloads a Python zipapp | Installs the standalone CLI binary; downloads are SHA-256 verified |
| `install-cli` with `pip-install: true` | Removed — pip is no longer used |
| `install-cli` `install-path` (default `$HOME/bin`, binary dropped in place) | Now the versioned installation root (default `~/.local/share/cloudsmith-cli`); the binary directory is added to `PATH` automatically |
| `install-cli` `cli-version: ""` for latest | Default is now `"latest"` |
| `authenticate-with-oidc` | Replaced by `configure-oidc` — the CLI performs the token exchange itself, and `CLOUDSMITH_API_KEY` is no longer exported. Steps that consumed that variable directly must use the CLI instead |
| `authenticate-with-oidc` `oidc-audience` | Removed — custom audiences must be configured on the Cloudsmith service account's OIDC provider settings instead |
| `authenticate-with-oidc` `oidc-auth-retry` | Removed — retries are handled by the CLI |
| `publish` (`package-format`, `cloudsmith-repository`, `package-path`) | Removed — run `cloudsmith push <format> <owner/repo> <file>` directly after `install-cli` and authentication |
| `publish` `allow-republish: true` | `--republish` flag on `cloudsmith push` |
| `publish` `package-distribution` (deb/rpm/alpine) | Distribution path segment: `cloudsmith push deb my-org/my-repo/ubuntu/focal app.deb` |
| `publish` `package-pom-file` (maven) | `--pom-file <path>` flag |
| `publish` raw metadata (`package-name`, `package-version`, `package-summary`, `package-description`) | `--name`, `--version`, `--summary`, `--description` flags on `cloudsmith push raw` |
| `default` executor uses `cimg/python` | Uses `cimg/base` — Python is not required |

## Development

We use the [CircleCI CLI](https://circleci.com/docs/guides/toolkit/local-cli/) to perform common development and release tasks for this orb. Please first ensure you have it installed and configured with appropriate credentials.

### Generating the orb

We store the orb in git as individual YAML files. Before we can use the orb or perform further actions we need to "pack" it up into a single `orb.yml` file. We do so with the `orb pack` command, which also inlines the scripts from `src/scripts/`:

```
$ circleci orb pack src/ > orb.yml
```

### Validating the orb

Once generated, we can use the CLI to validate that the orb is correctly structured and meets basic standards:

```
$ circleci orb validate orb.yml
```

### Vendored installer

`src/scripts/install.sh` is vendored from [cloudsmith-cli-install-script](https://github.com/cloudsmith-io/cloudsmith-cli-install-script) and bundled into the published orb, so jobs never fetch install logic at runtime. `src/scripts/install.sh.version` records the vendored version and checksum; CI fails if the two files drift apart. Update both files together when vendoring a new installer release.

## Release Management

Releasing the orb happens automatically from CI using the [`circleci/orb-tools`](https://circleci.com/developer/orbs/orb/circleci/orb-tools) orb. The orb source is linted, reviewed for best practices, packed, validated, and integration-tested as part of the pipeline.

### Dev/Alpha releases

To make a development (or alpha) release, simply push your changes to a branch on GitHub. CircleCI will automatically build and test the orb and push a development release.

### Production releases

Once happy with your changes, merge to master as normal via a PR and then tag a new release (either via CI or the GitHub UI) with an appropriate `v`-prefixed semver version.

For example, if you create a tag named `v3.0.0` it'll result in a public release to `cloudsmith/cloudsmith@3.0.0`.
