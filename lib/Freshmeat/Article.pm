# $Revision: 1.2 $
# $Id: Article.pm,v 1.2 2002/07/22 08:35:43 afoxson Exp $

# Mail::Freshmeat::Article - parses articles from freshmeat daily newsletters
# Copyright (c) 2002 Adam J. Foxson. All rights reserved.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

package Mail::Freshmeat::Article;

use strict;
use 5.005;
use Carp;
use vars qw($VERSION $AUTOLOAD);
use Mail::Freshmeat::Utils;

local $^W;

($VERSION) = '$Revision: 1.2 $' =~ /\s+(\d+\.\d+)\s+/;

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
			_title _posted_by_name _posted_by_url _posted_on _section
			_description _url
		)
	];

	# these are the allowed entry accessors
	$self->{_is_attr} = {map {$_ => 1} @{$self->{_attrs}}, '_full'};
	$self->_parse($entry, $count);

	return $self;
}

sub article_keys
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
	m/
		^ \s* (.*) $ \n
		^ \s* by \s (.*) \s \((.*)\) $ \n
		^ \s* Section: \s (.*) $ \n
		^ \s* (.*) $ \n
		$_blank_line
		(?s: (.+?) \n )
		$_blank_line
		^ \s* URL:\s (.*) $
	/mx)
	{
		$self->{_title}          = $1;
		$self->{_posted_by_name} = $2;
		$self->{_posted_by_url}  = $3;
		$self->{_section}        = $4;
		$self->{_posted_on}      = $5;
		$self->{_description}    = $6;
		$self->{_url}            = $7;
		$self->{_full}           = $entry;
	}
	else
	{
		_fatal_bug("Couldn't parse article $count (articles).");
	}

	for my $key (keys %$self)
	{
		$self->{$key} = '' if not defined $self->{$key};
	}

	return $self;
}

sub AUTOLOAD
{
	my $self = $_[0];
	my ($package, $method) = ($AUTOLOAD =~ /(.*)::(.*)/);

	return if $method =~ /^DESTROY$/;
	unless ($self->{_is_attr}->{"_$method"})
	{
		croak "No such article accessor entry: $method; aborting";
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
