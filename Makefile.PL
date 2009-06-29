use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Toss',
    AUTHOR              => 'Todd Rinaldo <toddr@cpan.org>',
    VERSION_FROM        => 'lib/Toss.pm',
    ABSTRACT_FROM       => 'lib/Toss.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE'=> 'perl') : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'DateTime' => 0, # Just using epoch. I see no reason to require a specific version of DateTime
        'Devel::StackTrace' => 0, # Tracking stack location of toss events
        'overload' => 0, # Used to stringify the object.
        'version' => 0, # It comes with most dists, but might as well be explicit
        'Test::More' => 0,  # For testing
        'Test::NoWarnings' => 0,  # For testing
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Toss-*' },
    META_MERGE  => {
        build_requires => {
            'Test::More' => 0,  # For testing
            'Test::NoWarnings' => 0,  # For testing
        },
        resources => {
            license => 'http://dev.perl.org/licenses/',
            homepage => 'http://wiki.github.com/toddr/perl-Toss',
            bugtracker => 'http://github.com/toddr/perl-Toss/issues',
            repository => 'http://github.com/toddr/perl-Toss/tree/master',
#            MailingList => 'http://groups.google.com/group/perl-net-jabber-bot',
        },
    },
);
