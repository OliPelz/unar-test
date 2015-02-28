# this module takes a password list and tries to decrypt a list of rar archives
# with it
# it will only test the archive and print out a correctly found password
# but will not actually extract the archive
# it is shipped with a cli interface
# it takes the approach shown here: stackoverflow link
# module managment: one module two get all rar files in path
# refactor the one found in the checker module for it
# one module to check
# one module to guess password

# basic workflow
# 1. use unrar -l to list content of rar file
# 2. parse this output
# 3. sort by file size asc
# 4. extract smallest file name (on top)
# 5. use unrar with extract single file param to get the file using a loop with all passwords
# 6. parse output
# 7. if file extract is ok write the filename and correct password into a file
# 8. TODO: use perl multithread to do one rar password try per core

#!/usr/bin/env perl
package UnarDecrypt;

use warnings;
use strict;
use File::Find;
use File::Temp qw/ tempfile tempdir /;
use Data::Dumper;


sub new {
	my $class = shift;
	my $self = {
		_version => "0.0.0.1",
		_outputDir  => shift,
		_rarFiles => {},
		_id => 0
	};
	bless $self, $class;
	$self->init();
	return $self;
}

sub init {
	my $self = shift;
	# init output log files
	# $self->{"errorLog"} = $self->{"_outputDir"}."/error.log";
	# $self->{"successLog"} = $self->{"_outputDir"}.."/sucess.log";
	# $self->{"stdoutLog"} = $self->{"_outputDir"}.."/stdout.log";
	# !/$self->{"stderrLog"} = $self->{"_outputDir"}.."/stderr.log";
}
# bruteforces all passwords of a list and returns the true one or empty string if not there
sub getCorrectRARPassword {
	my $self = shift;
	my $file_name = shift;
	my $passwordList = shift;
	
	return unless -f $file_name;
	# single part rar archive
	if($file_name =~ /(?!.part\d+).rar$/) {
		#we dont do anything here
	}
	# multi part rar archive
	elsif($file_name=~ /.part[0]*1.rar$/) {
		#if we are a multi part rar archive we need to treat this thing differently!
		#we only want to bruteforce the first part otherwise this will take too long
		#and the likelihood that every archive in a multi part rar is encrypted by a different password is close to zero
		#therefore we have to copy the archive away at a place where no other parts can be found!
		# todo: make this somewhere in the future a multicore task...perl can do this
		my $dir = tempdir( CLEANUP =>  1 );
		`cp $file_name $dir`;
		$file_name = $dir."/".basename $file_name;
	}
	my $cmd = "unrar e -p%s ".$file_name." ".$dir." 1>".$dir."/stdout.txt 2>".$dir."/stderr.txt"; 
	#http://stackoverflow.com/questions/15523249/test-only-password-on-rar-archive
	foreach my $pw (@$passwordList) {
		my $cmd_string = sprintf($cmd, $pw);
		my $returnValue = system($cmd_string);
		# Total errors will be 2 because we are missing the next volume and password was wrong
		# Total errors 1 : because missing next volume (and password was correct ;)
		
	}
	`unrar t `
	
	
	
}

sub decryptRARFile {
	my $self = shift;
	my $rarFile = shift;
	my $passwordList = shift;
	
}

1;
