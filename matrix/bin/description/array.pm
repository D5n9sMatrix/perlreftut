#!/usr/bin/perl

# @a is an array with three elements, and each one is 
# a reference to another array.

# $a[1] is one of these references. It refers to an 
# array, the array containing (4, 5, 6), and because 
# it is a reference to an array, Use Rule 2 says that 
# we can write $a[1]->[2] to get the third element from 
# that array. $a[1]->[2] is the 6. Similarly, 
# $a[0]->[1] is the 2. What we have here is like 
# a two-dimensional array; you can write 
# $a[ROW]->[COLUMN] to get or set the element 
# in any row and any column of the array.

# The notation still looks a little cumbersome, 
# so there's one more abbreviation:

package Array::Utils;

 
=head1 NAME
 
Array::Utils - small utils for array manipulation
 
=head1 SYNOPSIS
 
        use Array::Utils qw(:all);
         
        my @a = qw( a b c d );
        my @b = qw( c d e f );
 
        # symmetric difference
        my @diff = array_diff(@a, @b);
 
        # intersection
        my @isect = intersect(@a, @b);
         
        # unique union
        my @unique = unique(@a, @b);
         
        # check if arrays contain same members
        if ( !array_diff(@a, @b) ) {
                # do something
        }
         
        # get items from array @a that are not in array @b
        my @minus = array_minus( @a, @b );
         
=head1 DESCRIPTION
 
A small pure-perl module containing list manipulation routines. The module
emerged because I was tired to include same utility routines in numerous projects.
 
=head1 FUNCTIONS
 
=over 4
 
=item C<unique>
 
Returns an array of unique items in the arguments list.
 
=item C<intersect>
 
Returns an intersection of two arrays passed as arguments, keeping the order of the
second parameter. A nice side effect of this function can be exploited in situations as:
 
        @atreides = qw( Leto Paul Alia 'Leto II' );
        @mylist = qw( Alia Leto );
        @mylist = intersect( @mylist, @atreides );  # and @mylist is ordered as Leto,Alia
 
=item C<array_diff>
 
Return symmetric difference of two arrays passed as arguments.
 
=item C<array_minus>
 
Returns the difference of the passed arrays A and B (only those 
array elements that exist in A and do not exist in B). 
If an empty array is returned, A is subset of B.
 
Function was proposed by Laszlo Forro <salmonix@gmail.com>.
 
=back
 
=head1 BUGS
 
None known yet
 
=head1 AUTHOR
 
Sergei A. Fedorov <zmij@cpan.org>
 
I will be happy to have your feedback about the module.
 
=head1 COPYRIGHT
 
This module is Copyright (c) 2007 Sergei A. Fedorov.
All rights reserved.
 
You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.
 
=head1 WARRANTY
 
This is free software. IT COMES WITHOUT WARRANTY OF ANY KIND.
 
=cut
 
use strict;
 
require Exporter;
our @ISA = qw(Exporter);
 
our %EXPORT_TAGS = (
        all     => [ qw(
                &unique
                &intersect
                &array_diff
                &array_minus
        ) ],
);
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
 
our $VERSION = '0.5';
 
sub unique(@) {
        return keys %{ {map { $_ => undef } @_}}; 
}
 
sub intersect(\@\@) {
        my %e = map { $_ => undef } @{$_[0]};
        return grep { exists( $e{$_} ) } @{$_[1]};
}
 
sub array_diff(\@\@) {
        my %e = map { $_ => undef } @{$_[1]};
        return @{[ ( grep { (exists $e{$_}) ? ( delete $e{$_} ) : ( 1 ) } @{ $_[0] } ), keys %e ] };
}
 
sub array_minus(\@\@) {
        my %e = map{ $_ => undef } @{$_[1]};
        return grep( ! exists( $e{$_} ), @{$_[0]} ); 
}
 
1;