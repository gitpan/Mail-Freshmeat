# $Revision: 1.14 $
# $Id: Entry.pm,v 1.14 2002/07/21 03:27:16 afoxson Exp $

# Mail::Freshmeat::Entry - parses entries from freshmeat daily newsletters
# Copyright (c) 2002 Adam J. Foxson. All rights reserved.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

package Mail::Freshmeat::Entry;

use strict;
use 5.005;
use Carp;
use vars qw($VERSION $AUTOLOAD);
use Mail::Freshmeat::Utils;

local $^W;

($VERSION) = '$Revision: 1.14 $' =~ /\s+(\d+\.\d+)\s+/;

sub new
{
	my $type  = shift;
	my $entry = shift or croak "I need to be passed an entry.";
	my $count = shift or croak "I need to be passed a count.";
	my $class = ref($type) || $type;
	my $self  = bless {}, $class;

	$self->{_attrs} =
	[
		qw
		(
			position name_and_version name version posted_by posted_on
			trove about changes license url
		)
	];

	# these are the allowed entry accessors
	$self->{_is_attr} = {map {$_ => 1} @{$self->{_attrs}}, 'full'};
	$self->_parse($entry, $count);

	return $self;
}

sub entry_keys
{
	my $self = shift;
	wantarray ? @{$self->{_attrs}} : $self->{_attrs};
}

sub _parse
{
	my $self  = shift;
	my $entry = shift or croak "I need to be passed an entry.";
	my $count = shift or croak "I need to be passed a count.";
	my @entries;

	if ($entry =~
	/
		^ \s* \[(\d+)\] \s-\s (.*) $ \n
		^ (\s* .* \)) \s* by\s(.*) $ \n
		^ \s* (.*) $ \n

		(?: 
			$blank_line
			(?s: (?:Category:\s|Categories:\s)? (.+?) \n )
		)?
		$blank_line
		(?s: About:\s (.+?) \n )
		(?: 
			$blank_line
			(?s: Changes:\s (.+?) \n )
		)?
		$blank_line
		^ \s* License:\s (.*) $ \n
		$blank_line
		^ \s* URL:\s (.*) $
	/mx)
	{
		$self->{position}         = $1;
		$self->{name_and_version} = $2 . $3;
		$self->{posted_by}        = $4;
		$self->{posted_on}        = $5;
		$self->{trove}            = $6;
		$self->{about}            = $7;
		$self->{changes}          = $8;
		$self->{license}          = $9;
		$self->{url}              = $10;
		$self->{full}             = $entry;
	}
	elsif ($entry =~
	/
		^ \s* \[(\d+)\] \s-\s (.*) $ \n
		^ \s* by\s(.*) $ \n
		^ \s* (.*) $ \n

		(?: 
			$blank_line
			(?s: (?:Category:\s|Categories:\s)? (.+?) \n )
		)?
		$blank_line
		(?s: About:\s (.+?) \n )
		(?: 
			$blank_line
			(?s: Changes:\s (.+?) \n )
		)?
		$blank_line
		^ \s* License:\s (.*) $ \n
		$blank_line
		^ \s* URL:\s (.*) $
	/mx)
	{
		$self->{position}         = $1;
		$self->{name_and_version} = $2;
		$self->{posted_by}        = $3;
		$self->{posted_on}        = $4;
		$self->{trove}            = $5;
		$self->{about}            = $6;
		$self->{changes}          = $7;
		$self->{license}          = $8;
		$self->{url}              = $9;
		$self->{full}             = $entry;
	}
	elsif ($entry =~
	/
		^ \s* \[(\d+)\] \s-\s (.*) $ \n
		^ \s* by\s(.*) $ \n
		^ (\s* .*) $ \n
		^ \s* (.*) $ \n

		(?: 
			$blank_line
			(?s: (?:Category:\s|Categories:\s)? (.+?) \n )
		)?
		$blank_line
		(?s: About:\s (.+?) \n )
		(?: 
			$blank_line
			(?s: Changes:\s (.+?) \n )
		)?
		$blank_line
		^ \s* License:\s (.*) $ \n
		$blank_line
		^ \s* URL:\s (.*) $
	/mx)
	{
		$self->{position}         = $1;
		$self->{name_and_version} = $2;
		$self->{posted_by}        = $3 . $4;
		$self->{posted_on}        = $5;
		$self->{trove}            = $6;
		$self->{about}            = $7;
		$self->{changes}          = $8;
		$self->{license}          = $9;
		$self->{url}              = $10;
		$self->{full}             = $entry;
	}
	else
	{
		_fatal_bug("Couldn't parse entry $count (entries).");
	}

	@$self{qw/name version/} =
		$self->_parse_entry_version($self);

	for my $key (keys %$self)
	{   
		if (not defined $self->{$key} or not $self->{$key})
		{
			$self->{$key} = 'Not specified';
		}
	}

	if ($self->position() != $count)
	{   
		_fatal_bug("Detcted an entry with an incorrect position " .
			"(${\($self->position())}/$count).");
	}

	return $self;
}

# TODO: One day this will probably be have to be re-written. As it is now
# it parses the very vast majority name-version's successfully, but I'd
# like to get it to 100%
sub _parse_entry_version
{
	my ($self, $entry) = @_;

	# Start of first word of version must match this
	my $version_first_word_start = qr
	/   
		(   
			[.\d]           |
			pre             |
			alpha           |
			beta            |
			patch           |
			r               |
			rel             |
			release         |
			build           |
			v(?:er)? [^a-z]
		)
	/ix;

	# Start of further words of version must match this
	my $version_other_words_start = qr
	/   
		(   
			[.\d(]          |
			pre             |
			alpha           |
			beta            |
			r               |
			rel             |
			release         |
			build           |
			patch
		)
	/ix;

	# Rest of each word of version must match this
	my $version_rest_of_word = qr
	/   
		(   
			[.\w()\/-]      |
			pre             |
			alpha           |
			beta            |
			patch           |
			\d{1,6}(?!\d)       # not more than six digits
								# in a row
		)*
	/ix;

	my ($name, $version) = ($entry->{name_and_version}, '');

	if ($entry->{name_and_version} =~
	/^  
		(.+?)                       # save name in $1
		\s+
		(                           # save version in $2
			$version_first_word_start
			$version_rest_of_word
			(?: 
				\s+
				$version_other_words_start
				$version_rest_of_word
			)*
		)                           # end saving $2
	$/ix)
	{   
		$name    = $1;
		$version = $2;
	}

	return ($name, $version);
}

sub short_entry
{
	my $self = shift;

	return $self->position(), " - ", $self->name_and_version();
}   

sub AUTOLOAD
{
	my $self = $_[0];
	my ($package, $method) = ($AUTOLOAD =~ /(.*)::(.*)/);

	return if $method =~ /^DESTROY$/;
	unless ($self->{_is_attr}->{$method})
	{
		croak "No such accessor entry: $method; aborting";
	}

	my $code = q
	{
		sub
		{   
			my $self = shift;
			return $self->{METHOD};
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
