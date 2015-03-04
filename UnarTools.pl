#!/usr/bin/env perl
package Unar::Tools;

use strict;
use warnings;

use File::Find;

sub getAllRarFilesInPath {
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
sub getAllEncryptedRarFilesInPath {
   my $directory = shift;
   my @files = Unar::Tools->getAllRarFilesInPath($directory);
   
}
