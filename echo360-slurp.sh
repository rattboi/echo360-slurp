#!/bin/bash

urlEncode() { echo "$1" | python2 -c 'import sys,urllib;print urllib.quote(sys.stdin.read().strip())' ; }

IFS=$'\n'
filetitles=$(cat index.html | grep Title | sed 's/.*strong> \(.*\)<br>/\1/' | uniq | sed 's/\//-/') 

filestoget=( $(cat index.html | grep Vodcast | awk '/href/ {print $5}' | sed 's/.*\(http.*\)\.m4v"/\1content.m4v/') )
filedates=( $(cat index.html | grep Capture | sed 's/.*strong> \(.*\)<br>/\1/') )

echo ${#filestoget[*]}

numfiles=${#filestoget[*]}

#for a in $( seq 0 $numtitles ) ;
#do
#  echo ${filetitles[a]}
#  echo ${filedates[a]}
#  echo ${filestoget[a]}
#done;

read -p "Username: " usrname
urlname=$(urlEncode "$usrname" )
read -s -p "Password: " pass
urlpass=$(urlEncode "$pass")

echo

[ -d $filetitles ] || mkdir "$filetitles"
cd "$filetitles"

firstfile=1;
for a in $( seq 0 $numfiles );
do
  if [ $firstfile -eq 1 ]
  then
    wget --save-cookies cookies.txt \
         --keep-session-cookies \
         --referer="http://media.pdx.edu/dlcmedia/2010/fall/ECE411/" \
         ${filestoget[a]}

    rm mediacontent.m4v

    wget --load-cookies cookies.txt \
         --keep-session-cookies \
         --referer="https://echo360.pdx.edu/ess/ContentLogin.html" \
         --save-cookies cookies.txt \
         --post-data="j_username=$urlname&j_password=$urlpass" \
         https://echo360.pdx.edu/ess/j_spring_security_check
    mv j_spring_security_check "${filedates[a]}.m4v"
    firstfile=0;
  else
    wget --referer="https://echo360.pdx.edu/ess/j_spring_security_check" \
         --cookies="on" \
         --load-cookies cookies.txt \
         --keep-session-cookies \
         --save-cookies cookies.txt \
         ${filestoget[a]}

    mv mediacontent.m4v "${filedates[a]}.m4v"
  fi
done;

rm cookies.txt
