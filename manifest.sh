#!/bin/bash

set -eo pipefail

export PARALLEL_SHELL=bash
MANIFEST=default.xml

echo "Generating $MANIFEST ..."

# Header
cat << EOF > "$MANIFEST"
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <remote fetch="https://git.codelinaro.org/clo/la" name="caf"/>
  <remote fetch="https://android.googlesource.com" name="google"/>
  <default remote="caf" revision="master"/>

EOF

CPUS=$(nproc --all)
TMP=/tmp/$(uuidgen).caf

# Extract all "name=" values from LA.UM and QSSI targets
# This will take a while as it has to read gigabytes of XML files and sort them
# Use GNU parallel to divide the load to multiple CPU cores
grep -l /la */*.xml | parallel -N $CPUS "cat {} | grep '<project ' | sed -e 's@\"/@\" @g' -e 's@\">@\" @g' -e 's@\.git@@g' | tr ' ' '\n' | grep name= | sort | uniq" | sed -e 's@clo/la/@@g' | sort | uniq > $TMP

# Remove faulty repositories from blacklist.txt
while read line; do
  sed -i -e "/$(echo ${line} | sed -e 's@/@\\/@g')/d" $TMP
done < blacklist.txt

# Remove repositories that are replaced with '_repo' ones
if grep -q '_repo"' "$TMP"; then
  grep '_repo"' $TMP | sed 's/_repo//g' > $TMP.repo
  cat $TMP.repo | while read line; do
    grep -v "$line" < $TMP > $TMP.2
    mv $TMP.2 $TMP
  done
fi

# Fix "name=" values to proper XML format
cat $TMP | while read line; do
  echo "  <project ${line}/>"
done >> "$MANIFEST"

# Add Google
cd google
git branch -a | grep -v HEAD | awk '{print $1}' | parallel -N $CPUS "( git show \"{}\":default.xml || true ) | grep '<project ' | sed -e 's@\"/@\" @g' -e 's@\">@\" @g' -e 's@\.git@@g' | tr ' ' '\n' | grep name= | sort | uniq" | sort | uniq > ${TMP}.google
cd ..
echo >> "$MANIFEST"

# Fix "name=" values to proper XML format
comm -13 $TMP ${TMP}.google | while read line; do
  echo "  <project ${line} remote=\"google\"/>"
done >> "$MANIFEST"

# Footer
cat << EOF >> "$MANIFEST"

</manifest>
EOF

# Remove temp file
rm ${TMP}*
