#!/usr/bin/bash

## Q1
matlab -nodesktop -nosplash -r "warning('off', 'MATLAB:MKDIR:DirectoryExists'); \
cd('q1'); a = batch('tex;'); cd('..'); \
cd('q3'); c = batch('tex;'); cd('..'); \
cd('q5'); e = batch('tex;'); cd('..'); \
wait(a); wait(c); wait(e); \
quit;"