# $Revision: 1.16 $
# $Id: Freshmeat.pm,v 1.16 2002/07/21 03:27:13 afoxson Exp $

# Mail::Freshmeat - parses daily newsletters from http://freshmeat.net/
# Copyright (c) 2002 Adam J. Foxson. All rights reserved.
# Copyright (c) 1999-2000 Adam Spiers. All rights reserved.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

package Mail::Freshmeat;

use strict;
use 5.005;
use Carp;
use vars qw($VERSION @ISA $AUTOLOAD);
use Mail::Internet;
use Mail::Freshmeat::Entry;
use Mail::Freshmeat::Utils;

local $^W;

@ISA       = qw(Mail::Internet);
($VERSION) = '$Revision: 1.16 $' =~ /\s+(\d+\.\d+)\s+/;

sub new
{
	my $self   = shift;
	my $parser = $self->SUPER::new(@_);

	# these are the allowed newsletter accessors
	$parser->{fm_is_attr} =
	{
		map {$_ => 1} qw
		(
			links_header links ad_header ad headlines_header
			headlines details_header details footer total
			date full
		)
	};

	return $parser->_parse();
}

sub _parse
{
	my $self = shift;

	$self->_parse_non_entries();
	$self->_parse_misc();
	$self->_parse_entries();
	$self->_fix_headlines();

	return $self;
}

# This unfortunately is need since some of the individual one-line headline
# entries wrap over to the second line
sub _fix_headlines
{
	my $self   = shift;
	my $buffer = '';

	for my $entry (split /\n/, $self->headlines())
	{
		if ($entry =~ /^\[\d{3}/)
		{
			$buffer .= "$entry\n";
		}
		else
		{
			chop $buffer;
			$buffer .= " $entry\n";
		}
	}

	chomp $buffer;
	$self->{fm_headlines} = $buffer;
}

sub _parse_entries
{
	my $self        = shift;
	my $body        = join '', @{$self->body()};
	my $count       = 1;
	my @entries;

	for my $entry
	(
		split
		m/
			$blank_line
			^ \s* -\ %\ \ -\ %\ \ -\ %\ -\ %\ - \s* $ \n
			$blank_line
		/mx,
		$self->details()
	)
	{
		my $new_entry = Mail::Freshmeat::Entry->new($entry, $count);

		push @entries, $new_entry;
		$count++;
	}

	my $total_entries = scalar @entries;
	if ($total_entries != $self->total())
	{
		_fatal_bug("Counted entries don't match what the newsletter claims " .
			"($total_entries/${\($self->total())}).");
	}

	$self->{fm_entries} = \@entries;
}

sub _parse_misc
{
	my $self = shift;

	if ($self->headlines_header() =~ /\((\d+)\)/)
	{
		$self->{fm_total} = $1;
	}
	else
	{
		_fatal_bug("Couldn't parse newsletter structure (total).");
	}

	if (my ($year, $month, $day) =
			$self->links() =~ /(\d{4})\/(\d{2})\/(\d{2})/)
	{
		$self->{fm_date} = "$year/$month/$day";
	}
	else
	{
		_fatal_bug("Couldn't parse newsletter structure (date).");
	}
}

sub _parse_non_entries
{
	my $self        = shift;
	my $body        = join '', @{$self->body()};

	$body =~ s/\n{2,}/\n\n/g;
	$body =~
	m!
		^ (:::\ L\ I\ N\ K\ S\ \ \ F\ O\ R\ \ \ T\ H\ E\ \ \ D\ A\ Y\ :::) \s* $ \n
		$blank_line
		((?s:.+?)) \n?
		$blank_line
		$sep
		(?:
			$blank_line
			^ (:::\ A\ D\ V\ E\ R\ T\ I\ S\ I\ N\ G\ :::) \s* $ \n
			$blank_line
			((?s:.+?)) \n?
			$blank_line
			$sep
		)?
		$blank_line
		^ (:::\ R\ E\ L\ E\ A\ S\ E\ \ \ H\ E\ A\ D\ L\ I\ N\ E\ S\ \([^\)]+\)\ :::) \s* $ \n
		$blank_line
		((?: ^ \[\d+\]\ .* $ \n | ^ [^\)]+ \) $ \n)+)
		$blank_line
		$sep
		$blank_line
		^ (:::\ R\ E\ L\ E\ A\ S\ E\ \ \ D\ E\ T\ A\ I\ L\ S\ :::) \s* $ \n
		$blank_line
		((?s:.+?))
		$blank_line
		$sep
		$blank_line
		^ _+ \s* $ \n
		((?s:.+)) \n{2}
	!mx or _fatal_bug("Couldn't parse newsletter structure (body).");

	$self->{fm_links_header}     = $1;
	$self->{fm_links}            = $2;
	$self->{fm_ad_header}        = $3;
	$self->{fm_ad}               = $4;
	$self->{fm_headlines_header} = $5;
	$self->{fm_headlines}        = $6;
	$self->{fm_details_header}   = $7;
	$self->{fm_details}          = $8;
	$self->{fm_footer}           = $9;
	$self->{fm_full}             = $body;

	chomp $self->{fm_details};

	for my $key (keys %$self)
	{   
		if (not defined $self->{$key} or not $self->{$key})
		{
			$self->{$key} = 'Not specified';
		}
	}
}

sub entries
{
	my $self = shift;

	croak "entries is not a class method" if not ref $self;

	wantarray ? @{$self->{fm_entries}} : $self->{fm_entries};
}

sub AUTOLOAD
{
	my $self = $_[0];
	my ($package, $method) = ($AUTOLOAD =~ /(.*)::(.*)/);

	return if $method =~ /^DESTROY$/;

	croak "$method is not a class method or does not exist" if not ref $self;

	unless ($self->{fm_is_attr}->{$method})
	{
		croak "No such newsletter accessor: $method; aborting";
	}

	my $code = q
	{
		sub
		{   
			my $self = shift;
			return $self->{fm_METHOD};
		}
	};

	$code =~ s/METHOD/$method/g;

	{
		no strict 'refs';
		*$AUTOLOAD = eval $code;
	}

	goto &$AUTOLOAD;
}

1;

__END__

=head1 NAME

Mail::Freshmeat - parses daily newsletters from http://freshmeat.net/

=head1 SYNOPSIS

 my $newsletter = Mail::Freshmeat->new(\*STDIN);

 print "Date: ", $newsletter->date(), "\n";
 print "Total entries: ", $newsletter->total(), "\n";

 for my $entry ($newsletter->entries())
 {
   print "Position: ", $entry->position(), "\n";
   print "Name and version: ", $entry->name_and_version(), "\n";
 }

=head1 DESCRIPTION

IMPORTANT: DUE TO FRESHMEAT.NET CHANGING THE STRUCTURE OF THEIR
NEWSLETTERS, THE INTERFACE FOR THIS PACKAGE HAS CHANGED
SINCE Mail::Freshmeat 0.94.

Mail::Freshmeat is a subclass of B<Mail::Internet>.

This package provides parsing of the daily e-mail newsletters which
are sent out from F<http://freshmeat.net/> to any individual who
requests them.

=head1 NEWSLETTER METHODS

=over 4

=item * B<new>

This is the constructor. Pass it something that Mail::Internet will like
such as a file descriptor (reference to a GLOB) or a reference to an
array and you will get back a newsletter object.

=item * B<entries>

This object method will return an array or an array reference (depending
on context) of entry objects for all of the entries in the newsletter.

=back

=head1 ENTRY METHODS

=over 4

=item * B<entry_keys>

This object method will return an array or an array reference (depending
on context) of all the attribute names of an entry (e.g.: position, name,
license, url) in the order that they appeared.

=item * B<short_entry>

This object method will return the short description of the entry as it
appeared in the newsletter headlines section (eg: Linux 2.4.9-ac15 (2.4-ac))

=back

=head1 NEWSLETTER ACCESSORS

=over 4

=item * B<links_header>

=item * B<links>

=item * B<ad_header>

=item * B<ad>

=item * B<headlines_header>

=item * B<headlines>

=item * B<details_header>

=item * B<details>

=item * B<footer>

=item * B<total>

=item * B<date>

=item * B<full>

=back

=head1 ENTRY ACCESSORS

=over 4

=item * B<position>

=item * B<name_and_version>

=item * B<name>

=item * B<version>

=item * B<posted_by>

=item * B<posted_on>

=item * B<trove>

=item * B<about>

=item * B<changes>

=item * B<license>

=item * B<url>

=item * B<full>

=back

=head1 AUTHORS

 Adam J. Foxson B<afoxson@pobox.com>, 2002-
 Adam Spiers B<adam@spiers.net>, 1999-2000

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

=head1 VERSION

This is release 1.16.

=head1 SEE ALSO

perl(1).

=cut
