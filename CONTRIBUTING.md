# Contributing to Sustainability Metrics Dashboard
Thank you for contributing.

You can contribute to the Sustainability Metrics Dashboard by creating an issue for bugs and feature requests, helping
respond to an open issues, or working on open issues whilst letting others know with a comment.

### Requirements

First install the following tools

* Python 3.9
* Pipenv
* Terraform >= 1.3.0
* checkov >= 2.1.0
* pre-commit >= 2.20.0
* git-secrets

Some of the dependencies might require additional system development tools. Installations vary between systems.

#### MacOS
Install development tools by running:
```
xcode-select --install
```

#### Linux
Install the following using your distribution's package manager:
- make
- gcc

### Application Development

Initialise the application's Python Virtual Environment with all dependencies with the following commands:
```
make install
```

**Development and running tests requires the virtual environment to be activated!**

* to install and activate virtual environment
```
make shell
```

* to perform static analysis on the application code
```
make check
make lint
```

* to run unit tests
```
make test_unit
```

* to run integration tests
```
make test_integration
```

* to run smoke tests (TBD - post-deployment, e.g.: query athena for loaded datasets)
```
make test_smoke
```

* to run all tests
```
make test
```

### Infrastructure Development

#### Terraform remote state

Remote state configuration is done using environment variables. To successfully initialize terraform the following
environmental variables must be set:
- BACKEND_BUCKET: s3 bucket where the state is stored
- BACKEND_KEY: path to the state file in the bucket
- BACKEND_REGION: region where state file is stored

More information on partial backend configuration can be found in the [terraform's official documentation](
https://developer.hashicorp.com/terraform/language/settings/backends/configuration#partial-configuration).

#### Running terraform

Test terraform code ( fmt and validate ):
```
make test_terraform
```

Plan terraform execution:
```
make plan_terraform
```

Apply terraform:

```
make apply_terraform
```

CI/CD Apply terraform:

```
make ci_apply_terraform
```

### CI

Project uses GitHub Actions to automate checks after the code has been pushed.
Actions use the same pre-commit configuration as is used during local development.
For more information see the [action's configuration](.github/workflows/ci.yml).
