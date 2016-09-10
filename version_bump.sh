#! /bin/bash -x
[ -f "./exercism/exercism.factor" ] || (echo 'script run from wrong directory'; exit 2)
CHECKSUM=$(cat ./exercism/*/*.factor | sha224sum | cut -f1 -d' ')
NOWTIME=$(date -u +%s)
printf "%s\n%s" "$CHECKSUM" "$NOWTIME" | tee "exercism/VERSION.txt"