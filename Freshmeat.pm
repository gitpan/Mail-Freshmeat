# Mail::Freshmeat.pm --
# Perl module for parsing daily newsletters from http://freshmeat.net/
# (derived from the Mail::Internet class)
#
# Copyright (c) 1999 Adam Spiers <adam@spiers.net>. All rights
# reserved. This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# $Id: Freshmeat.pm,v 1.15 2000/03/12 18:56:58 adam Exp $
#

package Mail::Freshmeat;

use strict;
BEGIN { require 5.005; }

require AutoLoader;
use Mail::Internet;
use Carp;

use vars qw($VERSION @ISA);
@ISA = qw(Mail::Internet AutoLoader);
$VERSION = '0.93';

=head1 NAME

Mail::Freshmeat - class for parsing e-mail newsletters from freshmeat.net

=head1 SYNOPSIS

    $newsletter = new Mail::Freshmeat( \*STDIN );
    $newsletter->parse;

    foreach my $entry (@{$newsletter->entries}) {

      print "Name: $entry->{name}";
      print "Version: $entry->{version};
      ...

      # Get an entry line as if it was from the first list
      # in the newsletter
      print $newsletter->short_entry($entry), "\n";

    }


=head1 DESCRIPTION

A subclass of B<Mail::Internet>.

This package provides parsing of the daily e-mail newsletters which
are sent out from F<http://freshmeat.net/> to any individual who
requests them.

=head1 METHODS

=over 4

=item * B<parse>

    $newsletter->parse;

This method must be called before any accessors can be used.

=cut

sub parse {
  my $self = shift;

  my $clean_parse = 1;

  my $body = join '', @{ $self->body };

  my $blank_line  = qr/ ^ \s * $ \n            /x;
  my $blank_lines = qr/ (?: $blank_line )*     /x;
  my $divider     = qr/ ^ \s* [-\s]{10,} \s* $ /x;

  $body =~ m!
             (^This\ is\ the\ official\ freshmeat\ newsletter\ 
               for\ (.+?)\.
               (?s: .+)
               total,\ (\d+)\ articles\ have\ been\ posted\ and\ 
               are\ included\ in\ this\ email\.) \s* $ \n
             $blank_lines
        (?:
           (
             ^ \s* \[\ advertising\ \] \s* $ \n
             $blank_lines
           )
             ((?s:.+?))
             $blank_lines
        )?
           (
             ^ \s* \[\ article\ list\ \] \s* $ \n
             $blank_lines
           )
             ((?: ^o\ .* $ \n)+)
             $blank_lines
           (
             ^ \s* \[\ article\ details\ \] \s* $ \n
             $blank_lines
           )
             ((?s:.+?))
             $blank_lines
             $divider
             $blank_lines
             (^ that's\ it\ for\ today (?s: .*) ) $
            !mx
    or _fatal_bug("Couldn't parse newsletter structure.");

  $self->{fm_summary}        = $1;
  $self->{fm_date}           = $2;
  $self->{fm_total}          = $3;
  $self->{fm_ad_header}      = $4;
  $self->{fm_ad}             = $5;
  $self->{fm_list_header}    = $6;
  $self->{fm_list}           = $7;
  $self->{fm_details_header} = $8;
  $self->{fm_details}        = $9;
  $self->{fm_footer}         = $10;

  my @entries = ();
  my $count = 1;
  foreach my $entry (split /
                            $blank_line
                            $divider
                            $blank_line
                           /mx,
                           $self->{fm_details})
  {
    if ($entry !~ /
                   ^ \s* subject:   \s (.*) $ \n
                   ^ \s* added\ by: \s (.*) $ \n
               (?: ^ \s* license:   \s (.*) $ \n )?
                   ^ \s* category:  \s (.*) $ \n
          (?:  
                   $blank_line
               (?: ^ \s* homepage:  \s (.*) $ \n )?
               (?: ^ \s* download:  \s (.*) $ \n )?
               (?: ^ \s* changelog: \s (.*) $ \n )?
          )?
                   $blank_line
                   ^ (body|description) : \s* $ \n
                   (?s: (.+?) )
          (?: 
                   $blank_line
                   ^ changes: \s* $ \n
                   (?s: (.+?) )
          )?  
          (?: 
                   $blank_line
                   ^ urgency: \s* $ \n
                   (?s: (.+?) )
          )?
               (?: $blank_line )?
                   \|> \s (.+?) \s* $ \n
                  /mx)
    {
      my $entry_start = $entry;
      if ($entry_start =~ /^\s*(subject: .*)$/m) {
        $entry_start = $1;
      }
      else {
        $entry_start =~ s/\n/\\n/g;
        $entry_start = substr($entry_start, 0, 40);
      }
      
      warn "Couldn't parse entry beginning '$entry_start'; ignoring.\n";
      $clean_parse = 0;
      next;
    }

    # REMINDER: If you change the following keys, you must change
    # the entry_keys method and its documentation.
    my $new_entry = {
                     subject   => $1,
                     added_by  => $2,
                     license   => $3,
                     category  => $4,
                     homepage  => $5,
                     download  => $6,
                     changelog => $7,
                     body_type => $8,
                     body      => $9,
                     changes   => $10,
                     urgency   => $11,
                     url       => $12,
                    };

    # Start of first word of version must match this
    my $version_first_word_start
      = qr/
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
    my $version_other_words_start
      = qr/
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
    my $version_rest_of_word
      = qr/
                 (
                    [.\w()\/-]      |
                    pre             |
                    alpha           |
                    beta            |
                    patch           |
                    \d{1,6}(?!\d)       # not more than six digits
                                        # in a row (how silly am I?)
                 )*
          /ix;

    if ($new_entry->{category} ne 'Community' and
        $new_entry->{subject}
          =~ /^
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
      $new_entry->{name}    = $1;
      $new_entry->{version} = $2;
    }
    else {
      $new_entry->{name} = $new_entry->{subject};
    }

    $new_entry->{body} =~ s/\r$//mg;

    foreach my $key (keys %$new_entry) {
      delete $new_entry->{$key} unless $new_entry->{$key};
    }

    $new_entry->{position} = $count;

    push @entries, $new_entry;
    $count++;
  }

  # Bit of sanity checking never hurt anyone
  my $total_entries = @entries;
  if ($total_entries != $self->{fm_total}) {
    warn <<EOF;
Mismatch between total number of articles mentioned in summary ($self->{fm_total})
and actual number found ($total_entries).  Weird!  Will ignore number mentioned
in summary from now on ...
EOF
    $clean_parse = 0;
  }

  $self->{fm_entries} = \@entries;

  return ($self->{fm_parsed} = $clean_parse ? 'ok' : 'unclean');
}

=back

=cut

1;
########################    End of preloaded code    ########################
__END__


=head1 ACCESSORS

=over 4

=item * B<entry_keys>

    my @entry_keys = $newsletter->entry_keys;

Returns the keys which each entry may have set, in the order in which
they are encountered in the newsletter:

    - position
    - subject
    - name
    - version
    - added_by 
    - license 
    - category 
    - homepage 
    - download 
    - changelog 
    - body_type 
    - body 
    - changes 
    - urgency 
    - url

=cut

sub entry_keys {
  return qw/
            position
            subject
            name 
            version
            added_by 
            license 
            category 
            homepage 
            download 
            changelog 
            body_type 
            body 
            changes 
            urgency 
            url
           /;
}

##

my $do_parse_first_err
  = "You must call the parse() method on the object first";

##

=item * B<summary>

    $summary = $self->summary;

Returns the paragraph starting 'This is the official freshmeat
newsletter ...'.

=cut

sub summary {
  my $self = shift;

  croak $do_parse_first_err unless $self->{fm_parsed};

  return $self->{fm_summary};
}

##

=item * B<date>

    $date = $self->date;

Returns the date on which this newsletter was released.

=cut

sub date {
  my $self = shift;

  croak $do_parse_first_err unless $self->{fm_parsed};

  return $self->{fm_date};
}

##

=item * B<total>

    $total = $self->total;

Returns the total number of entries in the newsletter.

=cut

sub total {
  my $self = shift;

  croak $do_parse_first_err unless $self->{fm_parsed};

  return scalar(@{$self->{fm_entries}});
}

##

=item * B<entries>

Returns a reference to an array of hashes, each containing fully
parsed information about an entry of the newsletter.  The entries
are in the original newsletter order.

The keys of each hash will be a subset of the list returned by the
entry_keys method.

=cut

sub entries {
  my $self = shift;

  croak $do_parse_first_err unless $self->{fm_parsed};

  return $self->{fm_entries};
}

##

=item * B<advertisement>

    $ad = $self->advertisement;

Returns the '[ advertisement ]' section of the newsletter, which has
one entry per line.

=cut

sub advertisement {
  my $self = shift;

  croak $do_parse_first_err unless $self->{fm_parsed};

  return $self->{fm_ad};
}

##

=item * B<list>

    $list = $self->list;

Returns the '[ article list ]' section of the newsletter, which has
one entry per line.

=cut

sub list {
  my $self = shift;

  croak $do_parse_first_err unless $self->{fm_parsed};

  return $self->{fm_list};
}

##

=item * B<footer>

Returns the remainder of the newsletter following the '[ article details ]'
section.

=cut

sub footer {
  my $self = shift;

  croak $do_parse_first_err unless $self->{fm_parsed};

  return $self->{fm_footer};
}

##

=item * B<details>

Returns the '[ article details ]' sections of the newsletter, which
has each entry in full.

=cut

sub details {
  my $self = shift;

  croak $do_parse_first_err unless $self->{fm_parsed};

  return $self->{fm_details};
}

##

=item * B<short_entry>

    $list1 = $newsletter->list;
    $list2 = join '', map { 'o ' . $newsletter->short_entry($_) . "\n" }
                          @{$newsletter->entries};
    if ($list1 ne $list2) {
      die "Oh no!  Mail::Freshmeat doesn't do what it claims!";
    }

:-)

What, that's not real documentation?  Bah.  Alright then.  This method
returns the entry in exactly the same format as when it was one of the
lines beginning with 'o ' in the original newsletter, minus the actual
'o ' bit.  So, you can regenerate the entire '[ article list ]' section
(in a new order, if you want) using something similar to the example
above.

=cut

sub short_entry {
  my $self = shift;

  croak $do_parse_first_err unless $self->{fm_parsed};

  my $entry = shift;
  my ($name, $version, $category) = @$entry{qw/name version category/};
  $version ||= '';

  my $short = $name;
  $short .= " $version" if $version;
  $short .= " ($category)"
    if $category !~ /^(Community|Security|Documentation)$/
   and $name ne 'Linux';

  return $short;
}

##

=item * B<entry_header>

This method returns the entry's "header" (from the line starting
'subject:' to the line starting 'changelog:' (or to the line where
'changelog:' would have been if it was there)) in exactly the same
format (modulo whitespace) as when it was one of the entries in the
'[ article details ]' section of the original newsletter.

=cut

sub entry_header {
  my $self = shift;

  croak $do_parse_first_err unless $self->{fm_parsed};

  my $entry = shift;
  my %entry = map { $_ => ($entry->{$_} || '') } ($self->entry_keys);

  my $header = <<EOF;
  subject: $entry{subject}
 added by: $entry{added_by}
  license: $entry{license}
 category: $entry{category}

 homepage: $entry{homepage}
 download: $entry{download}
changelog: $entry{changelog}

EOF

  $header =~ s/^ .+? :\  $ \n //gmx;

  return $header;
}

##

=item * B<entry_body>

This method returns the entry's "body" -- everything following the
entry's "header" as returned by C<entry_header>.

=cut

sub entry_body {
  my $self = shift;

  croak $do_parse_first_err unless $self->{fm_parsed};

  my $entry = shift;
  my %entry = map { $_ => ($entry->{$_} || '') } ($self->entry_keys);

  chop @entry{qw/body changes urgency/};

  my $body .= <<EOF;
$entry{body_type}:
$entry{body}
EOF

  $body .= <<EOF if $entry{changes};

changes:
$entry{changes}
EOF

  $body .= <<EOF if $entry{urgency};

urgency:
$entry{urgency}
EOF

  $body .= <<EOF if $entry{url};

|> $entry{url}
EOF

  return $body;
}

##

=item * B<long_entry> 

    $list1 = $newsletter->details;
    $list2 = join $newsletter->divider,
                  map { $newsletter->long_entry($_) }
                      @{$newsletter->entries};

    # $list1 and $list2 should now be identical(ish) modulo whitespace

This method returns the entry in exactly the same format (modulo
whitespace differences) as when it was one of the entries in the
'[ article details ]' section of the original newsletter.  So, you can
regenerate that entire section (in a new order, if you want) using
something similar to the example above.

All this method actually does is concatenate the results of the
C<entry_header> and C<entry_body> methods.

=cut

sub long_entry {
  my $self = shift;

  my $entry = shift;

  croak $do_parse_first_err unless $self->{fm_parsed};

  my $long = $self->entry_header($entry) . $self->entry_body($entry);

  return $long;
}

##

=item * B<divider>

    print $newsletter->divider;

Returns one of those fancy 

  '--- - --- ------ - --- -- - - - -- -'

dividers.

=cut

sub divider {
  return "\n          --- - --- ------ - --- -- - - - -- -\n\n";
}

##

=item * B<ad_header>

    print $newsletter->ad_header;

Returns the text for starting the advertisement section.

=cut

sub ad_header {
  my $self = shift;

  return $self->{fm_ad_header};
}

##

=item * B<list_header>

    print $newsletter->list_header;

Returns the text for starting the article list section.

=cut

sub list_header {
  my $self = shift;

  return $self->{fm_list_header};
}

##

=item * B<details_header>

    print $newsletter->details_header;

Returns the text for starting the article details section.

=cut

sub details_header {
  my $self = shift;
  
  return $self->{fm_details_header};
}

##

=back

=cut

sub _fatal_bug {
  my $error = <<'EOF';

Please contact the author of Mail::Freshmeat at <adam@spiers.net>
if you believe that the module has failed to parse a genuine freshmeat
newsletter.

The above error occurred
EOF

  chop $error;

  croak +(join '', @_) . "\n" . $error;
}


=head1 AUTHOR

Adam Spiers <adam@spiers.net>

=head1 LICENSE

All rights reserved.  This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 VERSION

This is release 0.91.

=head1 SEE ALSO

perl(1).

=cut

