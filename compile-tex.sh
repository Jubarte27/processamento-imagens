#!/usr/bin/bash


if ! OPTIONS=$(getopt -o ac --long clean,autocompile -- "$@"); then
  exit 1
fi

eval set -- "$OPTIONS"

while true; do
  case "$1" in
    -a|--autocompile)
      autocompile=true
      shift
      ;;
    -c|--clean)
      clean=true
      shift
      ;;
    --) # End of options
      shift
      break
      ;;
    *)
      break
      ;;
  esac
done

IMAGE_NAME=processamento-imagens:latest

build_if_not_exists() {
    if [[ "$(docker images -q "$1" 2> /dev/null)" == "" ]]; then
        echo "Image $1 does not exist. Building..."
        docker build --force-rm --tag "$1" "$2"
    else
        echo "Image $1 already exists. Skipping build."
    fi
}
run_docker()        { docker run --rm -v "$(pwd):/data" -w /data $IMAGE_NAME "${@}";}
remove_aux_files()  { run_docker latexmk -aux-directory=.tmp -c;}
run_latexmk()       { run_docker latexmk -aux-directory=.tmp -pdflua "${@}" main.tex;}
count_on_log()      { grep --ignore-case --count --perl-regexp --regexp="$1" "${@:2}" main.log ;}

build_if_not_exists $IMAGE_NAME texlive

if [[ $clean == true ]]; then
    remove_aux_files
    exit 0 
fi

if [[ $autocompile == true ]]; then
    run_latexmk -pvc
else
    run_latexmk
fi