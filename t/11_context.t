#	-*- perl -*-

BEGIN { $| = 1; print "1..5\n"; }
use Text::ASED;
use Data::Dumper;

$testno = 1;

my $editor = new Text::ASED;

system( "rm",  "t/tmp" ) if ( -e "t/tmp" );
system( "cp", "t/httpd.conf", "t/tmp" );

$outfile = eval $editor->prep( begin => "<VirtualHost",
			       end => "</VirtualHost",
			       match => "ErrorLog", 
			       search => "host.foo",
			       replace => "MYCOMPANY");

if ( $outfile ) {		# test 1
    print "ok $testno\n";
} else {
    print "not ok $testno\n";
}
$testno++;
$outfile = eval $editor->edit( infile => "t/httpd.conf",
			       outfile => "/tmp/$$" );

if ( $outfile ) {		# test 2
    print "ok $testno\n";
    $testno++;
    test_maxclient( "$$" );
} else {
    print "not ok $testno\n";
}
unlink"/tmp/$$" ;


sub test_maxclient {
    my $outfile = shift;
    my $diff = `diff t/tmp /tmp/$outfile`;
    my @lines =  split /\n/, $diff;

    if ( $lines[0] eq "129c129" ) { # test 3
	print "ok $testno\n";
    } else {
	print "not ok $testno\n";
    }
    $testno++;
				# test 4
    if ( $lines[1] eq "< #ErrorLog logs/host.foo.com-error_log" ) {
	print "ok $testno\n";
    } else {
	print "not ok $testno\n";
    }
    $testno++;
				# test 5
    if ( $lines[3] eq "> #ErrorLog logs/MYCOMPANY.com-error_log" ) {
	print "ok $testno\n";
    } else {
	print "not ok $testno\n";
    }
}
