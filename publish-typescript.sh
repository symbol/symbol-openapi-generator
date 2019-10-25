#!/usr/bin/env bash
cp typescript-node-templates/.npmrc ./build/api-typescript-client/.npmrc
sh -c 'cd ./build/api-typescript-client && npm publish'