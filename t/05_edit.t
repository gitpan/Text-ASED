#	-*- perl -*-

BEGIN { $| = 1; print "1..5\n"; }
use Text::ASED;
use Data::Dumper;

$testno = 1;

my $editor = new Text::ASED;

unlink "t/tmp" if ( -e "t/tmp" );
system( "cp", "t/httpd.conf", "t/tmp");

$outfile = eval $editor->prep( search => "MaxClients", 
			       replace => "MAXCLIENTS");

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
    test_maxclient( "/tmp/$$" );
} else {
    print "not ok a$testno\n";
}
unlink "/tmp/$$" ;
$testno++;
sub test_maxclient {
    my $outfile = shift;
    my $diff = `diff t/httpd.conf $outfile`;
    my @lines =  split /\n/, $diff;

    if ( $lines[0] eq "106c106" ) { # test 3
	print "ok $testno\n";
    } else {
	print "not ok $testno\n";
    }	
    $testno++;

    if ( $lines[1] eq "< MaxClients 150" ) { # test 4
	print "ok $testno\n";
    } else {
	print "not ok $testno\n";
    }
    $testno++;

    if ( $lines[3] eq "> MAXCLIENTS 150" ) { # test 5
	print "ok $testno\n";
    } else {
	print "not ok $testno\n";
    }
}
