#!/bin/sh

remove_tar_time()
{
	awk -F '\t' 'BEGIN {OFS=FS} {print $1,$2,$3,$4,".",$6,$7,$8,$9,$10,$11,$12,$13;}'
}
export -f remove_tar_time

human_readable()
{
	numfmt --to=iec --format="%.2f" --field=$1 --invalid=ignore
}
export -f human_readable

to_md()
{
	file=$1
	name=$2
	fields=$3
	header=$4
	if [[ $header == "1" ]]; then
		head -n 1 $file | remove_tar_time | sed "s/[	]/ | /g;s/^/| /;s/$/ |/"
		head -n 1 $file | remove_tar_time | sed "s/[^	]/-/g;s/[	]/ | /g;s/^/| /;s/$/ |/"
	fi
	echo "| **$name** |"
	tail -n 8 $file | remove_tar_time | human_readable $fields | sed -r "s/[ ]+/ | /g;s/^/| /;s/$/ |/;s@NaN@N/A@g"
}

type=$1
human_readable=$2

if [[ $human_readable == "0" ]]; then
       fields=2,4
else
       fields=2,4,6-13
fi

to_md tar_$type.csv "Tar" $fields 1
to_md squashfs_$type.csv "SquashFS" $fields 0
to_md dwarfs_$type.csv "DwarFS" $fields 0


#head -n 1 $csv | sed "s/[	]/ | /g;s/^/| /;s/$/ |/"
#head -n 1 $csv | sed "s/[^	]/-/g;s/[	]/ | /g;s/^/| /;s/$/ |/"
#if [[ $2 == "0" ]]; then
#	fields=2,4
#else
#	fields=2,4,6-13
#fi
#tail -n 8 $csv | numfmt --to=iec --format="%.2f" --field=$fields --invalid=ignore | sed -r "s/[ ]+/ | /g;s/^/| /;s/$/ |/;s@NaN@N/A@g"
