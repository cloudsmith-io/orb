# Cloudsmith Orb for CircleCI

[![CircleCI build](https://dl.circleci.com/status-badge/img/gh/cloudsmith-io/orb/tree/master.svg?style=shield)](https://dl.circleci.com/status-badge/redirect/gh/cloudsmith-io/orb/tree/master)
[![Orb Registry](https://badges.circleci.com/orbs/cloudsmith/cloudsmith.svg)](https://circleci.com/developer/orbs/orb/cloudsmith/cloudsmith)

Install the standalone [Cloudsmith CLI](https://github.com/cloudsmith-io/cloudsmith-cli), add it to `PATH`, and configure authentication for the rest of a CircleCI job. The orb does not require Python, pip, or `jq` on the executor image.

[Quick start](#quick-start) · [Configuration](#configuration) · [Migration guide](#migrating-from-v2) · [Contributing](#contributing)

## At a glance

| Capability | Support |
| --- | --- |
| Authentication | OpenID Connect (OIDC) or API key |
| Executors | Linux and macOS with `bash` and `curl` or `wget` |
| Architectures | x86-64, plus Linux and macOS ARM64 |
| Installation | Standalone CLI binary with SHA-256 download verification |
| Version selection | Latest release or a specific CLI version |

## Quick start

### Authenticate with OIDC

OIDC is the recommended option for CI/CD because it uses short-lived credentials instead of a stored API key. Configure a Cloudsmith service account and an OIDC provider by following the [Cloudsmith OIDC documentation](https://docs.cloudsmith.com/authentication/openid-connect) before using this example.

> [!IMPORTANT]
> The job must use at least one [CircleCI context](https://circleci.com/docs/contexts/). Without a context, CircleCI does not issue the OIDC token used to authenticate with Cloudsmith.

```yaml
version: 2.1

orbs:
  cloudsmith: cloudsmith/cloudsmith@3.0.0

workflows:
  verify:
    jobs:
      - verify:
          context: my-context

jobs:
  verify:
    executor: cloudsmith/default
    steps:
      - cloudsmith/install-cli
      - cloudsmith/configure-oidc:
          organization: YOUR-NAMESPACE
          service-account: YOUR-SERVICE-ACCOUNT
      - run: cloudsmith whoami
```

### Authenticate with an API key

Provide the API key through the `CLOUDSMITH_API_KEY` environment variable, typically from a [CircleCI context](https://circleci.com/docs/contexts/). For automated pipelines, use a [Cloudsmith service account](https://docs.cloudsmith.com/accounts-and-teams/service-accounts) rather than a personal API key.

```yaml
version: 2.1

orbs:
  cloudsmith: cloudsmith/cloudsmith@3.0.0

workflows:
  verify:
    jobs:
      - verify:
          context: my-context

jobs:
  verify:
    executor: cloudsmith/default
    steps:
      - cloudsmith/ensure-api-key
      - cloudsmith/install-cli
      - run: cloudsmith whoami
```

Personal API keys are available from [Cloudsmith API settings](https://cloudsmith.io/user/settings/api/).

## Authentication

Choose one of the following authentication methods:

| Method | Configuration | Credential handling | Best suited to |
| --- | --- | --- | --- |
| OIDC | `organization` and `service-account` on `configure-oidc` | The CLI exchanges a CircleCI OIDC token on its first authenticated command | CI/CD pipelines |
| API key | `CLOUDSMITH_API_KEY`, optionally checked by `ensure-api-key` | CircleCI supplies the key through a context or project environment variable | Pipelines that cannot use OIDC |

With OIDC, `configure-oidc` exports the service account context needed by the CLI. The Cloudsmith access token is requested only when the CLI first needs to authenticate and is not exposed by the orb.

```mermaid
flowchart LR
    A[configure-oidc command] -->|Exports OIDC settings| B[Cloudsmith CLI command]
    B -->|Requests identity token| C[CircleCI OIDC]
    C -->|Exchanges identity| D[Cloudsmith]
```

Set `verify-auth: true` on `configure-oidc` to run `cloudsmith whoami` during setup and fail early if authentication is not configured correctly.

## Configuration

### `install-cli`

Installs the standalone Cloudsmith CLI on a Linux or macOS executor and adds its binary directory to `PATH` for later steps through `$BASH_ENV`.

#### Installation parameters

| Parameter | Description | Required | Default |
| --- | --- | --- | --- |
| `cli-version` | CLI version to install, such as `1.20.0` | No | `latest` |
| `install-path` | Root directory for versioned CLI installations | No | `$XDG_DATA_HOME/cloudsmith-cli` or `$HOME/.local/share/cloudsmith-cli` |

#### API configuration parameters

When supplied, these values are written to `~/.cloudsmith/config.ini`.

| Parameter | Description | Required | Default |
| --- | --- | --- | --- |
| `api-host` | Cloudsmith API host override | No | `api.cloudsmith.io` |
| `api-proxy` | HTTP or HTTPS proxy for Cloudsmith API calls | No | — |
| `api-ssl-verify` | Whether to verify API SSL certificates | No | `true` |
| `api-user-agent` | User agent override for Cloudsmith API requests | No | — |

### `configure-oidc`

Configures the CLI for CircleCI-native OIDC. The job must use at least one context so CircleCI issues an OIDC token.

| Parameter | Description | Required | Default |
| --- | --- | --- | --- |
| `organization` | Cloudsmith organization or namespace | Yes | — |
| `service-account` | Cloudsmith service account slug | Yes | — |
| `verify-auth` | Run `cloudsmith whoami` after configuration | No | `false` |

Run `install-cli` before using `verify-auth`.

### `ensure-api-key`

Validates that `CLOUDSMITH_API_KEY` is present and fails the job immediately when it is missing.

### Default executor

The `default` executor uses the `cimg/base` convenience image with the `current` tag. You can also use the orb commands with another Linux or macOS executor that provides `bash` and either `curl` or `wget`.

## Environment variables

The orb persists configuration for later steps through CircleCI’s `$BASH_ENV` file. Only `bash` steps source `$BASH_ENV`, and CircleCI selects the default step shell when the container starts — on minimal images where `bash` is installed during the job (for example `alpine`), give any step that runs the CLI an explicit `shell: /bin/bash`.

| Authentication method | Variable | Handling |
| --- | --- | --- |
| OIDC | `CLOUDSMITH_ORG` | Exported by `configure-oidc` |
| OIDC | `CLOUDSMITH_SERVICE_SLUG` | Exported by `configure-oidc` |
| OIDC | `CIRCLE_OIDC_TOKEN_V2` or `CIRCLE_OIDC_TOKEN` | Issued automatically when the job uses a CircleCI context |
| API key | `CLOUDSMITH_API_KEY` | Supply through a context or project environment variable |

## Publish a package

The following workflow installs the CLI with OIDC authentication and publishes a raw package:

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
          organization: YOUR-NAMESPACE
          service-account: YOUR-SERVICE-ACCOUNT
      - run:
          name: Publish package
          command: cloudsmith push raw YOUR-NAMESPACE/YOUR-REPOSITORY dist/app.tar.gz
```

See [Supported Formats](https://docs.cloudsmith.com/formats) for the upload command and options for each package format.

## Migrating from v2

Version 3 installs the standalone CLI instead of the Python package and uses CLI-native OIDC authentication.

> [!NOTE]
> OIDC authentication is now lazy: the CLI exchanges the token on its first authenticated command. Use `verify-auth: true` if the setup step should validate credentials immediately.

<details>
<summary><strong>View removed commands, parameters, and migration steps</strong></summary>

### Installation changes

| In v2 | In v3 | Migration |
| --- | --- | --- |
| `install-cli` downloads a Python zipapp | Installs a SHA-256-verified standalone binary | Remove Python and pip setup used only by this orb. |
| `pip-install: true` | Removed | Delete the parameter. |
| `install-path` defaults to `$HOME/bin` and receives the binary directly | Defines the versioned installation root | Update custom paths if the old single-file layout is required elsewhere. |
| `cli-version: ""` selects the latest release | `latest` is the explicit default | Remove empty overrides or replace them with `latest`. |
| `default` executor uses `cimg/python` | Uses `cimg/base` | Add Python explicitly only when other job steps require it. |

### Authentication changes

| In v2 | In v3 | Migration |
| --- | --- | --- |
| `authenticate-with-oidc` | Replaced by `configure-oidc` | Rename the command. The CLI now performs the token exchange itself. |
| `authenticate-with-oidc` exports `CLOUDSMITH_API_KEY` | No Cloudsmith API token is exported | Use `cloudsmith` commands for authenticated operations. |
| `oidc-audience` | Removed | Configure custom audiences on the Cloudsmith service account’s OIDC provider. |
| `oidc-auth-retry` | Removed | The CLI manages token exchange retries. |

### Publishing changes

The `publish` command has been removed. Run `cloudsmith push` directly after installation and authentication.

| Removed `publish` parameter | CLI equivalent |
| --- | --- |
| `package-format`, `cloudsmith-repository`, `package-path` | `cloudsmith push FORMAT OWNER/REPOSITORY FILE` |
| `allow-republish: true` | `--republish` |
| `package-distribution` | Distribution path, such as `OWNER/REPOSITORY/ubuntu/focal` |
| `package-pom-file` | `--pom-file PATH` |
| Raw package metadata | `--name`, `--version`, `--summary`, and `--description` |

</details>

## Contributing

The orb source is stored as individual YAML and shell files under `src/`. The CircleCI CLI packs these files into `orb.yml` for validation and publishing.

<details>
<summary><strong>View local development and release commands</strong></summary>

Pack and validate the orb from the repository root:

```bash
circleci orb pack src/ > orb.yml
circleci orb validate orb.yml
shellcheck src/scripts/*.sh
```

`src/scripts/install.sh` is synchronized with the [Cloudsmith CLI installer](https://github.com/cloudsmith-io/cloudsmith-cli-install-script) and bundled into the published orb. Do not edit it directly; update it together with `src/scripts/install.sh.version`.

Branches publish development releases automatically. To create a production release after merging to `master`, create a `v`-prefixed semantic version tag such as `v3.0.0`.

</details>

## Support

For help, [open a GitHub issue](https://github.com/cloudsmith-io/orb/issues) or contact [Cloudsmith Support](https://support.cloudsmith.com/).
