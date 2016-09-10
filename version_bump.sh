#! /bin/sh
[ -f "./exercism/testing/testing.factor" ] || (echo 'script run from wrong directory'; exit 2)
CHECKSUM=$(cat ./exercism/testing/* | sha224sum | cut -f1 -d' ')
NOWTIME=$(date -u +%s)
printf "%s\n%s" "$CHECKSUM" "$NOWTIME" | tee "exercism/testing/VERSION.txt"