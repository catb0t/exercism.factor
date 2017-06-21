#! /bin/bash
if [[ -f "VERSION.txt" ]]; then
  echo 'script run from wrong directory'
  exit
fi
CHECKSUM=$(find . -iregex '.*\.factor' | LC_ALL=C sort | xargs cat | sha224sum | cut -f1 -d' ')
NOWTIME=$(date -u +%s)
printf "%s\n%s" "$CHECKSUM" "$NOWTIME" | tee "exercism/VERSION.txt"