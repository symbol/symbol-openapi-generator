#!/bin/bash
set -e

SNAPSHOT_PREFIX=-SNAPSHOT
FULL_VERSION=$(head -n 1 version.txt)
VERSION="${FULL_VERSION%$SNAPSHOT_PREFIX}"

wget -q "https://github.com/nemtech/symbol-openapi/releases/download/v$VERSION/openapi3.yml" -O openapi3.yml

cp openapi3.yml openapi3-any-of-patch.yml

for value in EmbeddedTransactionInfoDTO.properties.transaction \
              TransactionInfoDTO.properties.transaction \
              ResolutionEntryDTO.properties.resolved \
              ResolutionStatementBodyDTO.properties.unresolved \
              MetadataEntryDTO.properties.targetId \
              TransactionStatementBodyDTO.properties.receipts.items \
              AccountRestrictionDTO.properties.values.items; do
  echo $value
  yaml set openapi3-any-of-patch.yml "components.schemas.$value.type" object >tmp.yml
  cp tmp.yml openapi3-any-of-patch.yml
  yaml set openapi3-any-of-patch.yml "components.schemas.$value.anyOf" > tmp.yml
  cp tmp.yml openapi3-any-of-patch.yml
done

for value in Amount BlockDuration Difficulty Height Importance Score Timestamp RestrictionValue; do
  echo $value
  yaml set openapi3-any-of-patch.yml "components.schemas.$value.type" x-number-string >tmp.yml
  cp tmp.yml openapi3-any-of-patch.yml
done

sed -i '/anyOf: ''/d' openapi3-any-of-patch.yml

rm tmp.ym
