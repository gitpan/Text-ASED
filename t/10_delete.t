#	-*- perl -*-

BEGIN { $| = 1; print "1..4\n"; }
use Text::ASED;
use Data::Dumper;

$testno = 1;

my $editor = new Text::ASED;

system( "rm",  "t/tmp" ) if ( -e "t/tmp" );
system( "cp", "t/httpd.conf", "t/tmp" );

$outfile = eval $editor->prep( delete => "^TransferLog" );

if ( $outfile ) {		# test 1
    print "ok $testno\n";
} else {
    print "not ok $testno\n";
}
$testno++;

$outfile = eval $editor-> edit( infile => "t/tmp", 
				outfile => "/tmp/$$" );

if ( $outfile ) {		# test 2
    print "ok $testno\n";
    $testno++;
    test_errorlog( "$$" );
} else {
    print "not ok $testno\n";
}
unlink "/tmp/$$" ;
$testno++;

sub test_errorlog {
    my $outfile = shift;
    my $diff = `diff t/tmp /tmp/$outfile`;
    my @lines =  split /\n/, $diff;

    if ( $lines[0] eq "54d53" ) { # test 3
	print "ok $testno\n";
    } else {
	print "not ok $testno\n";
    }
    $testno++;

    if ( $lines[1] eq "< TransferLog logs/access_log" ) { # test 4
	print "ok $testno\n";
    } else {
	print "not ok $testno\n";
    }
}
