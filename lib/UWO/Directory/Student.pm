# UWO::Directory::Student
#  Represent a student as an object
#
# $Id: Student.pm 10 2007-10-08 13:03:04Z frequency $
#
# Copyright (C) 2006-2007 by Jonathan Yu <frequency@cpan.org>
#
# This software is licensed under a modified version of the BSD License. For
# detailed information, please consult the `perldoc' for this module or read
# the LICENSE file included in this distribution.

package UWO::Directory::Student;

use strict;
use warnings;
use Carp ();

use LWP::UserAgent;
use HTML::Entities ();

use UWO::Student;

=head1 NAME

UWO::Directory::Student - Perform lookups using the University of Western
Ontario's student directory

=head1 VERSION

Version 0.02 ($Id: Student.pm 10 2007-10-08 13:03:04Z frequency $)

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

This module provides a Perl interface to the public directory search system
which lists current students, staff and faculty at the University of Western
Ontario. (L<http://uwo.ca/westerndir/>)

C<UWO::Directory> is a module with a similar interface capable of aggregating
search results from multiple directories.

Example code:

    use UWO::Directory::Student;

    # Create Perl interface to API
    my $dir = UWO::Directory::Student->new;

    # Look up a student by name
    my $results = $dir->lookup({
      first => 'John',
      last  => 'S'
    });

    # Go through results
    foreach my $stu (@{$results}) {
      print 'email: ' . $stu->email . "\n";
    }

    # Reverse a lookup (use e-mail to find record)
    my $reverse = $dir->lookup({
      email => 'jsmith@uwo.ca'
    });

    if (defined $reverse) {
      print "Found: $reverse\n";
    }

=head1 COMPATIBILITY

Though this module was only tested under Perl 5.8.8 on Linux, it should be
compatible with any version of Perl that supports its prerequisite modules.

If you encounter any problems on a different version or architecture, please
contact the maintainer.

=head1 METHODS

=head2 Class and Constructor Methods

=over

=item UWO::Directory::Student->new

=item UWO::Directory::Student->new(\%params)

Creates a C<UWO::Directory::Student> search object, which uses a given web page
and server. Being that this module is developed to target UWO's in-house
system, the defaults should suffice.

The parameters available are:

    my $dir = UWO::Directory::Student->new({
      url    => 'http://uwo.ca/cgi-bin/dsgw/whois2html2',
      server => 'localhost',
    });

Which instantiates a C<UWO::Directory::Student> instance using C<url> as the
frontend and C<server> as the "black-box" backend.

=cut

sub new {
  my ($class, $params) = @_;

  my $self = {
    url       => $params->{url} || 'http://uwo.ca/cgi-bin/dsgw/whois2html2',
    server    => $params->{server} || 'localhost',
  };

  bless($self, $class);
}

=back

=head2 Object Methods

=over

=item $dir->lookup(\%params)

Uses a C<UWO::Directory::Student> search object to locate a given person based
on either their name (C<first> and/or C<last>) or their address (C<email>).

The module uses the following procedure to locate users:

=over

=item 1

If an e-mail address is provided:

=over

=item 1

The address is deconstructed into a first initial and the portion of the last
name. (According to the regular expression C<^(\w)([^\d]+)([\d]*)$>)

=item 2

The partial name is looked up in the directory.

=item 3

The resulting records are tested against the e-mail address. If the e-mail
address matches a given record, the C<UWO::Student> object is returned. The
lookup returns a false value (0) upon failure.

=back

=item 2

If first and/or last names are provided:

=over

=item 1

The name is searched using the normal interface (using the query
C<last_name,first_name>) and the results are returned as an array
reference. If there are no results, the method returns a false
value (0).

=back

=back

Example code:

    # Look up "John S" in the student directory
    my $results = $dir->lookup({
      first => 'John',
      last  => 'S'
    });

    # Look up jsmith@uwo.ca
    my $reverse = $dir->lookup({
      email => 'jsmith@uwo.ca'
    });

This method is not guaranteed to return results. If no results are found,
the return code will be 0.

In the case of a name-based lookup, the results will be returned as a reference
pointing to an ARRAY containing C<UWO::Student> objects.

In the case of an e-mail reverse lookup, a single C<UWO::Student> object will
be returned if a match is found. Otherwise, the result will be C<undef>.

=cut

sub lookup {
  my ($self, $params) = @_;

  Carp::croak('You must call this method as an object') unless ref $self;

  Carp::croak('Parameter not a hash reference!') unless ref($params) eq 'HASH';

  Carp::croak('No search parameters provided')
   unless(
    exists($params->{first}) ||
    exists($params->{last})  ||
    exists($params->{email})
   );

  # Don't do anything in void context
  unless (defined wantarray) {
    Carp::carp('Output from function discarded');
    return;
  }

  if (exists $params->{email}) {
    my $query;
    if ($params->{email} =~ m/^(\w+)(\@uwo\.ca)?$/) {
      $query = $1;

      # no domain provided, assume @uwo.ca for matching
      if (!defined($2)) {
        $params->{email} .= '@uwo.ca';
      }
    }
    else {
      Carp::croak('Need a UWO username or e-mail address');
    }

    # Discover query by deconstructing the username
    #  jdoe32
    #   First name: j
    #   Last name:  doe
    #   E-mail:     jdoe32@uwo.ca
    if ($query =~ /^(\w)([^\d]+)([\d]*)$/) {
      my $result = $self->lookup({
        first   => $1,
        last    => $2,
      });
      foreach my $stu (@{$result}) {
        return $stu if ($stu->email eq $params->{email});
      }
    }
    else {
      Carp::croak('Given username does not match UWO username pattern.');
    }
  }
  else {
    my $data = $self->_query($params->{last} . ',' . $params->{first});
    return $self->_parse($data);
  }
  return 0;
}

=back

=head1 UNSUPPORTED API

C<WebService::UWO::Directory::Student> provides access to some internal
methods used to retrieve and process raw data from the directory server.
Its behaviour is subject to change and may be finalized later as the
need arises.

=over

=item $dir->_query($query)

=item $dir->_query($query, $ua)

This method performs an HTTP lookup using C<LWP::UserAgent> and returns
a SCALAR reference to the returned page content. A C<LWP::UserAgent> object
may optionally be passed, which is particularly useful if a proxy is required
to access the Internet.

Please note that if a C<LWP::UserAgent> is passed, the User-Agent string will
not be modified. In normal operation, this module reports its user agent as
C<__PACKAGE__ . '/' . $VERSION>.

=cut

sub _query {
  my ($self, $query, $ua) = @_;

  Carp::croak('You must call this method as an object') unless ref($self);

  if (!defined $ua) {
    $ua = LWP::UserAgent->new;
    $ua->agent(__PACKAGE__ . '/' . $VERSION);
  }

  my $r = $ua->post($self->{'url'},
  {
    server => $self->{'server'},
    query  => $query,
  });

  die 'Error reading response: ' . $r->status_line unless $r->is_success;

  return \$r->content;
}

=item $dir->_parse($response)

=item UWO::Directory::Student->_parse($response)

=item UWO::Directory::Student::_parse($response)

This method processes the HTML content retrieved by _query method and
returns an ARRAY reference containing HASH references to the result set.
Additionally, _parse can be treated as either a function or class method.

=cut

sub _parse {
  # magic to allow use as method and function
  shift if ref($_[0]) ne 'SCALAR';

  Carp::croak('Expecting a scalar reference') unless ref($_[0]) eq 'SCALAR';

  my ($data) = @_;

  HTML::Entities::decode_entities(${$data});

  # Record format from the directory server:
  #    Full Name: Last,First Middle
  #       E-mail: e-mail@uwo.ca
  # Registered In: Faculty Name

  # 4 fields captured
  my @matches = (
    ${$data} =~ m{
      [ ]{4}Full\ Name:\ ([^,]+),(.+)\n
      [ ]{7}E-mail:.*\>(.+)\</A\>\n
            Registered\ In:\ (.+)\n
    }xg
  );

  my $res;
  for (my $i = 0; $i < scalar(@matches); $i += 4) {
    my $stu = UWO::Student->new({
      last_name   => $matches[$i],
      given_name  => $matches[$i+1],
      email       => $matches[$i+2],
      faculty     => $matches[$i+3],
    });
    push(@{$res}, $stu);
  }

  return $res;
}

=back

=head1 CONTRIBUTORS

=head2 MAINTAINER

Jonathan Yu E<lt>frequency@cpan.orgE<gt>

=head2 ACKNOWLEDGEMENTS

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc UWO::Directory::Student

You can also look for information at:

=over

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/UWO-Directory-Student>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/UWO-Directory-Student>

=item * Search CPAN

L<http://search.cpan.org/dist/UWO-Directory-Student>

=item * CPAN Request Tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=UWO-Directory-Student>

=back

=head1 FEEDBACK

Please send relevant comments, rotten tomatoes and suggestions directly to the
maintainer noted above.

If you have a bug report or feature request, please file them on the CPAN
Request Tracker at L<http://rt.cpan.org>

=head1 SEE ALSO

L<UWO::Student>, L<UWO::Directory>, L<http://uwo.ca/cgi-bin/dsgw/whois2html2>,
L<http://uwo.ca/westerndir/index-student.html>

=head1 CAVEATS

=head2 KNOWN BUGS

There are no known bugs as of this release.

=head2 LIMITATIONS

=over

=item *

This module is only able to access partial student records since students must
give consent for their contact information to be published on the web.
(L<http://uwo.ca/westerndir/index-student.html>).

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007 by Jonathan Yu

Redistribution and use in source/binary forms, with or without modification,
are permitted provided that the following conditions are met:

=over

=item 1

Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

=item 2

Redistributions in binary form must reproduce the above copyright notice, this
list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

=back

=head1 DISCLAIMER OF WARRANTY

This software is provided by the copyright holders and contributors "AS IS" and
ANY EXPRESS OR IMPLIED WARRANTIES, including, but not limited to, the IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED.

In no event shall the copyright owner or contributors be liable for any direct,
indirect, incidental, special, exemplary or consequential damages (including,
but not limited to, procurement of substitute goods or services; loss of use,
data or profits; or business interruption) however caused and on any theory of
liability, whether in contract, strict liability or tort (including negligence
or otherwise) arising in any way out of the use of this software, even if
advised of the possibility of such damage.

=cut

1;
