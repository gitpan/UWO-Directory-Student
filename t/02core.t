#!perl -T

# $Id: 02core.t 4 2007-10-07 23:21:19Z frequency $

use strict;
use warnings;

use Test::More;

use UWO::Directory::Student;

# Check all core methods are defined
my @methods = (
  'new',

  # Public methods
  'lookup',

  # Private/internal methods
  '_query',
  '_parse',
);

# There is 1 non-method test
plan tests => (1 + scalar(@methods));

foreach my $meth (@methods) {
  ok(UWO::Directory::Student->can($meth), 'Method "' . $meth . '" exists.');
}

# Test the constructor initialization
my $dir = UWO::Directory::Student->new;
isa_ok($dir, 'UWO::Directory::Student');
