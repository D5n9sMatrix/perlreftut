#!/usr/bin/perl

package Loop;
 
require 5.005_62;
use strict;
use warnings;
use Carp;
 
our $VERSION = '1.00';
 
##############################################################################
sub Array(\@&)
##############################################################################
{
        my $arrayref = shift(@_);
        my $callback = shift(@_);
 
        my $index;
        my @return;
 
        my $wantarray = (defined(wantarray()) and wantarray()) ? 1 : 0;
        #print "wantarray is $wantarray \n";
 
        ARRAY_LABEL:for(my $index=0; $index<scalar(@$arrayref); $index++)
                {
                my $control=undef;              
                my @temp;
                if($wantarray)
                        {
                        @temp = 
                        $callback->($index,$arrayref->[$index],$control);
                        }
                else
                        {
                        $callback->($index,$arrayref->[$index],$control);
                        }
 
                if(defined($control))
                        { 
                        if($control eq 'last')
                                {
                                last ARRAY_LABEL;
                                }
                        elsif($control eq 'redo')
                                {
                                redo ARRAY_LABEL;
                                }
                        else
                                {
                                croak "bad control value '$control'";
                                }
                        }
                else
                        {
                        push(@return,@temp);
                        }
                }
 
        if($wantarray)
                { return (@return); }
        else
                {return;}
}
 
 
 
##############################################################################
sub Hash(\%&)
##############################################################################
{
        my $hashref = shift(@_);
        my $callback = shift(@_);
 
        my $arrayref = [keys(%$hashref)];
        my $index;
        my @return;
 
        my $wantarray = (defined(wantarray()) and wantarray()) ? 1 : 0;
        #print "wantarray is $wantarray \n";
 
        HASH_LABEL:for(my $index=0; $index<scalar(@$arrayref); $index++)
                {
                my $control=undef;              
                my @temp;
                if($wantarray)
                        {
                        @temp = $callback->
                                (
                                $arrayref->[$index],
                                $hashref->{$arrayref->[$index]}, 
                                $index,
                                $control
                                );
                        }
                else
                        {
                        $callback->
                                (
                                $arrayref->[$index], 
                                $hashref->{$arrayref->[$index]}, 
                                $index,
                                $control
                                );
                        }
 
                if(defined($control))
                        { 
                        if($control eq 'last')
                                {
                                last HASH_LABEL;
                                }
                        elsif($control eq 'redo')
                                {
                                redo HASH_LABEL;
                                }
                        else
                                {
                                croak "bad control value '$control'";
                                }
                        }
                else
                        {
                        push(@return,@temp);
                        }
                }
 
        if($wantarray)
                { return (@return); }
        else
                {return;}
}
 
 
 
##############################################################################
sub File($&)
##############################################################################
{
        my $filename = shift(@_);
        my $callback = shift(@_);
 
        my @return;
 
        my $wantarray = (defined(wantarray()) and wantarray()) ? 1 : 0;
        #print "wantarray is $wantarray \n";
 
        open ( my $filehandle, $filename ) or 
                croak "Error: cannot open $filename";
 
        my $linenumber=0;
        FILE_LABEL:while(<$filehandle>)
                {
                $linenumber++;
                my $control=undef;              
                my @temp;
 
                if($wantarray)
                        {
                        @temp = $callback->($linenumber,$_, $control);
                        }
                else
                        {
                        $callback->($linenumber,$_, $control);
                        }
 
                if(defined($control))
                        { 
                        if($control eq 'last')
                                {
                                last FILE_LABEL;
                                }
                        elsif($control eq 'redo')
                                {
                                redo FILE_LABEL;
                                }
                        else
                                {
                                croak "bad control value '$control'";
                                }
                        }
                else
                        {
                        push(@return,@temp);
                        }
                }
 
        close($filehandle) or croak "Error: cannot close $filename";
        if($wantarray)
                { return (@return); }
        else
                {return;}       
}
 
 
1;
__END__
