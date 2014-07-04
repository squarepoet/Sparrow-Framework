#!/bin/bash

# This script creates a nice API reference documentation for the Sparrow source
# and installs it in Xcode.
#
# To execute it, you need the "AppleDoc"-tool. Download it here:
# http://www.gentlebytes.com/home/appledocapp/

if [ $# -ne 1 ]
then
  echo "Usage: `basename $0` [version]"
  echo "  (version like '1.0')"
  exit 1
fi

version=$1
index_file=index.md

# write temporary index file

echo "**The Open Source Game Engine for iOS, v$version**"                          > $index_file
echo ""                                                                           >> $index_file
echo "* Homepage: [www.sparrow-framework.org](http://www.sparrow-framework.org)"  >> $index_file
echo "* Forum: [forum.sparrow-framework.org](http://forum.sparrow-framework.org)" >> $index_file
echo "* Wiki: [wiki.sparrow-framework.org](http://wiki.sparrow-framework.org)"    >> $index_file

appledoc \
  --project-name "Sparrow Framework" \
  --project-company "Gamua" \
  --company-id com.gamua \
  --project-version "$version" \
  --explicit-crossref \
  --ignore ".m" \
  --ignore "_Internal.h" \
  --index-desc "index.md" \
  --keep-undocumented-objects \
  --keep-undocumented-members \
  --keep-intermediate-files \
  --no-warn-missing-arg \
  --no-warn-undocumented-object \
  --no-warn-undocumented-member \
  --no-warn-empty-description \
  --docset-bundle-id "org.sparrow-framework.docset" \
  --docset-bundle-name "Sparrow Framework" \
  --docset-atom-filename "docset.atom" \
  --docset-feed-url "http://doc.sparrow-framework.org/core/feed/%DOCSETATOMFILENAME" \
  --docset-package-url "http://doc.sparrow-framework.org/core/feed/%DOCSETPACKAGEFILENAME" \
  --publish-docset \
  --output . \
  ../src/Classes

rm $index_file

echo
echo "Finished."
