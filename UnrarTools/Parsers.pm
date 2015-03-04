#!/usr/bin/env perl
package UnrarTools::Parsers;

use strict;
use warnings;

use File::Find;


# this method parses rar multipart creating output
# typically done with 'rar a -v<size>'
# returns a datastructure containing success status, errorTotal and errorType
# and all the names of all volumes
sub parseRARCreateOutput {
	my $stdoutFile = $_[1];
	my $FILE_STDOUT_HANDLER;
	open($FILE_STDOUT_HANDLER, "<", $stdoutFile);
	# TODO: I dont really have a lot of error code detection here
        # just a basic output file parser
        my %result = (
	    "success" => 0,
	    "errorTotal" => 0,
            "errorType"  => {},
            "volumeNames" => []
	);
	my $line;
        while($line = <$FILE_STDOUT_HANDLER>) {
                $line =~ s/\n+//g;
		# TODO: what is the exact regex for a filename?
		if($line =~ /^Creating archive ([\w_\.\-]+)$/) {
			push @{$result{"volumeNames"}}, $1;
		}
		elsif($line =~ /^Done$/) {
			$result{"success"} = 1;
		}
	}
	close $FILE_STDOUT_HANDLER;
	return \%result;
}

# parses RAR output files generated by RARs -t flag
# and stores if extraction was successful
sub parseUNRARTestOutputFile {
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
# parses RAR output files generated by using -lt flag (list technically)	
sub parseUNRARListTechnicalOutputFile {

}
1;
