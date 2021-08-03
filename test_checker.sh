#!/bin/bash

# set file names
INFILE=/dev/stdin
OUTFILE1=/dev/stdout
OUTFILE2=/dev/stdout

# clean
rm -f  $INFILE $OUTFILE1 $OUTFILE2 2> /dev/null

# write in both files
python3 -c "import this" > $INFILE
echo "outfile" > $OUTFILE1
cp $OUTFILE1 $OUTFILE2 2> /dev/null

# define
THICK="\033[1m"
CYAN="\033[1;36m"
RESET="\033[m"
PROMPT="${CYAN}$>${RESET}"

# EXPECTED OUTPUT -------------------------------
printf "${THICK}EXPECTED OUTPUT${RESET}\n"

printf "${PROMPT} <  ${INFILE} ${1} | ${2} > ${OUTFILE1}\n"
<  $INFILE $1 | $2 > $OUTFILE1

printf "${PROMPT} cat ${OUTFILE1}\n"
cat $OUTFILE1

echo ""

# rewrite in infile
python3 -c "import this" > $INFILE

#ACTUAL OUTPUT ----------------------------------
printf "${THICK}ACTUAL OUTPUT${RESET}\n"

printf "${PROMPT} ./pipex  ${INFILE} \"${1}\" \"${2}\" ${OUTFILE2}\n"
./pipex  $INFILE "$1" "$2" $OUTFILE2

printf "${PROMPT} cat ${OUTFILE2}\n"
cat $OUTFILE2

echo ""

#OUTPUT DIFF -----------------------------------
printf "${THICK}OUTPUT DIFF${RESET}\n"

printf "${PROMPT} diff ${OUTFILE1} ${OUTFILE2}\n"
diff $OUTFILE1 $OUTFILE2

# clean
rm -f $INFILE $OUTFILE1 $OUTFILE2 2> /dev/null