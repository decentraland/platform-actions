# Setup a project:

## To setup an "app"

`./generate-apps-workflows.sh <name>` then copy the generated `<name>/.github` directory to the proper repo

## To setup a "lib"

Just copy `libs-template` as `.github` inside the lib repo.

Remember this org variables should be enabled for the repo: 

```
    SDK_TEAM_S3_BUCKET
    SDK_TEAM_AWS_ID
    SDK_TEAM_AWS_SECRET
    SDK_TEAM_S3_BASE_URL
```

## Node.js Version Configuration

The workflows support flexible Node.js version configuration. By default, all workflows use Node.js `18.x`, but you can customize this in three ways:

### 1. Use Default Version (18.x)

Simply call the workflow without any version parameters:

```yaml
jobs:
  build:
    uses: decentraland/platform-actions/.github/workflows/apps-build.yml@main
```

### 2. Specify a Custom Version

Provide a specific Node.js version using the `node-version` input:

```yaml
jobs:
  build:
    uses: decentraland/platform-actions/.github/workflows/apps-build.yml@main
    with:
      node-version: '20.x'
```

### 3. Use a Version File

Specify a file (e.g., `.nvmrc`, `.node-version`) that contains the Node.js version:

```yaml
jobs:
  build:
    uses: decentraland/platform-actions/.github/workflows/apps-build.yml@main
    with:
      node-version-file: '.nvmrc'
```

**Note:** If both `node-version` and `node-version-file` are provided, `node-version-file` takes precedence.

### Supported Workflows

The following workflows support custom Node.js version configuration:

- `apps-build.yml`
- `apps-with-db-build.yml`
- `apps-docs.yml`
- `libs-build-and-publish.yml`
