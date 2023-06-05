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
