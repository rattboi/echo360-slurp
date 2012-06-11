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

IFS=$'\n'
filetitles=$(cat index.html | grep course-text | grep span | sed 's/.*course-text\".\(.*\)..\<.*/\1/' | sed 's/\//-/g' )

echo $filetitles

filestoget=( $(cat index.html | grep Video | sed 's/.*href=.\(.*\)\.m4v.*/\1content.m4v/') )
filedates=( $( cat index.html | grep Lecture | grep h4 | sed 's/.*\(Lecture.*\):.*/\1/' ) )

numfiles=${#filestoget[*]}

echo $numfiles

[ -d $filetitles ] || mkdir "$filetitles"
[ -d $filetitles ] || exit # minimal fail protection

cp cookies.txt "$filetitles"
cd "$filetitles"

for a in $( seq 0 $numfiles );
do
  wget --referer="$fourthpage" \
       --cookies="on" \
       --load-cookies cookies.txt \
       --keep-session-cookies \
       --save-cookies cookies.txt \
       ${filestoget[a]}

  mv mediacontent.m4v "${filedates[a]}.m4v"
done;

rm cookies.txt
