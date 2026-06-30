#!/usr/bin/perl
use strict;
use warnings;

# this script generates new secret and public keys
# exports them to initialise-linux/tmp/debhomeseckey.gpg
# and initialise-linux/etc/apt/keyrings/debhomepubkey.gpg
# the secret and public keys are then deleted from the keyring.
# the output from gpg --quick-generate-key is
# 
# gpg: revocation certificate stored as '/root/.gnupg/openpgp-revocs.d/2CD8319900216D7B36D7828D456DD768CEB04E19.rev'

# first command line argument is the name of the key
# if no name given prompt for one
# check if an argument was given
my $name;
if (scalar(@ARGV) == 0) {
	# no command line arguments given 
	# prompt for one.
	print "Enter a unique name for the key\n";
	$name = <STDIN>;
	chomp ($name);
} else {
	# argument on command line
	$name = $ARGV[0];
	chomp($name);
}
print "name is : [$name]\n";

# generate the key
my $output = `gpg --batch --yes --pinentry-mode loopback --passphrase 'coahtr3552' --quick-generate-key $name> /tmp/output.txt 2>&1`;

# open the file and get the key id
open (my $fh, "<", "/tmp/output.txt");

my @line = <$fh>;
close $fh;

# print "output: " . scalar(@line) . "\n@line\n";

# look for the line that has "certificate stored" in it
# and get the keyid
# the message may have 1 or 3 lines
my $keyid;
for (my $i=0; $i<scalar(@line); $i++) {
	# look for line with "certificate stored"
	if ($line[$i] =~ /certificate stored/i) {
		# found the line
		# get the key id
		$line[$i] =~ s/^.*revocs\.d\///;
		$line[$i] =~ s/\.rev\'//;
		$keyid = $line[$i];
		chomp($keyid);
		# exit loop
		last;
	}
}
print "keyid: [$keyid]\n";

# export the secret and public keys to the
# git repository for initialise-linux
my $msg = `gpg --verbose --batch --yes --pinentry-mode loopback --passphrase 'coahtr3552' --export-secret-key $keyid > /home/robert/initialise-linux/tmp/debhomeseckey.gpg`;
print "$msg\n";
$msg = `gpg --verbose --batch --yes --export $keyid > /home/robert/initialise-linux/etc/apt/keyrings/debhomepubkey.gpg`;
print "$msg\n";

# delete the secret and public keys
$msg = `gpg --verbose --batch --yes --pinentry-mode loopback --passphrase 'coahtr3552' --delete-secret-key $keyid`;
print "$msg\n";
$msg = `gpg --verbose --batch --yes --pinentry-mode loopback --delete-key $keyid`;
print "$msg\n";
