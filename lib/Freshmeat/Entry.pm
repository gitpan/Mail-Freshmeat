# $Revision: 1.16 $
# $Id: Entry.pm,v 1.16 2002/07/22 08:35:43 afoxson Exp $

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

($VERSION) = '$Revision: 1.16 $' =~ /\s+(\d+\.\d+)\s+/;

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
			_position _name_and_version _name _version _posted_by_name
			_posted_by_url _posted_on _trove _about _changes _license _url
		)
	];

	# these are the allowed entry accessors
	$self->{_is_attr} = {map {$_ => 1} @{$self->{_attrs}}, '_full'};
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
		^ (\s* .* \)) \s* by\s(.*) \s \((.*)\) $ \n
		^ \s* ( \w+ , \s \w+ \s \d{1,2} \w{2} \s \d{4} \s \d{2}:\d{2} ) $ \n

		(?: 
			$_blank_line
			(?s: (?:Category:\s|Categories:\s)? (.+?) \n )
		)?
		$_blank_line
		(?s: About:\s (.+?) \n )
		(?: 
			$_blank_line
			(?s: Changes:\s (.+?) \n )
		)?
		$_blank_line
		^ \s* License:\s (.*) $ \n
		$_blank_line
		^ \s* URL:\s (.*) $
	/mx)
	{
		$self->{_position}         = $1;
		$self->{_name_and_version} = $2 . $3;
		$self->{_posted_by_name}   = $4;
		$self->{_posted_by_url}    = $5;
		$self->{_posted_on}        = $6;
		$self->{_trove}            = $7;
		$self->{_about}            = $8;
		$self->{_changes}          = $9;
		$self->{_license}          = $10;
		$self->{_url}              = $11;
		$self->{_full}             = $entry;
	}
	elsif ($entry =~
	/
		^ \s* \[(\d+)\] \s-\s (.*) $ \n
		^ \s* by\s(.*) \s \((.*)\) $ \n
		^ \s* ( \w+ , \s \w+ \s \d{1,2} \w{2} \s \d{4} \s \d{2}:\d{2} ) $ \n

		(?: 
			$_blank_line
			(?s: (?:Category:\s|Categories:\s)? (.+?) \n )
		)?
		$_blank_line
		(?s: About:\s (.+?) \n )
		(?: 
			$_blank_line
			(?s: Changes:\s (.+?) \n )
		)?
		$_blank_line
		^ \s* License:\s (.*) $ \n
		$_blank_line
		^ \s* URL:\s (.*) $
	/mx)
	{
		$self->{_position}         = $1;
		$self->{_name_and_version} = $2;
		$self->{_posted_by_name}   = $3;
		$self->{_posted_by_url}    = $4;
		$self->{_posted_on}        = $5;
		$self->{_trove}            = $6;
		$self->{_about}            = $7;
		$self->{_changes}          = $8;
		$self->{_license}          = $9;
		$self->{_url}              = $10;
		$self->{_full}             = $entry;
	}
	elsif ($entry =~
	/
		^ \s* \[(\d+)\] \s-\s (.*) $ \n
		^ \s* by\s(.*) $ \n
		^ (\s* .*) $ \n
		^ \s* ( \w+ , \s \w+ \s \d{1,2} \w{2} \s \d{4} \s \d{2}:\d{2} ) $ \n

		(?: 
			$_blank_line
			(?s: (?:Category:\s|Categories:\s)? (.+?) \n )
		)?
		$_blank_line
		(?s: About:\s (.+?) \n )
		(?: 
			$_blank_line
			(?s: Changes:\s (.+?) \n )
		)?
		$_blank_line
		^ \s* License:\s (.*) $ \n
		$_blank_line
		^ \s* URL:\s (.*) $
	/mx)
	{
		$self->{_position}         = $1;
		$self->{_name_and_version} = $2;
		$self->{_posted_by_name}   = $3 . $4;
		$self->{_posted_on}        = $5;
		$self->{_trove}            = $6;
		$self->{_about}            = $7;
		$self->{_changes}          = $8;
		$self->{_license}          = $9;
		$self->{_url}              = $10;
		$self->{_full}             = $entry;

		($self->{_posted_by_name}, $self->{_posted_by_url}) =
			$self->{_posted_by_name} =~ /(.*) \s \((.*)\)/;
	}
	else
	{
		_fatal_bug("Couldn't parse entry $count (entries).");
	}

	@$self{qw/_name _version/} =
		$self->_parse_entry_version($self);

	for my $key (keys %$self)
	{
		$self->{$key} = '' if not defined $self->{$key};
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
	my $self = shift;

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

	my ($name, $version) = ($self->{_name_and_version}, '');

	if ($self->{_name_and_version} =~
	/^  
		(.+?)
		\s+
		(
			$version_first_word_start
			$version_rest_of_word
			(?: 
				\s+
				$version_other_words_start
				$version_rest_of_word
			)*
		)
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
	unless ($self->{_is_attr}->{"_$method"})
	{
		croak "No such entry accessor entry: $method; aborting";
	}

	my $code = q
	{
		sub
		{   
			my $self = shift;
			return $self->{_METHOD};
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
