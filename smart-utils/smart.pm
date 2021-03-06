package smart; 

use strict;
use warnings;
use common;
use utf8;
use log;
use run_program;
use lang;
use c;
use any;

#continents (currently Europe covers Asia and Africa and America covers Oceania&Pacific)
# 1=Europe, 2=Asia, 3=Africa, 4=Oceania&Pacific, 5=America

my @smart_mirrors;
my $file1;
my $file2;

sub fillInProperties {
    my $channelset = shift;

    my $path_to_channelsets = "/etc/smart/channelsets/$channelset";
    my $mirror_list = "$path_to_channelsets/mirror.list";
    open(LIST, $mirror_list) || die "Could not open $mirror_list: $!\n";
    @smart_mirrors = <LIST>;
    close(LIST);

# these are the files generated by running the selectSmartChannel() and selectSmartChannelAuto() functions
    $file1 = "$path_to_channelsets/1.mirror";
    $file2 = "$path_to_channelsets/2.mirror";
}

sub selectSmartChannel {
    my ($in, $locale, $channelset) = @_;

    fillInProperties($channelset);

    my @mirrors = (
                    { 
                        'label' => "Select your nearest location for software downloads",
                        'file'  => $file1
                    },
                    { 
                        'label' => "Select your first alternate location",
                        'file'  => $file2
                    }
    );
    
    # build up the array containing info for all mirrors
    my @mirrors_detail_info;
    buildSmartMirrorList(\@mirrors_detail_info, '', $channelset);
    
    foreach my $mirror (@mirrors) {
        # define a default selection
        my $selection = \@{$mirrors_detail_info[0]};
    
        # now ask the user for their preferred selection
        $in->ask_from_( {
                            title => N("Smart Channel Selection"),
                        },
                        [
                            { 
                                label => $$mirror{label}, 
                                title => 1,
                            },
                            { 
                                val => \$selection, 
                                list => \@mirrors_detail_info, 
                                format => sub { $_[0][0] }, 
                                type => 'list' 
                            },
                        ]
        );

        # process the selection
        writeSmartMirrorInfo($$mirror{file}, $$selection[3]);
	my $selected_mirror_index = 0;
	foreach (@mirrors_detail_info) {
	    if ($$_[3] eq $$selection[3]) {
                last;
	    }
	    $selected_mirror_index++;
	}
        
        # remove this mirror from the list so that we don't consider it a second time
        splice(@mirrors_detail_info, $selected_mirror_index, 1);
    }

    processNewSmartMirrors($channelset);
}

sub selectSmartAuto {
    my $channelset = shift;

    fillInProperties($channelset);

    # Read system informations
    my $locale = lang::read();
    
    # country (not enough mirrors to use that yet)
    my $country = lang::c2name($locale->{country});
    
    # continent
    my $continent = lang::c2continent($locale->{country});
    
    # build up the array containing info for all mirrors available for our continent
    my @mirrors_detail;
    buildSmartMirrorList(\@mirrors_detail, $continent, $channelset);

    foreach my $file (($file1, $file2)) {
	my $mirror_index = int(rand(scalar(@mirrors_detail)));
        
        # process the selection
        writeSmartMirrorInfo($file, $mirrors_detail[$mirror_index][3]);
        
        # remove this mirror from the list so that we don't consider it a second time
        splice(@mirrors_detail, $mirror_index, 1);
    }

    processNewSmartMirrors($channelset);
}

sub buildSmartMirrorList {
    my $list_r = shift;
    my $continent_pattern = shift;
    my $channelset = shift;

    if (!@smart_mirrors) {
        fillInProperties($channelset);
    }

    foreach my $mirror_detail (@smart_mirrors) {
        chomp $mirror_detail;
        my ($mirror_d_name, $mirror_d_country, $mirror_d_continent, $mirror_d_url) = split(/\|/, $mirror_detail);
        if ($mirror_d_continent =~ /$continent_pattern/) {
            push @{$list_r}, [$mirror_d_name, $mirror_d_country, $mirror_d_continent, $mirror_d_url];
        }
    }
}

sub writeSmartMirrorInfo {
    my $file = shift;
    my $url = shift;

    open(FILE, ">$file") || die "Failed to open file $file for write: $!\n";
    print FILE $url;
    close(FILE);
}

sub processNewSmartMirrors {
    my $channelset = shift;
    exec ("smart-update-channels -v $channelset") or print STDERR "cannot find smart-update-channels \n";
}

1;
