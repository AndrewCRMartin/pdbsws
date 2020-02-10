#!/bin/bash
for file in *.pl *.sql *.sh; do ci -l $file; done
