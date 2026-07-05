package cmdlOrder;

# this is a class that makes the order of execution
# of subs the same as the order given on the commandline.
# a switch -a will invoke a sub which is registered in the hash
# if the parameter following -a on command line is not another switch
# the corresponding global var $opt_switch is set to parameter value
# if there is no parameter $opt_switch is set to "null"
# if the switch was not on command line it is undefined.
#
# the switches that do not take subs are processed by
# first by the constructor method new.
# Note: if a switch is given multiple times
# with differents parameters, only the 
# global var $opt_switch will be set to the last parameter.
# the switches with subs are then executed.



use strict;
use warnings;

# ref to hash = (switch => [reftosub, \$opt_switch]
#                switch => [0, \$opt_switch],  if there is no associated sub
#
my $refhash;

# ref to array containing command line entry of switches
my $refswlist;

#######################################################
# constructor registers hash reference
# and command line parameters and 
# sets all global vars $opt_switch associated
# with switches but not with subs.
# this is done as some switches must be
# set before any methods are executed.
# parameters: ref to hash of switches and subs
#             ref to array of command line parameters
#######################################################
sub new {
	# print "invoking cmdlOrder->new()\n";
	# get parameters
	# there must be 2 parameters
	die "ref to hash with switches/subs and ref to command line array required\n" unless scalar(@_) >= 3;
	my $class = shift @_;

	# get ref to hash
	$refhash = shift @_;
	
	# get ref to command line array of switches
	$refswlist = shift @_;
	
	# set all switches to their values unless they are associated with a sub
	# if a switch has a parameter, $opt_switch = parameter value
	# else $opt_switch = "null" to indicate no parameter
	# and it is on the command line
	# for all items in cmd line list
	for (my $i=0; $i<scalar(@$refswlist); $i++) {
		# check that it is a switch
		my $switch = $refswlist->[$i];
		
		if ($switch=~ /^-/) {
			# this is a switch
			# check if it is valid
			if (exists($refhash->{$switch})) {
				# switch is valid
				# check if a sub is associated
#				if ($refhash->{$switch}->[0] == 0) {
					# valid switch not associated with sub
					# the switch must be set to parameter value
					# or null if there is no parameter
					# don't move past end of list
					if ($i < scalar(@$refswlist) - 1 and $refswlist->[$i+1] !~ /^-/) {
						# valid switch with a parameter
						# set the value
						${$refhash->{$switch}->[1]} = $refswlist->[$i+1];
						# print "$switch: ${$refhash->{$switch}->[1]}\n";
						
						# switch might be the last on the line
					} elsif ($i < scalar(@$refswlist) and $refswlist->[$i] =~ /^-/) {
						# this is a switch with no parameter
						${$refhash->{$switch}->[1]} = "null";
						# print "$switch: ${$refhash->{$switch}->[1]}\n";
					} else {
						# code should never get here
						print "line 87: Error: switch: $switch\ni: $i\n";
					}
#				}
			} else {
				# switch does not exist
				print "$refswlist->[$i] is invalid\n";
			}
		}
	}

	# make class into an object
	my $self = {};
	bless $self, $class;
	return $self;	
}	 

#####################################################
# method to invoke subs associated with command
# line switches. No parameters are passed to sub.
# The global variables are set.
# following command line order
# parameters : none
# return: nothing
######################################################
sub execsub {
	# get parameters
	my $self = shift @_;

	# general ref to subs
	# to be invoked
	my $refsub;

	# invoke subs from cmdl switches
	for (my $i=0; $i<scalar(@$refswlist); $i++) {
		# get sub ref if parameter is a switch
		# if it is not a switch, it must be
		# a parameter to the previous switch
		if ($refswlist->[$i] =~ /^-/) {
			# check if the switch (key) exists in the hash
			# print and error message if not
			# refhash is ref to hash $refhash = {switch => [reftosub/0, global var $opt_switch = 1/parameter]}
			# variable for switch
			my $switch = $refswlist->[$i];
			
			if (exists($refhash->{$switch})) {
				$refsub = $refhash->{$switch}->[0];
				# find the next switch with associated sub
				# and set global var $opt_switch with parameter
				# or "null" if there is/is not a parameter
				# execute the sub.
				if ($i < scalar(@$refswlist)) {
					# check if next item is a switch or parameter
					if ($i < scalar(@$refswlist) - 1 and $refswlist->[$i+1] !~ /^-/) {
						# this is the parameter for the previous switch
						# add sub ref to list for invokation
						# if switch is associated with sub
						if ($refsub != 0) {
							# print "switch = $switch: refsub = $refsub: parameter = $refswlist->[$i+1]\n";
							# set $opt_switch to parameter
							${$refhash->{$switch}->[1]} = $refswlist->[$i+1];

							# execute the sub
							$refsub->();
                        }

						# increase i since parameter following
						# switch was used
						$i++;
					} else {
						# there is no parameter
						# this could also be the last switch
						# the switch is still $refswlist->[$i]

						# add to execsublist only if ref != 0
						if ($refsub != 0) {
							# print "switch = $switch: refsub = $refsub: no parameter\n";
							# set $opt_switch to "null" there is no parameter
							${$refhash->{$switch}->[1]} = "null";

							# execute the sub
							$refsub->();
                        }

					}
				}
			} else {
				# print message show not a valid switch
				print "Invalid switch: $refswlist->[$i]\n";
			}
					
		}
	}
}
1;
