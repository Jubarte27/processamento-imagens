#!/usr/bin/bash

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
run_pdf_latex()     { run_docker pdflatex "${@}" main.tex ;}
remove_aux_files()  { run_docker latexmk -c;}
count_on_log()      { grep --ignore-case --count --perl-regexp --regexp="$1" "${@:2}" main.log ;}

build_if_not_exists $IMAGE_NAME texlive

run_pdf_latex -draftmode
run_pdf_latex

NOT_ERROR_TEXT=$(count_on_log "Providing info/warning/error messages")
CONTAINS_ERROR_WARNING=$(count_on_log "error|warning")

if ! [[ CONTAINS_ERROR_WARNING -gt NOT_ERROR_TEXT ]]; then
    remove_aux_files
fi