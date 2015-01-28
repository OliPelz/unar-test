#!/usr/bin/env perl

use warnings;
use strict;
use File::Find;
use File::Temp qw/tempfile/;
use Data::Dumper;

# for example let location be some download dir you used
my $directory  = $ARGV[0] || "/Users/olip/Downloads";
my $outputDir = $ARGV[1] || "/tmp";
# set the name of the directory you want to sort all archives by name in it
my $topLevelDir = $ARGV[3] || basename(dirname($directory));


my $errorLog   = $outputDir."/error.log";
my $successLog = $outputDir."/sucess.log";
my $stdoutLog  = $outputDir."/stdout.log";
my $stderrLog  = $outputDir."/stderr.log";

my %file_obj;
# keeps track if a file can be successful unarchived
my %file_to_succes;
# keeps track if file has any crc error while extracting
my %file_to_err;
# keeps track if file has missing parts while extracting
my %file_to_missing;
# keeps track if file needs password while extracting
my %file_to_password;


find ( \&wanted, $directory );

my $id = 0;
sub wanted {
	my $file_name = $_;
    return unless -f $file_name;
	# single part rar archive
	if($file_name =~ /(?!.part\d+).rar$/) {
		$id++;
		$file_obj{"rar_single"}{$File::Find::name} = $id;
	}
	# multi part rar archive
	elsif($file_name=~ /.part[0]*1.rar$/) {
		$id++;
		$file_obj{"rar_multi"}{$File::Find::name} = $id;
	}
}

#Dumper(%file_obj);
# unrar test , do not query for passwords
my $unrar_cmd = "unrar -t -p- %s 1> %s 2> %s"
# the actual test
foreach my $type (sort keys %file_obj) {
	#just create temp filenames
	my $stdout_file;
	(undef, $stdout_file) = tempfile('tmpStdout', OPEN=>0);
	my $stderr_file;
	(undef, $stderr_file) = tempfile('tmpStderr', OPEN=>0);
   
   if($type eq "rar_single") {
   	   my $cmd = sprintf($unrar_cmd, $stdout_file, $stderr_file);
	   `$cmd`;
	   if(-e $stdout_file) {
		   // check for all ok
	   }
	   if(-e $stderr_file) {
	   	   // parse error type
	   }
	   // save output files somewhere
   }	
}