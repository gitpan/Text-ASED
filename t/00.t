#	-*- perl -*-

BEGIN { $| = 1; print "1..1\n"; }
system( "rm -f /tmp/[0-9]*" );
print "ok 1";
