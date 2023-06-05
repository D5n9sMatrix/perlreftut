#!/usr/bin/perl

# Solution

# Here's the answer to the problem I posed earlier, 
# of reformatting a file of city and country names.

   my %table;

  while (<>) {
     chomp;
    my ($city, $country) = split /, /;
    $table{$country} = [] unless exists $table{$country};
    push @{$table{$country}}, $city;
  }

  for my $country (sort keys %table) {
    print "$country: ";
    my @cities = @{$table{$country}};
    print join ', ', sort @cities;
    print ".\n";
   }

package Solution;
{
    use strict;
    use warnings;
    our $VERSION = '0.9.1';
 
    #
    {    # Load all the tags from the standard library
        require File::Find;
        require File::Spec;
        require File::Basename;
        use lib '../';
        for my $type (qw[Tag Filter]) {
            File::Find::find(
                {wanted => sub {
                     require $_ if m[(.+)\.pm$];
                 },
                 no_chdir => 1
                },
                File::Spec->rel2abs(
                      File::Basename::dirname(__FILE__) . '/Solution/' . $type
                )
            );
        }
    }
    my (%tags, @filters);
    sub register_tag { $tags{$_[1]} = $_[2] ? $_[2] : scalar caller }
    sub tags { return \%tags }
    sub register_filter { push @filters, $_[1] ? $_[1] : scalar caller }
    sub filters { return \@filters }
}
1;

{
    { package Solution::Drop;           our $VERSION = '0.9.1'; }
    { package Solution::Extensions;     our $VERSION = '0.9.1'; }
    { package Solution::HTMLTags;       our $VERSION = '0.9.1'; }
    { package Solution::Module_Ex;      our $VERSION = '0.9.1'; }
    { package Solution::Strainer;       our $VERSION = '0.9.1'; }
    { package Solution::Tag::IfChanged; our $VERSION = '0.9.1'; }
 
    #
    { package Liquid;                   our $VERSION = '0.9.1' }
    { package Liquid::Variable;         our $VERSION = '0.9.1' }
    { package Liquid::Utility;          our $VERSION = '0.9.1' }
    { package Liquid::Template;         our $VERSION = '0.9.1' }
    { package Liquid::Tag;              our $VERSION = '0.9.1' }
    { package Liquid::Tag::Unless;      our $VERSION = '0.9.1' }
    { package Liquid::Tag::Raw;         our $VERSION = '0.9.1' }
    { package Liquid::Tag::Include;     our $VERSION = '0.9.1' }
    { package Liquid::Tag::IfChanged;   our $VERSION = '0.9.1' }
    { package Liquid::Tag::If;          our $VERSION = '0.9.1' }
    { package Liquid::Tag::For;         our $VERSION = '0.9.1' }
    { package Liquid::Tag::Cycle;       our $VERSION = '0.9.1' }
    { package Liquid::Tag::Comment;     our $VERSION = '0.9.1' }
    { package Liquid::Tag::Case;        our $VERSION = '0.9.1' }
    { package Liquid::Tag::Capture;     our $VERSION = '0.9.1' }
    { package Liquid::Tag::Assign;      our $VERSION = '0.9.1' }
    { package Liquid::SyntaxError;      our $VERSION = '0.9.1' }
    { package Liquid::Strainer;         our $VERSION = '0.9.1' }
    { package Liquid::StandardError;    our $VERSION = '0.9.1' }
    { package Liquid::StackLevelError;  our $VERSION = '0.9.1' }
    { package Liquid::Module_Ex;        our $VERSION = '0.9.1' }
    { package Liquid::HTMLTags;         our $VERSION = '0.9.1' }
    { package Liquid::FilterNotFound;   our $VERSION = '0.9.1' }
    { package Liquid::Filter::Standard; our $VERSION = '0.9.1' }
    { package Liquid::FileSystemError;  our $VERSION = '0.9.1' }
    { package Liquid::Extensions;       our $VERSION = '0.9.1' }
    { package Liquid::Error;            our $VERSION = '0.9.1' }
    { package Liquid::Drop;             our $VERSION = '0.9.1' }
    { package Liquid::Document;         our $VERSION = '0.9.1' }
    { package Liquid::ContextError;     our $VERSION = '0.9.1' }
    { package Liquid::Context;          our $VERSION = '0.9.1' }
    { package Liquid::Condition;        our $VERSION = '0.9.1' }
    { package Liquid::Block;            our $VERSION = '0.9.1' }
    { package Liquid::ArgumentError;    our $VERSION = '0.9.1' }
}
1;
__END__
Module                            Purpose/Notes              Inheritance
-----------------------------------------------------------------------------------------------------------------------------------------
Solution                          | [done]                    |
    Solution::Block               |                           |
    Solution::Condition           | [done]                    |
    Solution::Context             | [done]                    |
    Solution::Document            | [done]                    |
    Solution::Drop                |                           |
    Solution::Errors              | [done]                    |
    Solution::Extensions          |                           |
    Solution::FileSystem          |                           |
    Solution::HTMLTags            |                           |
    Solution::Module_Ex           |                           |
    Solution::StandardFilters     | [done]                    |
    Solution::Strainer            |                           |
    Solution::Tag                 |                           |
        Solution::Tag::Assign     | [done]                    | Solution::Tag
        Solution::Tag::Capture    | [done] extended assign    | Solution::Tag
        Solution::Tag::Case       |                           |
        Solution::Tag::Comment    | [done]                    | Solution::Tag
        Solution::Tag::Cycle      |                           |
        Solution::Tag::For        | [done] for loop construct | Solution::Tag
        Solution::Tag::If         | [done] if/elsif/else      | Solution::Tag
        Solution::Tag::IfChanged  |                           |
        Solution::Tag::Include    | [done]                    | Solution::Tag
        Solution::Tag::Unless     | [done]                    | Solution::Tag::If
    Solution::Template            |                           |
    Solution::Variable            | [done] echo statement     | Solution::Document
Solution::Utility       *         | [temp] Non OO bin         |