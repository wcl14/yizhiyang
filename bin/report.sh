#!/bin/bash
for filename in $@
do
	# filename=`echo $1`
	skip=1
	while read -r line
	do
		if [[ -n "$buffer" && "$line" =~ "Time:" ]]; then
			# echo "$buffer"
			echo # hide buffer
			sed 's/Time: //; s/ ms//;' <<< $line
			echo
			buffer=''
		fi
		if [[ "$line" =~ "select" || "$line" =~ "SELECT" ]]; then
			unset skip
		fi
		if [ -z "$skip" ]; then
			buffer="$buffer $line"
		fi
		if [[ "$line" =~ ";" ]]; then
			skip=1
		fi
	done < $filename
done
