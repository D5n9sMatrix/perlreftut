#!/usr/bin/perl

# An Example

# Let's see a quick example of how all this is useful.

# First, remember that [1, 2, 3] makes an anonymous 
# array containing (1, 2, 3), and gives you a reference 
# to that array.

# Now think about

my @a = ( [1, 2, 3],
       [4, 5, 6],
       [7, 8, 9]
     );

#!/usr/bin/perl
use warnings;
use strict;
 
 
use Data::Dumper;
use Getopt::Long;
use Pod::Usage;

 
my $DEBUGGING;
my $help;
my $password = '';
 
 
GetOptions("v" => \$DEBUGGING, "p=s"  => \$password,"h" => \$help,   );
pod2usage(-verbose => 2,)  if ($help);
pod2usage(-verbose => 1, 
          -msg => 'A password MUST be supplied',)  if (! $password);
 
 
 
 
##  Set up the Socket
 
 
# Register the app
my $p = Net::Growl::RegistrationPacket->new( application=>"Perl Notifier", password => $password,);
$p->addNotification();
 
 
 
 
# send a notification
$p = Net::Growl::NotificationPacket->new( application=>"Perl Notifier",
                                          title=>'Warning',
                                          description=>'from the OO API ',
                                          priority=>2,
                                          sticky=>'True',
                                          password => $password,
                                        );
 
 
## or the easy way -- more sockets are created though
# when outside the module  you can just do 
register(   password => $password);   # register
notify(   password => $password);   # notify, using default values for everything, but the pw
 
 
exit;
 
 
 
__END__

 
=head1 NAME
 
example.pl   -   Illustrates both the internal and external  Net::Growl API's
 
=head1 SYNOPSIS
 
 example.pl <-h>  -p=password 
 
 Options:
  -h flag displays this help message.
  -p flag allows for you to enter a password on the command line (otherwise edit the script)
 
 
=head1 DESCRIPTION
 
This command is an example -- should send 2 notifications,  plus the fiorst time it may depending on you growl settings display a registration notification
 
 
 
 
=cut    