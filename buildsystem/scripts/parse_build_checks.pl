#!/usr/bin/perl
#
# This script is passed two svn revs and a file name.
# It pulls all the commits betwen the two revs and fetches
# all the info from them.  commiter, time, what pkg
# and then outputs that to a file that is read by another
# script and puts that info into the db table for
# the avail.php to display.
# This is split into two scripts so it's easier to
# go between svn,git, polling and hook script.


 use Data::Dumper;
my @blah;
my($line);

$argcnt = $#ARGV + 1;
if ($argcnt < 2) {
   print "Usage: $0 <infile> <jobid>\n";
   print "   This script loops through the build checks logfile\n";
   print "   and gathers all the info and writes it out to the db.\n";
   print "\n";
   print "\n";
   print "   <infile> output file from bldchrt that contains our info tags\n";
   print "   <jobid> the jobid of this job. Used to link to all the other db info.\n";
   print "\n";
   exit 1;
}

$infile=$ARGV[0];
$jobid=$ARGV[1];

#print "Running: $cmdstr\n";
open(MYINPUTFILE, "$infile"); # open for input
my(@lines) = <MYINPUTFILE>; # read file into list
close(MYINPUTFILE);
my($line);

my $cntr=-1;
foreach $line (@lines) # loop thru list
{
   chomp ($line);
   my @tmp= split(/=/, $line);
   my @tmp1= split(/-/, $tmp[0]);

   my $name=$tmp1[0];
   my $type=$tmp1[1];
   my $value=$tmp[1];
   #print ".";

   #$blah{$name}{$type} = $value;

   $cntr++ unless exists($blah{$cntr}{$name});
   $blah{$cntr}{$name}{$type} = $value;
}
#print "\n";

# print the whole thing
$truestr="";
$falsestr="";
foreach my $order ( sort keys %blah ) {
	   foreach my $name ( keys %{$blah{$order}} ) {

   $status=$blah{$order}{$name}{"status"};
   $message=$blah{$order}{$name}{"message"};

   $status=~s/"//g;
   $status=~s/;$//g;
   $status=~s/'/\\'/g;

   $message=~s/"//g;
   $message=~s/;$//g;
   $message=~s/'/\\'/g;

   #print "!".$status  ."!";
   #print "!".$message ."!";
   if ($status =~"ok") { 
      $stat="TRUE";
   } else {
      $stat="FALSE";
   }

   $cmdstr="mysql -u insertevent -pinsertevent BS -e ";
   $cmdstr.="\"update jobs set stage='Build', tag='$name', pass=$stat, ";
   $cmdstr.="note='$message', TS=now() where job_id=$jobid\"";
   @args=($cmdstr);


   #Move the final build status to the end.
   if ($stat =~ 'TRUE') {
	   $truestr.=$cmdstr.";\n";
   } else {
	   $falsestr.=$cmdstr.";\n";
   }
   #print "Build Check Mysql Update Status: $?\n";
}
}
if ($truestr ne "") {
   print "$truestr";
   @args=($truestr);
   system(@args);
}
if ($falsestr ne "") {
   print "$falsestr";
   @args=($falsestr);
   system(@args);
}

#chroot_exit_32: { status="ok"; message="Filesystems successfully unmounted"; }


#Turn this:
#---------------------------------
#specfile-status="ok";
#specfile-message="Using specfile: /home/unity/src/svn/ldetect-lst/F/ldetect-lst.spec";
#build-status="ok";
#build-message="Succeeded in building package";
#chroot_exit_32-status="ok";
#chroot_exit_32-message="Filesystems successfully unmounted";
#---------------------------------
#into this:
#---------------------------------
#mysql -u buildcheck_user -pbuildcheck_user BS -e "insert into buildchecks (job_id, checkname, status, prepost, output) values ($jobid, 'specfile', 'ok', 'build', 'Using specfile: /home/unity/src/svn/ldetect-lst/F/ldetect-lst.spec')"
#mysql -u buildcheck_user -pbuildcheck_user BS -e "insert into buildchecks (job_id, checkname, status, prepost, output) values ($jobid, 'build', 'ok', 'build', 'Succeeded in building package')"
#mysql -u buildcheck_user -pbuildcheck_user BS -e "insert into buildchecks (job_id, checkname, status, prepost, output) values ($jobid, 'chroot_exit', 'ok', 'build', 'Filesystems successfully unmounted')"
	#
	#





