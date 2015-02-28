#!/usr/bin/env perl
package UnarChecker;

use warnings;
use strict;
use File::Find::Rule;
use File::Temp qw/tempfile/;
use Data::Dumper;
use DateTime;
use File::Basename;


sub new {
	my $class = shift;
	my $self = {
		_version => "0.0.0.1",
		_outputDir  => shift,
		_rarFiles => {},
		_id => 0
	};
	
	my $tmpVisitedFile =  shift;
	$self->{_visited} = {};
	if(defined($tmpVisitedFile)){
		open my $handle, '<', $tmpVisitedFile;
		while(my $line = <$handle>) {
			$self->{_visited}{chomp $line} = 1;
		}
		close $handle;
	}
	
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
sub getAllRarFilesInPath {
	my $self = shift;
	my $directory = shift;
	my %hshRef;
	
	# get all rar archives and store in directory datastructure
	my $id = 0;
	my @files = File::Find::Rule->file()
	                            ->name(qr/.*\.rar$/ )
	                            ->in( $directory );
	for my $file_name (@files) {
		if($file_name =~ /\.rar$/ && $file_name !~ /\.part\d+\.rar$/) {
			$hshRef{"rar_single"}{$file_name} = $self->{'_id'}++;
		}
		# multi part rar archive
		elsif($file_name=~ /\.part[0]*1.rar$/) {
			$hshRef{"rar_multi"}{$file_name} = $self->{'_id'}++;
		}
	}
	return \%hshRef;
	
}
sub test {
	my $self = shift;
	# for example let location be some download dir you used
	my $directory = shift || "~/Downloads";
	# set the name of the directory you want to sort all archives by name in it
	# TODO: my $topLevelDir = $ARGV[3] || basename(dirname($directory));
	$self->{'_rarFiles'} = $self->getAllRarFilesInPath($directory);
	
	#Dumper(%file_obj);
	# unrar test , do not query for passwords
	my $unrar_cmd = "unrar t -p- %s 1> %s 2> %s";
	# prepare the output folder structure
	my $cmd = "mkdir -p ".($self->{"_outputDir"})."/reports/single/";
	`$cmd`;
	$cmd = "mkdir -p ".($self->{"_outputDir"})."/reports/overview/";
	`$cmd`;
	
	my $OV_RUN;
	my $OV_VIS;
	my $OV_SUCCESS;
	my $OV_CRC;
	my $OV_ENCRYPT;
	my $OV_MISSING;
	
	open($OV_RUN, ">", $self->{"_outputDir"}."/reports/overview/run.txt");
	open($OV_VIS, ">", $self->{"_outputDir"}."/reports/overview/visited.txt");
	open($OV_SUCCESS, ">", $self->{"_outputDir"}."/reports/overview/success.txt");
	open($OV_CRC, ">", $self->{"_outputDir"}."/reports/overview/crc_error.txt");
	open($OV_ENCRYPT, ">", $self->{"_outputDir"}."/reports/overview/encrypted.txt");
	open($OV_MISSING, ">", $self->{"_outputDir"}."/reports/overview/parts_missing.txt");
	
	# writing some stats about the run
	my $dt   = DateTime->now;
	print $OV_RUN "# UnarChecker v" . $self->{_version} . " started on ".$dt->ymd . " " . $dt->hms . "\n"; 
	print $OV_RUN "# testing following list of rar files\n";
	print $OV_RUN "# Format: Filename<tab>Rar stdout file<tab>Rar stderr file<tab>Successful extraction: Yes/No<newline>\n";
	# the actual test
	foreach my $type (sort keys $self->{'_rarFiles'}) {
		my %archives = %{$self->{'_rarFiles'}{$type}};
		foreach my $archive (sort keys %archives) { 
			next if(defined($self->{_visited}{$archive}));
			
			print $OV_RUN $archive."\t";
			
			my $ts = time;
			my $stdoutFile = $self->{"_outputDir"}."/reports/single/".basename($archive).".".$ts.".stdout";
			my $stderrFile = $self->{"_outputDir"}."/reports/single/".basename($archive).".".$ts.".stderr";
			
			print $OV_RUN $stdoutFile."\t".$stderrFile."\t";
			
			if($type eq "rar_single" || $type eq "rar_multi") {
				my $cmd = sprintf($unrar_cmd, $archive, $stdoutFile, $stderrFile);
				my $exit_code = system($cmd);
				my $hshRef = $self->parseRAROutputFile($stdoutFile, $stderrFile);
				if($hshRef->{"success"} == 1) {
					print $OV_SUCCESS $archive."\n";
				}
				elsif($hshRef->{"success"} == 0) {
					if(defined($hshRef->{"errorType"}{"wrong_password"})) {
						print $OV_ENCRYPT $archive."\t".$hshRef->{"errorType"}{"wrong_password"}."\n";
					}
					elsif(defined($hshRef->{"errorType"}{"volume_missing"})) {
						print $OV_MISSING $archive."\t".$hshRef->{"errorType"}{"volume_missing"}."\n";
					}
					elsif(defined($hshRef->{"errorType"}{"checksum"})) {
						print $OV_CRC $archive."\t".$hshRef->{"errorType"}{"checksum"}."\n";
					}
					
				}
				print $OV_RUN ($hshRef->{"success"} eq 1 ? "yes" : "no") ."\n";
			}
			print $OV_VIS $archive ."\n";	
		}	
	}	
	close $OV_RUN;
	close $OV_VIS;
	close $OV_SUCCESS;
	close $OV_CRC;
	close $OV_ENCRYPT;
	close $OV_MISSING;
	
	print STDOUT "written report output files: ".$self->{"_outputDir"}."/reports/overview/run.txt\n".
	$self->{"_outputDir"}."/reports/overview/visited.txt\n".
	$self->{"_outputDir"}."/reports/overview/success.txt\n".
	$self->{"_outputDir"}."/reports/overview/crc_error.txt\n".
	$self->{"_outputDir"}."/reports/overview/encrypted.txt\n".
	$self->{"_outputDir"}."/reports/overview/parts_missing.txt\n\n".
        "written single stderr/stdout output files for all archives found to ".
        $self->{"_outputDir"}."/reports/single/\n";
       ;
}
sub parseRAROutputFile {
	my $self = shift;
	my $stdoutFile = shift;
	my $stderrFile = shift;
	my $FILE_STDOUT_HANDLER;
	my $FILE_STDERR_HANDLER;
	open($FILE_STDOUT_HANDLER, "<", $stdoutFile);
	open($FILE_STDERR_HANDLER, "<", $stderrFile);
	
	my %result = (
	    "success" => 1,
		"errorTotal" => 0,
		"errorType"  => {},
	);
	my $line;
	#Todo : search only in last two lines
	while($line = <$FILE_STDERR_HANDLER>) {
		$line =~ s/\n+//g;
		if($line=~ /^Cannot find volume/) {
			$result{"success"} = 0;
			$result{"errorType"}{"volume_missing"} = $line;
		}
		if($line =~ /checksum error$/) {
			$result{"success"} = 0;
			$result{"errorType"}{"checksum"} = $line;
		}
		if($line =~ /Corrupt file or wrong password.$/) {
			$result{"success"} = 0;
			$result{"errorType"}{"wrong_password"} = $line;
		}	
	}
	close $FILE_STDERR_HANDLER;
	while($line = <$FILE_STDOUT_HANDLER>) {
		if($line =~ /^Total errors: (\d+)$/) {
			$result{"success"} = 0;
			$result{"errorTotal"} = $1;
		}
		elsif($line =~ /^All OK$/) {
			$result{"success"} = 1;
		}
	}
	close $FILE_STDOUT_HANDLER;
	return \%result;
}
1;
