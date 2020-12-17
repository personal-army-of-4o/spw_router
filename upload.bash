#!/bin/bash
fn=$1.dot
cmd="curl http://bashupload.com/$fn --data-binary @$fn"
echo $cmd
eval $cmd