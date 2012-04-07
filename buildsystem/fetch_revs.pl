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

$argcnt = $#ARGV + 1;
if ($argcnt < 3) {
   print "Usage: $0 <start_rev> <stop_rev> <outfile>\n";
   print "   This script loops through svn from revision <start_rev> to <stop_rev>\n";
   print "   and gathers all the info and writes it out to <outfile>\n";
   print "\n";
   exit 1;
}

$svn_path ="/mnt/disk/unity-linux/packages";
$start_ver=$ARGV[0];
$stop_ver =$ARGV[1];
$outfile  =$ARGV[2]; 

$cmdstr="svn -r" . $start_ver . ":" . $stop_ver . " -v log $svn_path 2>/dev/null";
#print "Running: $cmdstr\n";
open(MYINPUTFILE, "$cmdstr|"); # open for input
my(@lines) = <MYINPUTFILE>; # read file into list
close(MYINPUTFILE);
my($line);
$cntr=-1;
foreach $line (@lines) # loop thru list
{
   if ( $line =~ /^\-+$/) {
      $msglinecntr=0;
      $pkgcntr=0;
      $cntr++;
   } elsif ( $line =~ /^Changed paths/) {
	   # do nothing, we just toss this line out.
   } elsif (( $line =~ /^r/) and ( $revinfo[$cntr]=="")) { # only the first line beginning with 'r'
                                                         # is the rev# and info we want.
      @tmp= split(/\s+/, $line);
      $tmp[0]=~s/r//;

      $revinfo[$cntr]{"rev"}=$tmp[0];
      $revinfo[$cntr]{"committer"}=$tmp[2];
      $revinfo[$cntr]{"commitdate"}=$tmp[4];
      $revinfo[$cntr]{"committime"}=$tmp[5];
      $revinfo[$cntr]{"committz"}=$tmp[6];
   } elsif ( $line =~ /^   . \/packages/ ) {
	   $tmp=$line;
	   $tmp=~s/^   . \/packages\///;
	   @tmp1=split(/\//,$tmp);  # we want the pkg name, which is the dirname
	   chomp($tmp1[0]);   # strip off newline
	   #print "FOUND PACKAGES: " . $tmp1[0] . "|\n";
      $revinfo[$cntr]{"pkgs"}[$pkgcntr]=$tmp1[0];
      $pkgcntr++;
      $revinfo[$cntr]{"pkgcnt"}=$pkgcntr;
   } else { # assuming the rest is the commit msg.
	   # which also means we have all our pkgs, so we can uniq them
      $revinfo[$cntr]{"msg"}[$msglinecntr]=$line;
      $msglinecntr++;
      $revinfo[$cntr]{"msglinecnt"}=$msglinecntr;
   }
}
# write to file
open(OUTP, ">" . $outfile) or die("Error");


for ($i=0;$i<$cntr;$i++) {

   # unique the pkg list for this rev
   %seen=();
   @uniq=();
   for ($j=0;$j<$revinfo[$i]{"pkgcnt"};$j++) {
	   push(@uniq, $revinfo[$i]{"pkgs"}[$j]) unless $seen{$revinfo[$i]{"pkgs"}[$j]}++;
   }
   @uniq=sort(@uniq);

   # join the commitmsg 
   #the first and last lines are always blank. don't include them
   $msg="";
   @logmsg=();
   for ($j=1;$j<$revinfo[$i]{"msglinecnt"}-1;$j++) {
	   push(@logmsg, $revinfo[$i]{"msg"}[$j]);
   }
   chomp(@logmsg);
   $msg=join (" ", @logmsg);

   # just in case the delimiter char shows up in the msg, we replace with space.
   $msg =~ s/\|/ /g;

   foreach $line (@uniq) { # loop thru list 
      $specfile="$svn_path/$line/F/$line.spec";
      if (-e $specfile) {
         open(MYINPUTFILE, "rpm -q --specfile --qf '%{version}\n' $specfile 2>/dev/null|");
         my(@versionfile) = <MYINPUTFILE>; # read file into list
         close(MYINPUTFILE); 
	 chomp(@versionfile);
         $revinfo[$i]{"pkgver"} = $versionfile[0];

	 #print "Running rpm -q --specfile --qf '%{summary}\n' $specfile\n";
         open(MYINPUTFILE, "rpm -q --specfile --qf '%{summary}\n' $specfile 2>/dev/null|");
         my(@specfile) = <MYINPUTFILE>; # read file into list
         close(MYINPUTFILE);  
	 chomp(@specfile);
         # just in case the delimiter char shows up, we replace with space.
	 $specfile[0] =~ s/\|/ /g;
         $revinfo[$i]{"pkgsummary"} = $specfile[0];
      } else {
         $revinfo[$i]{"pkgver"} = "Unknown";
         $revinfo[$i]{"pkgsummary"} = "Spec file ($line/F/$line.spec) not found.";
      }

      print OUTP $revinfo[$i]{"rev"} . " | ";
      print OUTP $revinfo[$i]{"pkgver"} . " | ";
      print OUTP $revinfo[$i]{"committer"} . " | ";
      print OUTP $revinfo[$i]{"commitdate"} . " | ";
      print OUTP $revinfo[$i]{"committime"} . " | ";
      print OUTP $revinfo[$i]{"committz"} . " | ";
      print OUTP $line . " | ";
      print OUTP $revinfo[$i]{"pkgsummary"} . " | ";
      print OUTP $msg . "\n";
   }
}

