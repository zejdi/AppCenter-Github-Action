#!/bin/bash -e
RELEASE_NOTES=""
isFirst=true
releaseId=""
export IFS=";"
params=()
[ "${INPUT_NOTIFYTESTERS}" != true ] && params+=(--silent)
[ "${INPUT_DEBUG}" == true ] && params+=(--debug)
[ "${INPUT_MANDATORY}" == true] && params+=(--mandatory)
if [ -n "${INPUT_RELEASENOTES}" ]; then
    RELEASE_NOTES=${INPUT_RELEASENOTES}
elif [ $INPUT_GITRELEASENOTES ]; then
    RELEASE_NOTES="$(git log -1 --pretty=short)"
fi

if [ -n "${INPUT_BUILDVERSION}" ]; then
    params+=(--build-version "$INPUT_BUILDVERSION")
fi

if [ -n "${INPUT_BUILDNUMBER}" ]; then
    params+=(--build-number "$INPUT_BUILDNUMBER")
fi

for group in $INPUT_GROUP; do
    if ${isFirst} ; then
        isFirst=false
        if [ "${INPUT_MARKUPRELEASENOTES}" == true ]; then
            echo "$RELEASE_NOTES" > /tmp/releasenotes
            appcenter distribute release --token "$INPUT_TOKEN" --app "$INPUT_APPNAME" --group $group --file "$INPUT_FILE" --release-notes-file /tmp/releasenotes "${params[@]}"
        else
            appcenter distribute release --token "$INPUT_TOKEN" --app "$INPUT_APPNAME" --group $group --file "$INPUT_FILE" --release-notes "$RELEASE_NOTES" "${params[@]}"
        fi
        releaseId=$(appcenter distribute releases list --token "$INPUT_TOKEN"  --app "$INPUT_APPNAME" | grep ID | tr -s ' ' | cut -f2 -d ' ' | sort -n -r | head -1)
    else
        appcenter distribute releases add-destination --token "$INPUT_TOKEN" -d $group -t group -r $releaseId --app "$INPUT_APPNAME" "${params[@]}"
    fi
done
