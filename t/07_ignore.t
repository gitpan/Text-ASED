#	-*- perl -*-

BEGIN { $| = 1; print "1..5\n"; }
use Text::ASED;
use Data::Dumper;

$testno = 1;

my $editor = new Text::ASED;

unlink "t/tmp"  if ( -e "t/tmp" );
system( "cp", "t/httpd.conf", "t/tmp" );

$outfile = eval $editor->prep( ignore => "TransferLog",
			       match => "^[^#]*Log",
			       search => "logs", 
			       replace => "XXX");

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

sub test_errorlog {
    my $outfile = shift;
    my $diff = `diff t/tmp /tmp/$outfile`;
    my @lines =  split /\n/, $diff;
    if ( $lines[0] eq "49c49" ) { # test 3
	print "ok $testno\n";
    } else {
	print "not ok $testno\n";
    } $testno++;

    if ( $lines[1] eq "< ErrorLog logs/error_log" ) { # test 4
	print "ok $testno\n";
    } else {
	print "not ok $testno\n";
    }
    $testno++;

    if ( $lines[3] eq "> ErrorLog XXX/error_log" ) { # test 5
	print "ok $testno\n";
    } else {
	print "not ok $testno\n";
    }
}
