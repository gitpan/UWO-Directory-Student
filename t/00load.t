#!perl -T

# $Id: 00load.t 7 2007-10-07 23:22:50Z frequency $

use Test::More tests => 1;

# Check that we can load the module
BEGIN {
  use_ok('UWO::Directory::Student');
}

diag('Testing UWO::Directory::Student ', UWO::Directory::Student->VERSION);
diag('Running under Perl ', $], ' [', $^X, ']');
