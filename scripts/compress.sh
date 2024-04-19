#!/bin/zsh

BASEDIR=$(dirname "$0")
TIMEFMT="%E"

csv_files=(dwarfs_create-size.csv dwarfs_create-time.csv squashfs_create-size.csv squashfs_create-time.csv tar_create-size.csv tar_create-time.csv)

rdir=results_$(date +"%Y-%m-%d_%H-%M-%S")
mkdir $rdir
rm -f latest
ln -s $rdir latest

for f in $csv_files; do
	echo -n "days\tsize\tfiles\ttar_size\ttar_time" > $rdir/$f
	for bs in 16 18 20 22 24 26 28 30; do
		echo -n "\t$bs" >> $rdir/$f
	done
	echo "" >> $rdir/$f
done

for as in 1 2 4 8 16 32 64 128; do
	echo ""
	echo "################################"
	echo "##### ARCHIVE SIZE $as"

	mkdir -p $rdir/archives
	echo "Signature: 8a477f597d28d172789f06886806bc55" > $rdir/archives/CACHEDIR.TAG

	# copy data
	rm -rf tmp
	mkdir -p tmp
	for d in $(ls -d data/*/ | head -n $as); do
		cp -rp $d tmp/
	done
	cd tmp

	# analyze data
	ras=$(du -axb --max-depth=0 | cut -d"	" -f 1)
	raf=$(du -ax --max-depth=0 --inodes | cut -d"	" -f 1)
	echo "$as: $(($ras/1024**2)) MB, $raf files"

	# create tar archive with infinite block size for reference
	echo "Creating Tar archive with infinite block size for reference"
	archive="../$rdir/archives/${as}.tar.xz"
	tar_time=$((time tar -I "xz -9 -T1" -cf $archive .) |& tail -n 1 | sed "s/s//")
	tar_size=$(echo "$(du -b $archive | cut -d"	" -f 1)")

	# write headers
	for f in $csv_files; do
		echo -n "$as\t$ras\t$raf\t${tar_size}\t${tar_time}" >> ../$rdir/$f
	done

	# create archives with all block sizes
	for bs in 16 18 20 22 24 26 28 30; do
		rbs=$((2**$bs))
		echo "# BLOCK SIZE $bs ($(($rbs/1024)) kB)"

		# Dwarfs
		echo "Creating Dwarfs archive"
		archive="../$rdir/archives/${as}_${bs}.dwarfs"
		dwarfs_time=$((time /tmp/dwarfs/bin/mkdwarfs -l9 -S$bs --log-level warn --no-progress -i . -o $archive) |& tail -n 1 | sed "s/s//")
		dwarfs_size=$(echo "$(du -b $archive | cut -d"	" -f 1)")
		echo -n "\t$dwarfs_size" >> ../$rdir/${csv_files[1]}
		echo -n "\t$dwarfs_time" >> ../$rdir/${csv_files[2]}

		# Squashfs
		if [[ $bs -le 20 ]]; then
			echo "Creating Squashfs archive"
			archive="../$rdir/archives/${as}_${bs}.squashfs"
		        squashfs_time=$((time mksquashfs . $archive -comp xz -b $rbs) |& tail -n 1 | sed "s/s//")
			squashfs_size=$(echo "$(du -b $archive | cut -d"	" -f 1)")
		else
			echo "Skip Squashfs archive that does not support this block size"
			squashfs_time="NaN"
			squashfs_size="NaN"
		fi
		echo -n "\t$squashfs_size" >> ../$rdir/${csv_files[3]}
		echo -n "\t$squashfs_time" >> ../$rdir/${csv_files[4]}

		# Tar
		echo "Creating Tar archive"
		archive="../$rdir/archives/${as}_${bs}.tar.xz"
		tar_time=$((time tar -I "xz -9 --block-size=$rbs -T0" -cf $archive .) |& tail -n 1 | sed "s/s//")
		tar_size=$(echo "$(du -b $archive | cut -d"	" -f 1)")
		echo -n "\t$tar_size" >> ../$rdir/${csv_files[5]}
		echo -n "\t$tar_time" >> ../$rdir/${csv_files[6]}
	done

	for f in $csv_files; do
		echo "" >> ../$rdir/$f
	done
	cd ../
done


$BASEDIR/csv_to_md.sh create-size 1 > create-size.md
$BASEDIR/csv_to_md.sh create-time 0 > create-time.md

rm -rf tmp

