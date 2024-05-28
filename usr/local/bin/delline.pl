#!/usr/bin/perl
use strict;
use warnings;

###############################################################
# sub to delete a matching line from a text file and to 
# delete the next line if it is empty.
# used by init-linux to edit config.txt
# so that multiple empty lines to not appear in the file
# if init-linux is run multiple times.
# parameters: file name
#             ref to edited file
#             search string -- a|b|c|d etc
# return: none
###############################################################

sub delline {
	# read file into array
	# file name
	my $file = shift @_;

	# ref to edited file
	my $refnewlist = shift @_;

	# search criteria
	my $searchcriteria = shift @_;

	open FH, "<", $file or die "Could not open $file for reading: $!\n";

	my @list = <FH>;
	chomp(@list);

	# close file
	close FH;

	# line counter
	my $i = 0;

	# delete a line containing something and delete all the empty lines following
	for ($i=0; $i<scalar(@list); $i++) {
		# copy each line not containing string
		if ($list[$i] !~ /$searchcriteria/) {
			push @$refnewlist, $list[$i];
		} else {
			# string found
			# do not copy this line
			# and if the next line is empty
			# delete it
			# important $i < scalar(@list) at all times
			if ($i < scalar(@list) - 1) {
				# check if line is empty
				while ($i < scalar(@list) - 1 and $list[$i+1] =~ /^$/) {
					# increase i by 1 to skip
					# this line
					$i++;
				}
			}
		}
	}
}

# main entry for testing
my $file = "file.txt";
my $sc = "disable.*wifi|disable bluetooth|disable-bt";
my @newlist;

delline ($file, \@newlist, $sc);

# display the newlist
foreach my $line (@newlist) {
	# print each line
	print "$line\n";
}

