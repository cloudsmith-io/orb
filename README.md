# Cloudsmith Orb for CircleCI

CircleCI orb for publishing packages to (and interacting with) Cloudsmith repositories.

See [onsite documentation](https://circleci.com/orbs/registry/orb/cloudsmith/cloudsmith) for further details.

## Development

We use the [CircleCI CLI](https://circleci.com/docs/2.0/local-cli/) to perform common development and release tasks for this orb. Please first ensure you have it installed and configured with appropriate credentials.

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

Releasing the orb happens automatically from CI. The orb is linted (`yamllint`) and validated (`circleci orb validate`) as part of the CI process.

### Dev/Alpha releases

To make an development (or alpha) release, simply push your changes to a branch on Github. CircleCI will automatically build the orb and push a development release to the version `cloudsmith/cloudsmith@dev:$BRANCH_NAME`.

### Production releases

Once happy with your changes, merge to master as normal via a PR and then tag a new release (either via CI or the Github UI) with an appropriate version number (must be semver compatible).

For example, if you create a tag named `2.0.0` it'll result in a public release to `cloudsmith/cloudsmith@2.0.0`.
