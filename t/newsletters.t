#!/usr/bin/perl -w

use strict;
use Test;
use Mail::Freshmeat;

BEGIN { plan test => 7382 }

my $count = -1;
my @newsletters;

open FM, "t/sample.newsletters" or die $!;
#open FM, "../fmold" or die $!;
#open FM, "../fm" or die $!;
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
	ok($letter->links(),
		qr!\d{4}/\d{2}/\d{2}/!);
	ok($letter->headlines_header(),
		qr/^::: R E L E A S E   H E A D L I N E S \(\d+\) :::$/);
	ok($letter->headlines(),
		qr/((?: ^ \[\d+\]\ .* $ \n | ^ [^\)]+ \) $ \n)+)/mx);
	ok($letter->ad_header(), '::: A D V E R T I S I N G :::') if
		$letter->ad_header();
	ok($letter->articles_header(),
		qr/^::: A R T I C L E S \(\d+\) :::$/) if $letter->articles_header();
	ok($letter->entries_header(),
		'::: R E L E A S E   D E T A I L S :::');
	ok($letter->ad(), qr!http://!) if $letter->ad();
	my $footer = <<'EOF';
The freshmeat daily newsletter
To unsubscribe, send email to freshmeat-news-request@lists.freshmeat.net
or visit http://lists.freshmeat.net/mailman/listinfo/freshmeat-news

EOF
	chomp $footer;
	chomp $footer;
	ok($letter->footer(), $footer);
	ok($letter->entries_total(), qr/^\d+$/);
	ok($letter->articles_total(), qr/^\d+$/) if $letter->articles_total();
	ok($letter->date(), qr/\d+\/\d+\/\d+/);
	ok(ref $letter->entries(), 'ARRAY');

	for my $entry ($letter->entries())
	{
		#warn "testing nl #$count, entry#", $entry->position(), "\n";
		my $entry_keys = join '', $entry->entry_keys();
		ok($entry_keys, '_position_name_and_version_name_version_posted_by_name_posted_by_url_posted_on_trove_about_changes_license_url');
		ok($entry->position(), qr/^\d{3}$/);
		ok($entry->posted_on(),
			qr/^\w+,\s\w+\s\d{1,2}\w{2}\s\d{4}\s\d{2}:\d{2}$/);
		ok($entry->license(),
			qr/license|commercial|domain|free|approved|
				shareware|gpl|unknown|/ix);
		ok($entry->url(), qr/^http:\/\//);
		ok($entry->name_and_version(), qr/${\(quotemeta($entry->name()))}/);
		ok($entry->short_entry(), qr/${\(quotemeta($entry->name()))}/);
		ok($entry->posted_by_url(), qr/http:\/\/|/);
		#ok($entry->about(), qr/^About:\s/);
		#ok($entry->changes(), qr/^Changes:\s|/);
	}

	for my $article ($letter->articles())
	{
		my $article_keys = join '', $article->article_keys();
		ok($article_keys, '_title_posted_by_name_posted_by_url_posted_on_section_description_url');
		ok($article->posted_by_url(), qr/mailto|http|ftp|\@/);
		ok($article->posted_on(),
			qr/^\w+,\s\w+\s\d{1,2}\w{2}\s\d{4}\s\d{2}:\d{2}$/);
		ok($article->url(), qr!http://!);
	}

	$count++;
}
