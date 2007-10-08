#!perl -T

# $Id: 01pod-coverage.t 3 2007-10-06 12:53:59Z frequency $

use strict;
use warnings;

use Test::More;

eval 'use Test::YAML::Meta';

if ($@) {
  plan skip_all => 'Test::YAML::Meta required to test META.yml';
}

plan tests => 2;

# counts at 2 tests
meta_spec_ok('META.yml', undef, 'META.yml matches the META-spec');
