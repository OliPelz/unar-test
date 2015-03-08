#!/usr/bin/perl

use strict;

use Test::More qw(no_plan);
use lib "../";
use UnarChecker;
use File::Slurp;	



# init important stuff
my $ORG_FILES_DIR = "./org-files/rars/";
my $OUTPUT_TEST_FILES = "./org-files/rar-extract-stddout/";
my $TESTRUN_DIR = "./testrun-files/";
my $UNAR_TESTER = "../unar-check.pl";
my $OUT_DIR = "./out";

my %test_files = (
   "good" => ["good.rar"],
   "good_deep" => ["good.rar"],
   "good_multi" => ["example_split_archive.part1.rar",
                    "example_split_archive.part2.rar",
	            "example_split_archive.part3.rar"
                   ],
   "good_multi_deep" => ["example_split_archive.part1.rar",
                         "example_split_archive.part2.rar",
	                 "example_split_archive.part3.rar"
                        ],
   "bad" => ["example_corrupted.rar"],
   "bad_deep" => ["example_corrupted.rar"], 
   "multi" => ["example_split_archive.part1.rar"],
   "multi_deep" => ["example_split_archive.part1.rar"],
   "password_deep" => ["example_password_protected.rar"],
   "password" => ["example_password_protected.rar"]
   
);

my %subfolder_hash = (
  "good" => "good/",
  "good_deep" => "good_deep/1/2/3/4/5/",
  "good_multi" => "good_multi/",
  "good_multi_deep" => "good_multi_deep/1/2/3/4/5/6/7/8/9/",
  "bad" => "bad/",
  "bad_deep" => "bad_deep/6/7/8/9/10/",
  "multi" => "multi/",
  "multi_deep" => "multi_deep/11/12/13/14/15/",
  "password" => "password/",
  "password_deep" => "password_deep/16/17/18/19/20/"
);
#first test we are using the right unrar version!
#for example tests fail/script does not work when using
#unrar v4 because the output is different
my $unrarVersion = `unrar `;
ok($unrarVersion =~ /UNRAR 5.2/, 'testing if correct unrar version 5 can be found in path');

# unit test object methods from UnarChecker module

# parseRAROutputFile
my $checker = UnarChecker->new("/tmp");
my $hashRef = $checker->parseRAROutputFile("./stdout-files/good-stdout.txt", "./stdout-files/good-stderr.txt");
ok($hashRef->{"success"} == 1, "parsed 'success' state correctly for good archive");
ok($hashRef->{"errorTotal"} == 0, "parsed 'errorTotal' state correctly for good archive");

$hashRef = $checker->parseRAROutputFile("./stdout-files/bad-stdout.txt", "./stdout-files/bad-stderr.txt");
ok($hashRef->{"success"} == 0, "parsed 'success' state correctly for bad archive");
ok($hashRef->{"errorTotal"} == 1, "parsed 'errorTotal' state correctly for bad archive");
ok(defined($hashRef->{"errorType"}{"checksum"}), "checksum error for bad archive must be defined!"); 

$hashRef = $checker->parseRAROutputFile("./stdout-files/multi-error-stdout.txt", "./stdout-files/multi-error-stderr.txt");
ok($hashRef->{"success"} == 0, "parsed 'success' state correctly for multi volume missing archive");
ok($hashRef->{"errorTotal"} == 1, "parsed 'errorTotal' state correctly for multi volume missing archive");
ok(defined($hashRef->{"errorType"}{"volume_missing"}), "error type 'archive has volume missing' must be defined!"); 

$hashRef = $checker->parseRAROutputFile("./stdout-files/password-error-stdout.txt", "./stdout-files/password-error-stderr.txt");
ok($hashRef->{"success"} == 0, "parsed 'success' state correctly for password error archive");
ok($hashRef->{"errorTotal"} == 1, "parsed 'errorTotal' state correctly for password error a archive");
ok(defined($hashRef->{"errorType"}{"wrong_password"}), "error type for password error must be defined!"); 


# create some test folders with subfolders for extensive testing
if(-e $TESTRUN_DIR) {
  `rm -rf $TESTRUN_DIR`;
}
if(-e $OUT_DIR) {
	`rm -rf $OUT_DIR`;
}
#creaate the main folder for all our testing
ok(system("mkdir $TESTRUN_DIR") == 0, "successfully created main testdir");

foreach my $name (keys %subfolder_hash) {
	ok(system("mkdir -p ".$TESTRUN_DIR.$subfolder_hash{$name}) == 0, "successfully created testdir for ".$name);
}

# copy a bunch of rar files with: password, multiarchived, corrupted etc. in those sub folders
# and test existance afterwards
foreach my $sect (keys %test_files) {
        foreach my $name (@{$test_files{$sect}}) {
	ok(system("cp ".$ORG_FILES_DIR.$name." ".$TESTRUN_DIR.$subfolder_hash{$sect}) == 0, "copied file to test folder ".$name." ".$TESTRUN_DIR.$subfolder_hash{$sect});
	# test if file is actually there
	ok(-e $TESTRUN_DIR.$subfolder_hash{$sect}.$name, "target file exists ".$TESTRUN_DIR.$subfolder_hash{$sect}.$name);
}
}

# now test if we can get/find all the rar files recursively
$checker = UnarChecker->new("./tmp");
my $hshRef = $checker->getAllRarFilesInPath("./testrun-files");
#check if we got both single and multi rar keys
ok(defined($hshRef->{"rar_single"}), "check if we got rar_single defined");
ok(defined($hshRef->{"rar_multi"}), "check if we got rar_multi defined");
my $cnt = 0;
#get a collection of all files
my @allFiles = keys %{$hshRef->{"rar_single"}};
foreach my $tmpFile (keys %{$hshRef->{"rar_multi"}}) {
   push @allFiles,$tmpFile; 
}
foreach my $file1 (@allFiles) {
   my $found = 0;
   foreach my $sect (keys %test_files) {
      foreach my $name (@{$test_files{$sect}}) {
      my $file2 = $TESTRUN_DIR.$subfolder_hash{$sect}.$name;
      $file2 =~ s/\.\///g;
      if($file1 eq $file2 ) {
         $found = 1;
      }
      }
   }
   ok($found, "file $file1 could be found in path");
}
ok(scalar @allFiles == scalar keys %test_files, "all files must be found in path");

# test rar output file parser...therefore we have to refactor the perl script to a file
# $OUTPUT_TEST_FILES 
# TODO: create a temp dir using perl module

# test the good file ################################
`mkdir -p /tmp/test1`;
$checker = UnarChecker->new("/tmp/test1");
$checker->test("./testrun-files/good");
ok(( -f "/tmp/test1/reports/overview/run.txt"), "see if run file exists" );
ok(( -f "/tmp/test1/reports/overview/visited.txt"), "see if visited file exists" );
ok(( -f "/tmp/test1/reports/overview/success.txt"), "see if success file exists" );
ok(( -f "/tmp/test1/reports/overview/crc_error.txt"), "see if crc_error file exists" );
ok(( -f "/tmp/test1/reports/overview/encrypted.txt"), "see if encrypted file exists" );
ok(( -f "/tmp/test1/reports/overview/parts_missing.txt"), "see if parts_missing file exists" );
	
# TODO : check file size and run, visited and sucesss files
ok((-s "/tmp/test1/reports/overview/run.txt"), "run file must contain stuff" );
ok((-s "/tmp/test1/reports/overview/visited.txt"), "visited file must contain stuff" );
ok((-s "/tmp/test1/reports/overview/success.txt"), "sucess file must contain stuff" );
ok((not -s "/tmp/test1/reports/overview/crc_error.txt"), "crc_error file must be empty" );
ok((not -s "/tmp/test1/reports/overview/encrypted.txt"), "encrypted file must be empty" );
ok((not -s "/tmp/test1/reports/overview/parts_missing.txt"), "parts_missing file must be empty" );

my $runA = read_file("/tmp/test1/reports/overview/run.txt");
ok($runA =~ "testrun-files/good/good.rar.*stdout.*stderr\tyes", "run file contains our file");
my $visitedA = read_file("/tmp/test1/reports/overview/visited.txt");
ok($visitedA =~ "testrun-files/good/good.rar", "run file contains our file");
my $sucessA = read_file("/tmp/test1/reports/overview/success.txt");
ok($sucessA =~ "testrun-files/good/good.rar", "run file contains our file");


####  end of test the good file##################################


# test the good file located in deep subdir ################################
`mkdir -p /tmp/test2`;
$checker = UnarChecker->new("/tmp/test2");
$checker->test("./testrun-files/good_deep");
ok(( -f "/tmp/test2/reports/overview/run.txt"), "see if run file exists" );
ok(( -f "/tmp/test2/reports/overview/visited.txt"), "see if visited file exists" );
ok(( -f "/tmp/test2/reports/overview/success.txt"), "see if success file exists" );
ok(( -f "/tmp/test2/reports/overview/crc_error.txt"), "see if crc_error file exists" );
ok(( -f "/tmp/test2/reports/overview/encrypted.txt"), "see if encrypted file exists" );
ok(( -f "/tmp/test2/reports/overview/parts_missing.txt"), "see if parts_missing file exists" );

# TODO : check file size and run, visited and sucesss files
ok((-s "/tmp/test2/reports/overview/run.txt"), "run file must contain stuff" );
ok((-s "/tmp/test2/reports/overview/visited.txt"), "visited file must contain stuff" );
ok((-s "/tmp/test2/reports/overview/success.txt"), "sucess file must contain stuff" );
ok((not -s "/tmp/test2/reports/overview/crc_error.txt"), "crc_error file must be empty" );
ok((not -s "/tmp/test2/reports/overview/encrypted.txt"), "encrypted file must be empty" );
ok((not -s "/tmp/test2/reports/overview/parts_missing.txt"), "parts_missing file must be empty" );

my $runB = read_file("/tmp/test2/reports/overview/run.txt");
ok($runB = "testrun-files/good_deep/1/2/3/4/5/good.rar.*stdout.*stderr\tyes", "run file contains our file");
my $visitedB = read_file("/tmp/test2/reports/overview/visited.txt");
ok($visitedB =~ "testrun-files/good_deep/1/2/3/4/5/good.rar", "run file contains our file");
my $sucessB = read_file("/tmp/test2/reports/overview/success.txt");
ok($sucessB =~ "testrun-files/good_deep/1/2/3/4/5/good.rar", "run file contains our file");

####  end of test the good file located in deep subdir##################################


# test the multiple archive good file ################################
`mkdir -p /tmp/test3`;
$checker = UnarChecker->new("/tmp/test3");
$checker->test("./testrun-files/good_multi_deep");
ok( (-f "/tmp/test3/reports/overview/run.txt"), "see if run file exists" );
ok( (-f "/tmp/test3/reports/overview/visited.txt"), "see if visited file exists" );
ok( (-f "/tmp/test3/reports/overview/success.txt"), "see if success file exists" );
ok( (-f "/tmp/test3/reports/overview/crc_error.txt"), "see if crc_error file exists" );
ok( (-f "/tmp/test3/reports/overview/encrypted.txt"), "see if encrypted file exists" );
ok( (-f "/tmp/test3/reports/overview/parts_missing.txt"), "see if parts_missing file exists" );

# TODO : check file size and run, visited and sucesss files
ok((-s "/tmp/test3/reports/overview/run.txt"), "run file must contain stuff" );
ok((-s "/tmp/test3/reports/overview/visited.txt"), "visited file must contain stuff" );
ok((-s "/tmp/test3/reports/overview/success.txt"), "sucess file must contain stuff" );
ok((not -s "/tmp/test3/reports/overview/crc_error.txt"), "crc_error file must be empty" );
ok((not -s "/tmp/test3/reports/overview/encrypted.txt"), "encrypted file must be empty" );
ok((not -s "/tmp/test3/reports/overview/parts_missing.txt"), "parts_missing file must be empty" );

my $runC = read_file("/tmp/test3/reports/overview/run.txt");
ok($runC =~ "testrun-files/good_multi_deep/1/2/3/4/5/6/7/8/9/example_split_archive.part1.rar.*stdout.*stderr\tyes", "run file contains our file");
my $visitedC = read_file("/tmp/test3/reports/overview/visited.txt");
ok($visitedC =~ "testrun-files/good_multi_deep/1/2/3/4/5/6/7/8/9/example_split_archive.part1.rar", "run file contains our file");
my $sucessC = read_file("/tmp/test3/reports/overview/success.txt");
ok($sucessC =~ "testrun-files/good_multi_deep/1/2/3/4/5/6/7/8/9/example_split_archive.part1.rar", "run file contains our file");

####  end of test the multiple archive good file##################################


######### testing a bad crc file ###############################################

`mkdir -p /tmp/test4`;
$checker = UnarChecker->new("/tmp/test4");
$checker->test("./testrun-files/bad_deep");
ok(( -f "/tmp/test4/reports/overview/run.txt"), "see if run file exists" );
ok(( -f "/tmp/test4/reports/overview/visited.txt"), "see if visited file exists" );
ok(( -f "/tmp/test4/reports/overview/success.txt"), "see if success file exists" );
ok(( -f "/tmp/test4/reports/overview/crc_error.txt"), "see if crc_error file exists" );
ok(( -f "/tmp/test4/reports/overview/encrypted.txt"), "see if encrypted file exists" );
ok(( -f "/tmp/test4/reports/overview/parts_missing.txt"), "see if parts_missing file exists" );
ok((-s "/tmp/test4/reports/overview/run.txt"), "run file must contain stuff" );
ok((-s "/tmp/test4/reports/overview/visited.txt"), "visited file must contain stuff" );
ok((not -s "/tmp/test4/reports/overview/success.txt"), "sucess file must not contain stuff" );
ok(( -s "/tmp/test4/reports/overview/crc_error.txt"), "crc_error file must not be empty" );
ok((not -s "/tmp/test4/reports/overview/encrypted.txt"), "encrypted file must be empty" );
ok((not -s "/tmp/test4/reports/overview/parts_missing.txt"), "parts_missing file must be empty" );

my $runD = read_file("/tmp/test4/reports/overview/run.txt");
ok($runD =~ "testrun-files/bad_deep/6/7/8/9/10/example_corrupted.rar.*stdout.*stderr\tno", "run file contains our file");
my $visitedD = read_file("/tmp/test4/reports/overview/visited.txt");
ok($visitedD =~ "testrun-files/bad_deep/6/7/8/9/10/example_corrupted.rar", "run file contains our file");
my $sucessD = read_file("/tmp/test4/reports/overview/crc_error.txt");
ok($sucessD =~ "testrun-files/bad_deep/6/7/8/9/10/example_corrupted.rar", "run file contains our file");
#########end of testing a bad file##########################################

######### testing a password file ###############################################

`mkdir -p /tmp/test5`;
$checker = UnarChecker->new("/tmp/test5");
$checker->test("./testrun-files/password_deep");
ok(( -f "/tmp/test5/reports/overview/run.txt"), "see if run file exists" );
ok(( -f "/tmp/test5/reports/overview/visited.txt"), "see if visited file exists" );
ok(( -f "/tmp/test5/reports/overview/success.txt"), "see if success file exists" );
ok(( -f "/tmp/test5/reports/overview/crc_error.txt"), "see if crc_error file exists" );
ok(( -f "/tmp/test5/reports/overview/encrypted.txt"), "see if encrypted file exists" );
ok(( -f "/tmp/test5/reports/overview/parts_missing.txt"), "see if parts_missing file exists" );
ok((-s "/tmp/test5/reports/overview/run.txt"), "run file must contain stuff" );
ok((-s "/tmp/test5/reports/overview/visited.txt"), "visited file must contain stuff" );
ok((not -s "/tmp/test5/reports/overview/success.txt"), "success file must not contain stuff" );
ok((not -s "/tmp/test5/reports/overview/crc_error.txt"), "crc_error file must be empty" );
ok(( -s "/tmp/test5/reports/overview/encrypted.txt"), "encrypted file must NOT be empty" );
ok((not -s "/tmp/test5/reports/overview/parts_missing.txt"), "parts_missing file must be empty" );

my $runD = read_file("/tmp/test5/reports/overview/run.txt");
ok($runD =~ "testrun-files/password_deep/16/17/18/19/20/example_password_protected.rar.*stdout.*stderr\tno", "run file contains our file");
my $visitedD = read_file("/tmp/test5/reports/overview/visited.txt");
ok($visitedD =~ "testrun-files/password_deep/16/17/18/19/20/example_password_protected.rar", "run file contains our file");
my $sucessD = read_file("/tmp/test5/reports/overview/encrypted.txt");
ok($sucessD =~ "testrun-files/password_deep/16/17/18/19/20/example_password_protected.rar", "run file contains our file");

#########end of testing a password file##########################################

###multiple parts file with missing  parts####################################

`mkdir -p /tmp/test6`;
$checker = UnarChecker->new("/tmp/test6");
$checker->test("./testrun-files/multi_deep");
ok(( -f "/tmp/test6/reports/overview/run.txt"), "see if run file exists" );
ok(( -f "/tmp/test6/reports/overview/visited.txt"), "see if visited file exists" );
ok(( -f "/tmp/test6/reports/overview/success.txt"), "see if success file exists" );
ok(( -f "/tmp/test6/reports/overview/crc_error.txt"), "see if crc_error file exists" );
ok(( -f "/tmp/test6/reports/overview/encrypted.txt"), "see if encrypted file exists" );
ok(( -f "/tmp/test6/reports/overview/parts_missing.txt"), "see if parts_missing file exists" );
ok((-s "/tmp/test6/reports/overview/run.txt"), "run file must contain stuff" );
ok((-s "/tmp/test6/reports/overview/visited.txt"), "visited file must contain stuff" );
ok((not -s "/tmp/test6/reports/overview/success.txt"), "success file must not contain stuff" );
ok((not -s "/tmp/test6/reports/overview/crc_error.txt"), "crc_error file must be empty" );
ok((not -s "/tmp/test6/reports/overview/encrypted.txt"), "encrypted file must NOT be empty" );
ok((-s "/tmp/test6/reports/overview/parts_missing.txt"), "parts_missing file must be empty" );

my $runD = read_file("/tmp/test6/reports/overview/run.txt");
ok($runD =~ "testrun-files/multi_deep/11/12/13/14/15/example_split_archive.part1.rar.*stdout.*stderr\tno", "run file contains our file");
my $visitedD = read_file("/tmp/test6/reports/overview/visited.txt");
ok($visitedD =~ "testrun-files/multi_deep/11/12/13/14/15/example_split_archive.part1.rar", "run file contains our file");
my $sucessD = read_file("/tmp/test6/reports/overview/parts_missing.txt");
ok($sucessD =~ "testrun-files/multi_deep/11/12/13/14/15/example_split_archive.part1.rar", "run file contains our file");

#########end of multiple parts file with msg parts##########################################



ok(0, "test creation of a visitied file");
ok(0, "test if visited functionality works!");
