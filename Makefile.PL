# $Id: Makefile.PL,v 1.9 2002/07/22 06:14:34 afoxson Exp $
# $Revision: 1.9 $

use ExtUtils::MakeMaker;

print "\nIMPORTANT: DUE TO FRESHMEAT.NET CHANGING THE STRUCTURE OF THEIR\n";
print "NEWSLETTERS, THE INTERFACE FOR THIS PACKAGE HAS CHANGED\n";
print "SINCE Mail::Freshmeat 0.94.\n\n";

WriteMakefile
(
	'NAME'                         => 'Mail::Freshmeat',
	'PM'                           =>
	{
		'lib/Freshmeat.pm'         => '$(INST_LIBDIR)/Freshmeat.pm',
		'lib/Freshmeat/Article.pm' => '$(INST_LIBDIR)/Freshmeat/Article.pm',
		'lib/Freshmeat/Entry.pm'   => '$(INST_LIBDIR)/Freshmeat/Entry.pm',
		'lib/Freshmeat/Utils.pm'   => '$(INST_LIBDIR)/Freshmeat/Utils.pm',
	},
	'PREREQ_PM'                    =>
	{
		'Mail::Internet'           => 0,
	},
	'VERSION_FROM'                 => 'lib/Freshmeat.pm',
	'dist'                         => { 'COMPRESS' => 'gzip --best' },
	(   
		$] >= 5.005 ?
		(   
			ABSTRACT_FROM          => 'lib/Freshmeat.pm',
			AUTHOR                 => 'Adam J. Foxson <afoxson@pobox.com>',
		) : ()
	),
);
