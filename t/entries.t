#!/usr/bin/perl -w

use strict;
use Test;
use Mail::Freshmeat;

BEGIN { plan tests => 27 }

open LETTER, "t/sample.entries" or die $!;
my $newsletter = Mail::Freshmeat->new(\*LETTER);
close LETTER or die $!;

ok(ref $newsletter, 'Mail::Freshmeat');
ok($newsletter->links_header(), '::: L I N K S   F O R   T H E   D A Y :::');
chomp(my $links = <<EOF);
Today's news on the web: http://freshmeat.net/daily/2002/02/01/
freshmeat.net newsgroup: news://news.freshmeat.net/fm.announce
EOF
ok($newsletter->links(), $links);
# '
ok($newsletter->ad_header(), '::: A D V E R T I S I N G :::');
chomp(my $ad = <<EOF);
Sponsored by Thawte

FREE SSL Guide from Thawte   Are you planning your Web Server Security?
Click  here to get a FREE Thawte SSL guide and find the answers to all your
 SSL security issues.      

http://www.thawte.com/ucgi/gothawte.cgi?a=n173875740071000
EOF
ok($newsletter->ad(), $ad);
ok($newsletter->headlines_header(), '::: R E L E A S E   H E A D L I N E S (85) :::');
my $headlines = <<EOF;
[001] - arch 1.0pre3 (Release)
[002] - AuthToken 1.01
[003] - Auto Control Pro 2.1
[004] - b. 1.3.0
[005] - BeatForce 0.0.8-ALPHA
[006] - Blitzed Open Proxy Monitor 1.1r2 (Stable)
[007] - BSD ex/vi 01/26/02
[008] - bzip2 1.0.2
[009] - centericq 4.5.1
[010] - CrisoftRicette 0.1
[011] - Current 0.9.4 "Brown Paper Bag" (Stable)
[012] - dataMiner 0.9.0
[013] - DNSMan 0.66
[014] - E-CELL Simulation Environment 3.0.0-alpha2 (Development)
[015] - EC 1.9
[016] - EJBCA 1.2 (Development)
[017] - eXtensible Data Format 017-stable1 (Stable)
[018] - FreeTTS 1.1
[019] - FreeVMS 0.0.7 (Unstable kernel)
[020] - ftp-utils 1.0pre3 (Release)
[021] - FUDform 1.1.1
[022] - Ganglia Cluster Toolkit 2.0.3 (Monitoring core)
[023] - gettext 0.11
[024] - GKrellKam 0.3.3
[025] - GNU shtool 1.6.0
[026] - GraphThing 20020202 (Development)
[027] - GtkDiskFree 1.6.6 (Stable)
[028] - harvest 1.7.16
[029] - Hashish Beta 1 (Stable)
[030] - HDK Time Tracker 1.2
[031] - ht://Dig 3.1.6 (Stable)
[032] - HTML::Template 2.5
[033] - HTTrack Website Copier 3.15
[034] - ICMP Shell 0.2 (Stable)
[035] - IPFC 1.0.3 (Release)
[036] - IPTables Perl eXpander 2.0
[037] - Java SOS 2.71
[038] - JBossMX 1.0 Alpha 1 (Development)
[039] - Jitac 0.2.0
[040] - jpegextractor 1.0
[041] - kio-mac 0.8
[042] - kludge3d 2002-2-1
[043] - LibCGI 0.7.1 (Stable)
[044] - LocalSQL 0.0.4
[045] - Lyric Display System 0.16
[046] - Magma 1.0pre1 (Pre Release)
[047] - MakeNG: The Superior Build System 1.8 (Stable)
[048] - mod_ssl 2.8.6-1.3.23
[049] - monit 2.2.1
[050] - Monkey HTTP Daemon 0.2.6 (Development)
[051] - motor 3.2.0
[052] - my own diary 1.4 (Stable)
[053] - Netjuke 1.0b8 (Application)
[054] - nInvaders 0.0.3
[055] - OdeiaVir 0.4.3 (Development)
[056] - ol'bookmarks manager 0.5.3 (Stable)
[057] - OpenAFS 1.2.3
[058] - Organon 0.5.1 (Stable)
[059] - Pan 0.11.1.94
[060] - PLplot 5.1.0 (Stable)
[061] - Project Labrador 0.5
[062] - ProMA 0.6
[063] - PT 0.1.0
[064] - pygame 1.4
[065] - ReqTools 0.1.1
[066] - Secure FTP Wrapper 2.0 PR 2
[067] - Securepoint Firewall and VPN Server 2.0.6
[068] - Siege 2.50 (Stable)
[069] - SILC 0.7.5 (Client)
[070] - Single System Image Clusters for Linux 0.6.0 (Development)
[071] - Sitenews 0.10 (Beta)
[072] - TAcHash 0.2
[073] - taglog 0.1.30
[074] - Tcl/Tk Project Manager 0.1.3
[075] - Tilde 0.4.0 (Stable)
[076] - Tilde pre0.5.0 (Development)
[077] - TM4J 0.6.0 beta 1 (Development)
[078] - UDS Collection 1.0.2
[079] - Vstr string library 0.7.2
[080] - web2ldap 0.10.0
[081] - WebGUI 3.1.0
[082] - WebUMake Instant Helper 1.0
[083] - Wlan FE 1.0.0 (Stable)
[084] - Xpdf 1.00
[085] - Zaval Database Front-end 1.1.0 (Stable)
EOF
chomp $headlines;
ok($newsletter->headlines(), $headlines);
# '
ok($newsletter->entries_header(), '::: R E L E A S E   D E T A I L S :::');
my $footer = <<'EOF';
The freshmeat daily newsletter
To unsubscribe, send email to freshmeat-news-request@lists.freshmeat.net
or visit http://lists.freshmeat.net/mailman/listinfo/freshmeat-news

EOF
chomp $footer;
chomp $footer;
ok($newsletter->footer(), $footer);
ok($newsletter->entries_total(), 85);
ok($newsletter->date(), '2002/02/01');
ok(ref $newsletter->entries(), 'ARRAY');

my $ent;
my $count = 1;
for my $entry ($newsletter->entries())
{
	$ent = $entry if $count++ == 1;
}

ok($count, 86);
ok($ent->short_entry(), 'arch 1.0pre3 (Release)');
my $entry_keys = join '', $ent->entry_keys();
ok($entry_keys, '_position_name_and_version_name_version_posted_by_name_posted_by_url_posted_on_trove_about_changes_license_url');
ok($ent->position(), '001');
ok($ent->name_and_version(), 'arch 1.0pre3 (Release)');
ok($ent->posted_by_name(), 'T Lord');
ok($ent->posted_by_url(), 'http://freshmeat.net/users/tlord/');
ok($ent->posted_on(), 'Friday, February 1st 2002 02:00');
ok($ent->trove(), 'Software Development :: Version Control');
my $about = <<EOF;
arch is a revision control system with features that are ideal for
free software and open source projects characterized by widely distributed
development, concurrent support of multiple releases, and substantial
amounts of development on branches. It is intended to replace CVS and
corrects many mis-features of that system.  
EOF
chomp $about;
ok($ent->about(), $about);
my $changes = <<EOF;
In this release, past revisions can now be made available in a
(space efficient) forest of (ordinary) file system trees. There is a new
web browser for exploring the repositories.  A number of portability
glitches and minor bugs have been fixed, including a serious security bug
in with-ftp.
EOF
chomp $changes;
ok($ent->changes(), $changes);
ok($ent->license(), 'GNU General Public License (GPL)');
ok($ent->url(), 'http://freshmeat.net/projects/archrc/');
ok($ent->name(), 'arch');
ok($ent->version(), '1.0pre3 (Release)');
