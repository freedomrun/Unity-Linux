# This script checks for the existance of exactly 1 spec file in the pkg.
#Output is 0=success; 1=failure; anything else is <TBD>
pkgname=$1
SVNDIR=`/usr/sbin/unity_repo_details.sh -m`/$pkgname
ALTSVNDIR=`/usr/sbin/unity_repo_details.sh -o`/$pkgname/current

if [ -f $SVNDIR/$pkgname.pkginfo ]; then
	cnt=$(find $ALTSVNDIR/SPECS -name "*.spec" | wc -l);
else 
	cnt=$(find $SVNDIR -name "*.spec" | wc -l);
fi
if [ $cnt -eq 1 ]; then
	exit 0;
else
	exit 1;
fi

