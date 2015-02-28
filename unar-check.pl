#!/usr/bin/perl

use UnarChecker;

use strict;
use warnings;
# unar-check.pl rar-dir output-dir
my $checker = UnarChecker->new($ARGV[1]);
$checker->test($ARGV[0]);
