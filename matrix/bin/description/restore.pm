#!perl
 
# Note: This script is a CLI for Riap function /App/WHMCSUtils/restore_whmcs_client
# and generated automatically using Perinci::CmdLine::Gen version 0.491
 
our $DATE = '2019-11-29'; # DATE
our $DIST = 'App-WHMCSUtils'; # DIST
our $VERSION = '0.011'; # VERSION
 
use 5.010001;
use strict;
use warnings;
use Log::ger;
 
use Perinci::CmdLine::Any;
 
my $cmdline = Perinci::CmdLine::Any->new(
    url => "/App/WHMCSUtils/restore_whmcs_client",
    program_name => "restore-whmcs-client",
    log => 1,
);
 
$cmdline->run;
 
# ABSTRACT: Restore a missing client from SQL database backup
# PODNAME: restore-whmcs-client
 
__END__

 
=pod
 
=encoding UTF-8
 
=head1 NAME
 
restore-whmcs-client - Restore a missing client from SQL database backup
 
=head1 VERSION
 
This document describes version 0.011 of restore-whmcs-client (from Perl distribution App-WHMCSUtils), released on 2019-11-29.
 
=head1 SYNOPSIS
 
Usage:
 
 % restore-whmcs-client [options]
 
=head1 OPTIONS
 
C<*> marks required options.
 
=head2 Main options
 
=over
 
=item B<--client-email>=I<s>
 
=item B<--client-id>=I<s>
 
=item B<--no-restore-domains>
 
=item B<--no-restore-hostings>
 
=item B<--no-restore-invoices>
 
=item B<--sql-backup-dir>=I<s>
 
Directory containing per-table SQL files.
 
=item B<--sql-backup-file>=I<s>
 
Can accept either `.sql` or `.sql.gz`.
 
Will be converted first to a directory where the SQL file will be extracted to
separate files on a per-table basis.
 
 
=back
 
=head2 Configuration options
 
=over
 
=item B<--config-path>=I<s>, B<-c>
 
Set path to configuration file.
 
=item B<--config-profile>=I<s>, B<-P>
 
Set configuration profile to use.
 
=item B<--no-config>, B<-C>
 
Do not use any configuration file.
 
=back
 
=head2 Environment options
 
=over
 
=item B<--no-env>
 
Do not read environment for default options.
 
=back
 
=head2 Logging options
 
=over
 
=item B<--debug>
 
Shortcut for --log-level=debug.
 
=item B<--log-level>=I<s>
 
Set log level.
 
=item B<--quiet>
 
Shortcut for --log-level=error.
 
=item B<--trace>
 
Shortcut for --log-level=trace.
 
=item B<--verbose>
 
Shortcut for --log-level=info.
 
=back
 
=head2 Output options
 
=over
 
=item B<--format>=I<s>
 
Choose output format, e.g. json, text.
 
Default value:
 
 undef
 
=item B<--json>
 
Set output format to json.
 
=item B<--naked-res>
 
When outputing as JSON, strip result envelope.
 
Default value:
 
 0
 
By default, when outputing as JSON, the full enveloped result is returned, e.g.:
 
    [200,"OK",[1,2,3],{"func.extra"=>4}]
 
The reason is so you can get the status (1st element), status message (2nd
element) as well as result metadata/extra result (4th element) instead of just
the result (3rd element). However, sometimes you want just the result, e.g. when
you want to pipe the result for more post-processing. In this case you can use
`--naked-res` so you just get:
 
    [1,2,3]
 
 
=back
 
=head2 Other options
 
=over
 
=item B<--dry-run>
 
Run in simulation mode (also via DRY_RUN=1).
 
Default value:
 
 ""
 
=item B<--help>, B<-h>, B<-?>
 
Display help message and exit.
 
=item B<--version>, B<-v>
 
Display program's version and exit.
 
=back
 
=head1 COMPLETION
 
This script has shell tab completion capability with support for several
shells.
 
=head2 bash
 
To activate bash completion for this script, put:
 
 complete -C restore-whmcs-client restore-whmcs-client
 
in your bash startup (e.g. F<~/.bashrc>). Your next shell session will then
recognize tab completion for the command. Or, you can also directly execute the
line above in your shell to activate immediately.
 
It is recommended, however, that you install modules using L<cpanm-shcompgen>
which can activate shell completion for scripts immediately.
 
=head2 tcsh
 
To activate tcsh completion for this script, put:
 
 complete restore-whmcs-client 'p/*/`restore-whmcs-client`/'
 
in your tcsh startup (e.g. F<~/.tcshrc>). Your next shell session will then
recognize tab completion for the command. Or, you can also directly execute the
line above in your shell to activate immediately.
 
It is also recommended to install L<shcompgen> (see above).
 
=head2 other shells
 
For fish and zsh, install L<shcompgen> as described above.
 
=head1 CONFIGURATION FILE
 
This script can read configuration files. Configuration files are in the format of L<IOD>, which is basically INI with some extra features.
 
By default, these names are searched for configuration filenames (can be changed using C<--config-path>): F<~/.config/restore-whmcs-client.conf>, F<~/restore-whmcs-client.conf>, or F</etc/restore-whmcs-client.conf>.
 
All found files will be read and merged.
 
To disable searching for configuration files, pass C<--no-config>.
 
You can put multiple profiles in a single file by using section names like C<[profile=SOMENAME]> or C<[SOMESECTION profile=SOMENAME]>. Those sections will only be read if you specify the matching C<--config-profile SOMENAME>.
 
You can also put configuration for multiple programs inside a single file, and use filter C<program=NAME> in section names, e.g. C<[program=NAME ...]> or C<[SOMESECTION program=NAME]>. The section will then only be used when the reading program matches.
 
Finally, you can filter a section by environment variable using the filter C<env=CONDITION> in section names. For example if you only want a section to be read if a certain environment variable is true: C<[env=SOMEVAR ...]> or C<[SOMESECTION env=SOMEVAR ...]>. If you only want a section to be read when the value of an environment variable has value equals something: C<[env=HOSTNAME=blink ...]> or C<[SOMESECTION env=HOSTNAME=blink ...]>. If you only want a section to be read when the value of an environment variable does not equal something: C<[env=HOSTNAME!=blink ...]> or C<[SOMESECTION env=HOSTNAME!=blink ...]>. If you only want a section to be read when an environment variable contains something: C<[env=HOSTNAME*=server ...]> or C<[SOMESECTION env=HOSTNAME*=server ...]>. Note that currently due to simplistic parsing, there must not be any whitespace in the value being compared because it marks the beginning of a new section filter or section name.
 
List of available configuration parameters:
 
 client_email (see --client-email)
 client_id (see --client-id)
 format (see --format)
 log_level (see --log-level)
 naked_res (see --naked-res)
 restore_domains (see --no-restore-domains)
 restore_hostings (see --no-restore-hostings)
 restore_invoices (see --no-restore-invoices)
 sql_backup_dir (see --sql-backup-dir)
 sql_backup_file (see --sql-backup-file)
 
=head1 ENVIRONMENT
 
=head2 RESTORE_WHMCS_CLIENT_OPT => str
 
Specify additional command-line options.
 
=head1 FILES
 
F<~/.config/restore-whmcs-client.conf>
 
F<~/restore-whmcs-client.conf>
 
F</etc/restore-whmcs-client.conf>
 
=head1 HOMEPAGE
 
Please visit the project's homepage at L<https://metacpan.org/release/App-WHMCSUtils>.
 
=head1 SOURCE
 
Source repository is at L<https://github.com/perlancar/perl-App-WHMCSUtils>.
 
=head1 BUGS
 
Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-WHMCSUtils>
 
When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.
 
=head1 AUTHOR
 
perlancar <perlancar@cpan.org>
 
=head1 COPYRIGHT AND LICENSE
 
This software is copyright (c) 2019, 2018, 2017 by perlancar@cpan.org.
 
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
 
=cut