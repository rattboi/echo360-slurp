#!/bin/bash

urlEncode() { echo "$1" | xxd -plain | tr -d '\n' | sed 's/\(..\)/%\1/g'; }

read -p "Username: " usrname
urlname=$(urlEncode "$usrname" )
read -s -p "Password: " pass
urlpass=$(urlEncode "$pass")

wget --save-cookies cookies.txt \
     --keep-session-cookies \
     --referer="http://media.pdx.edu/dlcmedia/2010/fall/ECE411/" \
     "$1" -O firstpage.html

wget --load-cookies cookies.txt \
     --keep-session-cookies \
     --referer="https://echo360.pdx.edu/ess/ContentLogin.html" \
     --save-cookies cookies.txt \
     --post-data="j_username=$urlname&j_password=$urlpass" \
     "https://echo360.pdx.edu/ess/j_spring_security_check" \
     -O secondpage.html

thirdpageurl=$( cat secondpage.html | grep div | sed 's/.*src=\"\(.*\)\" scrolling.*/\1/' )
thirdpage=$( echo https://echo360.pdx.edu"$thirdpageurl" )

echo $thirdpage

wget --load-cookies cookies.txt \
     --keep-session-cookies \
     --referer="https://echo360.pdx.edu/ess/ContentLogin.html" \
     --save-cookies cookies.txt \
     "$thirdpage" \
     -O thirdpage.html 

fourthpageurl=$( cat thirdpage.html| grep previous | sed 's/.*href=\"\(.*\)\".*/\1/' | sed 's/amp;//g' )
fourthpage=$( echo http://echo360.pdx.edu"$fourthpageurl" )

echo $fourthpage

wget --load-cookies cookies.txt \
     --keep-session-cookies \
     --referer="$thirdpage" \
     --save-cookies cookies.txt \
     "$fourthpage" \
     -O index.html 

exit

IFS=$'\n'
filetitles=$(cat index.html | grep Title | sed 's/.*strong> \(.*\)<br>/\1/' | uniq | sed 's/\//-/g') 

filestoget=( $(cat index.html | grep Vodcast | awk '/href/ {print $5}' | sed 's/.*\(http.*\)\.m4v"/\1content.m4v/') )
filedates=( $(cat index.html | grep Capture | sed 's/.*strong> \(.*\)<br>/\1/') )

numfiles=${#filestoget[*]}

read -p "Username: " usrname
urlname=$(urlEncode "$usrname" )
read -s -p "Password: " pass
urlpass=$(urlEncode "$pass")

echo

[ -d $filetitles ] || mkdir "$filetitles"
[ -d $filetitles ] || exit # minimal fail protection
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
