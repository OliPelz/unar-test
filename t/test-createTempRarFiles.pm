use strict;
use warnings;

# test for class : UnrarTools::CreateRarFiles

use lib "../";

use UnrarTools::CreateRarFiles;


my $rarFileCreator = UnrarTools::CreateRarFiles->new();

$rarFileCreator->init();
my $rarFile = $rarFileCreator->createRarFile();
ok((-s $rarFile), "check if we could succesfully create a rar file");

