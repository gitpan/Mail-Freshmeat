#!/usr/bin/perl -w

use strict;
use Test;
use Mail::Freshmeat;

BEGIN { plan test => 12027 }

my $count = -1;
my @newsletters;

open FM, "t/sample.newsletters" or die $!;
while (<FM>)
{
	$count++ if /^From\s/;
	push @{$newsletters[$count]}, $_;
}
close FM or die $!;

$count = 1;
for my $newsletter (@newsletters)
{
	my $letter;
	eval { $letter = Mail::Freshmeat->new($newsletter) };

	ok(not $@);
	ok($letter->links_header(),
		'::: L I N K S   F O R   T H E   D A Y :::');
	ok($letter->headlines_header(),
		qr/^::: R E L E A S E   H E A D L I N E S \(\d+\) :::$/);
	ok($letter->headlines(),
		qr/((?: ^ \[\d+\]\ .* $ \n | ^ [^\)]+ \) $ \n)+)/mx);
	ok($letter->details_header(),
		'::: R E L E A S E   D E T A I L S :::');
	my $footer = <<'EOF';
The freshmeat daily newsletter
To unsubscribe, send email to freshmeat-news-request@lists.freshmeat.net
or visit http://lists.freshmeat.net/mailman/listinfo/freshmeat-news

EOF
	chomp $footer;
	chomp $footer;
	ok($letter->footer(), $footer);
	ok($letter->total(), qr/^\d+$/);
	ok($letter->date(), qr/\d+\/\d+\/\d+/);
	ok(ref $letter->entries(), 'ARRAY');

	for my $entry ($letter->entries())
	{
		#warn "testing nl #$count, item #", $entry->position(), "\n";
		ok($entry->position(), qr/^\d{3}$/);
		ok($entry->posted_on(),
			qr/^\w+,\s\w+\s\d{1,2}\w{2}\s\d{4}\s\d{2}:\d{2}$/);
		ok($entry->license(),
			qr/license|commercial|domain|free|approved|
				shareware|gpl|unknown|not\sspecified/ix);
		ok($entry->url(), qr/^http:\/\//);
		ok($entry->name_and_version(), qr/${\(quotemeta($entry->name()))}/);
		ok($entry->posted_by(), qr/http:\/\//);
		#ok($entry->about(), qr/^About:\s/);
		#ok($entry->changes(), qr/^Changes:\s|Not\sspecified/);
	}
	$count++;
}
