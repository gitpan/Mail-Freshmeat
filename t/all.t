#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 20 }

use Mail::Freshmeat;


my @newsletter = ();


unless (open(LETTER1, 't/sample.newsletter.1')) {
  die "Failed to open sample.newsletter.1: $!\n";
}
print "Testing new() constructor ...\n";
$newsletter[0] = new Mail::Freshmeat(\*LETTER1);
ok($newsletter[0] ? 1 : 0);
close(LETTER1);


unless (open(LETTER2, 't/sample.newsletter.2')) {
  die "Failed to open sample.newsletter.2: $!\n";
}
print "Testing new() constructor ...\n";
$newsletter[1] = new Mail::Freshmeat(\*LETTER2);
ok($newsletter[1] ? 1 : 0);
close(LETTER2);


print "Attempting to parse() ...\n";
ok($newsletter[0]->parse, 'ok');
ok($newsletter[1]->parse, 'ok');

my $summary = <<EOF;
This is the official freshmeat newsletter for Sunday, August 01st. In
total, 122 articles have been posted and are included in this email.
EOF
chop $summary;

print "Checking summary() ...\n";
ok($newsletter[0]->summary, $summary);

print "Checking date() ...\n";
ok($newsletter[0]->date,  'Sunday, August 01st');

print "Checking total() ...\n";
ok($newsletter[0]->total, 122);

my ($ad_header, $advertisement) = (<<EOF, <<EOF);
  [ advertising ]

EOF
Vstore.com lets you open your own FREE online store:
- Choose from over one million products to sell
- Build repeat business-when customers buy, they buy from you
- Earn up to 25% of each sale in commissions -- Open your store today!

http://adcenter.in2.com/cgi-bin/click.cgi?tid=24510&cid=vstore-andover_1-0x0&hid+=andover
EOF

print "Checking advertisement() and ad_header() ...\n";

ok(! $newsletter[0]->ad_header);
ok(! $newsletter[0]->advertisement);
ok($newsletter[1]->ad_header, $ad_header);
ok($newsletter[1]->advertisement, $advertisement);


my $slist1 = <<EOF;
o DizzyICQ 0.14b (Console/Communication)
o KDevelop 1.0 Beta1 (KDE/Development)
o tpctl 0.6.1 (Console/Administration)
o TWIG 1.0.3 (Web/Applications)
o FreeAmp 1.3.0 (Console/MP3)
o Gqcam 0.4 (X11/Graphics)
o libgcj 2.95 (Development/Java Packages)
o Etherboot 4.2.5 (Console/Networking)
o The Small Side of Unix
o GNU make 3.77.92 (Development/Tools)
o The N.U.E. Order 0.0.4 (Web/Online Shopping)
o GNU xhippo 1.1 (X11/Sound)
o Yacas 1.0.7 (Console/Scientific Applications)
o Zebra 0.75 (Daemons/Misc)
o Modeline 0.5.1 (Console/Video)
o FreeWorld BBS 0.2.2 (Daemons/BBS)
o textutils 1.22p (Console/Utilities)
o X-Mame 0.36b1.2 (X11/Emulators)
o Epeios 19990801 (Development/Libraries)
o Rael's Binary Grabber 1.2.1 (Console/News)
o Getleft 0.5.3 (Web/Tools)
o code2html 0.7.0 (Web/Tools)
o ripit 1.5 (Console/MP3)
o Sentinel 1.1.7c (Console/Firewall and Security)
o CDRDAO 1.1.2 (Console/CD Writing Software)
o MyGuestbook 0.8.1 (Web/Applications)
o Oracle Procedit 1.0 (X11/Database)
o poll (Console/Communication)
o asmutils 0.04 (Console/Utilities)
o fryit 0.3.1 (X11/CD Writing Software)
o sfspatch 2.2.10 (Console/Filesystems)
o gbeta 0.8 (Development/Compilers)
o Ted 2.5 (X11/Office Applications)
o Bnetd 0.4.15.1 (Daemons/Misc)
o logcoloriser 1.0.0 (Console/Log Analyzers)
o bzip2 0.9.5b (Console/Compression Utilities)
o wcII-grab 0.1.1 (X11/TV and Video)
o PHP ircd 0.4 (Daemons/IRC)
o XQF 0.9.0 (X11/Games)
o gcc 2.95 (Development/Compilers)
o TARA 2.2.6 (Console/Firewall and Security)
o DizzyICQ 0.13b (Console/Communication)
o SARA 2.0.6 (X11/Firewall and Security)
o Debian: New samba packages available
o Red Hat: New Samba packages available
o Red Hat: misuse of squid cachemgr.cgi
o xcheckers 1.2 (X11/Games)
o curl 5.9.1 (Console/Utilities)
o Aglets Open Source Petition
o I-Docs
o Everything Linux adds News Portal w/Search
o Cosource website goes to live beta
o Lithium 0.3.1 (X11/Administration)
o BladeEnc 0.82 (Console/MP3)
o Euphoria 2.01 pre alpha 4 (Development/Languages)
o Libgraph 0.0.1 (Development/Libraries)
o Libra 0.1.0 (Development/Libraries)
o Energymech 2.6.1.1 (Console/IRC)
o GameStalker Linux 1.04 (X11/Games)
o Galway 0.17 (Web/Tools)
o Qvwm 1.1 (X11/Window Managers)
o HuggieTag 0.8.6 (Console/eMail)
o sh-utils 1.22l (Console/Utilities)
o ScryMUD 2.0.0 (Daemons/MUD)
o TSambaClass 1.0 (Development/Libraries)
o glFtpD 1.16.9 (Daemons/FTP)
o TiMidity++ 2.3.0 (X11/Sound)
o privtool 0.90 Beta GT010 (X11/eMail)
o GSokoban 0.60 (GNOME/Games)
o KBiff 2.3.10 (KDE/Networking)
o XQF 0.9 (X11/Games)
o CDPlayer.app 1.3 (X11/Sound)
o typespeed 0.3.5 (Console/Games)
o vsa 0.9 (GNOME/Sound)
o CompuPic 4.6 build 1009 (X11/Graphics)
o AfterStep 1.7.126 (X11/Window Managers)
o lsof 4.45 (Console/Utilities)
o Mailman 1.0 (Daemons/Mailinglist Managers)
o XRacer 0.82 (X11/Games)
o TT-News 0.2.4 (X11/News)
o MySQLShopper 0.03d (Web/Online Shopping)
o PerlSETI 0.5p2 (Console/Scientific Applications)
o ext2resize 1.0.4 (Console/Filesystems)
o GtkShadow 0.1.1 (Web/Tools)
o Linuxconf 1.16r1.4 (Console/Administration)
o Genpage 1.0.5 (Web/Pre-Processors)
o ToyPlaneFDTD 0.1 (Console/Scientific Applications)
o Carillon 1.0 (Development/Debugging)
o ibs 0.3.3 (Console/Backup)
o Edcom Pre1.3 (Web/Applications)
o Multi-vendor UPS Monitoring Project 0.41.2 (Console/Monitoring)
o MultiMail 0.28 (Console/Communication)
o ProcEdit 1.0 (X11/Database)
o units 1.55 (Console/Utilities)
o Lynx 2.8.3.dev5 (Console/Web Browsers)
o netcomics 0.9 (Web/Tools)
o 4inarow 0.24 (Console/Games)
o vpnd 1.0.8 (Console/Firewall and Security)
o gsmlib 0.1 (Development/Libraries)
o X-Chat 1.1.6 (X11/IRC)
o demcd 2.0.5 (Console/Sound)
o mod_frontpage 1.3.6-3.0.4.3-4.0 (Daemons/HTTP)
o si 0.3 (Console/System)
o Rasca 1.2.2 (X11/MP3)
o GRE 0.2 (X11/Editors)
o Pan 0.4.0 (X11/News)
o pvmsync 0.41 (Development/Libraries)
o CapsiChat 0.19++ (Daemons/IRC)
o Screen Under X 0.1 (Console/Utilities)
o GNotes! 1.64 (GNOME/Core)
o miniCHESS 0.6 (X11/Games)
o Common UNIX Printing System 1.0b6 (Console/Printing)
o sarep 0.31 (Console/Editors)
o X-Tract Build 244 (Web/Tools)
o RRDtool 1.0.3 (Console/Networking)
o Tac 0.15 (Console/Communication)
o Gzilla 0.2.1 (X11/Web Browsers)
o WinMGM 2.0 (X11/Scientific Applications)
o dbMetrix 0.1.8 (X11/Database)
o GTKtalog 0.03 (X11/Utilities)
o xrio a0.02 (X11/MP3)
o phpAds 1.0.0 (Web/Applications)
EOF

print "Checking list() ...\n";
my $slist2 = $newsletter[0]->list;
ok($slist2, $slist1);

print "Checking entries() ...\n";

ok($newsletter[0]->entries->[1]{name}, 'KDevelop');

ok($newsletter[0]->entries->[16]{version}, '1.22p');
ok($newsletter[0]->entries->[17]{version}, '0.36b1.2');
ok($newsletter[0]->entries->[18]{version}, '19990801');
ok($newsletter[0]->entries->[74]{version}, '4.6 build 1009');

ok($newsletter[0]->entries->[74]{category}, 'X11/Graphics');

print "Checking short_entry() ...\n";

my $slist3 = 
  join '', map { 'o ' . $newsletter[0]->short_entry($_) . "\n" }
               @{$newsletter[0]->entries};

ok($slist3, $slist1);

print "Checking long_entry() ...\n";

my $llist1 = $newsletter[0]->details;
my $llist2 = join $newsletter[0]->divider,
                  map { $newsletter[0]->long_entry($_) }
                      @{$newsletter[0]->entries};

# There must be a quicker way to do this
$llist1 =~ s/[ \t]+/ /g;
$llist2 =~ s/[ \t]+/ /g;
$llist1 =~ s/\r$//gm;
$llist2 =~ s/\r$//gm;
$llist1 =~ s/^[\s*\n]+/\n/gms;
$llist2 =~ s/^[\s*\n]+/\n/gms;

ok($llist1, $llist2);

