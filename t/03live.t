#!perl -T

# $Id: 03live.t 5 2007-10-07 23:22:01Z frequency $

use strict;
use warnings;

use Test::More;

use UWO::Directory::Student;
use UWO::Student;

# Check if Term::ReadKey is available
eval 'use Term::ReadKey ()';

sub intro {
  diag(
    "\n",
    "This module can test your ability to query the server and process\n",
    "the results. It will only work for direct connections at this time.\n",
  );

  print STDERR 'Perform live tests? [yN] ';
}

if ($@) {
  if (!$ENV{TEST_AUTHOR}) {
    plan skip_all => 'Term::ReadKey not found and $ENV{TEST_AUTHOR} is false';
  }
  else {
    intro;

    # Block for a response since TEST_AUTHOR is on
    my $i = <>;
    chomp($i);

    if ($i =~ /^[nN]/) {
      plan skip_all => 'User selected no';
    }
  }
}
else {
  intro;

  # Wait 8 seconds to get input or continue
  my $i = Term::ReadKey::ReadLine(8);

  if (!defined $i) {
    plan skip_all => 'Timeout while waiting for user input';
  }
  elsif ($i !~ /^[yY]/) {
    plan skip_all => 'User selected no';
  }
}

plan tests => 8;

my $dir = UWO::Directory::Student->new;

# Normal lookup functionality
my $res = $dir->lookup({
  first => 'Continuing',
  last  => 'Test',
});

is($res->[0]->given_name, 'Continuing', 'User found by name');
is($res->[0]->last_name,  'Test');
is($res->[0]->email,      'ctest@uwo.ca');
is($res->[0]->faculty,    'Faculty of Graduate Studies');

# Reverse lookup functionality
$res = $dir->lookup({
  email => 'ctest@uwo.ca',
});

is($res->given_name, 'Continuing', 'User found by email reverse');
is($res->last_name,  'Test');
is($res->email,      'ctest@uwo.ca');
is($res->faculty,    'Faculty of Graduate Studies');
