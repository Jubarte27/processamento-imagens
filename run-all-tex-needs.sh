#!/usr/bin/bash

## Q3
matlab -nodesktop -nojvm -nosplash -r "cd('q3'); warning('off', 'MATLAB:MKDIR:DirectoryExists'); run('adicao_de_ruido.m'); run('maina.m'); run('mainb.m'); quit;"