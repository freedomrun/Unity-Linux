#!/bin/sh

# Before proceeding, it cleans up the any previous generated file.
rm -f lang_database

# It generates a database which only contains the languages
# for which a tarball with .mo files is provided.
touch lang_database

pushd langpacks 1> /dev/null
for i in $(ls *.tar.xz); do
	langcode=$(echo $i|cut -d. -f1)
	grep "^$langcode;" ../lang_database.in >> ../lang_database
done 
popd 1> /dev/null
