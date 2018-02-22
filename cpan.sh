#!/usr/bin/env bash
cat /root/perl_install_modules.list | while read line
do
    cpanm $line -n
done
