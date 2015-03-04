# unrar-tools
convenient processing of multiple rar files

this toolset provides convenient methods for batch-processing big
amount of rar files in the filesystem 
this includes:

* automatic multi-archive testing made easy
  given a folder, this tool will recursively test every available rar file
  if it is errorfree (without crc errors)

rar testfiles i use in my unit tests come from
http://www.philipp-winterberg.com/software/rar_faq_corrupted_damaged_broken_partial_files.php

you need the following perl module dependecies installed (some distros have them already installed, others need cpan or install by yum/apt etc.

File::Slurp

TODO: only works on *Nix since I have hardcoded "/" dir paths
