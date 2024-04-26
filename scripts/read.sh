#!/bin/zsh

BASEDIR=$(dirname "$0")
TIMEFMT="%E"

rdir=$1
cd $rdir
mkdir -p mount
cmd=$2
command="$3"

csv_files=(dwarfs_read-time.${cmd}.csv squashfs_read-time.${cmd}.csv tar_read-time.${cmd}.csv)

for f in $csv_files; do
	echo -n "days\tsize\tfiles\ttar_size\ttar_time" > $f
	for bs in 16 18 20 22 24 26 28 30; do
		echo -n "\t$bs" >> $f
	done
	echo "" >> $f
done

for as in 1 2 4 8 16 32 64 128; do
	echo "################################"
	echo "##### ARCHIVE SIZE $as"
	for f in $csv_files; do
		h=$(cat dwarfs_create-time.csv | grep "^$as	" | cut -d"	" -f1-5)
		echo -n $h >> $f
	done

	for bs in 16 18 20 22 24 26 28 30; do
		rbs=$((2**$bs))
		echo "# BLOCK SIZE $bs ($(($rbs/1024)) kB)"

		# DwarFS
		echo "Reading Dwarfs archive"
		/tmp/dwarfs/sbin/dwarfs archives/${as}_${bs}.dwarfs mount
		cd mount/2022-12-01
		dwarfs_time=$((time sh -c "$command") |& tail -n 1 | sed "s/s//")
		cd ../../
		echo -n "\t${dwarfs_time}" >> ./${csv_files[1]}
		umount mount

		# SquashFS
		if [[ $bs -le 20 ]]; then
			echo "Reading Squashfs archive"
			sudo mount -o loop archives/${as}_${bs}.squashfs mount
			cd mount/2022-12-01
			squashfs_time=$((time sh -c "$command") |& tail -n 1 | sed "s/s//")
			cd ../../
			sudo umount mount
		else
			echo "Skip Squashfs archive that does not support this block size"
			squashfs_time="NaN"
		fi
		echo -n "\t${squashfs_time}" >> ./${csv_files[2]}

		# Tar
		echo "Reading Tar archive"
		archivemount archives/${as}_${bs}.tar.xz mount
		cd mount/2022-12-01
		tar_time=$((time sh -c "$command") |& tail -n 1 | sed "s/s//")
		cd ../../
		echo -n "\t${tar_time}" >> ./${csv_files[3]}
		umount mount
	done

	for f in $csv_files; do
		echo "" >> $f
	done
done

../$BASEDIR/csv_to_md.sh read-time.${cmd} 0 > read-time.${cmd}.md

cd ../
