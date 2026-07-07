# Platform Actions

Reusable GitHub Actions workflows for Decentraland repositories.

## Quick Setup

### For Applications

```bash
./generate-apps-workflows.sh <service-name>
```

Then copy the generated `<service-name>/.github` directory to your repository.

### For Libraries

Copy the `libs-template` directory as `.github` inside your library repository.

---

## Available Workflows

### Libraries

#### `libs-build-and-publish.yml`

Build, test, and publish NPM packages with S3 distribution.

```yaml
# .github/workflows/build-and-publish.yml
name: build and publish

on:
  push:
    branches: [main]
  pull_request:
  release:
    types: [created]

jobs:
  build-publish:
    uses: decentraland/platform-actions/.github/workflows/libs-build-and-publish.yml@main
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
      SDK_TEAM_S3_BUCKET: ${{ secrets.SDK_TEAM_S3_BUCKET }}
      SDK_TEAM_S3_BASE_URL: ${{ secrets.SDK_TEAM_S3_BASE_URL }}
      SDK_TEAM_AWS_ID: ${{ secrets.SDK_TEAM_AWS_ID }}
      SDK_TEAM_AWS_SECRET: ${{ secrets.SDK_TEAM_AWS_SECRET }}
      SDK_TEAM_AWS_REGION: ${{ secrets.SDK_TEAM_AWS_REGION }}
      GITLAB_TOKEN: ${{ secrets.GITLAB_TOKEN }}
      GITLAB_URL: ${{ secrets.GITLAB_URL }}
```

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `run-pre-publish` | No | `false` | Run `yarn pre-publish` before publishing |
| `custom-tag` | No | - | Custom npm tag (e.g., `pr-123`) |
| `branch-to-custom-tag` | No | - | Branch name that should use the custom tag |

---

#### `npm-deprecate.yml`

Deprecate NPM packages. Useful when archiving repositories.

```yaml
# .github/workflows/npm-deprecate.yml
name: npm deprecate

on:
  workflow_dispatch:
    inputs:
      deprecation-message:
        description: 'Deprecation message shown to users'
        required: true
        type: string
      version-spec:
        description: 'Version specification (leave empty for all versions)'
        required: false
        type: string
      dry-run:
        description: 'Dry run mode - preview without making changes'
        required: false
        type: boolean
        default: false

jobs:
  deprecate:
    uses: decentraland/platform-actions/.github/workflows/npm-deprecate.yml@main
    with:
      package-name: '@dcl/your-package-name'
      deprecation-message: ${{ inputs.deprecation-message }}
      version-spec: ${{ inputs.version-spec }}
      dry-run: ${{ inputs.dry-run }}
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `package-name` | Yes | - | Full NPM package name (e.g., `@dcl/platform-server-commons`) |
| `deprecation-message` | Yes | - | Message shown when users install the package |
| `version-spec` | No | all versions | Semver range to deprecate (e.g., `< 2.0.0`) |
| `dry-run` | No | `false` | Preview mode - no changes made |

---

### Sites

#### `sites-build-release.yml`

Build a site and deploy via AWS OIDC + direct S3 upload (no npm publish, no GitLab CDN pipeline). Sets the Cloudflare rollout via `set-rollout-action`.

Replaces the legacy npm-publish + GitLab-CDN-pipeline path used by older site workflows. One file in this repo controls build + deploy for every site that opts in.

```yaml
# .github/workflows/build-release.yml
name: Build and release

on:
  push:
    branches: [master]
  release:
    types: [created]
  workflow_dispatch:
    inputs:
      deploymentEnvironment:
        type: choice
        description: 'Deployment environment'
        required: true
        default: 'zone'
        options: [zone, today, org]
      rolloutPercentage:
        description: 'Rollout percentage'
        required: true
        default: '100'

jobs:
  build-release:
    uses: decentraland/platform-actions/.github/workflows/sites-build-release.yml@main
    permissions:
      id-token: write
      contents: read
      deployments: write
    with:
      deployment-path: 'sites'                              # Cloudflare KV path key
      aws-role-arn: ${{ vars.AWS_SITES_DEPLOYER_ROLE_ARN }}
      aws-bucket: ${{ vars.AWS_SITES_BUCKET }}
      deployment-environment: ${{ github.event.inputs.deploymentEnvironment }}
      rollout-percentage: ${{ github.event.inputs.rolloutPercentage }}
```

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `deployment-path` | Yes | - | Cloudflare KV path key (e.g. `marketplace`, `sites`, `profile`) |
| `aws-role-arn` | Yes | - | IAM role ARN to assume via OIDC |
| `aws-bucket` | Yes | - | Target S3 bucket name |
| `node-version` | No | `22.x` | Node.js version |
| `working-directory` | No | `.` | Path containing `package.json` (use `./webapp` for monorepos) |
| `install-command` | No | `npm install` | Install command |
| `build-command` | No | `npm run build` | Build command |
| `dist-dir` | No | `dist` | Build output directory (relative to working-directory) |
| `aws-region` | No | `us-east-1` | AWS region |
| `deployment-environment` | No | `''` | Manual env override (pass workflow_dispatch input) |
| `rollout-percentage` | No | `100` | Manual rollout % (pass workflow_dispatch input) |

**Rollout behavior** (driven by `github.event_name`):
- `push` → `zone` @ 100% + `today` @ 100%
- `release` → `org` @ 100%
- `workflow_dispatch` → selected env @ selected %

**Required permissions** on the caller job:
- `id-token: write` (AWS OIDC)
- `contents: read`
- `deployments: write` (set-rollout-action creates deployment records)

**Required repo/org variables** (configure once, ideally at org level so all sites inherit):

| Variable | Description |
|----------|-------------|
| `AWS_SITES_DEPLOYER_ROLE_ARN` | IAM role ARN. Trust policy must accept the consumer repo (e.g. wildcard `repo:decentraland/*`). |
| `AWS_SITES_BUCKET` | Target S3 bucket for site assets. |

No secrets required — auth is OIDC end-to-end.

---

### Shared

#### `lint-package-json.yml`

Lint `package.json` using `npm-package-json-lint`.

```yaml
# .github/workflows/lint-package-json.yml
name: lint package.json

on: [push]

jobs:
  lint-pkg:
    uses: decentraland/platform-actions/.github/workflows/lint-package-json.yml@main
```

No secrets required.

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `node-version` | No | `24` | Node.js version to use |
| `working-directory` | No | `.` | Directory that contains `package.json` |

---

### Applications

#### `apps-build.yml`

Run validations (lint) and tests with coverage reporting.

```yaml
# .github/workflows/build.yml
name: build

on:
  push:
    branches: [main]
  pull_request:

jobs:
  build:
    uses: decentraland/platform-actions/.github/workflows/apps-build.yml@main
```

No inputs or secrets required.

---

#### `apps-with-db-build.yml`

Same as `apps-build.yml` but includes a PostgreSQL service for database tests.

```yaml
# .github/workflows/build.yml
name: build

on:
  push:
    branches: [main]
  pull_request:

jobs:
  build:
    uses: decentraland/platform-actions/.github/workflows/apps-with-db-build.yml@main
    with:
      node-version: '24'
```

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `node-version` | No | `24` | Node.js version to use |

PostgreSQL connection string is exposed as `PG_COMPONENT_PSQL_CONNECTION_STRING`.

---

#### `apps-pr.yml`

Build and push Docker images for pull requests.

```yaml
# .github/workflows/pr.yml
name: pr

on:
  pull_request:

jobs:
  pr:
    uses: decentraland/platform-actions/.github/workflows/apps-pr.yml@main
    with:
      service-name: my-service
    secrets:
      QUAY_USERNAME: ${{ secrets.QUAY_USERNAME }}
      QUAY_TOKEN: ${{ secrets.QUAY_TOKEN }}
```

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `service-name` | Yes | - | Service/image name |
| `build-args` | No | - | Docker build arguments |
| `layers` | No | `true` | Enable layer caching |
| `dockerfile-url` | No | - | URL to download Dockerfile from |

---

#### `apps-docker-next.yml`

Build and push Docker images on main branch merges. Tags images with `next` and commit SHA.

```yaml
# .github/workflows/docker-next.yml
name: docker next

on:
  push:
    branches: [main]

jobs:
  docker:
    uses: decentraland/platform-actions/.github/workflows/apps-docker-next.yml@main
    with:
      service-name: my-service
      deployment-environment: dev
    secrets:
      QUAY_USERNAME: ${{ secrets.QUAY_USERNAME }}
      QUAY_TOKEN: ${{ secrets.QUAY_TOKEN }}
```

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `service-name` | Yes | - | Service/image name |
| `image-name` | No | service-name | Override image name |
| `deployment-environment` | No | - | Target environment for auto-deploy |
| `docker-tag` | No | `next` | Docker tag |
| `build-args` | No | - | Docker build arguments |
| `layers` | No | `true` | Enable layer caching |
| `dockerfile-url` | No | - | URL to download Dockerfile from |

**Outputs:** `registry-path`, `registry-paths`

---

#### `apps-docker-release.yml`

Build and push Docker images on GitHub releases. Tags images with `latest`, release tag, and commit SHA.

```yaml
# .github/workflows/docker-release.yml
name: docker release

on:
  release:
    types: [created]

jobs:
  docker:
    uses: decentraland/platform-actions/.github/workflows/apps-docker-release.yml@main
    with:
      service-name: my-service
      deployment-environment: prd
    secrets:
      QUAY_USERNAME: ${{ secrets.QUAY_USERNAME }}
      QUAY_TOKEN: ${{ secrets.QUAY_TOKEN }}
```

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `service-name` | Yes | - | Service/image name |
| `image-name` | No | service-name | Override image name |
| `deployment-environment` | No | - | Target environment for auto-deploy |
| `docker-tag` | No | `latest` | Docker tag |
| `build-args` | No | - | Docker build arguments |
| `layers` | No | `true` | Enable layer caching |
| `dockerfile-url` | No | - | URL to download Dockerfile from |

**Outputs:** `registry-path`, `registry-paths`

---

#### `apps-docker-manual-deployment.yml`

Manually trigger deployment of an existing Docker image.

```yaml
# .github/workflows/manual-deploy.yml
name: manual deployment

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        required: true
        type: choice
        options: [dev, stg, prd]
      registry-path:
        description: 'Quay registry path'
        required: true
        type: string

jobs:
  deploy:
    uses: decentraland/platform-actions/.github/workflows/apps-docker-manual-deployment.yml@main
    with:
      service-name: my-service
      deployment-environment: ${{ inputs.environment }}
      quay-registry-path: ${{ inputs.registry-path }}
    secrets:
      QUAY_USERNAME: ${{ secrets.QUAY_USERNAME }}
      QUAY_TOKEN: ${{ secrets.QUAY_TOKEN }}
```

| Input | Required | Description |
|-------|----------|-------------|
| `service-name` | Yes | Service name to deploy |
| `deployment-environment` | Yes | Target environment |
| `quay-registry-path` | Yes | Full registry path from Quay |

---

#### `apps-docs.yml`

Build and publish OpenAPI documentation to GitBook.

```yaml
# .github/workflows/docs.yml
name: docs

on:
  push:
    branches: [main]

jobs:
  docs:
    uses: decentraland/platform-actions/.github/workflows/apps-docs.yml@main
    with:
      api-spec-file: './src/openapi/spec.yaml'
      api-spec-name: 'my-api'
```

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `api-spec-file` | Yes | - | Path to OpenAPI spec file |
| `api-spec-name` | Yes | - | API name in GitBook |
| `output-bundle-file` | No | `docs/api-reference.yaml` | Bundled output path |
| `node-version` | No | `24` | Node.js version |

Requires `GITBOOK_TOKEN` and `GITBOOK_ORGANIZATION_ID` org secrets.

---

## Required Organization Secrets

Enable these secrets for repositories using these workflows:

| Secret | Used By | Description |
|--------|---------|-------------|
| `NPM_TOKEN` | libs | NPM registry authentication |
| `SDK_TEAM_S3_BUCKET` | libs | S3 bucket for package distribution |
| `SDK_TEAM_S3_BASE_URL` | libs | S3 base URL |
| `SDK_TEAM_AWS_ID` | libs | AWS Access Key ID |
| `SDK_TEAM_AWS_SECRET` | libs | AWS Secret Access Key |
| `SDK_TEAM_AWS_REGION` | libs | AWS region |
| `GITLAB_TOKEN` | libs | GitLab API token for CDN propagation |
| `GITLAB_URL` | libs | GitLab pipeline URL |
| `QUAY_USERNAME` | apps | Quay.io registry username |
| `QUAY_TOKEN` | apps | Quay.io registry token |
| `GITBOOK_TOKEN` | apps (docs) | GitBook API token |
| `GITBOOK_ORGANIZATION_ID` | apps (docs) | GitBook organization ID |
