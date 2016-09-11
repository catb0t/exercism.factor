#! /bin/sh
[ -f "./exercism.factor" ] || (echo 'script run from wrong directory'; exit 2)
CHECKSUM=$(echo ./*/*.factor | sed -e 's/ /\n/g' | LC_ALL=C sort | xargs cat | sha224sum | cut -f1 -d' ')
NOWTIME=$(date -u +%s)
printf "%s\n%s" "$CHECKSUM" "$NOWTIME" | tee "VERSION.txt"