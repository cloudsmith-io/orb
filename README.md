# Cloudsmith Orb for CircleCI

CircleCI orb for publishing packages to (and interacting with) Cloudsmith repositories.

See [onsite documentation](https://circleci.com/orbs/registry/orb/cloudsmith/cloudsmith) for further details.

## Commands

### `authenticate-with-oidc`

Authenticate with Cloudsmith using OpenID Connect (OIDC) to obtain a short-lived API token. The token is exported as the `CLOUDSMITH_API_KEY` environment variable for use by the Cloudsmith CLI or any subsequent steps.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `organization` | string | *required* | Cloudsmith organization name |
| `service-account` | string | *required* | Cloudsmith service account name |
| `oidc-audience` | string | `""` | Custom audience for the OIDC token exchange (omitted when empty) |
| `oidc-auth-retry` | integer | `3` | Number of token exchange attempts (5 s delay between retries) |


### `install-cli`

Installs the Cloudsmith CLI by downloading the zipapp from Cloudsmith. Set `pip-install: true` to install via pip instead. Optional parameters configure the CLI via `~/.cloudsmith/config.ini`.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `cli-version` | string | `""` | Pin a specific CLI version (e.g. `"1.2.0"`). Empty installs the latest |
| `pip-install` | boolean | `false` | Install via pip instead of the default zipapp |
| `install-path` | string | `/usr/local/bin` | Directory where the zipapp binary is installed (ignored when using pip) |
| `api-host` | string | `""` | Override `api_host` in config.ini (default: `api.cloudsmith.io`) |
| `api-proxy` | string | `""` | HTTP/HTTPS proxy (`api_proxy` in config.ini) |
| `api-ssl-verify` | boolean | `true` | Enable/disable SSL verification (`api_ssl_verify` in config.ini) |
| `api-user-agent` | string | `""` | Custom user-agent (`api_user_agent` in config.ini) |

### `ensure-api-key`

Validates that the `CLOUDSMITH_API_KEY` environment variable is set. Fails the build immediately if it is missing.

### `publish` *(deprecated)*

Wraps individual `cloudsmith push` calls. This command will be removed in a future major version. The recommended approach is to call `install-cli` and `authenticate-with-oidc` (or `ensure-api-key`), then invoke the Cloudsmith CLI directly in your run steps.

## Executor

The `default` executor uses the `cimg/python` convenience image (default tag `3.12`), which has the prerequisites for installing the Cloudsmith CLI.

## Usage

### Recommended — OIDC authentication with direct CLI usage

```yaml
version: 2.1

orbs:
  cloudsmith: cloudsmith/cloudsmith@2.0.0

workflows:
  publish:
    jobs:
      - publish

jobs:
  publish:
    executor: cloudsmith/default
    steps:
      - checkout
      - cloudsmith/authenticate-with-oidc:
          organization: my-org
          service-account: my-service-account
      - cloudsmith/install-cli
      - run:
          name: Build and publish Python package
          command: |
            pip install build
            python -m build --wheel
            cloudsmith push python my-org/my-repo dist/*.whl
```

### API key authentication

```yaml
version: 2.1

orbs:
  cloudsmith: cloudsmith/cloudsmith@2.0.0

jobs:
  publish:
    executor: cloudsmith/default
    steps:
      - checkout
      - cloudsmith/ensure-api-key
      - cloudsmith/install-cli
      - run:
          name: Build and publish
          command: |
            pip install build
            python -m build --wheel
            cloudsmith push python cloudsmith/examples dist/*.whl
```

## Development

We use the [CircleCI CLI](https://circleci.com/docs/guides/toolkit/local-cli/) to perform common development and release tasks for this orb. Please first ensure you have it installed and configured with appropriate credentials.

### Generating the orb

We store the orb in git as individual YAML files. Before we can use the orb or perform further actions we need to "pack" it up into a single `orb.yml` file. We do so with the `pack` command:

```
$ circleci config pack src/ > orb.yml
```

### Validating the orb

Once generated, we can use the CLI to validate that the orb is correctly structured and meets basic standards:

```
$ circleci orb validate orb.yml
```

## Release Management

Releasing the orb happens automatically from CI using the [`circleci/orb-tools`](https://circleci.com/developer/orbs/orb/circleci/orb-tools) orb. The orb source is linted, reviewed for best practices, packed, and validated as part of the pipeline.

### Dev releases

Dev releases are published automatically on every push that is not a release tag. They are mutable and expire after 90 days.

### Production releases

Once your PR is approved, a Cloudsmith maintainer will merge it and tag a new release using a `v`-prefixed semver tag. For example, tagging `v2.0.0` publishes the orb as `cloudsmith/cloudsmith@2.0.0`.
