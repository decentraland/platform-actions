#!/bin/bash

set -e

function usage {
  echo -e "usage:
generate-apps-workflows.sh <name>
"
}

if [ $# -eq 0 ]; then
  usage
  exit 1
fi

NAME=$1

mkdir -p $NAME
cp -r apps-template/ $NAME/
mv $NAME/apps-template $NAME/.github

sed -i "s/\$SERVICE_NAME/${NAME}/g" $NAME/.github/workflows/*.yml
