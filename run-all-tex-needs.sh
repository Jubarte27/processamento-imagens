#!/usr/bin/bash


matlab -nodesktop -nosplash -r "warning('off', 'MATLAB:MKDIR:DirectoryExists'); \
cd('q1'); tex; cd('..'); \
cd('q3'); tex; cd('..'); \
cd('q5'); tex; cd('..'); \
quit;"