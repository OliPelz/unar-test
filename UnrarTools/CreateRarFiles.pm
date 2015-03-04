#!/usr/bin/perl
package UnrarTools::CreateRarFiles;
# this class is basically made for unit testing 
# it generates all kinds of rar files
# i have made a module out of it in order to access
# rar files in many unit test files and after all tests went through
# test files will be deleted automatically
# this class itself acts as a unit tests and has some ok() checks embedded
# it should therefore not be used in some production environment
use strict;

use Test::More qw(no_plan);
use File::Temp qw/ tempfile tempdir /;
use UnrarTools::Parsers;

sub new {
	my $class = shift;
        my $PASSWORD = "x7HbKo00PgD21";
	my $self = {
		_version => "0.0.0.1",
		_password  => shift,
		_CMD_RAR => "rar a %s %s",
		_CMD_RAR_ENCRYPT => "rar a -p$PASSWORD %s %s",
		_CMD_MULTIPART_RAR => "rar a -v100k %s %s",             
		_CMD_MULTIPART_RAR_ENCRYPT => "rar a %s %s",             
		# create random file of 1 MB size
		_CMD_DD_RANDOM => "dd if=/dev/urandom of=%s bs=1M count=1",
                # this is for overwriting a file 1 byte long
                # this introduces 1 byte of random bit data after ~80 kbyte
                # printf '\x31\xc0\xc3' | dd of=test_blob bs=1 seek=100 count=3 conv=notrunc 
                _CMD_DD_CRC => "dd if=/dev/urandom of=%s skip=10000 bs=8 count=1",
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
# create a normal rar file and return pull path to file
sub createRarFile {
   my $self = shift;
   my (undef, $randFile) = tempfile();
   my $cmd = sprintf($self->{_CMD_DD_RANDOM}, $randFile);
   `$cmd`;
   ok((-s $randFile), "test if random file has been created");
   my ($fh, $tempRarFile) = tempfile(	SUFFIX => ".rar");
   close $fh;
   `rm $tempRarFile`;
   my ($fh2, $tempRarOutputFile) = tempfile(	SUFFIX => ".out");
   close $fh2;
   $cmd = sprintf($self->{_CMD_RAR}, $tempRarFile, $randFile);
   `$cmd > $tempRarOutputFile`;
   ok((-s $tempRarFile), "test if we can create temp rar file");
   my %hsh = %{UnrarTools::Parsers->parseRARCreateOutput($tempRarOutputFile)};
   ok((-s $hsh{success} eq 1), "test if the rar output file could be successful created");
   ok((-s $hsh{volumeNames}[0] eq $tempRarFile), "test if the rar output file fits");
   return $tempRarFile;
}
# create a multipart rar file
sub createMultipartRarFile {
   # sidenote: _CMD_MULTIPART_RAR
}

sub createRarFileWithCRC {
   my $self = shift;
   my $validRarFile = $self->createRarFile();

   my ($fh, $tempRarFile) = tempfile(	SUFFIX => ".rar");
   close $fh;
   `cp $validRarFile $tempRarFile`;
   # introduce some crc errors
   # should be outside the rar header
   my $cmd = sprintf($self->{_CMD_DD_CRC}, $tempRarFile );
   return $tempRarFile; 
}
sub createMultipartRarFile {
   my $self = shift;
   my (undef, $randFile) = tempfile();
   my $cmd = sprintf($self->{_CMD_DD_RANDOM}, $randFile);
   `$cmd`;
   ok((-s $randFile), "test if random file has been created");
   my ($fh, $tempRarFile) = tempfile(	SUFFIX => ".rar");
   close $fh;
   `rm $tempRarFile`;
   $cmd = sprintf($self->{_CMD_RAR}, $tempRarFile, $randFile);
   my ($fh2, $tempRarOutputFile) = tempfile(	SUFFIX => ".out");
   close $fh2;
   `$cmd > $tempRarOutputFile`;
   # get all output files
   my %hsh 
 = %{UnrarTools::Parsers->parseRARMultiVolumeCreate($tempRarOutputFile)};

  
	
}

1;
