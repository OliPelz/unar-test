#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw(no_plan);
use lib "../";
use File::Slurp;
use UnrarTools::Parsers;

# this tests parsing of a single rar creating output
my %hsh 
 = %{UnrarTools::Parsers->parseRARCreateOutput("./stdout-files/rar-create-singlerar.txt")};
ok($hsh{"success"} eq 1, "parsing should be successful in parseRARCreateOutput single");
ok($hsh{"errorTotal"} eq 0, "there should be no error in parseRARCreateOutput single");
ok(scalar keys $hsh{"errorType"} eq 0, "parsing should be successful in parseRARCreateOutput single");
ok(scalar  @{$hsh{"volumeNames"}} eq 1, "number of parsed volumes should be correct in parseRARCreateOutput single");
ok($hsh{"volumeNames"}[0] eq "myFile.rar", "parsed volume name should be correct in parseRARCreateOutput single");

# this tests parsing of rar command creating a multi rar file output
my %hsh 
 = %{UnrarTools::Parsers->parseRARCreateOutput("./stdout-files/rar-create-multirar.txt")};

ok($hsh{"success"} eq 1, "parsing should be successful in parseRARCreateOutput multi");
ok($hsh{"errorTotal"} eq 0, "there should be no error in parseRARCreateOutput multi");
ok(scalar keys $hsh{"errorType"} eq 0, "parsing should be successful in parseRARCreateOutput multi");
ok(scalar  @{$hsh{"volumeNames"}} eq 11, "number of parsed volumes should be correct in parseRARCreateOutput multi");
ok($hsh{"volumeNames"}[1] eq "our-multirarfile.part02.rar", "parsed volume name should be correct in parseRARCreateOutput multi");

# TODO first test basic parsing capabilities by generating pure output and 
# parse this



# TODO: insert tests from unarchecker and switch to generate all those files on your own

# 


