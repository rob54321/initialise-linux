#!/usr/bin/perl
# perl script to call the StEdit.pm module
# so it can be easily used from a bash script
# the commands are passed by command line
# arguments to this script which then calls
# StEdit.pm methods

# use bash ANSI-C quoting when interpolation of \n \r etc are required
# stedit.pl -a $'oneline\nlast line\n'
# format is $'...'

use strict;
use warnings;
# use lib "/home/robert/stedit/usr/local/lib/site_perl";
use StEdit;
use cmdlOrder;
# use Getopt::Std;

our ($opt_a, $opt_b, $opt_d, $opt_e, $opt_f, $opt_h, $opt_i, $opt_l, $opt_o, $opt_s, $opt_w, $opt_F, $opt_V);
# editor object of StEdit.pm
my $editor;

# subcontrol object
my $subcontrol;

###############################################################
# command line switches for stedit.pl
# -a text to be appended
# -d /pattern/iedelete line    - i case insensitive match, e delete empty lines following
# -f file name to edit           - must be given
# -i /pattern/text to insert/iab - i case insensitive match, a|b insert after|before line
# -l display buffer
# -s /pattern/replacement/ig     - i case insensitive match, g sust globally
# -w file name|default write     - default is to use the same file name as source
# -b make a backup file only used with -w
# -V version and exit
# -D turn debugging on
###############################################################

# main hash for cmdlOrder.pm
# all switches are set by cmdlOrder->new()
# if the sub is not to be invoked
# set the sub ref to 0 followed by ref
# to the global var
my %subhash = (-a => [\&append,  	\$opt_a],
               -d => [\&delete,  	\$opt_d],
               -f => [0,         	\$opt_f],
			   -h => [0,         	\$opt_h],
               -i => [\&insert,  	\$opt_i],
               -l => [\&display, 	\$opt_l],
               -s => [\&subst,   	\$opt_s],
               -o => [\&cdisplay,	\$opt_o],
               -w => [\&write,   	\$opt_w],
               -b => [0,         	\$opt_b],
			   -F => [\&script,  	\$opt_F],
			   -V => [0,         	\$opt_V]);

###############################################################
# script function
# this method reads commands from the script file $opt_F
# and applies them line by line to the file being edited.
###############################################################
sub script {
	$editor->script($opt_F);
}

# delete function
# delete a line(s) that match pattern
# if no pattern is given, nothing is done
# parameters passed: pattern, optional -i modifier
# the -i modifier works with delete
sub delete {
	# rc is no lines deleted or undefined if an error occurred.
	my $count = $editor->delete($opt_d);
}

# if append given
# note: if the string contains \n characters
# the bash ansi-c quoting $'...' must be used: eg. -a $'string\nnext line'
# must be used
# parameters passed: text from -t option
# no modifiers work with append
sub append {
	my $rc = $editor->append($opt_a);
	print "stedit: Error appending to $opt_f\n" unless defined($rc);
}

# insert function
# text can be inserted before (default) or after each line
# where the pattern matches.
# also the pattern can be case (in)sensitive 
# stedit.pl modifiers -i case insensitive, -a insert after, -b insert before - default, work
# parameters passed: pattern, text, optional modifiers
sub insert {
	# do insert, return from method is no of insertions
	my $count = $editor->insert($opt_i);	
	print "stedit: Error: inserting\n" unless defined($count);
}

# substitute a pattern with replacement text
# parameters passed: pattern, text replacement, optional modifiers -i -g
sub subst {
	# do the substitution
	my $count = $editor->subst($opt_s);
	print "stedit: Error: substituting\n" unless defined($count);
}

# write the file to disk
# a file name may be "" whicn means the original file must be writtern to.
sub write {
	# write the file to disk
	# if no parameter is given for -w
	# then use the original file
	# given with -f
	# set file name
	my $fname;
	if ($opt_w eq "null") {
		$fname = $opt_f;
	} else {
		$fname = $opt_w;
	}
	# if -b switch given create backup
	if ($opt_b) {
		$editor->write($fname, 1);
	} else {
		$editor->write($fname, 0);
	}
}


# display the file
# no title can be given
# StEdit.pm uses a title for debugging purposes only
sub display {
	# display the edited file
	$editor->display();
}

# display the original file with colour indicators
# parameters none
# return nothing
sub cdisplay {
	$editor->cdisplay();
}

# usage function
sub usage {
	print "use ANSI-C quoting \$'...' for interpolation of \\n or \' etc in text arguments\n";
	print "stedit -f \"full pathname\" OR -F script with filename on line1 ie # filename\n";
	print "-d (delete) \"/pattern/ie\"  - i for case insensitive search, e for delete line and following empty lines\n";
	print "-a (append) \"text\"\n";
	print "-i (insert) \"/pattern/text to insert/iab\" - -i case insensitive, a|b insert after|before\n";
	print "-s (subst)  \"/pattern/replacement/ig\" -i case insensitive, g global\n";
	print "-w (write)  \"new filename\"|default is original name if none given\n";
	print "-b (backup file) makes a file.bak, only works with the -w switch\n";
	print "-l (list edited file)\n";
	print "-o (list original file with colour changes\n";
	print "-F (script file name) run commands from file, file name can be obtained from line 1, # filename or from -f \n";
	print "-V print version and exit\n";
	print "pattern could be \$'^some line\$|^or.*another\$|^\$'\n";
	print "-h (help)\n";
	exit 0;
}
# this sub operates on the list @ARGV
# all the switches in the ARGV list are checked to see if they have arguments
# if they do not have arguments, the default arguments are inserted into ARGV
# this sub must must be invoked before command line processings
sub defaultparameter {

	# hash supplying default arguments to switches
	# -w is writing file to disk. No parameter given means use original file name
	# the default argument, if not given on the command line is all drives
	# the parameter "" cannot be used hence " " is used to indicate there is no filename
	my %defparam = ( -w => "/home/robert/file101.txt");

	# for each switch in the defparam hash find it's index and insert default arguments if necessary
	foreach my $switch (keys(%defparam)) {
		# find index of position of -*
		my $i = 0;
		foreach my $param (@ARGV) {
			# check for a -b and that it is not the last parameter
			if ($param eq $switch) {
				if ($i < $#ARGV) {
					# -* has been found at $ARGV[$i] and it is not the last parameter
					# if the next parameter is a switch -something
					# then -* has no arguments
					# check if next parameter is a switch
					if ($ARGV[$i+1] =~ /^-/) {
						# -* is followed by a switch and is not the last switch
						# insert the 2 default filenames as a string at index $i+1
						my $index = $i + 1;
						splice @ARGV, $index, 0, $defparam{$switch};
					}
				} else {
					# the switch is the last in the list so def arguments must be appended
					my $index = $i + 1;
					splice @ARGV, $index, 0, $defparam{$switch}; 
				}
			}
			# increment index counter
			$i++;
		}
	}
} 

####################################################
# help method
# this method displays all command of this module
# and exits
####################################################
sub help {
	print "use ANSI-C quoting \$'...' for interpolation of \\n or \' etc in text arguments\n";
	print "stedit -f \"full pathname\" OR -F script with filename on line1 ie # filename\n";
	print "-d (delete) \"/pattern/ie\"  - i for case insensitive search, e for delete line and following empty lines\n";
	print "-a (append) \"text\"\n";
	print "-i (insert) \"/pattern/text to insert/iab\" - -i case insensitive, a|b insert after|before\n";
	print "-s (subst)  \"/pattern/replacement/ig\" -i case insensitive, g global\n";
	print "-w (write)  \"new filename\"|default is original name if none given\n";
	print "-b (backup file) makes a file.bak, only works with the -w switch\n";
	print "-l (list edited file)\n";
	print "-o (list original file with colour changes\n";
	print "-F (script file name) run commands from file, file name can be obtained from line 1, # filename or from -f \n";
	print "-V print version and exit\n";
	print "pattern could be \$'^some line\$|^or.*another\$|^\$'\n";
	print "-h (help)\n";
	exit 0;
}

###################################################
########### main entry
###################################################
# usage stedit options command options
# 1. -f filename to edit compulsory
# 2. commands
#             -d  (delete): "/pattern/ei"     options: i for case insensitive, e delete line and following empty lines
#             -a  (append): "text to append"
#             -i  (insert): "/pattern/text to insert/iab" options i case insensitive, a|b insert after|before line       
#             -s  (subst) : "/pattern/replacement/ig"     options i case insensitive, g global
#             -w  (write) : "optional new file name"| nothing = current name
#             -l  (list)  : 
#             -V  print version and exit
#             -h  (help)

# get default parameter for -w if none was given
# this function must be invoked
# before any command line processing
# defaultparameter;

# check at least some arguments were given
# getopts deletes ARGV, so save
# so it can be used for debugging
my @cmdlargs = @ARGV;
my $count = scalar(@cmdlargs);

# set command line switch parameters
# that are not associated with a sub
# register the control hash
$subcontrol = cmdlOrder->new(\%subhash, \@cmdlargs);

# print version and exit
if ($opt_V) {
	# print the installed version from dpkg-query
	my $string = `dpkg-query -W stedit`;
	my ($name, $version) = split /\s+/,$string;
	if ($version) {
		print "Version: $version (installed version)\n";
	} else {
		print "stedit is not installed\n";
	}
	exit 0;
}

# invoke usage if no arguments given
# or help switch
help() if $count == 0 || $opt_h;

# create the editor instance
# this must be done before
$editor = StEdit->new();


# execute the subs in StEdit.pm
$subcontrol->execsub();
