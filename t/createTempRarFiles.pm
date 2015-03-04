#!/usr/bin/perl
package UnarTools::CreateRarFiles;
# this class is basically made for unit testing 
# it generates all kinds of rar files
# i have made a module out of it in order to access
# rar files in many unit test files and after all tests went through
# test files will be deleted automatically
use strict;

use Test::More qw(no_plan);

sub new {
	my $class = shift;
        my $PASSWORD = "x7HbKo00PgD21";
	my $self = {
		_version => "0.0.0.1",
		_password  => shift,
		_CMD_RAR => "rar a %s %s",
		_CMD_RAR_ENCRYPT => "rar a -p$PASSWORD %s %s",
		# create random file of 1 MB size
		_CMD_DD_RANDOM => "dd if=/dev/random of=%s bs=1024 count=1",
		_TEMPDIR => undef
	};
	bless $self, $class;
	$self->init();
	return $self;
}
sub init {
  my $self = shift;
# check if linux tools are available for this test
  my $ddVersion = `dd --help`;
  ok(($ddVersion =~ /Copy a file, converting and formatting according to the operands./),
    "checking if linux cmd dd is available");
  my $rarVersion = `rar`;
  my $unrarVersion = `unrar`;
  ok(($rarVersion=~ /RAR 5.2/), "checking if rar cmd is available");
  ok(($unrarVersion=~ /UNRAR 5.2/), "checking if unrar cmd is available");
#first create a bunch of rar test files
# create temp dir
  $self->{_TEMPDIR} = tempdir( CLEANUP => 0 );
}

# create a normal rar file and return full path to file
sub createRarFile {
   my $self = shift;
   my (undef, $randFile) = tempfile();
   my $cmd = sprintf($self->{_CMD_DD_RANDOM}, $randFile);
   `$cmd`;
   ok((-s $randFile), "test if random file has been created");
   my (undef, $tempRarFile) = tempfile(	SUFFIX => ".rar");
   $cmd = sprintf($self->{_CMD_RAR}, $randFile, $tempRarFile);
   ok((-s $tempRarFile), "test if we can create temp rar file");
   return $tempRarFile;
}
