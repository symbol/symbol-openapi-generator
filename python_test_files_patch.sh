#!/usr/bin/env bash
set -e

TEST_FILE_DIR="$1"
echo "Patch test files in $TEST_FILE_DIR"

echo "Comment out line having \"include_optional=False\" in following test files"
declare -a FILE_LIST=(
"test_aggregate_transaction_body_dto.py"
"test_aggregate_transaction_dto.py"
"test_block_info_dto.py"
"test_embedded_transaction_info_dto.py"
"test_metadata_dto.py"
"test_metadata_entries_dto.py"
"test_resolution_entry_dto.py"
"test_resolution_statement_body_dto.py"
"test_resolution_statement_dto.py"
"test_statements_dto.py"
"test_transaction_info_dto.py"
)

for filename in "${FILE_LIST[@]}"
do
  filepath="$TEST_FILE_DIR/${filename}"
  if [[ -e "${filepath}" ]]; then
    echo "${filepath}"
    sed -i -e '/include_optional=False/s/^#*/#/g' "${filepath}"
  fi
done

echo "Comment out line having \"include_optional=True\" in following test files"
declare -a FILE_LIST=(
"test_metadata_entry_dto.py"
)

for filename in "${FILE_LIST[@]}"
do
  filepath="$TEST_FILE_DIR/${filename}"
  if [[ -e "${filepath}" ]]; then
    echo "${filepath}"
    sed -i -e '/include_optional=True/s/^#*/#/g' "${filepath}"
  fi
done

exit 0