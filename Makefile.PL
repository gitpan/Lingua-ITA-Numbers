
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Lingua::ITA::Numbers converts arbitrary numbers into human-oriented Italian text. The interface is sligtly different from that defined for Lingua::EN::Numbers, for one it can be used in a procedural way, just like Lingua::FR::Numbers, importing the number_to_it function.",
  "AUTHOR" => "Leo \"TheHobbit\" Cacciari <hobbit\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Test::More" => 0,
    "utf8" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Lingua-ITA-Numbers",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Lingua::ITA::Numbers",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Perl6::Export::Attrs" => 0,
    "integer" => 0,
    "overload" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.044",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



