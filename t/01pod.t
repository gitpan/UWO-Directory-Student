#!perl -T

# $Id: 01pod.t 3 2007-10-06 12:53:59Z frequency $

use strict;
use warnings;

use Test::More;

eval 'use Test::Pod 1.14';

if ($@) {
  plan skip_all => 'Test::Pod 1.14 required to test POD';
}

all_pod_files_ok();
