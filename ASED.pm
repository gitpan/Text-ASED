package Text::ASED;

# Author : $Author: legrady $
# Date	 : $Date: 2002/04/16 00:12:10 $
# Version : $Revision: 1.9 $
# Log	  : $Log: ASED.pm,v $
# Log	  : Revision 1.9  2002/04/16 00:12:10  legrady
# Log	  : That version generated syntax errors.
# Log	  :
# Log	  : Revision 1.7  2002/04/16 00:56:50  legrady
# Log	  : Modified version line.
# Log	  :
# Log	  : Revision 1.4  2002/04/16 00:36:06  legrady
# Log	  : Added cvs variables to get version and file.
# Log	  :

require 5.005_62;
use strict;
use warnings;

use Text::Abbrev;
use Carp;

use vars qw( $VERSION );
($VERSION = '$Revision: 1.9 $') =~ s/[^\d\.]*//g;

#
sub true ()	{ 1; }
sub false ()	{ 0; }
sub isScalar ()	{ 1; }
sub isPush ()	{ 2; }
sub isUnShift (){ 3; }

#	------------------------------------------------------------
#	Variables.
#

#	Note:
#		'SNR' stands for 'search-and-replace'
#


my %prep_opts = (
		 append	 	=> isScalar,
		 begincontext	=> isPush,
		 delete	 	=> isScalar,
		 endcontext 	=> isUnShift,
		 ignore	 	=> isScalar,
		 match	 	=> isScalar,
		 prepend 	=> isScalar,
		 replace 	=> isScalar,
		 search	 	=> isScalar,
		 );

my %edit_opts = (
		 infile	 => isScalar,
		 outfile => isScalar,
		 );

my %prep_expand = ();
my %edit_expand = ();
my $processed_abbreviations;
#	------------------------------------------------------------
#	Public and private methods.
#
#	Generate a list of abbreviations for each valid command in
#	the $prep_opts list. If two options have the same initial sequence,
#	The identical portion is marked as invalid.
#

#	Keep constructor simple, defer initialization to separate routine.
#	(public)
#
sub new {
    my $self = {};
    bless $self, shift;
    $self->_init(@_);
    return $self;
}

#	Initialize the new object.
#	(private)
#
sub _init {
    my $self = shift;

    %prep_expand = abbrev( keys %prep_opts )	unless( keys %prep_expand );

    $self->{used}  = false;
    $self->{empty} = true;
    $self->{eval};
}

sub scrub {
    my $self = shift
;
    $self->{edits} = ();
    $self->{used} = false;
    $self->{empty} = true;
    delete $self->{eval};
}
sub reuse {
    my $self = shift;
    $self->{used} = false;
    delete $self->{eval};
}
sub prep {
    my $self = shift;

    croak( "ASED::prep() invoked with odd number of arguements:\n" . 
	  join "\n", @_ )
	if ( (scalar @_) %2 );

    croak( "ASED::prep() - used edit set needs either scrub() or reuse()\n" )
	if ( $self->{used} );

    my %edit;
    my ( $beginCnt, $endCnt ) = qw( 0 0 );
    while ( scalar @_ ) {
	my $key = shift;
	my $value = shift;
	carp( "ASED::prep invoked with unknown key: '$key' => $value\n")
	    unless( exists $prep_expand{$key} );

	my $option = $prep_expand{$key};
	carp( "ASED::prep key is prefix to more than one option: " .
	      "'$key' => $value\n")
	    unless( defined $option );

	$beginCnt++	if ( $option eq "begincontext" );
	$endCnt++	if ( $option eq "endcontext" );

	if ( isPush == $prep_opts{$option} ) {
	    push @{$edit{$option}}, $value;
	} elsif ( isUnShift == $prep_opts{$option} ) {
	    unshift @{$edit{$option}}, $value;
	} elsif ( isScalar == $prep_opts{$option} ) {
	    if ( exists $edit{$option} ) {
		croak( "ASED::prep: $key presented twice with arguments: " .
		       "`'$edit{$option}' & '$value'\n" ) ;
	    } elsif ( $option eq "scriptfile" ) {
		open SCRIPT, $value;
		my @script = <>;
		$self->prep( $_ )	for ( @script ); 
		close SCRIPT;
	    } else {
		$edit{$option} = $value;
	    }
	} else {
	    carp( "ASED::prep: Module editor made a mistake: " .
		  "\$prep_opts{$key} has value $prep_opts{$key}, " .
		  "should be isScalar(), isPush() or isUnShift()\n" );
	}
    }

    die( "ASED::prep() - should have same number of 'begincontext' " .
	 "and 'endcontext' :\n@_\n" ) unless ( $beginCnt == $endCnt );;

    push @{$self->{edits}}, \%edit;
    $self->{empty} = false;
    return scalar @{$self->{edits}};
}

my $indent;
my $varno;

sub line_actions {
    my $edit = shift;
    my ( $decl, $retval );
    my $gap = " " x $indent;

    $retval = "${gap}do {\n";
    {				# localized value of $gap
	my $gap = "$gap  ";
	if ( exists $edit->{append} && $edit->{append} ) {
	    $edit->{append} =~ s|"|\\"|g;
	    $edit->{append} =~ s|/|\\/|g;
	    $edit->{append} =~ s|\n|\\n|g;
	    $retval .= "${gap}\$_ .= \"$edit->{append}\"\n";
	}
	if ( exists $edit->{prepend} && $edit->{prepend} ) {
	    $edit->{prepend} =~ s|"|\\"|g;
	    $edit->{prepend} =~ s|/|\\/|g;
	    $edit->{prepend} =~ s|\n|\\n|g;
	    $retval .= "${gap}\$_ = \"$edit->{prepend}\$_\"\n";
	}
	if ( exists $edit->{search} && exists $edit->{replace} 
	     && $edit->{search} && $edit->{replace} ) {
	    $edit->{search} =~ s|\n|\\n|g;
	    $edit->{replace} =~ s|\n|\\n|g;
	    $edit->{search}  =~ s|/|\\/|g;
	    $edit->{replace} =~ s|/|\\/|g;
	    $edit->{replace} =~ s|\$(\d)|\$$1|;
	    my $search = "\$var_$varno";
	    $varno++;
	    my $replace = $edit->{replace};
	    $decl  = "my $search = qr/$edit->{search}/;\n";
	    $retval .= "${gap}s/$search/$replace/o;\n";
	}
	if ( exists $edit->{delete} && $edit->{delete} ) {
	    $edit->{delete} =~ s|\n|\\n|g;
	    $edit->{delete}  =~ s|/|\\/|g;
	    my $delete = "\$var_$varno";
	    $varno++;
	    $decl .= "my $delete = qr/$edit->{delete}/;\n";
	    $retval .= 
		"${gap}if ( /$delete/o ) {\n${gap}  next;\n${gap}}\n";
	}
    }
    $retval .= "${gap}};\n";
    return ( $decl, $retval );
    
}

sub convert_ignore {
    my $edit = shift;
    my ( $decl, $subdecl, $retval, $subretval );
    my $gap = " " x $indent;

    if ( exists $edit->{ignore} && $edit->{ignore} ) {
	$edit->{ignore} =~ s|\n|\\n|g;
	$edit->{ignore} =~ s|/|\\/|g;
	my $ignore = "\$var_$varno";
	$varno++;
	$decl    = "my $ignore = qr/$edit->{ignore}/;\n";
	$retval .= "${gap}unless ( /$ignore/o ) {\n" ;
	$indent += 2;
    }

    ( $subdecl, $subretval ) = line_actions( $edit );
    $decl   .= $subdecl		if ( defined $subdecl );
    $retval .= $subretval	if ( defined $subretval );

    if ( exists $edit->{ignore} && $edit->{ignore} ) {
	$indent -= 2;
	$retval .= "${gap}}\n";
    }
    return ( $decl, $retval );
}

sub convert_match {
    my $edit = shift;
    my ( $decl, $subdecl, $retval, $subretval );
    my $gap = " " x $indent;
    
    if ( exists $edit->{match} && $edit->{match} ) {
	$edit->{match} =~ s|\n|\\n|g;
	$edit->{match} =~ s|/|\\/|g;
	my $match = "\$var_$varno";
	$varno++;
	$decl    = "my $match = qr/$edit->{match}/;\n";
	$retval .= "${gap}if ( /$match/o ) {\n";
	$indent +=2;
    }

    ( $subdecl, $subretval ) = convert_ignore( $edit );
    $decl   .= $subdecl		if ( defined $subdecl );
    $retval .= $subretval	if ( defined $subretval );

    if ( exists $edit->{match} && $edit->{match} ) {
	$indent -=2;
	$retval .= "${gap}}\n";
    }
    return ( $decl, $retval );
}

sub convert_context {
    my ( $idx, $edit ) = @_;
    my ( $begin, $end );
    my ( $decl, $subdecl, $retval, $subretval );
    my $gap = " " x $indent;
    my $processed_while;

    if ( exists $edit->{begincontext} 
	 && exists $edit->{endcontext} 
	 && $idx < scalar @{$edit->{begincontext}}
	 && $idx < scalar @{$edit->{endcontext}} ) {
	$processed_while++;	# flag: processed a context this recursion?
	$begin = $edit->{begincontext}[$idx];
	$end = $edit->{endcontext}[$idx];

	$begin =~ s|\n|\\n|g;
	$begin =~ s|/|\\/|g;
	$end =~ s|\n|\\n|g;
	$end =~ s|/|\\/|g;
	
	my $match1 = "\$var_$varno";
	$varno++;
	$decl    = "my $match1 = qr/$begin/;\n";
	my $match2 = "\$var_$varno";
	$varno++;
	$decl   .= "my $match2 = qr/$end/;\n";
	$retval .= "${gap}if ( /$match1/o../$match2/o ) {\n";
	$indent +=2;
	$idx++;			# Which idx to process next recursion
    }
    
    ( $subdecl, $subretval ) = (( $processed_while )
				? convert_context( $idx, $edit )
				: convert_match( $edit ) );
    $decl .= $subdecl		if ( defined $subdecl );
    $retval .= $subretval	if ( defined $subretval );

    if ( $processed_while ) {
	$retval .= "$gap\};\n";
	$indent -= 2;
    }
    return ( $decl, $retval );
}
sub convert_one_block {
    my ( $edit ) = @_;
    my ( $decl, $retval ) = convert_context( 0, $edit );
    my $gap = " " x $indent;

    return ( $decl, $retval );
}

sub convert_end_overhead {
    my ( %args ) = @_;    
    my $retval;

    $indent -= 8;

    my $gap = " " x $indent;

    return "\n$gap    print \$out \$_;\n$gap  }\n$gap  return !eof(\$in);\n${gap}}";
}
sub convert_start_overhead {
    my $decl = shift;
    my ( %args ) = @_;    
    my $retval;
    $indent += 4;

    $decl    =~ s/^/  /gsm;

    return <<"SCRIPT";
\{
  my ( \$in, \$out );
  open \$in, \"<\", \"$args{infile}\"
      or die( \"Could not open file '$args{infile}'\" );
  open \$out, \">\", \"$args{outfile}\"
      or die( \"Could not open file '$args{outfile}'\" );

$decl

  while ( <\$in> ) {
SCRIPT


    $indent += 2;
}
sub edit {
    my $self = shift;
    my ( %args ) = @_;
    my %newargs;
    my $fileflag;

    %edit_expand = abbrev( keys %edit_opts )	unless( keys %edit_expand );
    
    if ( 0 == @_ ) {
	carp( "ASED::edit() - invoked without arguments" );
	return;
    } elsif ( 1 == @_ ) {
	$newargs{infile} = $_[0];
    } else {
	for ( keys %args ) {
	    if ( exists $edit_expand{$_} && $edit_expand{$_} ) {
		$newargs{$edit_expand{$_}} = $args{$_};
	    } else {
		carp( "ASED::edit() - unrecognized option '$_'\n" );
	    }
	}
    }
    unless ( $newargs{outfile} ) {
	$newargs{outfile} = "/tmp/$$";
	$fileflag = true;
    }

    unless ( defined $self->{eval} ) {
	my ( $decl, $code );

	$indent = 4;	# initialize vars
	$varno = 'a';

	foreach my $edit ( @{$self->{edits}} ) {
	    my ( $d, $c ) = convert_one_block( $edit );
	    $decl .= $d;
	    $code .= $c;
	}
	$self->{eval} .= convert_start_overhead(  $decl, %newargs );
	$self->{eval} .= $code;
	$self->{eval} .= convert_end_overhead( @_ );
    }
#    print "Running:\n$self->{eval}\n";
    unless ( defined eval $self->{eval} ) {
	die( "$@" );
    }
    $self->{used} = true;
    rename( "/tmp/$$", $newargs{infile} ) if $fileflag;
    1;
}

sub snr {
    my $self = shift;
    my $argcnt = scalar @_;
    $self->scrub() if ( $self->{used} );

    while ( scalar @_ > 1 ) {
	my ( $s, $r );
	$s = shift;
	$r = shift;
	$self->prep( search => $s, replace => $r );
    }
    if ( scalar @_ ) {
	$self->edit( infile => @_ );
	return $$;
    } else {
	return $argcnt;
    }
}

#	------------------------------------------------------------
1;	# Do not change this line; 
#	------------------------------------------------------------
__END__
# Below is stub documentation for your module. You better edit it!


=head1 NAME

ASED.pm - Perl extension providing an Advanced Stream EDitor

=head1 Synopsis 

    use ASED;

    my $editor = new ASED;

    $editor->prep( search  => $pattern1
	           replace => $patther2); 
    $editor->edit( infile   => $infile, 
		   outfile  => $outfile);
    $editor->scrub();

or

    $editor->snr(  $search1, $replace1, 
	           $search2, $replace2, 
                   $search3, $replace3 );
    $editor->prep( search  => $search2,
		   replace => $pattern5 );
    $editor->edit( $infile1 );
    $editor->reuse();
    $editor->edit( $infile2 );

or

    $editor->snr(  $search1, $replace1, 
		   $search2, $replace2, 
		   $search2, $replace2,
		   $file_or_string );

=head1 Description

An ASED object provides five commands, besides the constructor:
F<prep()>, F<edit()>, F<snr()>, F<scrub()> and F<reuse()>.

F<prep()> describes the modifications which are to be performed on a
file.  Each invocation of F<prep()> describes a single set of edits,
thus three search-and-replace operations require three invocations of
F<prep()>. The various parameters to F<prep()> are described in
L<Options|options>.

Note that parameter keywords can be contracted. Intead of specifying
C<begincontext>, it is possible to use any unique subset of this
string. While C<b> would work, I would suggest C<begin> as optimally
combining brevity and clarity.

Once all the modifications are described, the editing is performed by
invoking F<edit()>. F<edit()> can be invoked with a single argument, the
name of the file to edit, with several named arguments specifying
several file names, or with the string to edit.

If all the modifications to be performed are simple search-and-replace
operations, and there is no need for separate output files, log files,
etc., a simplified form is provided. F<snr()> stands for
I<search-and-replace>. Arguments are taken two at a time and
interpretated as a I<search> string and a I<replace> string. After all
pairs have been processed, if there remains a single argument, it
specifies the file or string to process. The final argument is tested
to see if it specifies the name of an existing file. if it does, that
file is processed in place. If no matching file is found, the
argument is considered to specify a string which is to be modified.

If you are finished with an ASED object, there is no need to invoke
F<reuse()> or F<scrub()>, but one or the other of these must be called
if an ASED object will be used several times. Whether using predefined
Perl edit commands or sed scripts invoked from shell scripts, a common
mistake (i.e., one I tend to make) is to forget to re-initialize the
edit sequence. This may result in accidentally making unintended
changes to a file, or simply in producing error messages concerning
failed edits. In the worst case, not removing the old set of edits may
prevent the new, intended edits from occurring properly. This is the
reason for requiring the use of F<reuse()> and F<scrub()>. 

F<reuse()> is used when a set of edits is to be applied to more than
one file. The identical set of edits can be applied to the next file,
or additional edits can be added.

Once you are finished with a set of edits, F<scrub()> it. This empties
the edit set, causing new F<snr()> or F<prep()> commands to generate a
new set of edits.

    $editor->snr( $pattern1, $pattern2 );
    $editor->edit( $file1 );
    $editor->reuse();

    $editor->edit( $file2 );
    $editor->reuse();

    $editor->snr( $pattern3, $pattern4 );
    $editor->edit( $file3 );
    $editor->scrub();

    $editor->snr( $pattern5, $pattern6 );
    $editor->edit( $file4 );

=head1 Options

The patterns provided to options are automatically adjusted so that
the use of C</> or of C<\/n> are passed on to the intended string,
rather than being interpreted too early.

The C<prep()> command takes the following options:

B<Action Specifying Options>

=over 4

=item search I<pattern>

The pattern specified is used as the first component in C<s///>. Any Perl regexp component can be used.

=item replace I<pattern>

The second component in C<s///>. Any appropriate Perl regexp component can be used

=item append I<string>

Normally, this command would be used in conjunction with C<match> to
locate lines to be modified.  The specified string is added to the
current line.

Lines of the input string are not C<chomped>, thus C<append> adds text to beginning of the following line. Make sure there is a C<\/n> at the end of the C<append> string if you want a new line.

=item prepend I<string>

Like C<append>, this is used with line-specifying options such as C<match>. The specified text is added to the beginning of the line. Use a C<\/n> at the end of the new string, if you want a new line before the matched line.

=item delete I<pattern>

C<delete> specifies a pattern and deletes matching lines.

Note the difference between this and the behaviour of C<append> and C<prepend>.

=back 4


B<Region Specifying Options>

=over 4

=item match I<pattern>

Attempt other commands only to lines which match this pattern.

C<match> makes it possible to simplify search-and-replace patterns
which require some text to isolate the correct line, but need to
modify different components. Instead of:

    s{(My_Complicated_variable_name)\s*=\s*Complicated_value}
     {\1 = New_Value}

it becomes possible to use the clearer:

    $editor->prep( match => "My_Complicated_variable_name\s*="
	           search => "=\s*Complicated_value",
	           replace => "= New_Value" );

C<match> nests within contexts.

=item ignore I<pattern>

Do not attempt other commands on lines which match this pattern.

C<ignore> nests within contexts.

=item begincontext I<pattern>

Sometimes C<match> isn't enough. In Apache's httpd.conf file, you
might want to modify only I<DocumentRoot> lines within a certain
I<VirtualHost> section. In a script, you might want to modify I<my
$tmp> only within a certain subroutine.

C<begincontext> specifies the first line of the region which will have
other options applied to it.

Contexts can be nested without limit, usign the pattern:

    begin			# 1
    begin			# 2
    begin			# 3
    end				# 3
    end				# 2
    end				# 1

=item endcontext I<pattern>

Specifies the last line of a context region.

=back 4

The C<edit()> command takes the following options:

=head1 AUTHOR

Tom Legrady tdl@cpan.org

=head1 COPYRIGRHT

Copyright (c) 2002 Tom Legrady tdl@cpan.org

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

If  you use my module, I would appreciate an email (tdl@cpan.org)
letting me know about it. Even better, let me know what you like, what
different features you would like, what could be done better.

=cut
