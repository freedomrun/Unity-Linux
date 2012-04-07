#!/bin/sh

cd ~/src/rpm/SRPMS/PHPFULL
if [ ! -d done ]; then
	echo "mkdir `pwd`/done"
	mkdir done
fi

for tmp in $(ls *src.rpm)
do
	rpm -i $tmp
	specname=$(rpm2cpio $tmp | cpio -t --quiet "*spec")
	cd ~/src/rpm/SPECS/
	if [ ! -d done ]; then
		echo "mkdir `pwd`/done"
		mkdir done
	fi

	echo "adding changelog to $specname"
	SET_DATE=`date +"%a %b %e %Y"`
	sed -i "s/%changelog/%changelog\n\* $SET_DATE Matthew Dawkins <mdawkins@osource.org>\n- import into pclos\n/" $specname;
	sleep 2
	rpm -ba $specname
	#if [ $? -eq 1 ]; then 
	#	/usr/bin/addpkg $specname
	#fi
	#echo "exit status: $? $0"
	sleep 2
	echo "moving specfile $specname to `pwd`/done"
	mv $specname done/	
	cd -
	echo "moving sourcerpm $tmp to `pwd`/done"
	mv $tmp done/
	specname=""
	sleep 2
done
