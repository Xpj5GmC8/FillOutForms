#!/bin/bash
IsCancelling () {
[[ "$(<"$CancelTxt")" == "1" ]] &&
return 0 ||
return 1; }
ErrorZenity () {
echo 100
echo "#$1"
sleep 1
exit 1; }
SayZenity () { #function to update zenity's text and progress percentage
((Prog++))
echo "$Prog" "$LinesBefore" "$NoOfLines" "$LinesAfter" | { #the form filling out progress happens between 10% and 90% of zenity's progress
 [ "$NoOfLines" -eq 0 ] &&
 awk '{print (10*$1)/$2}' ||
 awk '{print 10+((90*($1-$2))/($3+$4))}'; }
printf "%s" '#'
[ "$1" -eq 1 ] && printf "%s" 'Done '"$(( Prog - LinesBefore )) out of $NoOfLines"
echo "$2"; }
AddText () {
echo '<text xmlns="http://www.w3.org/2000/svg" font-family="'"$1"'" '"$6"' font-size="'"$2"'px" y="'"$5"'">'
a=0
echo "$3"|sed 's/\\n/\n/g'|while read;do
 printf %s '<tspan x="'"$4"'"'
 [ $a -eq 1 ] && printf %s ' dy="1.25em"' || a=1
 printf %s ">$REPLY</tspan>"
 done
echo '</text>'
}
FormGen () {
IsCancelling && return
Txt="${FormatDir}"format.txt
cd "$1"
abc="$2"
shift 2
{
 echo '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="'"$w"'" height="'"$h"'">'
 echo '<image xlink:href="file://'"$pngg"'" width="100%" height="100%" x="0" y="0" />'
 { read f
   read fs
  while read -ra a;do
   d="${a[I-1]}"
   c="${a[I-2]}"
   b="${a[I-3]}"
   unset 'a[-1]'
   unset 'a[-1]'
   unset 'a[-1]'
   a="${a[@]}"
   a="$(date +"$(eval "echo \"$a\"")")"
   D='text-anchor="'
   case "${d:0:1}" in
   l) D+='start' ;;
   c) D+='middle' ;;
   r) D+='end' ;;
   esac
   D+='" dominant-baseline="'
   case "${d:1:1}" in
   t) D+='text-before-edge' ;;
   c) D+='central' ;;
   b) D+='alphabetical' ;;
   esac
   D+='"'
   AddText "$f" "$fs" "$a" "$b" "$c" "$D"
  done; } < "$Txt"
 echo '</svg>'
 } > "$abc".svg &&
{
 IsCancelling && return
 convert "$abc".svg "$abc".png
 } &&
rm "$abc".svg &&
echo &&
exit 0 ||
ErrorZenity "Error code 3"
}

FormatDir="$1"
OutDir="$2"
Dir="$3"
CancelTxt="$4"
echo 0 >"$CancelTxt"

OneByOne=1
case "$5" in
0) OneByOne=1 ;;
1) OneByOne=0 ;;
*) ErrorZenity "Error code 0" ;;
esac
shift 5

LinesBefore=4 #number of times zenity progress window's text will update before filling out forms
NoOfLines=0 #number of forms to fill out
LinesAfter=6 #how many times to update after
Prog=0 #how many forms filled out thus far

SayZenity 0 "Initializing..."
Datee="$(date +%Y-%m-%d)" &&
pngg="${FormatDir}bg.png" &&
w="$(identify -ping -format '%w %h' "$pngg" 2>/dev/null)" && #can't be passed as a here string directly into 'w' 'h' cuz the command's return value will be ignored
read w h <<< "$w" ||

ErrorZenity 'Error code 1'

SayZenity 0 "Extracting data from file..."
case "$(echo "${1##*.}"|gawk '{printf toupper($0);}')" in
ODS) libreoffice --headless --invisible --convert-to csv:"Text - txt - csv (StarCalc)":44,34,76 --outdir "$Dir/" "$1" &>/dev/null ;;
XLS)
  xls2csv "$1" 2>&1 >"$Dir/1.csv"|wc -c|grep '^0$' &>/dev/null ||
  ErrorZenity "Error code 4"
  head -n -1 "$Dir/1.csv" > "$Dir/2.csv" &&
  mv "$Dir/2.csv" "$Dir/1.csv"
  ;;
XLSX) xlsx2csv "$1" 1>"$Dir/1.csv" 2>/dev/null ;;
*) ErrorZenity "Filename has to end with ODS, XLS, or XLSX." ;;
esac ||
ErrorZenity "File not ODS/XLS/XLSX or some other error."

[[ "$(sh -c 'echo $#' -- "$Dir/"*".csv")" -gt 0 ]] && [ ! -f "$Dir/1.csv" ] && mv "$Dir/"*".csv" "$Dir/1.csv" >&2

SayZenity 0 "Processing the extracted data..."

csvtool -t , -u TAB cat "$Dir/"*".csv" |
sed 's/ /\&#160;/g' |
while read;do
 [[ "$( echo $REPLY|tr -d "\t")" == "" ]] || { #ignoring empty rows
  a="$REPLY"
  for((;;)){ #replacing empty cells with a space char
   printf %s "$a"|grep -P '\t\t' >/dev/null &&
   a="$(printf %s "$a"|sed 's/\t\t/\t\&#160;\t/g')" ||
   {
   a="$(printf %s "$a"|sed 's/^\t/\&#160;\t/'|sed 's/\t$/\t\&#160;/')"
   printf '%s\n' "$a"
   break;}; }; }
done |
sed 's/\t/ /g' |
#print (before the lines) how many lines are there (for zenity progress bar)
{
readarray arr
echo "${#arr[@]}"
for((i=0;i<${#arr[@]};i++)){
 echo ${arr[i]}; }
} |
{
read NoOfLines
[ "$NoOfLines" -eq 0 ] && ErrorZenity "Passed file is valid but empty. Nothing to generate."
texxt=""
abc=1
SayZenity 0 "Beginning to generate..."
{
MaxThread="$(( 25 * $(nproc) ))"
iThread=0
while read -ra t1;do
 IsCancelling && break
 FormGen "$Dir/" "$abc" "${t1[@]}" &
 ((abc++))
 [ "$OneByOne" -eq 1 ] && wait || {
  [ "$iThread" -eq $(( MaxThread  - 1 )) ] &&
  { wait;iThread=0; } ||
  ((iThread++)); }
done
wait
 } |
while read;do
 SayZenity 1 "$REPLY"
done
i=$?
IsCancelling && exit
Prog=$(( LinesBefore + NoOfLines )) #this is a cheap fix for variables reverting to their former values when they leave the command group. without this, 'Prog' will be the same value as 'BeforeLines'
[ "$i" -eq 0 ] && SayZenity 0 "Finished."
sleep 1

SayZenity 0 "Checking for errors..."
find "$Dir/" -type f|grep -v '\.csv$\|\.png$\|\.txt$' &>/dev/null &&
ErrorZenity "Error code 5"
SayZenity 0 "No errors found."
sleep 1

SayZenity 0 "Finalizing the pdf..."
#making a filename that's not already used in the output folder
for((i=0;;i++)){
 texxt="Forms-$Datee"
 [ "$i" -eq 0 ] || texxt+=" ($i)"
 [ -f "$OutDir/${texxt}.pdf" ] || break; }
texxt+=".pdf"

eval "img2pdf -o \"$Dir/$texxt\"$(find "$Dir/"*".png"|sort -V|awk '{printf " "$0}')" &&
SayZenity 0 "Successfuly generated the PDF!" || ErrorZenity "Error code 6"
rm "$Dir/"*".png" "$Dir/"*".csv"
mv "$Dir/$texxt" "$OutDir/$texxt" &&
{
 SayZenity 0 "Done. Saved PDF as $texxt"'\\nin '"\"$OutDir/\""
 echo 100
 exit 0; } ||
ErrorZenity 'Cannot write to output folder. Probably folder is read-only.'
}
