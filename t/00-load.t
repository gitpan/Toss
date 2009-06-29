#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Toss' );
}

diag( "Testing Toss $Toss::VERSION, Perl $], $^X" );
