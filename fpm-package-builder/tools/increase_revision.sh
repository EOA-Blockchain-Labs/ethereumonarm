#!/usr/bin/env bash

function print_help() {
cat<<EOF
Usage: $0 folder name/s | all
This script incresaes the Debian revision number by 1 in any given proyect
EOF
  exit 0
}

if [ $# -eq 0 ]; then
  print_help
fi

proyects=$@

if [[ $1 == "all" ]]; then
  proyects=$(find ../ -path "../*/*" -iname Makefile | cut -d '/' -f 2 | xargs echo)
fi

for proyect in $(echo $proyects)
do
if [ -f  ../$proyect/Makefile ];
then
  old_release=$(grep -i "pkg_release :=" ../$proyect/Makefile | cut  -d ' ' -f 3)
  new_release=$(( $old_release + 1 ))
  sed -i "s/pkg_release := $old_release/pkg_release := $new_release/"  ../$proyect/Makefile
  echo "Changed $proyect revision from $old_release to $new_release"
else
  echo "$proyect/Makefile does not found"
fi

done
