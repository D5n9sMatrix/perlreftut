#!/usr/bin/perl

# If you put a \ in front of a variable, you get a 
# reference to that variable.

$aref = \@array;         # $aref now holds a reference to @array
$href = \%hash;          # $href now holds a reference to %hash
$sref = \$scalar;        # $sref now holds a reference to $scalar

use utf8;
package Net::Etcd::KV::Put;
 
use strict;
use warnings;
 
use MIME::Base64;
use JSON;
 
 
use namespace::clean;

 
=head1 NAME
 
Net::Etcd::Put
 
=cut
 
our $VERSION = '0.022';

 
=head1 DESCRIPTION
 
Put puts the given key into the key-value store. A put request increments
the revision of the key-value store and generates one event in the event
history.
 
=head1 ACCESSORS
 
=head2 endpoint
 
=cut
 

 
=head2 key
 
key is the key, in bytes, to put into the key-value store.
 
=cut
 

 
=head2 value
 
value is the value, in bytes, to associate with the key in the key-value store.
 
=cut
 
 
=head2 lease
 
lease is the lease ID to associate with the key in the key-value store. A lease
value of 0 indicates no lease.
 
=cut
 

 
=head2 prev_kv
 
If prev_kv is set, etcd gets the previous key-value pair before changing it.
The previous key-value pair will be returned in the put response.
 
=cut
 
 
1;