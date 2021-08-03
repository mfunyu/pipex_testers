#!/bin/bash

# execution in bash is preffered

# filenames
EX_IN="expected_in"
EX_OUT="expected_out"
AC_IN="actual_in"
AC_OUT="actual_out"
ERR_LOG="error_log"
LOG="log"

AC_LOG="actual_log"
EX_LOG="expected_log"

make

# clean
rm -f $EX_IN $EX_OUT $AC_IN $AC_OUT $ERR_LOG $LOG $EX_LOG $AC_LOG
touch $EX_IN $AC_IN

# cmd
CMD1=("echo a" "ls -1" "grep a1" "pwd")
CMD2=("wc -l" "wc" "wc -w" "echo")
TXT=("ls" "")

# functions
function tester () {
	printf "\033[36m[ cmd1='${1}' cmd2='${2}' ]\033[m "
	cp $EX_IN $AC_IN
	# execute
	< $EX_IN $1 | $2 > $EX_OUT
	./pipex $AC_IN "$1" "$2" $AC_OUT

	# write in log file
	printf "====== cmd1='${1}' cmd2='${2}' ======\n" >> $LOG
	cat $EX_OUT >> $LOG

	# check input file
	diff $EX_IN $AC_IN 2> stash > stash
	if [ $? != 0 ]; then
		printf "\033[1mIN\033[m \033[31mKO :( \033[m"
		# write in err_log file
		printf "[ cmd1='${1}' cmd2='${2}' ]\n" >> $ERR_LOG
		diff -y $EX_IN $AC_IN >> $ERR_LOG
	else
		printf "\033[1mIN\033[m \033[32mOK :) \033[m"
	fi

	# check output file
	diff $EX_OUT $AC_OUT 2> stash > stash
	if [ $? != 0 ]; then
		printf "\033[1mOUT\033[m \033[31mKO :(\033[m\n"
		# write in err_log file
		printf "[ cmd1='${1}' cmd2='${2}' ]\n" >> $ERR_LOG
		diff -y $EX_OUT $AC_OUT >> $ERR_LOG
	else
		printf "\033[1mOUT\033[m \033[32mOK :)\033[m\n"
	fi
}

function err_tester () {
	printf "\033[36m[ ${1} ]\033[m "
	2> $EX_LOG < $EX_IN $2 | 2> $EX_LOG $3 > $EX_OUT
	2> $AC_LOG ./pipex $AC_IN "$2" "$3" $AC_OUT

	# write in log file
	printf "======= ${1} =======\n" >> $LOG
	printf "(ERROR_LOG)\n" >> $LOG
	cat $EX_LOG >> $LOG 2> stash
	printf "(LOG)\n" >> $LOG
	cat $EX_OUT >> $LOG 2> stash

	# check log file
	diff $EX_LOG $AC_LOG 2> stash > stash
	if [ $? != 0 ]; then
		printf "\033[1mLOG\033[m \033[33mCheck error_log\033[m\n"
		# write in err_log file
		printf "[ ${1} ]\n" >> $ERR_LOG
		diff -y $EX_LOG $AC_LOG 2>> $ERR_LOG >>$ERR_LOG
	else
		diff $EX_OUT $AC_OUT 2> stash > stash
		if [ $? != 0 ]; then
			printf "\033[1mOUT\033[m \033[31mKO :(\033[m\n"
			# write in err_log file
			printf "[ ${1} ]\n" >> $ERR_LOG
			diff -y $EX_OUT $AC_OUT 2>> $ERR_LOG >>$ERR_LOG
		else
			printf "\033[1mLOG, OUT\033[m \033[32mOK :)\033[m\n"
		fi
	fi
}

# Basic Tests
printf "Basic Tests\n"

for txt in "${TXT[@]}"
do
	for cmd1 in "${CMD1[@]}"
	do
		for cmd2 in "${CMD2[@]}"
		do
			$txt > $EX_IN
			tester "$cmd1" "$cmd2"
		done
	done
done

echo "==="
# Detailed Tests
printf "Detailed Tests\n"

## successes
err_tester "executable run" "echo" "./pipex test_tester.sh cat wc outfile"
err_tester "executable success" "./pipex a b c d" "echo"
err_tester "executable success2" "cat" "./pipex a b c d"

cat test_tester.sh > $EX_OUT
cp $EX_OUT $AC_OUT
err_tester "fail middle1" "ls l" "grep a"
err_tester "fail middle2" "ls l" "echo a"

echo "---"
## errors
err_tester "fail both" "ls l" "m"
err_tester "fail both" "l" "m"
err_tester "executable fail" "pipex a b c d" "echo"
err_tester "executable fail2" "echo" "pipex a b c d"


echo "==="
# Error Tests
printf "Error Tests\n"

## successes
EX_IN=dir
AC_IN=dir
mkdir dir
err_tester "Dir cat" "cat" "wc"

EX_IN=dir
AC_IN=dir
err_tester "Dir ls" "ls" "wc"

EX_IN=pipex
AC_IN=pipex
err_tester "Bin file" "cat" "grep a"

err_tester "usage err cmd1" "ls --illegaloption" "wc"
err_tester "usage err cmd2" "ls -b" "wc -p"

err_tester "cmd1 err" "ls l" "echo a"
err_tester "cmd2 err" "ls -l" "wc 1"

echo "---"
## errors
EX_IN="expected_in"
AC_IN="actual_in"
err_tester "cmd1 dne" "fakecmd1" "grep a"

err_tester "cmd2 dne" "pwd" "fakecmd2"


touch no_perm
ls > no_perm
chmod 000 no_perm

EX_OUT=no_perm
AC_OUT=no_perm
err_tester "Perm out" "ls" "wc"

EX_OUT="expected_out"
AC_OUT="actual_out"

EX_IN=no_perm
AC_IN=no_perm
err_tester "Perm in" "ls" "wc"

EX_IN=dne
AC_IN=dne
err_tester "DNE" "ls" "wc"

echo "==="
# clean up
chmod 777 no_perm
rm -fR no_perm dir stash outfile