#!/bin/bash
set -e

cp openapi3.yml openapi3-any-of-patch.yml

replaceAnyOf() {
  value=$1
  newType=$2
  echo $value
  yaml set openapi3-any-of-patch.yml "components.schemas.$value.type" $newType >tmp.yml
  cp tmp.yml openapi3-any-of-patch.yml
  yaml set openapi3-any-of-patch.yml "components.schemas.$value.anyOf" >tmp.yml
  cp tmp.yml openapi3-any-of-patch.yml
}

replaceXNumberString() {
  value=$1
  echo $value
  yaml set openapi3-any-of-patch.yml "components.schemas.$value.type" x-number-string >tmp.yml
  cp tmp.yml openapi3-any-of-patch.yml
}

for value in EmbeddedTransactionInfoDTO.properties.transaction \
  TransactionInfoDTO.properties.transaction \
  BlockInfoDTO.properties.block \
  TransactionInfoDTO.properties.meta \
  MosaicRestrictionDTO \
  TransactionStatementDTO.properties.receipts.items \
  MosaicRestrictionsPage.properties.data.items \
  AccountRestrictionDTO.properties.values.items; do
  replaceAnyOf $value object
done

for value in ResolutionEntryDTO.properties.resolved \
  ResolutionStatementDTO.properties.unresolved \
  MetadataEntryDTO.properties.targetId; do
  replaceAnyOf $value string
done

for value in Amount UInt64 FinalizedHeight BlockDuration Difficulty Height Importance Score Timestamp RestrictionValue CosignatureVersion; do
  replaceXNumberString $value
done

PATCHFILE="openapi3-any-of-patch.yml"
SED_ARGS_ANYOF_PATCH='/anyOf: ''/d'

case $(uname | tr '[:upper:]' '[:lower:]') in
  linux*)
    echo "Patch anyof using sed on Linux"
    sed -i "$SED_ARGS_ANYOF_PATCH" "$PATCHFILE"
    ;;
  darwin*)
    echo "Patch anyof using sed on OSX"
    sed -i '' -e "$SED_ARGS_ANYOF_PATCH" "$PATCHFILE"
    ;;
  msys*)
    echo "This patch script does not run on Windows"
    ;;
  *)
    echo "This patch script does not run on $(uname)"
    ;;
esac

rm tmp.yml
