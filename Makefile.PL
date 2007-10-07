#!perl

# Makefile.PL
#  Script to generate an acceptable module Makefile
#
# $Id: Makefile.PL 8 2007-10-07 23:24:59Z frequency $
#
# This helper script is hereby released into the public domain.

use strict;
use warnings;

use ExtUtils::MakeMaker ();

use File::Spec;

my @tests = glob File::Spec->catfile('t', '*.t');

ExtUtils::MakeMaker::WriteMakefile(
  NAME                => 'UWO::Directory::Student',
  AUTHOR              => 'Jonathan Yu <frequency@cpan.org>',
  LICENSE             => 'bsd',
  VERSION_FROM        => 'lib/UWO/Directory/Student.pm',
  ABSTRACT_FROM       => 'lib/UWO/Directory/Student.pm',
  PL_FILES            => {},
  PREREQ_PM => {
    # Pragmatic and special modules
    'Carp'            => 1.04,

    # Other modules
    'LWP::UserAgent'  => 2.003,
    'Test::More'      => 0.62,
    'UWO::Student'    => 0.02,
    'HTML::Entities'  => 0,
  },

  test                => { TESTS => join(' ', @tests) },
  dist                => {
    COMPRESS          => 'gzip -9f',
    SUFFIX            => 'gz',
  },
  clean               => { FILES => 'UWO-Directory-Student-*' },
);
