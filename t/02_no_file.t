#	-*- perl -*-

BEGIN { $| = 1; print "1..1\n"; }
use Text::ASED;
use Data::Dumper;


$testno = 1;

my $editor = new Text::ASED;

unlink "t/tmp"  if ( -e "t/tmp" );
system( "cp", "t/httpd.conf", "t/tmp" );

$outfile = eval $editor->snr( "MaxClients", "MAXCLIENTS", "t/tmp" );

if ( $outfile ) {
    if ( -e $$ ) {
	print "not ok $testno\n";
    } else {
	print "ok $testno";
    }
} else {
    print "not ok $testno\n";
}


