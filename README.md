# unar-test
convenient automatic multi-archive testing made easy

rar testfiles i use in my unit tests come from
http://www.philipp-winterberg.com/software/rar_faq_corrupted_damaged_broken_partial_files.php

you need the following perl module dependecies installed (some distros have them already installed, others need cpan or install by yum/apt etc.

File::Slurp
DateTime


TODOs: 
* only works on *Nix since I have hardcoded "/" dir paths
* introduce verbose flag to switch on/off progress etc.


Troubleshooting: 
if tests fail oftentimes this is because not using correct rar version
this program was written for rar 5.21, please install only this one!
you can find linux executables at rarlabs.com
