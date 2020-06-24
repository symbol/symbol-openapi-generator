#!/bin/bash
set -e
npm run build --prefix ../symbol-openapi
cp ../symbol-openapi/_build/openapi3.yml .
source patch.sh