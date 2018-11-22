#!/bin/sh
sed -e 's,run_test,RUN,' | perl -ne "s/EXPECT='/EXPECT=<<EOF\n/;s/CMDS='/CMDS=<<EOF\n/;s/^'$/EOF/;  if (/NAME=/||/FILE/){s/\"//g;s/'//g;}; s/^BROKEN=$//;print"
