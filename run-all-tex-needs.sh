#!/usr/bin/bash

## Q1
matlab -nodesktop -nosplash -r "warning('off', 'MATLAB:MKDIR:DirectoryExists'); \
cd('q1'); a = batch('tex;'); cd('..'); \
cd('q3'); b = batch('tex;'); cd('..'); \
wait(a); wait(b); \
quit;"