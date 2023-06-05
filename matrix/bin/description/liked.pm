#!/usr/bin/perl

# References in Perl are like names for arrays 
# and hashes. They're Perl's private, internal names, 
# so you can be sure they're unambiguous. Unlike a human 
# name, a reference only refers to one thing, and you 
# always know what it refers to. If you have a reference 
# to an array, you can recover the entire array from it. 
# If you have a reference to a hash, you can recover the 
# entire hash. But the reference is still an easy, 
# compact scalar value.

#!/usr/bin/perl -w
#
# rezrov: a pure perl z-code interpreter
#
# Copyright (c) 1998-(infinity+1), Michael Edmonson. All rights reserved.
# This program is free software; you may redistribute it and/or modify
# it under the same terms as Perl itself.
#
# One of these email addresses "should" always work:
#
#   edmonson@sdf.lonestar.org
#   mn_edmonson@world.oberlin.edu
#
# "edmonson@poboxes.com" and "mikeedmo@voicenet.com" are defunct.
 
# standard modules:
use strict;
use Getopt::Long;
use 5.005;
 
# local modules:
 
$main::VERSION = $main::VERSION = '0.20';
# twice to shut up perl -w
 
my %FLAGS;
 
use constant TK_VERSION_REQUIRED => 800;
 
use constant SPECIFIED => 1;
use constant DETECTING => 2;
 
use constant OPTIONS =>
  (
   # interface selection:
   "tk",
   "dumb",
   "curses",
   "termcap",
   "win32",
   "test",
      
   "game=s",
   # game to run
 
   "speak",
   # enable speech synthesis
 
   "listen",
   # enable speech recognition
 
   # color control options:
   "fg=s",
   "bg=s",
   "sfg=s",
   "sbg=s",
   "cc=s",
    
   # font control (tk only):
   "fontsize=i",
   "family=s",
 
   # tk-related graphics options
   "x=i",
   "y=i",
   "fontspace=i",
   "blink=i",
 
   # other interface controls:
   "no-title",
   "no-graphics",
   "rows=s",
   "columns=s",
   "max-scroll",
   "flaky=i",
 
   # other
   "player=i",
   "highlight-objects",
   "cheat",
   "snoop-obj",
   "snoop-properties",
   "snoop-attr-set",
   "snoop-attr-test",
   "snoop-attr-clear",
   "count-opcodes",
   "debug:s",
   "undo=i",
   "readline=i",
   "playback=s",
   "playback-die",
   "id=i",
   "tandy",
   "hack=i",
   "shameless=i",
   "force",
   "checksum",
   "24h",
   "eos=i",
   "typo=i",
   "test-recog",
  );
 
unless (GetOptions(\%FLAGS, OPTIONS)) {
  die sprintf("Legal options are:\n  %s\nSee \"perldoc rezrov\" for documentation.\n", join "\n  ", column_list([ sort map {"-" . $_} OPTIONS ]))
}
 
if ($FLAGS{"fg"} or $FLAGS{"bg"}) {
  die "You must specify both -fg and -bg\n" unless $FLAGS{"fg"} and $FLAGS{"bg"};
}
 
#
# set options:
#
Games::Rezrov::ZOptions::SNOOP_OBJECTS($FLAGS{"snoop-obj"} ? 1 : 0);
Games::Rezrov::ZOptions::SNOOP_ATTR_CLEAR($FLAGS{"snoop-attr-clear"} ? 1 : 0);
Games::Rezrov::ZOptions::SNOOP_ATTR_SET($FLAGS{"snoop-attr-set"} ? 1 : 0);
Games::Rezrov::ZOptions::SNOOP_ATTR_TEST($FLAGS{"snoop-attr-test"} ? 1 : 0);
Games::Rezrov::ZOptions::SNOOP_PROPERTIES($FLAGS{"snoop-properties"} ? 1 : 0);
 
Games::Rezrov::ZOptions::GUESS_TITLE($FLAGS{"no-title"} ? 0 : 1);
Games::Rezrov::ZOptions::MAXIMUM_SCROLLING($FLAGS{"max-scroll"} ? 1 : 0);
Games::Rezrov::ZOptions::COUNT_OPCODES($FLAGS{"count-opcodes"} ? 1 : 0);
Games::Rezrov::ZOptions::WRITE_OPCODES(exists $FLAGS{"debug"} ? $FLAGS{"debug"} || "STDERR" : 0);
Games::Rezrov::ZOptions::TIME_24(exists $FLAGS{"24h"} ? 1 : 0);
Games::Rezrov::ZOptions::PLAYBACK_DIE(exists $FLAGS{"playback-die"} ? 1 : 0);
 
if (exists $FLAGS{"undo"}) {
  Games::Rezrov::ZOptions::EMULATE_UNDO($FLAGS{"undo"});
  Games::Rezrov::ZOptions::UNDO_SLOTS($FLAGS{"undo"});
} else {
  Games::Rezrov::ZOptions::EMULATE_UNDO(1);
  Games::Rezrov::ZOptions::UNDO_SLOTS(10);
}
 
if ($FLAGS{"player"}) {
  # force a particular object ID for the player
  Games::Rezrov::StoryFile::player_object($FLAGS{"player"});
}
 
Games::Rezrov::ZOptions::MAGIC(exists $FLAGS{"cheat"} ? 1 : 0);
Games::Rezrov::ZOptions::CORRECT_TYPOS(exists $FLAGS{"typo"} ? $FLAGS{"typo"} : 1);
Games::Rezrov::ZOptions::HIGHLIGHT_OBJECTS(exists $FLAGS{"highlight-objects"} ? 1 : 0);
 
if (exists $FLAGS{"id"}) {
  my $id = $FLAGS{"id"};
  die "Whoa there: ID must be between 1 and 11; see the documentation.\n"
    if ($id < 1 or $id > 11);
  Games::Rezrov::ZOptions::INTERPRETER_ID($id);
}
Games::Rezrov::ZOptions::TANDY_BIT(1) if exists $FLAGS{"tandy"};
Games::Rezrov::ZOptions::SHAMELESS($FLAGS{"shameless"}) if exists $FLAGS{"shameless"};
 
Games::Rezrov::ZOptions::END_OF_SESSION_MESSAGE($FLAGS{"eos"}) if exists $FLAGS{"eos"};
 
use constant INTERFACES => (
                            ["tk", "Tk", \&tk_validate ],
                            ["win32", "Win32::Console"],
                            # look for Win32::Console before Curses
                            # because setscrreg() doesn't seem to work
                            # w/Curses for win32 (5.004 bindist)
                            ["curses", "Curses"],
                            ["termcap", [ "Term::Cap", "POSIX" ], \&termcap_validate ],
                            ["dumb" ],
                            ["test" ],
                           );
# available interfaces
 
if ($FLAGS{"test-recog"}) {
  require Games::Rezrov::ZIO_dumb;
  my $zio = new Games::Rezrov::ZIO_dumb(
                                        "columns" => 80, "rows" => 25
                                       );
  $zio->test_speech_recognition();
  exit(0);
}
 
#
#  determine interface implementation to use:
#
my $zio_type = get_interface(SPECIFIED);
# check if user specified one
$zio_type = get_interface(DETECTING) unless $zio_type;
# none specified; guess the "best" one
 
#
#  Figure out name of storyfile
#
my $storyfile;
if ($FLAGS{"game"}) {
  $storyfile = $FLAGS{"game"};
} elsif (@ARGV) {
  $storyfile = $ARGV[0];
} elsif ($0 eq "test.pl") {
  # being run under "make test"
  $storyfile = "minizork.z3";
} else {
  die "You must specify a game file to interpret; e.g. \"rezrov zork1.dat\".\n";
}
 
die sprintf 'File "%s" does not exist.' . "\n", $storyfile
  unless (-f $storyfile);
 
#
#  Initialize selected i/o module
#
my $zio;
 
if ($zio_type eq "tk") {
  # GUI interface
  require Games::Rezrov::ZIO_Tk;
  $zio = new Games::Rezrov::ZIO_Tk(%FLAGS);
} elsif ($zio_type eq "win32") {
  # windows console
  require Games::Rezrov::ZIO_Win32;
  $zio = new Games::Rezrov::ZIO_Win32(%FLAGS);
} elsif ($zio_type eq "curses") {
  # smart terminal w/Curses
  require Games::Rezrov::ZIO_Curses;
  $zio = new Games::Rezrov::ZIO_Curses(%FLAGS);
} elsif ($zio_type eq "termcap") {
  # address terminal w/Term::Cap
  require Games::Rezrov::ZIO_Termcap;
  $FLAGS{"readline"} = 1 if (!exists($FLAGS{"readline"}) and exists $ENV{"TERM"});
  $zio = new Games::Rezrov::ZIO_Termcap(%FLAGS);
} elsif ($zio_type eq 'dumb') {
  # dumb terminal and/or limited perl installation
  require Games::Rezrov::ZIO_dumb;
  $FLAGS{"readline"} = 1 if (!exists($FLAGS{"readline"}) and exists $ENV{"TERM"});
  $zio = new Games::Rezrov::ZIO_dumb(%FLAGS);
} else {
  # REALLY dumb terminal
  require Games::Rezrov::ZIO_test;
  $zio = new Games::Rezrov::ZIO_test(%FLAGS);
}
 
my $story;
 
$SIG{"INT"} = sub {
  $zio->set_game_title(" ") if $story->game_title();
  #    $zio->fatal_error("Caught signal @_.");
  $zio->cleanup();
  exit 1;
};
 
#
#  Initialize story file
#
$story = new Games::Rezrov::StoryFile($storyfile, $zio);
Games::Rezrov::StoryFile::font_3_disabled(1) if $FLAGS{"no-graphics"};
my $z_version = Games::Rezrov::StoryFile::load(1);
 
#Games::Rezrov::ZOptions::GUESS_TITLE(0) unless $zio->can_change_title();
# always try to guess the title, for use w/"help" emulation
 
1;
&cont() unless $zio->set_version(($z_version <= 3 ? 1 : 0),
                                \&cont);
# Tk version invokes cont() itself, as a callback, since Tk's MainLoop blocks.
# A better way???
 
sub cont () {
  Games::Rezrov::StoryFile::setup();
  # complete inititialization
 
  if ($FLAGS{"hack"}) {
    # cheat development assistance; get operands for a 2OP opcode
    my $pc = $FLAGS{"hack"};
    my $opcode = Games::Rezrov::StoryFile::get_byte_at($pc++);
    die "not 2OP" unless ($opcode & 0x80) == 0;
    my $mask = 0x40;
    for (my $i=1; $i<=2; $i++) {
      my $thing = Games::Rezrov::StoryFile::get_byte_at($pc++);
      printf "operand %d: %s\n", $i, (($opcode & $mask) == 0) ?
        "literal $thing" : "get_var($thing)";
      $mask >>= 1;
    }
    exit;
  } elsif ($FLAGS{"checksum"}) {
    printf "Game checksum is: %d\n", Games::Rezrov::StoryFile::header()->file_checksum();
    exit;
  }
 
   
  #
  #  Start interpreter
  #
  if (0) {
    print STDERR "DEBUG! using ZInterpreter2\n";
    require Games::Rezrov::ZInterpreter2;
    my $zi = new Games::Rezrov::ZInterpreter2($zio);
  } else {
    my $zi = new Games::Rezrov::ZInterpreter($zio);
  }
}
 
sub tk_validate {
  # called to see if the version of the Tk module available on the system
  # is new enough.
  my $type = shift;
  my $ok;
  if ($Tk::VERSION >= TK_VERSION_REQUIRED) {
    # OK
    $ok = 1;
  } elsif ($type == SPECIFIED) {
    # user specifically asked to use Tk
    die sprintf "I need Tk %s or later, you seem to have version %s.  Pity.\n", TK_VERSION_REQUIRED, $Tk::VERSION;
  } elsif ($type == DETECTING) {
    # just trying to figure out whether we can use Tk; nope!
    $ok = 0;
  } else {
    die;
  }
 
  if ($ok and
      $^O !~ /win/i and
      !$ENV{DISPLAY} and
      (!exists $FLAGS{"force"})) {
    # On Unix systems, Tk requires the DISPLAY variable be set.
    # Even though Tk is installed, the user might not be running X.
    # Avoid fatal "couldn't connect to display" error message from Tk.
    if ($type == SPECIFIED) {
      die "Your DISPLAY variable doesn't seem to be set.\nUse the -force switch if you think you don't need it.\n";
    } else {
      $ok = 0;
    }
  }
 
  return $ok;
}
 
sub get_interface {
  my ($search_type) = @_;
 INTERFACE:
  foreach (INTERFACES) {
    my ($name, $modules, $validate_sub) = @{$_};
    my @modules = $modules ? 
      (ref $modules ? @{$modules} : ($modules)) : ();
    if ($search_type == SPECIFIED) {
      #
      # we're looking to see if the user specified a particular type
      #
      if ($FLAGS{$name}) {
        # they did (this one)
        foreach (@modules) {
          my $cmd = 'use ' . $_ . ";";
#         print STDERR "eval: $cmd\n";
          eval $cmd;
          die sprintf "You can't use -%s, as the module %s is not installed.\nPity.\n", $name, $_ if $@;
        }
        if ($validate_sub) {
          next unless &$validate_sub($search_type);
        }
        return $name;
        # OK
      }
    } elsif ($search_type == DETECTING) {
      #
      #  we're trying to find the "nicest" interface to use.
      #
      if (@modules) {
        foreach (@modules) {
          my $cmd = 'use ' . $_ . ";";
#         print STDERR "eval: $cmd\n";
          eval $cmd;
          next INTERFACE if $@;
        }
        if ($validate_sub) {
          next unless &$validate_sub($search_type);
        }
        return $name;
        # OK
      } else {
        # no requirements, OK
        return $name;
      }
    } else {
      die;
    }
  }
  return undef;
}
 
sub column_list {
  # print a list in "column" format
  my ($list, %options) = @_;
 
  my $longest = 0;
  foreach (@{$list}) {
    my $len = length($_);
    $longest = $len if $len > $longest;
  }
  $longest += 2;
  my $columns = int(75 / $longest);
  my $format_one = "%-" . $longest . "s";
  my @results;
  my @list = @{$list};
  while (@list) {
    my $count = @list < $columns ? @list : $columns;
    my $format = $format_one x $count;
    push @results, sprintf $format, splice(@list,0,$columns);
  }
  return @results;
}
 
sub termcap_validate {
  my ($val_type) = @_;
 
  eval {
    my $termios = new POSIX::Termios();
    $termios->getattr();
    my $ospeed = $termios->getospeed();
    my $tc = Tgetent Term::Cap { TERM => undef, OSPEED => $ospeed };
   
    $tc->Trequire('ce');
    # "ce" = clear to end of line
  };
 
  if ($@) {
    # problem!
    my $invalid_termcap = ($@ =~ /^Can\'t find a valid termcap file/);
 
    my $mac_osx = $^O eq "darwin";
    $ENV{TERM} = "xterm" if $mac_osx and $ENV{TERM} eq "vt100";
    # HACK: under OS X, default TERM type seems to be "vt100" but this
    # doesn't seem to work right if ESR's termcap file is installed.
    # However, "xterm" seems to work fine!
    # So, Think Different.  :P
 
    if ($val_type == SPECIFIED) {
      # user specifically asked for Termcap; explain problem
      my $msg = "-termcap: sorry, ";
      if ($invalid_termcap) {
        $msg .= "you don't seem to have a termcap file installed!";
      } else {
        $msg .= sprintf "can't use termcap due to this error:\n%s", $@;
      }
      die $msg . "\n";
    } elsif ($mac_osx and $invalid_termcap) {
      # HACK: under OS X, /etc/termcap doesn't appear to be installed
      # (as of fall 2003), but system perl comes with Term::Cap built in.
      # Works fine if you:
      #  1. Get a termcap file from http://catb.org/~esr/terminfo/
      #     and install it in /etc
      #  2. set your TERM to "xterm" rather than "vt100"
      print "You appear to be running on a Mac which doesn't seem to\n";
      print "have a termcap file installed.  Try downloading one from:\n";
      print "\n";
      print "  http://catb.org/~esr/terminfo/\n";
      print "\n";
      print "...and copying it to \"/etc/termcap\".\n";
      print "Otherwise, I can only use the dumb (read \"ugly\") interface.\n";
       
      print "Press <RETURN> to continue...\n";
      my $line = <STDIN>;
    }
    return 0;
  } else {
    return 1;
  }
}
 
__END__

 
=head1 NAME
 
rezrov - a pure Perl Infocom (z-code) game interpreter
 
=head1 SYNOPSIS
 
rezrov game.dat [flags]
 
=head1 DESCRIPTION
 
Rezrov is a program that lets you play Infocom game data files.
Infocom's data files (e.g. "zork1.dat") are actually
platform-independent "z-code" programs written for a virtual machine
known as the "z-machine".  Rezrov is a z-code interpreter which can
run programs written in z-code versions 3 through 5 (nearly complete
support) and 8 (limited support).
 
Rezrov's chief distinguishing feature among z-code interpreters is its
cheat commands.  It also features basic speech synthesis and
recognition capabilities (when running under Windows, using the SAPI4
interface).
 
=head1 INTERFACES
 
I/O operations have been abstracted to allow the games to be playable
through any of several front-end interfaces.  Normally rezrov tries to
use the "best" interface depending on the Perl modules available on
your system, but you can force the use of any of them manually.
 
=head2 Dumb
 
Designed to work on nearly any Perl installation.  Optionally uses
Term::ReadKey and/or local system commands to guess the terminal size,
clear the screen, and read the keyboard.  Optionally uses
Term::ReadLine to provide line-editing history, assuming a backend
readline module is available (e.g. Term::ReadLine::Perl).  While there
is no status line or multiple window support, this interface is
perfectly adequate for playing most version 3 games.  Usage of the
dumb interface can be forced with the "-dumb" command-line switch.
 
=head2 Termcap
 
Makes use of the standard Term::Cap module to provide support for a
status line and multiple windows.  Usage of the Termcap interface can
be forced with "-termcap".
 
=head2 Curses
 
Use the Curses module to improve upon the features available in the
Termcap interface, adding support for color, clean access to all the
lines on the screen, better keyboard handling, and some support for
character graphics.  Some problems remain: if you specify screen
colors, the terminal may not be reset correctly when the program
exits.  Also, I've only tested this with a few versions of Curses
(Linux/ncurses and Digital Unix's OEM curses), and was unpleasantly
surprised by the difficulties I encountered getting this to work
properly under both of them.  Can be forced with "-curses".
 
=head2 Windows console
 
Uses the Win32::Console module to act much like the Curses version.
Only works under win32 (Windows 95, 98, etc).  Force with "-win32".
 
=head2 Tk
 
Uses the Tk module; supports variable-width fonts and color.  Requires
the 800+ series of Tk; tested under Linux and the ActiveState binary
distribution of perl under win32.  Force with "-tk".
 
=head2 Test
 
The simplest output model, even more stripped-down than the Dumb
interface.  It is meant for use in automated testing rather than
interactive play, and to have no external dependencies.  The interface
has the following restrictions:
 
=over 4
 
=item *
 
Terminal size detection is disabled.  The geometry defaults to 80
columns by 25 rows, which may be overridden on the command line
with the -columns and -rows switches.
 
=item *
 
The [MORE] prompt is disabled.  This allows for scripts (see
"-playback") to run commands producing large amounts of text without
the interpreter thinking it needs to pause for the user to read them.
 
=item *
 
The status line is ignored, as are attempts to clear the screen or
move the cursor.
 
=item *
 
The upper window is not available, and all output to it is silently
suppressed.  Unlike the "dumb" interface, no warning message will be
generated in a game attempts to use the upper window.
 
=item *
 
Single-character input is not available, breaking some input styles
and prompts.
 
=back
 
Obviously this interface is only appropriate for games with the
simplest I/O requirements.  On the other hand, it "should" work on any
Perl installation.  I've received some reports from CPAN testers where
even the "dumb" interface fails in ways I can't reproduce, probably
related to the gyrations that module goes through to perform
single-character input (via GetKey.pm) and detect the screen size (via
GetSize.pm).  Hopefully this interface will address these problems,
and so test.pl now uses it.  Use the "-test" command-line switch to
enable.
 
=head1 FEATURES
 
=head2 Advanced command emulation
 
Rezrov emulates a number of in-game commands which were either not or
only sporadically available in version 3 games:
 
=over 4
 
=item *
 
B<undo>: undoes your previous turn.  This allows you to recover from
foolish or irresponsible behavior (walking around in the dark, jumping
off cliffs, etc) without a saved game.  You can undo multiple turns by
repeatedly entering "undo"; the -undo switch can be used to specify
the maximum number of turns that may be undone (default is 10).
 
=item *
 
B<oops>: allows you to specify the correct spelling for a word you
misspelled on the previous line.  For example:
 
  >give lmap to troll
  I don't know the word "lmap".
   
  >oops lamp
  The troll, who is not overly proud, graciously accepts the
  gift and not having the most discriminating tastes,       
  gleefully eats it.                                        
  You are left in the dark...   
 
=item *
 
B<notify>: has the game tell you when your score goes up or down.  This
is especially useful when playing without a status line (ie with the
"dumb" interface).
 
=item *
 
B<#typo>: toggles typo correction on or off.  This
feature attempts to automatically correct misspelled words by
comparing them to words in the game's internal dictionary.  This is
modeled after the algorithm used by the Nitfol interpreter:
 
  If the entered word is in the dictionary, behave normally.
 
  If the length of the word is less than 3 letters long, give up.
  We don't want to make assumptions about what very short words
  might be.
 
  If the word is the same as a dictionary word with one
  transposition, assume it's that word ("exmaine" becomes
  "examine").
 
  If it is a dictionary word with one deleted letter, assume it's
  that word ("botle" becomes "bottle").
 
  If it is a dictionary word with one inserted letter, assume it's
  that word ("tastey" becomes "tasty").
 
  If it is a dictionary word with one substitution, assume it's 
  that word ("opin" becomes "open").
 
While often helpful, typo correction may not be desirable in some
games where the user can (or is expected to) use non-dictionary words.
This is a problem for example in Spellbreaker, where the user can
label objects and then refer to them by those labels.  Unfortunately,
these user-defined names are not recognized by the typo correction
code as legitimate because they are not stored in the game's
dictionary.  Apparently a similar problem occurs in Beyond Zork,
possibly related to that game's environmental randomization features
(anyone?).
 
Typo correction is enabled by default, and can be disabled on the
command line with "-typo 0".
 
=item *
 
B<#reco>: Writes a transcript of the commands you enter to the file
you specify.
 
=item *
 
B<#unre>: Stops transcripting initiated by the #reco command.
 
=item *
 
B<#comm>: Plays back commands from the transcript file you specify.
You can also start a game with recorded commands by specifying the
"-playback" command-line option.
 
=back
 
Rezrov also expands the following "shortcut" commands for games
that do not support them:
 
    x = "examine"
    g = "again"
    z = "wait"
    l = "look"
    o = "oops"
 
=head2 Cheating
 
The "-cheat" command-line parameter enables the interpretation of
several fun new verbs.  Using these commands in a game you haven't
played honestly will most likely ruin the experience for you.
However, they can be entertaining to play around with in games you
already know well.  Note that none of them work if the game
understands the word they use; for example, "Zork I" defines "frotz"
in its dictionary (alternate verbs are available).  You can turn
cheating on and off from within the game by entering "#cheat".
 
=over 4
 
=item *
 
B<teleport, #teleport>: moves you to any room in the game.  For example:
"teleport living room".  Location names are guessed so they all might
not be available; see "rooms" command below.  If you specify the name
of an item, rezrov will attempt to take you to the room where the
item is located.
 
=item *
 
B<pilfer>: moves any item in the game to your current location, and
then attempts to move it into your inventory.  For example: "pilfer
sword".  Doesn't work for some objects (for example, the thief from
Zork I).  Can be dangerous -- for example, pilfering the troll from
Zork I can be hazardous to your health.
 
  Robot Shop
  This room, with exits west and northwest, is filled with
  robot-like devices of every conceivable description, all in
  various states of disassembly.
  Only one robot, about four feet high, looks even remotely
  close to being in working order.
 
  >open robot
  In one of the robot's compartments you find and take a
  magnetic-striped card embossed "Loowur Elavaatur Akses
  Kard."
 
  >turn on robot
  Nothing happens.
 
  >wait
  Time passes...
 
  Suddenly, the robot comes to life and its head starts
  swivelling about. It notices you and bounds over. "Hi! I'm
  B-19-7, but to everyperson I'm called Floyd. Are you a
  doctor-person or a planner-person? That's a nice lower
  elevator access card you are having there. Let's play
  Hider-and-Seeker you with me."
 
  >show access card to floyd
  "I've got one just like that!" says Floyd. He looks
  through several of his compartments, then glances at you
  suspiciously.
 
                                      - "Planetfall", 1983
 
I'd be very curious to know about any easter eggs this command might
uncover.  For example, in Planetfall there is a blacked-out room you
can't see anything in.  There's a lamp in the game, but it's located
in a lab full of deadly radiation.  You can enter the lab and take the
lamp, but will die of radiation poisoning before you can make it back
to the darkened room.
 
I always wondered, if you could get the lamp somehow, what was in the
dark room?  Now you can find out.
 
=item *
 
B<bamf>: makes the object you specify disappear from the game.  For
example: "bamf troll".  This works nicely for some objects but less so
for others.  For example, in Zork I the troll disappears obligingly,
but the bamf'ing the cyclops doesn't help.
 
=item *
 
B<frotz, futz, lumen>: attempts to emulate the "frotz" spell from
Enchanter, which means "cause something to give off light."  It can
turn any item into a light source, thus obviating the need to worry
about your lamp/torch running out while you wander around in the dark.
I would have liked to just use the word "frotz"; unfortunately Zorks
I-III define that word in their dictionaries (interesting, as these
games predate Enchanter), and I am reluctant to interfere with its
"original" use in those games (if any?).
 
While this is just a simple tweak, turning on a particular object
property, exactly *which* property varies by game and I know of no
easy way to determine this dynamically, so at present this only works
in a few games: Zork I, Zork II, Zork III, Zork: The Undiscovered
Underground, Infidel, and Planetfall (I'm taking requests).
 
=item *
 
B<tail>: follow a character in the game -- as they move from room to
room, so do you.  Also allows you to follow characters where you
ordinarily aren't allowed to, for example the unlucky Veronica from
"Suspect".
 
=item *
 
B<travis>: attempts to fool the game into thinking the object
you specify is a weapon.  Like "frotz" this is very game-specific; it
only works in Zork I at present:
 
    >i
    You are carrying:                        
      A brass lantern (providing light)
      A leaflet
 
    >north
    The Troll Room
    This is a small room with passages to the east and south
    and a forbidding hole leading west. Bloodstains and deep
    scratches (perhaps made by an axe) mar the walls.
    A nasty-looking troll, brandishing a bloody axe, blocks all
    passages out of the room.
 
    >kill troll with leaflet                         
    Trying to attack the troll with a leaflet is suicidal.
 
    >travis leaflet
    The leaflet glows wickedly.                             
 
    >kill troll
    (with the leaflet)                                         
    Your leaflet misses the troll by an inch.                               
    The axe crashes against the rock, throwing sparks!
 
    >g
    You charge, but the troll jumps nimbly aside.
    The troll's axe barely misses your ear.
 
    >g
    It's curtains for the troll as your leaflet removes his head.
    Almost as soon as the troll breathes his last breath, a
    cloud of sinister black fog envelops him, and when the fog
    lifts, the carcass has disappeared.
 
    >
 
=item *
 
B<lummox>: Removes all practical limitations on the weight and total
number of items you can carry.  Very game-specific; only works in Zorks
I-III and Planetfall for now.
 
=item *
 
B<voluminus>: Increases the number of items which may be held in containers.
Works in Zork I only for now.
 
=item *
 
B<systolic>: Lowers your blood pressure in the game "Bureaucracy".  In
"Bureaucracy," using a word unknown to the game or entering an empty
line bumps up your character's blood pressure.  A few such missteps
and you drop dead of a stroke.  Bureaucracy is too effective by half;
this "feature" alone irritated me so much I never got far in the game.
This cheat should make the game a little more bearable to play.
See also the superior "angiotensin" command, below.
 
=item *
 
B<angiotensin>: A cheat that mimics taking medication for your chronic
high blood pressure in the game "Bureaucracy".  It works by resetting
your BP to normal in-between turns.  While it's still possible to
stroke out by leaning on the enter key, in normal play this cheat
should immunize you from Bureaucracy's blood pressure annoyances.
Note that the cheat is part of the interpreter and not the game, and
so will not stay in effect if you restore a game or restart.  So in
short, "Bureaucracy" is still annoying despite my best efforts.  I
wonder if Douglas Adams might have approved.
 
=item *
 
B<embezzle>: sets your score in version 3 games to the value you
specify.  Useful for "finishing" games in a hurry.  You could use this
to quickly see the effects of the Tandy bit on the ending of Zork I,
for example.
 
=item *
 
B<gmacho>: intended for the Enchanter series, this cheat copies any
spell in the game to your spellbook, even those which are too complex
for "gnusto".  Once in your spellbook, even these powerful spells may
be memorized and cast repeatedly.  Possession of the scroll the spell
is written on is not necessary.  Presumably this cheat won't let you
do much new because of the sandboxing of powerful and uniquely-used
spells, but who knows?  Supported in Enchanter, Sorcerer, and
Spellbreaker.
 
=item *
 
B<verdelivre>: intended for the Enchanter series, attempts to copy
every spell in the game to your spellbook.  See "gmacho".
 
=item *
 
B<vilify>: A silly cheat which tries to make the game think
the object you specify is attackable.  Like "frotz" this is very
game-specific; it only works in Zork I at present.
Show that mailbox what for:
 
   West of House
   You are standing in an open field west of a white house,
   with a boarded front door.
   There is a small mailbox here.
 
   >kill mailbox
   (with the sword)
   I've known strange people, but fighting a small mailbox?
 
   >vilify mailbox
   That small mailbox is really asking for trouble.
 
   >kill mailbox
   (with the sword)
   Clang! Crash! The small mailbox parries.
   Your sword has begun to glow very brightly.
 
   >g
   The quickness of your thrust knocks the small mailbox
   back, stunned.
 
=item *
 
B<baste, nosh>: Another silly cheat which attempts to make the game think
the specified object is edible.  Only works in Zork I for now.
 
=item *
 
B<lingo>: prints out all the words in the dictionary.
 
=item *
 
B<spiel>: attempts to decode all the text in the game by brute force.
This basically walks through every memory location in the game and
tries to decode it as if it were encoded z-characters.  There are a
lot of hacks here to attempt to filter out junky text.  I put this in
to try and uncover easter eggs or funny things in games that I'd never
run into while playing.  For example, here's a little tidbit from Zork
I that I'd never seen before, probably a message for an "impossible"
case that you were never supposed to encounter:
 
  It takes a talented person to be killed while already dead. YOU are
  such a talent. Unfortunately, it takes a talented person to deal
  with it. I am not such a talent. Sorry.
 
spiel takes up to 3 arguments, all optional.  The first argument
is the memory address to start decoding text.  The default is the 
start of static memory, which is often a bit early.  20000 is usually
a good starting point for version 3 games.  The second argument
is the level of detail to show.  This is a number from 1 to 4:
 
1: Unconditionally show whatever's decoded from each possible address.
 
2: Like 1, but if a chunk of text is decoded that passes the various junk filters, continues decoding after it rather than at the next byte.  Still shows "bad" text.
 
3: don't show text I suspect is junky.  Subjective but pretty effective.
 
4: only show text we're highly confident of.  This is the default setting.
 
The third argument is the minimum number of decoded words that must be
present in a fragment to consider it good under most circumstances.
Defaults to 3.
 
=item *
 
B<rooms>: print a list of rooms/locations in the game.  This is a
rough guess based on descriptions taken from the game's object table,
and so may contain a few mistakes.
 
=item *
 
B<items>: print a list of items in the game.  Like "rooms", this is a
rough guess based on descriptions taken from the game's object table.
 
=item *
 
B<omap>: prints a report of the objects in the game, indented by
parent-child relationship.
 
=item *
 
B<#serials>: displays the Z-machine version, release number, serial
number, and checksum of the current game (a few more technical
details that are shown by the traditional "version" command).
 
=back
 
=head2 Speech synthesis and recognition
 
=over 4
 
Speech synthesis and recognition capabilities are available under
Windows via the Win32::SAPI4 Perl module, which must be installed
separately, along with Microsoft's SAPI4 speech API distribution.  As
of this writing (March 2004), SAPI4 seems to be on the verge of being
obsoleted by Microsoft, but it works fine on my Windows XP system.
The API distribution is about a 40 MB download, search for
"SAPI4SDKSUITE.EXE".  Here's one link, though YMMV:
 
 http://download.microsoft.com/download/speechsdk/Install/4.0a/win98/EN-US/SAPI4SDKSUITE.EXE
 
=item B<-speak>
 
Command-line option to enable speech synthesis (you may also type
"#speak" during the game at the command prompt to toggle it on or
off).  When speech synthesis is enabled, the game will speak the game
text as well as print it to the screen.  This will not work well with
games using multiple windows.
 
=item B<-listen>
 
Command-line option to enable speech recognition (you may also type
"#listen" at the command prompt to enable it).  When speech
recognition is enabled, the game will listen for you to speak commands
into your computer's microphone rather than type them at the keyboard.
Once enabled, control will only be returned to the keyboard if
dictation is disabled in the Microsoft Dictation control panel.  In
future releases of Rezrov, event-driven interfaces (such as Tk) may
allow simultaneous voice and keyboard input.
 
The SAPI4 speech recognition API requires voice training to work well.
Use the Microsoft Voice and Dictation tools to set up your microphone
and train the system to recognize your voice.  Be sure you are able to
run the Microsoft Dictation pad and dictate with reasonable success 
before attempting to use voice recognition with Rezrov.
 
Dictation B<must> be enabled within the Microsoft Dictation
application for speech recognition to work.
 
Rezrov's speech recognition support should be considered highly
experimental, and it can be a pain to get running.  But it's fun when
it works!
 
=item B<-test-recog>
 
Command-line option to enter speech recognition debugging mode.  This
will display speech recognition events as they are processed by the
system.  More work needs to be done to explain incoming events.
 
=back
 
=head2 Snooping
 
Several command-line flags allow you to observe some of the internal
machinations of your game as it is running.  These options will
probably be of limited interest to most people, but may be the
foundation of future trickery.
 
=over 4
 
=item B<-snoop-obj>
 
Whenever an object in the game is moved, it tells you the name
of the object and where it was moved to.  Using this feature
you can, among other things, see the name Infocom assigned to
the "player" object in a number of their early games:
 
 West of House
 There is a small mailbox here.
 
 >north
 [Move "cretin" to "North of House"]
 North of House                     
 You are facing the north side of a white house. There is no
 door here, and all the windows are boarded up. To the north
 a narrow path winds through the trees.
 
=item B<-snoop-properties>
 
Each object in the game has a list of properties associated with it.
This flag lets you see when object properties are changed.  As an
example, in my version of Zork 1 the "blue glow" given off by the
sword in the presence of enemies is property number 12 (1 for "a faint
blue glow" and 2 for "glowing very brightly").
 
=item B<-snoop-attr-set>
 
Likewise, each object has an associated list of single-bit attributes.
This flag lets you observe when object attributes are set.  As an
example, in my version of Zork I the "providing light" attribute is
number 20.  Tweaking of this attribute is the foundation of "frotz"
emulation (see "Cheating" below).
 
=item B<-snoop-attr-test>
 
This option lets you see when object attributes are tested.
 
=item B<-snoop-attr-clear>
 
This option lets you see when object attributes are cleared.
 
=item B<-highlight-objects>
 
Highlights object descriptions in the text printed out via the
B<print_obj> opcode (1OP, 0x0a).
 
=back
 
=head2 Interface flags
 
=over 4
 
=item B<-fg, -bg>
 
If the interface you want to use supports colored text, this allows
you to specify foreground (text) and background colors used in the
game.  If you specify one you must specify the other, i.e. you cannot
specify just the foreground or background color.  Example: "-fg white
-bg blue".
 
When using the Curses interface, allowable colors are black, blue,
cyan, green, magenta, red, white, and yellow.
 
When using the Win32::Console interface, allowable colors are black,
blue, lightblue, red, lightred, green, lightgreen, magenta,
lightmagenta, cyan, lightcyan, brown, yellow, gray, and white.  Note
that the program tries to shift to lighter colors to simulate "bold"
text attributes: bold blue text uses lightblue, bold gray text uses
white, etc.  For this reason it looks best if you not use white or any
of the "light" colors directly (for "white" text, specify "gray").
 
=item B<-sfg, -sbg>
 
Specifies the foreground and background colors use for the status line
in version 3 games; the same restrictions apply as to -fg and -bg.
These must also be used as a pair, and -fg and -bg must be specified
as well.  Example: "-fg white -bg blue -sbg black -sfg white".
 
=item B<-cc>
 
Specifies the color of the cursor.  At present this only works for the
Tk interface, and defaults to black.  Note that if the game changes
the screen's background color to the cursor color, the cursor color
will be changed to the foreground color to prevent it from
"disappearing".  This happens in "photopia", for example.
 
=item B<-columns, -rows>
 
Allows you to manually specify the number of columns and/or lines in
your display.
 
=item B<-max-scroll>
 
Updates the screen with every line printed, so scrolling is always
visible.  As this disables any screen buffering provided by the I/O
interface it will slow things down a bit, but some people might like
the visual effect.
 
=back
 
=head2 Tk-specific flags
 
=over 4
 
=item B<-family [name]>
 
Specifies the font family to use for variable-width fonts.  Under
win32, this defaults to "Times New Roman".  On other platforms
defaults to "times".
 
=item B<-fontsize [points]>
 
Specifies the size of the font to use, as described in Tk::Font.
Under win32 this defaults to 10, on other platforms it defaults to 18.
If your fonts have a "jagged" appearance under X you should probably
experiment with this value; for best results this should match a
native font point size on your system.  You might also try using the
"xfstt" TrueType font server, which I've had very good results with
under Linux.
 
=item B<-blink [milliseconds]>
 
Specifies the blink rate of the cursor, in milliseconds.
The default is 1000 (one second).  To disable blinking entirely,
specify a value of 0 (zero).
 
=item B<-x [pixels]>
 
Specifies the width of the text canvas, in pixels.  The default
is 70% of the screen's width.
 
=item B<-y [pixels]>
 
Specifies the height of the text canvas, in pixels.  The default
is 60% of the screen's height.
 
=back
 
=head2 Term::ReadLine support
 
If you have the Term::ReadLine module installed (and a backend such as
Term::Readline::Perl), support for it is available in the dumb,
termcap, and curses interfaces.  By default support is enabled in the
"dumb" module and "termcap" interfaces, and disabled in the curses
interfaces (because it doesn't work right C<:P> ).  You can
enable/disable support for it with the "-readline" flag: "-readline 1"
enables support, and "-readline 0" disables it.
 
=head2 Miscellaneous flags
 
=over 4
 
=item B<-24h>
 
Displays the game time in "time" games (Deadline, Suspect, etc) in
24-hour format rather than 12-hour AM/PM format.
 
=item B<-no-graphics>
 
Disables usage of the "font 3" character graphics font.  Generally
only has meaning in Beyond Zork when using the Tk or Curses interfaces.
Font 3 support is incomplete so you'll probably need this if you're
playing Beyond Zork for any length of time.
 
=item B<-debug [file]>
 
Writes a log of the opcodes being executed and their arguments.  If a
filename is specified, the log is written to that file, otherwise it
is sent to STDERR.
 
=item B<-count-opcodes>
 
Prints a count and summary of the opcodes executed by the game between
your commands.
 
=item B<-undo turns>
 
Specifies the number of turns that can be undone when emulating the
"undo" command; the default is 10 turns.
 
Undo emulation works by creating a temporary saved game in memory
between every command you enter.  To disable undo emulation entirely,
specify a value of zero (0).
 
=item B<-playback file>
 
When the game starts, reads commands from the file specified instead
of the keyboard.  Control is returned to the keyboard when there are
no more commands left in the file.  Useful for testing, especially 
with the "-test" output interface.
 
=item B<-no-title>
 
Disables rezrov's attempts to guess the name of the game you're
playing for use in the title bar.  To guess the title, rezrov actually
hijacks the interpreter before your first command, submitting a
"version" command and parsing the game's output.  This can slow the
start of your game by a second or so, which is why you might want to
turn it off.  This also currently causes problems with the Infocom
Sampler (sampler1_R55.z3) and Beyond Zork, for which title guessing
is automatically disabled.
 
=item B<-id>
 
Specifies the ID number used by the interpreter to identify itself to
the game.  These are the machine ID numbers from section 11.1.3 of
Graham Nelson's z-machine specification (see acknowledgments section):
 
   1   DECSystem-20     5   Atari ST           9   Apple IIc
   2   Apple IIe        6   IBM PC            10   Apple IIgs
   3   Macintosh        7   Commodore 128     11   Tandy Color
   4   Amiga            8   Commodore 64
 
The default is 6, IBM PC.  This only seems to affect gameplay for a
few games, notably "Beyond Zork".
 
=head1 GOALS
 
My primary goal has been to write a z-code interpreter in Perl which
is competent enough to play my favorite old Infocom games, which are
mostly z-code version 3.  Infocom's version 3 games are Ballyhoo,
Cutthroats, Deadline, Enchanter, The Hitchhiker's Guide To The Galaxy,
Hollywood Hijinx, Infidel, Leather Goddesses of Phobos, The Lurking
Horror, Moonmist, Planetfall, Plundered Hearts, Seastalker, Sorcerer,
Spellbreaker, Starcross, Stationfall, Suspect, Suspended, Wishbringer,
The Witness, and Zork I, II, and III.  These all seem to work pretty
well under the current interpreter.
 
Version 4 and later games introduce more complex screen handling and
difficult-to-keep-portable features such as timed input.  Later games
also introduce a dramatic increase in the number of opcodes executed
between commands, making a practical implementation more problematic.
For example, consider the number of opcodes executed by the
interpreter to process a single "look" command:
 
                             Zork 1 (version 3):  387 opcodes
                            Trinity (version 4):  905 opcodes
 Zork: The Undiscovered Underground (version 5): 2186 opcodes (!)
 
While rezrov can run most of these games, if you seriously want to
*play* them I recommend you use an interpreter written in C, such as
frotz or zip; these are much faster and more accurate than rezrov.
 
A secondary goal has been to produce a relatively clean,
compartmentalized implementation of the z-machine that can be read
along with the Specification (see acknowledgments section).  Though
the operations of the interpreter are broken into logical packages,
performance considerations have kept me from strict OOP; more static
data remains than is Pretty.  The core StoryFile.pm package, formerly
quasi-OO, has been flattened to plain functional style in a crass
attempt to make the program run faster.  The Perl version is actually
based on my original version of rezrov, which was written in Java.
 
=head1 ACKNOWLEDGMENTS
 
rezrov would not have been possible to write without the work of the
following individuals:
 
=over 4
 
=item *
 
B<Graham Nelson> for his amazing z-machine specification:
 
 http://www.gnelson.demon.co.uk/zspec/
 
=item *
 
The folks at the B<IF-archive> for their repository:
 
 http://www.ifarchive.org/if-archive/README
 
=item *
 
B<Marnix Klooster> for "The Z-Machine, and How to Emulate It",
a critical second point of view on the spec:
 
 http://www.ifarchive.org/if-archive/infocom/interpreters/specification/zspec02/
 
=item *
 
B<Mark Howell> for his "zip" interpreter, whose source code made
debugging all my stupid mistakes possible:
 
 http://www.ifarchive.org/if-archive/infocom/interpreters/zip/
 
=item *
 
B<Martin Frost> for his Quetzal universal save-game file format, which is
implemented by rezrov:
 
 http://www.ifarchive.org/if-archive/infocom/interpreters/specification/savefile_14.txt
 
=item *
 
B<Evin Robertson>, author of the Nitfol z-code interpreter, for the
idea of automatic typo correction and the basic algorithm.
 
=item *
B<Neil Bowers> for contributing ZIO_Test.pm.
 
=item *
 
B<Andrew Plotkin> for "TerpEtude" (etude.z5), his suite of z-machine
torture tests.
 
=item *
 
B<Torbjorn Andersson> for his "strictz.z5", a suite of torture tests for
the (nonexistent) object 0.
 
=item *
 
B<Amir Karger> for the mighty (and humbling) "Czech" suite of
z-machine compliance tests, available from:
 
 http://www.ifarchive.org/if-archive/infocom/interpreters/tools/
 
=item *
 
B<Nick Ing-Simmons> for Tk.pm, B<William Seltzer> for Curses.pm,
B<Tony Sanders> for Term::Cap, B<Aldo Calpini> for
Win32::Console, and of course B<Larry Wall> and the perl development
team for Perl.
 
=item *
 
And lastly, the mighty Implementers:
 
 >read dusty book
 The first page of the book was the table of contents. Only
 two chapter names can be read: The Legend of the Unseen   
 Terror and The Legend of the Great Implementers.          
 
 >read legend of the implementers
 This legend, written in an ancient tongue, speaks of the
 creation of the world. A more absurd account can hardly be
 imagined. The universe, it seems, was created by          
 "Implementers" who directed the running of great engines. 
 These engines produced this world and others, strange and 
 wondrous, as a test or puzzle for others of their kind. It
 goes on to state that these beings stand ready to aid those
 entrapped within their creation. The great                 
 magician-philosopher Helfax notes that a creation of this  
 kind is morally and logically indefensible and discards the
 theory as "colossal claptrap and kludgery."                
 
                                      - "Enchanter", 1983
 
=back
 
=head1 BUGS
 
   Bug? Not in a flawless program like this! (Cough, cough).
                     - Zork I (encoded at byte 29292 of revision 88)
 
While I've tried, the interpreter is not fully compliant with the
specification in some areas.  With that said, I currently know of no
flaws that prevent version 3 games from being perfectly playable.
Version 4 games (A Mind Forever Voyaging, Bureaucracy, Nord and Bert
Couldn't Make Head or Tail of It, and Trinity) I'm less sure about,
this complicated by the fact that I haven't completed any of them C<:)>
Version 5 games (Beyond Zork, Border Zone, Sherlock) seem to work to
the limited extent I've played them, but there are a few unimplemented
opcodes that I have yet to see used.  The only version 8 game I've
tried has been "anchorhead", which runs, but is unbearably slow on my
P133.  YMMV.
 
=head1 HELP WANTED
 
Things I need:
 
=over 4
 
=item *
 
Any examples of bugs or crashes.
 
=item *
 
Any suggestions to improve execution speed.
 
=item *
 
An example of where typo correction doesn't work in Beyond Zork so I
can document it.
 
=item *
 
 
A saved game from Seastalker, from just before the sonar scope is
used.  This is (I think) the only example of a version 3 game
splitting the screen, and I'd like to test it.  I know for sure it
won't work correctly now.
 
=item *
 
Command transcripts/walkthroughs for version 4 games, for testing
purposes.  On second thought, I should really play Trinity first.
 
=item *
 
Feedback and suggestions for spiffy new features.
 
=back
 
=head1 REZROV?
 
 >up
 Jewel Room
 This fabulous room commands a magnificent view of the Lonely
 Mountain which lies to the north and west. The room itself is
 filled with beautiful chests and cabinets which once contained
 precious jewels and other objets d'art. These are empty.
 Winding stone stairs lead down to the base of the tower.
 There is an ornamented egg here, both beautiful and complex. It
 is carefully crafted and bears further examination.
 
 >get egg then examine it     
 Taken.
 
 This ornamented egg is both beautiful and complex. The egg
 itself is mother-of-pearl, but decorated with delicate gold
 traceries inlaid with jewels and other precious metals. On the
 surface are a lapis handle, an emerald knob, a silver slide, a
 golden crank, and a diamond-studded button carefully and
 unobtrusively imbedded in the decorations. These various
 protuberances are likely to be connected with some machinery
 inside.
 The beautiful, ornamented egg is closed.
 
 >read spell book
 
 My Spell Book
 
 The rezrov spell (open even locked or enchanted objects).
 The blorb spell (safely protect a small object as though in a
 strong box).
 The nitfol spell (converse with the beasts in their own
 tongue).
 The frotz spell (cause something to give off light).
 The gnusto spell (write a magic spell into a spell book).
 
 >learn rezrov then rezrov egg 
 Using your best study habits, you learn the rezrov spell.
 
 The egg seems to come to life and each piece slides
 effortlessly in the correct pattern. The egg opens, revealing a
 shredded scroll inside, nestled among a profusion of shredders,
 knives, and other sharp instruments, cunningly connected to the
 knobs, buttons, etc. on the outside.
 
                                      - "Enchanter", 1983
 
 
=head1 AUTHOR
 
Michael Edmonson E<lt>edmonson@sdf.lonestar.orgE<gt>
 
Rezrov homepage: http://edmonson.paunix.org/rezrov/
 
=cut