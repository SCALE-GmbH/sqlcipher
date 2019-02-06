#!/usr/bin/env bash
set -eo pipefail

# --------------------------------------------------------------
# config

OUTPUT_BASE="./scale/test_results"
RESULT_FILE="${OUTPUT_BASE}.csv"
OUTPUT_LOG="${OUTPUT_BASE}.log"
OUTPUT_TMP="${OUTPUT_BASE}.tmp"

TEST_LIST_FILE="scale/scale_test_list.txt"

PERM_TEMPLATE="scale/scale_permutations.test.template"
PERM_FILE="test/scale_permutations.test"

MIN_LINE=0
MAX_LINE=-1

REBUILD_ALWAYS=0

# --------------------------------------------------------------

# go to base dir of sqlcipher, not to this subdir!
cd $(dirname `readlink -f "$0"`)/..

echo -e '\nset ulimit'
ulimit -c unlimited >/dev/null
ulimit -a >/dev/null
ulimit -n 1024 >/dev/null

if [ "$REBUILD_ALWAYS" == "1" ] || [ ! -f ./sqlite3 ] || [ ! -f ./testfixture ]; then
    touch $OUTPUT_LOG
    echo -e "\nset environment"
    source ./scale/scale_include.sh | tee -a $OUTPUT_LOG

    ./scale/scale_build.sh
fi

if [ ! -f $PERM_TEMPLATE ] ; then
    echo "ERROR: '$PERM_TEMPLATE' not found!"
    exit 1
fi

echo -e "\nrun tests"
echo "output: ${OUTPUT_BASE}.*)"
echo "pwd="$(pwd)

set +e
COUNTER=0
COUNT_ERRORS=0

while read LINE_IN; do
    COUNTER=$((COUNTER+1))
    if [ $COUNTER -lt $MIN_LINE ] ; then
        echo "($COUNTER) skip \$MIN_LINE=$MIN_LINE"
        continue
    fi
    if [[ $MAX_LINE -gt 0  &&  $COUNTER -gt $MAX_LINE ]] ; then
        echo "($COUNTER) abort \$MAX_LINE=$MAX_LINE"
        break
    fi

    LINE=$(echo "$LINE_IN" | sed 's/^[ \t]*//;s/[ \t]*$//')
    if [ -z "$LINE" ] ; then
        continue
    fi
    if [ -z "$LINE" ] || [ ${LINE:0:1} == '#' ] ; then
        continue
    fi

    echo -e "\n$COUNTER. test file: ${LINE}" | tee -a $OUTPUT_LOG

    cp -f $PERM_TEMPLATE $PERM_FILE
    sed -i "s%#SED_RELACE_WITH_TEST_FILE#%  ${LINE}%" "$PERM_FILE"

    rm "$OUTPUT_TMP" >/dev/null 2>&1

    SECONDS=0
    ./testfixture $PERM_FILE "scale-test-suite" >"$OUTPUT_TMP" 2>&1
    RC=$?
    DURATION=$SECONDS

    if [ $RC -eq 0 ] ; then
        TEST_RESULT='OK'
        #echo -e "$OUTPUT" | tee -a $OUTPUT_LOG
    else
        COUNT_ERRORS=$((COUNT_ERRORS+1))
        TEST_RESULT='ERROR'
        cat "$OUTPUT_TMP" | grep -v "... Ok" | tee -a $OUTPUT_LOG
    fi

    rm "$OUTPUT_TMP" >/dev/null 2>&1

    echo "$TEST_RESULT (${DURATION}s)" | tee -a $OUTPUT_LOG
    echo "$LINE;$TEST_RESULT" >> $RESULT_FILE

done <$TEST_LIST_FILE

if [[ $COUNTER -gt 0 && $COUNT_ERRORS -eq 0 ]] ; then
    echo -e "\n$COUNTER tests succeeded!\n" | tee -a $OUTPUT_LOG
    exit 0
else
    echo -e "\nFAILURE: $COUNT_ERRORS tests of $COUNTER (lines) failed.\n" | tee -a $OUTPUT_LOG
    exit 1
fi
