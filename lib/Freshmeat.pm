# $Revision: 1.20 $
# $Id: Freshmeat.pm,v 1.20 2002/07/22 08:35:42 afoxson Exp $

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
use Mail::Freshmeat::Article;
use Mail::Freshmeat::Utils;

local $^W;

@ISA       = qw(Mail::Internet);
($VERSION) = '$Revision: 1.20 $' =~ /\s+(\d+\.\d+)\s+/;

sub new
{
	my $self   = shift;
	my $parser = $self->SUPER::new(@_);

	# these are the allowed newsletter accessors
	$parser->{_fm_is_attr} =
	{
		map {$_ => 1} qw
		(
			_date
			_links_header _links
			_ad_header _ad
			_headlines_header _headlines
			_entries_header _entries_payload _entries_total
			_articles_header _articles_payload _articles_total
			_footer
			_full
		)
	};

	return $parser->_parse();
}

sub _parse
{
	my $self = shift;

	$self->_parse_structure();
	$self->_parse_articles();
	$self->_parse_entries();
	$self->_fix_headlines();

	return $self;
}

sub _parse_structure
{
	my $self = shift;
	my $body = join '', @{$self->body()};

	$body =~ s/\n{2,}/\n\n/g;
	$body =~
	m!
		^ (:::\ L\ I\ N\ K\ S\ \ \ F\ O\ R\ \ \ T\ H\ E\ \ \ D\ A\ Y\ :::) \s* $ \n
		$_blank_line
		((?s: .+? (\d{4}\/\d{2}\/\d{2}) .+? )) \n?
		$_blank_line
		$_sep
		(?:
			$_blank_line
			^ (:::\ A\ D\ V\ E\ R\ T\ I\ S\ I\ N\ G\ :::) \s* $ \n
			$_blank_line
			((?s:.+?)) \n?
			$_blank_line
			$_sep
		)?
		(?:
			$_blank_line
			^ (:::\ A\ R\ T\ I\ C\ L\ E\ S\ \((\d+)\)\ :::) \s* $ \n
			$_blank_line
			((?s:.+?)) \n?
			$_blank_line
			$_sep
		)?
		$_blank_line
		^ (:::\ R\ E\ L\ E\ A\ S\ E\ \ \ H\ E\ A\ D\ L\ I\ N\ E\ S\ \((\d+)\)\ :::) \s* $ \n
		$_blank_line
		((?: ^ \[\d+\]\ .* $ \n | ^ [^\)]+ \) $ \n)+)
		$_blank_line
		$_sep
		$_blank_line
		^ (:::\ R\ E\ L\ E\ A\ S\ E\ \ \ D\ E\ T\ A\ I\ L\ S\ :::) \s* $ \n
		$_blank_line
		((?s:.+?)) \n
		$_blank_line
		$_sep
		$_blank_line
		^ _+ \s* $ \n
		((?s:.+)) \n{2}
	!mx or _fatal_bug("Couldn't parse newsletter structure (body).");

	$self->{_fm_links_header}     = $1;
	$self->{_fm_links}            = $2;
	$self->{_fm_date}             = $3;
	$self->{_fm_ad_header}        = $4;
	$self->{_fm_ad}               = $5;
	$self->{_fm_articles_header}  = $6;
	$self->{_fm_articles_total}   = $7;
	$self->{_fm_articles_payload} = $8;
	$self->{_fm_headlines_header} = $9;
	$self->{_fm_entries_total}    = $10;
	$self->{_fm_headlines}        = $11;
	$self->{_fm_entries_header}   = $12;
	$self->{_fm_entries_payload}  = $13;
	$self->{_fm_footer}           = $14;
	$self->{_fm_full}             = $body;

	chomp $self->{_fm_headlines};

	for my $key (keys %$self)
	{
		$self->{$key} = '' if not defined $self->{$key};
	}
}

sub _parse_articles
{
	my $self  = shift;
	my $count = 1;
	my @articles;

	return if not $self->articles_payload();

	for my $article
	(
		split
		m/
			\/ $ \n
		/mx,
		$self->articles_payload()
	)
	{
		my $new_article = Mail::Freshmeat::Article->new($article, $count);

		push @articles, $new_article;
		$count++;
	}

	my $total_articles = scalar @articles;
	if ($total_articles != $self->articles_total())
	{
		_fatal_bug("Counted articles don't match what the newsletter claims " .
			"($total_articles/${\($self->articles_total())}).");
	}

	$self->{_fm_articles} = \@articles;
}

sub _parse_entries
{
	my $self  = shift;
	my $count = 1;
	my @entries;

	for my $entry
	(
		split
		m/
			$_blank_line
			^ \s* -\ %\ \ -\ %\ \ -\ %\ -\ %\ - \s* $ \n
			$_blank_line
		/mx,
		$self->entries_payload()
	)
	{
		my $new_entry = Mail::Freshmeat::Entry->new($entry, $count);

		push @entries, $new_entry;
		$count++;
	}

	my $total_entries = scalar @entries;
	if ($total_entries != $self->entries_total())
	{
		_fatal_bug("Counted entries don't match what the newsletter claims " .
			"($total_entries/${\($self->entries_total())}).");
	}

	$self->{_fm_entries} = \@entries;
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
	$self->{_fm_headlines} = $buffer;
}

sub articles
{
	my $self = shift;

	croak "articles is not a class method" if not ref $self;

	return if not exists $self->{_fm_articles};
	wantarray ? @{$self->{_fm_articles}} : $self->{_fm_articles};
}

sub entries
{
	my $self = shift;

	croak "entries is not a class method" if not ref $self;

	return if not exists $self->{_fm_entries};
	wantarray ? @{$self->{_fm_entries}} : $self->{_fm_entries};
}

sub AUTOLOAD
{
	my $self = $_[0];
	my ($package, $method) = ($AUTOLOAD =~ /(.*)::(.*)/);

	return if $method =~ /^DESTROY$/;

	croak "$method is not a class method or does not exist" if not ref $self;

	unless ($self->{_fm_is_attr}->{"_$method"})
	{
		croak "No such newsletter accessor: $method; aborting";
	}

	my $code = q
	{
		sub
		{   
			my $self = shift;
			return $self->{_fm_METHOD};
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

 use Mail::Freshmeat;

 my $newsletter = Mail::Freshmeat->new(\*STDIN);

 print "Date: ", $newsletter->date(), "\n";
 print "Total entries: ", $newsletter->entries_total(), "\n";

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

=item * B<articles>

This object method will return an array or an array reference (depending
on context) of article objects for all of the articles in the newsletter.

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

=head1 ARTICLE METHODS

=over 4

=item * B<article_keys>

This object method will return an array or an array reference (depending
on context) of all the attribute names of an article (e.g.: title,
description, url) in the order that they appeared.

=back

=head1 NEWSLETTER ACCESSORS

=over 4

=item * B<ad>

=item * B<ad_header>

=item * B<articles_header>

=item * B<articles_payload>

=item * B<articles_total>

=item * B<date>

=item * B<entries_header>

=item * B<entries_payload>

=item * B<entries_total>

=item * B<footer>

=item * B<full>

=item * B<headlines>

=item * B<headlines_header>

=item * B<links>

=item * B<links_header>

=back

=head1 ENTRY ACCESSORS

=over 4

=item * B<about>

=item * B<changes>

=item * B<full>

=item * B<license>

=item * B<name>

=item * B<name_and_version>

=item * B<position>

=item * B<posted_by_name>

=item * B<posted_by_url>

=item * B<posted_on>

=item * B<trove>

=item * B<url>

=item * B<version>

=back

=head1 ARTICLE ACCESSORS

=over 4

=item * B<description>

=item * B<full>

=item * B<posted_by_name>

=item * B<posted_by_url>

=item * B<posted_on>

=item * B<section>

=item * B<title>

=item * B<url>

=back

=head1 AUTHORS

=item Adam J. Foxson B<afoxson@pobox.com>, 2002-

=item Adam Spiers B<adam@spiers.net>, 1999-2000

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

This is release 1.20.

=head1 SEE ALSO

perl(1).

=cut
