#!/usr/bin/perl
use strict;
use UnarChecker;


use strict;
use warnings;
if(!defined($ARGV[0]) && !defined($ARGV[1])) {
  die "parameter 1 : rar-dir or parameter 2: output-dir missing"
}
# Usage: unar-check.pl rar-dir output-dir
my $checker = UnarChecker->new($ARGV[1]);
$checker->test($ARGV[0]);
