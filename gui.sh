#!/bin/bash
ErrorExit () {
 zenity --warning --text="$1"
 exit 1; }

zenity --help  &>/dev/null || { echo "Zenity is needed.";exit 1; }
img2pdf --help &>/dev/null || ErrorExit "img2pdf is needed."
convert --help &>/dev/null || ErrorExit "ImageMagick is needed."
gawk --help    &>/dev/null || ErrorExit "gawk is needed."
sed --help     &>/dev/null || ErrorExit "sed is needed."
csvtool --help &>/dev/null || ErrorExit "csvtool is needed."
[ -f "$1" ] || ErrorExit "The file you passed doesn't exist"
case "$(echo "${1##*.}"|gawk '{printf toupper($0);}')" in
 ODS)  libreoffice --help &>/dev/null || ErrorExit "LibreOffice is needed for extracting ODS files." ;;
 XLS)  xls2csv -V         &>/dev/null || ErrorExit "xls2csv is needed for extracting XLS files."     ;;
 XLSX) xlsx2csv --help    &>/dev/null || ErrorExit "xlsx2csv is needed for extracting XLSX files."   ;;
esac

FormatDir="$(zenity --file-selection --title="Choose a format folder" --directory --filename="$(pwd)/")" ||
ErrorExit 'A format folder is needed.'
FormatDir+='/'

[ -f "$FormatDir"bg.png ] &&
[ -f "$FormatDir"format.txt ] ||
ErrorExit 'The format folder does not contain bg.png and format.txt !'

convert -list font|grep '^    family: '"$(read < "$FormatDir"format.txt;echo "$REPLY")"'$' &>/dev/null ||
ErrorExit "You don't have the specified font installed on this system."

#INPUT VALIDATION
{
read;read
while read -ra a;do
 d="${a[I-1]}" #LAST WORD IN LINE IS ALIGN
 c="${a[I-2]}" #SECOND LAST IS Y COORD
 b="${a[I-3]}" #THIRD LAST IS X WORD
 unset 'a[-1]'
 unset 'a[-1]'
 unset 'a[-1]'
 a="${a[@]}" #ALL THE OTHERS ARE TEXT
 
 #PREVENT PRINTING NON-ARG SHELL VARs
 echo "$a"|grep '[{][A-Z]\|[{][a-z]' && ErrorExit 'Printing non-argument shell variables not allowed.'
 #PREVENT COMMAND INJECTIONS
 echo "$a"|grep '$('                 && ErrorExit 'Command injections not allowed.'
 #THE XY COORD VALUES HAVE TO BE INTEGERS
 [[  "$b$c" =~ ^[0-9]+$ ]]           || ErrorExit 'The coordinate values have to be integers.'
 #THE ALIGN HAS TO BE VALID
 [[ "${#d}" -eq 2 ]] &&         #IS d TWO CHARS?
 [[ "lcr" =~ "${d:0:1}" ]] && #IS 1ST CHAR VALID?
 [[ "tcb" =~ "${d:1:1}" ]] || #IS 2ND CHAR VALID?
 ErrorExit 'SUPPORTED ALIGN FORMATS ARE: lt, lc, lb, ct, cc, cb, rt, rc, rb.'" Yours is \"$d\""
done; } < "$FormatDir"format.txt

[ "$#" -eq 0 ] && ErrorExit "You need to pass a file as an argument!"
[ "$#" -ge 2 ] && ErrorExit "You need to pass only one file as only one argument!"

OutDir="$(zenity --file-selection --title="Choose output directory" --directory --filename="$(pwd)/")"
[ "$?" -eq 0 ] || ErrorExit "Selecting Output folder required.\nExiting."

a="one by one (recommended)"
b="all at once"
c="$(zenity --list --radiolist --text \
"Would you like to have this program fill out one form at a time or all forms at once.\n\
Generating all at once is much faster but uses all CPU cores to 100% !\n\
If you have a low-end PC or plan to use it while the program is working, select \"one by one\".\n\
The generated PDF file will be the same regardless of the method you choose." \
--hide-header --column "" --column "" --title "$2" FALSE "$a" FALSE "$b")"
case "$c" in
"$a") d=0 ;;
"$b") d=1 ;;
*)    exit 1
esac
a="one by one"

DIR="/dev/shm/FORMS"
for((i=1;;i++)){
 mkdir "$DIR$i" &>/dev/null
 [ $? -eq 0 ] && { DIR+="$i"; break; }
 [ "$i" -eq 99999 ] && ErrorExit "Error!"; }

CancelTxt="$DIR/cancelling.txt"
#backend.sh SHOULD BE CALLED WITH BASH COMMAND SO IT WONT NEED chmod +x
( bash backend.sh "$FormatDir" "$OutDir" "$DIR" "$CancelTxt" "$d" "$1" & echo $! >&3 ) 3>"$DIR/pid.txt" |
while read;do
 echo "$REPLY"
 echo "$REPLY" >&2 #THIS LINE IS FOR DEBUGGING PURPOSES
 done |
zenity --width=450 --progress --title='Filling out forms... ('"$([ "$d" -eq 1 ] && echo "$b" || echo "$a")"')' --percentage=0

#IF "Cancel" IS PRESSED
[ $? -eq 1 ] && {
 echo 1 >"$CancelTxt"
 pp="$(<"$DIR/pid.txt")"
 for((;;)){ [ -d "/proc/$pp" ] || { echo 100;break; }; } |
  zenity --progress --pulsate --no-cancel --text="Cancelling..." --title="" --auto-close
 rm -r "$DIR" &>/dev/null
 zenity --info --text="Canceled successfuly" --title=""; }

rm -r "$DIR" &>/dev/null
