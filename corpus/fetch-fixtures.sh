#!/bin/sh
# Fetch test/benchmark fixtures that we may NOT redistribute, into the
# gitignored corpus/fixtures/. Checksums are pinned so the data the
# tests see is exactly the data this script was written against.
#
#   tdoku data.zip   - benchmark collections compiled by t-dillon/tdoku:
#                      forum-hardest lists (SE 11+), magictour top1465,
#                      Royle 17-clue (CC BY 2.5 Gordon Royle/UWA), etc.
#                      Forum compilations carry no license - local use only.
#   reglib-1.3.txt   - HoDoKu regression library (GPLv3): ~1100 cases,
#                      each naming a technique and its exact expected
#                      eliminations/placements. Used as fetched fixtures;
#                      kept out of the repo to keep our code BSD.
set -eu
cd "$(dirname "$0")"
mkdir -p fixtures
cd fixtures

fetch() { # url file sha256
    if [ ! -f "$2" ]; then
        echo "fetching $2 ..."
        curl -sL --fail -o "$2" "$1"
    fi
    echo "$3  $2" | shasum -a 256 -c -
}

fetch https://github.com/t-dillon/tdoku/raw/master/data.zip \
    tdoku-data.zip \
    9be0601c721ac4e702e3fe097576f025fcb99b216aabfe9dbea37cac43e6bc4f

fetch https://hodoku.sourceforge.net/libraries/reglib-1.3.txt \
    reglib-1.3.txt \
    d37272f245ca6cfc5f3d4037998c80a1fd2ce996682dd7c2b3cc5aefa3ff7173

if [ ! -d tdoku ]; then
    unzip -q -d tdoku tdoku-data.zip
fi
echo "fixtures ready:"
ls tdoku | sed 's/^/  tdoku\//'
echo "  reglib-1.3.txt"
