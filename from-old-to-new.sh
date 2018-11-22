#!/bin/sh
sed -e 's,run_test,RUN,' | perl -ne "
s/EXPECT_ERR=\"/EXPECT_ERR=<<EOF\n/;
s/EXPECT=\"/EXPECT=<<EOF\n/;
s/CMDS=\"/CMDS=<<EOF\n/;
s/EXPECT_ERR='/EXPECT_ERR=<<EOF\n/;
s/EXPECT='/EXPECT=<<EOF\n/;
s/CMDS='/CMDS=<<EOF\n/;
s/^'$/EOF/;
s/^\"$/EOF/;
if (/NAME=/ || /FILE/){
	s/\"//g;s/'//g;
};
s/^BROKEN=$//;
s/IGNORE_ERR=.*$//;
if (!/\.\.\/tests/) {
	print;
}
"
