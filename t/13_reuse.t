#	-*- perl -*-

BEGIN { $| = 1; print "1..13\n"; }
use Text::ASED;
use Data::Dumper;

$testno = 1;

my $editor = new Text::ASED;

unlink "t/tmp" if ( -e "t/tmp" );
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
    test_errorlog( "$$" );
} else {
    print "not ok $testno\n";
}
$testno++;

$editor->reuse();
$outfile = eval $editor->prep( search => "MaxClients",
                               replace => "MAXCLIENTS");
if ( $outfile ) {		# test 6
    print "ok $testno\n";
} else {
    print "not ok $testno\n";
}
$testno++;

$outfile = eval $editor-> edit( infile => "t/tmp",
                                outfile => "/tmp/$$" );

if ( $outfile ) {		# test 7
    print "ok $testno\n";
    $testno++;
    test_maxclient( "$$" );
} else {
    print "not ok $testno\n";
}
unlink "/tmp/$$" ;
$testno++;


sub test_errorlog {
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
    if ( $lines[3] ne "> #ErrorLog logs/MYCOMPANY.com-error_log" ) {
	print "not ok $testno\n";
    } else {
	print "ok $testno\n";
    }
}

sub test_maxclient {
    my $outfile = shift;
    my $diff = `diff t/tmp /tmp/$outfile`;
    my @lines =  split /\n/, $diff;

    if ( $lines[0] eq "106c106" ) { # test 8
        print "ok $testno\n";
    } else {
        print "not ok $testno\n";
    }
    $testno++;
    
    if ( $lines[1] eq "< MaxClients 150" ) { # test 9
        print "ok $testno\n";
    } else {
        print "not ok $testno\n";
    }
    $testno++;

    if ( $lines[3] eq "> MAXCLIENTS 150" ) { # test 10
        print "ok $testno\n";
    } else {
        print "not ok $testno\n";
    }
    $testno++;

    if ( $lines[4] eq "129c129" ) { # test 11
	print "ok $testno\n";
    } else {
	print "not ok $testno\n";
    }
    $testno++;

				# test 12
    if ( $lines[5] eq "< #ErrorLog logs/host.foo.com-error_log" ) {
	print "ok $testno\n";
    } else {
	print "not ok $testno\n";
    }
    $testno++;
				# test 13
    if ( $lines[7] ne "> #ErrorLog logs/MYCOMPANY.com-error_log" ) {
	print "not ok $testno\n";
    } else {
	print "ok $testno\n";
    }
}
