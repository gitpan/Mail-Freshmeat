use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Mail::Freshmeat',
    'VERSION_FROM' => 'Freshmeat.pm',
    'PREREQ_PM' => {
                    # More accurate version requirements welcome
                    'Mail::Internet' => 0,
                    'Mail::Header' => 0, # not needed for earlier versions
                                         # of Mail::Internet?
                   }
);
