#	-*- perl -*-

BEGIN { $| = 1; print "1..8\n"; }
use Text::ASED;
use Data::Dumper;

$testno = 1;

my $editor = new Text::ASED;

unlink "t/tmp" if ( -e "t/tmp" );
system( "cp", "t/httpd.conf", "t/tmp" );

$outfile = eval $editor->snr( "MaxClients", "MAXCLIENTS", "t/tmp" );

if ( $outfile ) {		# test 1
    print "ok $testno\n";
    $testno++;
    test_maxclient( "t/tmp" );
} else {
    print "not ok $testno\n";
}
unlink "t/tmp" ;
system( "cp", "t/httpd.conf", "t/tmp" );
$testno++;

$outfile = eval $editor->snr( "MaxClients", "MAXCLIENTS", "t/tmp" );

if ( $outfile ) {
    print "ok $testno\n";	# test 5
    $testno++;
    test_maxclient( "t/tmp" );
} else {
    print "not ok $testno\n";
}
unlink"/tmp/$$" ;

sub test_maxclient {
    my $outfile = shift;
    my $diff = `diff t/httpd.conf $outfile`;
    my @lines =  split /\n/, $diff;

    if ( $lines[0] eq "106c106" ) { # test 2 & 6
	print "ok $testno\n";
    } else {
	print "not ok $testno\n";
    }	
    $testno++;

    if ( $lines[1] eq "< MaxClients 150" ) { # test 3 & 7
	print "ok $testno\n";
    } else {
	print "not ok $testno\n";
    }
    $testno++;

    if ( $lines[3] eq "> MAXCLIENTS 150" ) { # test 4 & 8
	print "ok $testno\n";
    } else {
	print "not ok $testno\n";
    }
}
