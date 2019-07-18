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

### Publishing the orb to dev

CircleCI allows publishing an orb in development mode where it can be used and tested prior to promoting to general release (where it shows up in site-wide documentation). To do so use the `orb publish` command:

```
$ circleci orb publish orb.yml cloudsmith/cloudsmith@dev:0.1.0
```
