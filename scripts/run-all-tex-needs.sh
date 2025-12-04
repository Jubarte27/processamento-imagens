#!/usr/bin/bash


SCRIPT_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")") && source "$SCRIPT_DIR/util.bash"


matlab -nodesktop -nosplash -r "run_all_tex_needs"