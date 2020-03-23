#!/bin/bash
set -e
cp openapi3.yml openapi3-any-of-patch.yml
for value in Amount BlockDuration Difficulty Height Importance Score Timestamp RestrictionValue
do
    echo $value
    yaml set openapi3-any-of-patch.yml "components.schemas.$value.type" x-number-string > tmp.yml
    cp tmp.yml openapi3-any-of-patch.yml
done












