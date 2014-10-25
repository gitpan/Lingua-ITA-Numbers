# For Emacs: -*- mode:cperl; mode:folding -*-

package Lingua::ITA::Numbers;
# ABSTRACT: Lingua::ITA::Numbers converts arbitrary numbers into human-oriented Italian text. The interface is sligtly different from that defined for Lingua::EN::Numbers, for one it can be used in a procedural way, just like Lingua::FR::Numbers, importing the number_to_it function.

# {{{ use block

use strict;
use warnings;

use overload ( 
  '""' => \&get_string,
  '0+' => \&get_number,
  '='  => \&clone,
  '+'  => \&add,
  '-'  => \&minus,
  '*'  => \&mult,
  '/'  => \&div,
  fallback => 1);

use Carp qw(carp);
use Perl6::Export::Attrs;

# }}}
# {{{ variables declaration

my($ver)      = ('$Rev: 440 $' =~ m{(\d+)}xms);
our $VERSION = $ver / 10_000;

our %SIGN_NAMES           = ('-' => 'meno',
                             '+'  => '');

our %OUTPUT_DECIMAL_DELIMITERS = (normal => 'virgola',
                                  fract => 'e');

our %NUMBER_NAMES         = (
                             0    => 'zero',
                             1    => 'un',
                             2    => 'due',
                             3    => 'tre',
                             4    => 'quattro',
                             5    => 'cinque',
                             6    => 'sei',
                             7    => 'sette',
                             8    => 'otto',
                             9    => 'nove',
                             10   => 'dieci',
                             11   => 'undici',
                             12   => 'dodici',
                             13   => 'tredici',
                             14   => 'quattordici',
                             15   => 'quindici',
                             16   => 'sedici',
                             17   => 'diciassette',
                             18   => 'diciotto',
                             19   => 'diciannove',
                             20   => 'venti',
                             30   => 'trenta',
                             40   => 'quaranta',
                             50   => 'cinquanta',
                             60   => 'sessanta',
                             70   => 'settanta',
                             80   => 'ottanta',
                             90   => 'novanta',
                             100  => 'cento');

our @PART_NAMES    = qw(_ mila milioni miliardi);
our @UNITS_NAMES    = qw(_ mille milione miliardo);
our @FRACT_NAMES = qw(decim centesim millesim decimillesim centomillesim
                      milionesim decimilionesim centomilionesim 
                      miliardesim);

our %DEFAULT_OPTS = (
                     decimal => 0,
                     decmode => 'normal',
                     name => "",
                    );

# }}}
# {{{ number_to_it

sub number_to_it :Export {
  my ($number,$opts) = @_;
  $opts = {} unless defined $opts;
  $opts = {%DEFAULT_OPTS,%$opts};
  my $parsed = parse_num_string($number);
  my @parts = ();
  push @parts,$SIGN_NAMES{$parsed->{sign}};
  my $intpart = convert_to_string($parsed->{intpart});
  my $one = $NUMBER_NAMES{1};
  $intpart =~ s/($one)$/$1o/;
  push @parts,$intpart;
  if ($opts->{name}) {
    my $name = ! ref($opts->{name}) ? $opts->{name} : 
      ($intpart eq $NUMBER_NAMES{1} ? $opts->{name}[0] : $opts->{name}[1]);

    push @parts,$name;
  }

  if ($parsed->{fracpart} || $opts->{decimal}) {
    push @parts,$OUTPUT_DECIMAL_DELIMITERS{$opts->{decmode}};
    if ($opts->{decimal}) {
      if (length($parsed->{fracpart}) < $opts->{decimal}) {
        $parsed->{fracpart} .= "0" x ($opts->{decimal} - 
                                      length($parsed->{fracpart}));
      }
    }
    my $fractpart = convert_to_string($parsed->{fracpart});
    if ($opts->{decmode} eq 'fract') {
      if ($fractpart eq $NUMBER_NAMES{1}) {
        push @parts,$fractpart,$FRACT_NAMES[length($parsed->{fracpart}) - 1] . "o";
      }
      else {
        push @parts,$fractpart,$FRACT_NAMES[length($parsed->{fracpart}) - 1] . "i";
      }
    }
    else {
      my $one = $NUMBER_NAMES{1};
      $fractpart =~ s/($one)$/$1o/;
      push @parts,$fractpart;
    }
  }
  my $result = join(" ",@parts);
  $result =~ s/^\s*//;
  return $result;
}

# }}}
# {{{ convert_short

sub convert_short {
  use integer;
  my $num = shift; # 1 < num < 1000

  my $hundreds = $num / 100;
  my $tens     = $num % 100;
  my @parts = ();
  if ($hundreds == 1) {
    push @parts,$NUMBER_NAMES{100};
  }
  elsif ($hundreds > 1) {
    push @parts,$NUMBER_NAMES{$hundreds},$NUMBER_NAMES{100};
  }
  if ($tens == 0) {
    #nothing
    ;
  }
  elsif ($tens <= 20) {
    push @parts,$NUMBER_NAMES{$tens};
  }
  else {
    my $units = $tens % 10;
    $tens = $tens - $units;
    my $tenstr = $NUMBER_NAMES{$tens};
    $tenstr =~ s/.$// if ($units == 1) or ($units == 8);
    push @parts,$tenstr;
    if ($units >= 1) {
      push @parts,$NUMBER_NAMES{$units};
    }
  }
  return join("",@parts);
}

# }}}
# {{{ convert_to_string

sub convert_to_string {
  use integer;
  my $number = shift; #$number >= 0 and integer
  return $NUMBER_NAMES{0} if !$number || $number !~ m/[1-9]/;
  return $NUMBER_NAMES{1} if "$number" eq "1" ;
  if (my $r = length($number) % 3) {
    $number = "0" x (3 - $r) . $number;
  }
  my @blocks = ($number =~ m!(\d\d\d)!g);
  @blocks = reverse @blocks;
  if (@blocks > 4) {
    carp "Numbers bigger than 1e10-1 not handled in version $VERSION";
    return;
  }
  my @name_parts = ();
  my $firstpart = "";
  if ($blocks[0] == 1) {
    #nb one of the following blocks is != 0, since the whole number 
    #is greater than one
    $firstpart = $NUMBER_NAMES{1};
  }
  elsif ($blocks[0] > 1) {
    $firstpart = convert_short($blocks[0]);
  }
  if ($#blocks >= 1 && $blocks[1] == 1) {
    $firstpart = $UNITS_NAMES[1] . $firstpart;
  }
  elsif ($#blocks >= 1 && $blocks[1] > 1) {
    $firstpart = convert_short($blocks[1]) . $PART_NAMES[1] . $firstpart;
  }
  push @name_parts,$firstpart;
  foreach my $pos (2..$#blocks) {
    next unless $blocks[$pos];
    push @name_parts," ";
    if ($blocks[$pos] == 1) {
      push @name_parts,$NUMBER_NAMES{1} . " " . $UNITS_NAMES[$pos];
    }
    else {
      my $part = convert_short($blocks[$pos]);
      push @name_parts,$part. " " . $PART_NAMES[$pos];
    }
  }
  my $tmp = join("",reverse(@name_parts));
  $tmp =~ s/^\s*//;
  $tmp =~ s/\s*$//;
  $tmp =~ s!\s+! !g;
  return $tmp;
}

# }}}
# {{{ parse_num_string

sub parse_num_string {
  my $string = shift;

  return { intpart  => $string,
           sign     => '+',
           fracpart => 0,
  };
}

# }}}

# OO Methods
# {{{ new
sub new {
    my $class  = shift;
    my $number = shift;
    my @a = @_;
    my %opts = (%DEFAULT_OPTS,@a);
    return bless { number => $number,
                   opts   => \%opts}, $class;
}

# }}}
# {{{ get_string

sub get_string {
    my $self = shift;
    return number_to_it($self->{number},$self->{opts});
}

# }}}
# {{{ get_number

sub get_number {
  my $self = shift;
  return $self->{number}
}

# }}}
# {{{ set_number

sub set_number {
  my $self = shift;
  $self->{number} = shift;
  return $self;
}

# }}}
# {{{ add

sub add {
  my $self = shift;
  my $num = shift;
  $num = UNIVERSAL::isa($num,__PACKAGE__) ? $num->{number} : $num;
  my $tmp = $self->{number} + $num;
  return bless {number => $tmp,
                opts => $self->{opts}},ref($self);
}

# }}}
# {{{ mult

sub mult {
  my $self = shift;
  my $num = shift;
  $num = UNIVERSAL::isa($num,__PACKAGE__) ? $num->{number} : $num;
  return bless {number => $self->{number} * $num,
                opts => $self->{opts}},ref($self);
}

# }}}
# {{{ div

sub div {
  my $self = shift;
  my $num = shift;
  $num = UNIVERSAL::isa($num,__PACKAGE__) ? $num->{number} : $num;
  my $inverted = shift;
  my $tmp  = 
    ($inverted) ? $num / $self->{number} : $self->{number} / $num;
  return bless {number => $tmp,
                opts => $self->{opts}},ref($self);
}

# }}}
# {{{ minus

sub minus {
  my $self = shift;
  my $num = shift;
  $num = UNIVERSAL::isa($num,__PACKAGE__) ? $num->{number} : $num;
  my $inverted = shift;
  my $tmp  = 
    ($inverted) ? $num - $self->{number} : $self->{number} - $num;
  return bless {number => $tmp,
                opts => $self->{opts}},ref($self);
}

# }}}
# {{{ clone

sub clone {
  my $self = shift;
  my $class = ref($self);
  return bless {%$self},$class;
}

# }}}

1;
__END__

# {{{ module documentation

=head1 NAME

Lingua::ITA::Numbers - Converts numeric values into their Italian string equivalents

=head1 VERSION

version 0.044

=head1 SYNOPSIS

 # Procedural Style
 use Lingua::ITA::Numbers qw(number_to_it);
 print number_to_it(315);
 # prints trecentoquindici

 print number_to_it(325.12)
 # prints trecentoventicinque virgola dodici

 print number_to_it(325.12,decmode => 'fract')
 # prints trecentoveticinque e dodici centesimi

 # OO Style
 use Lingua::ITA::Numbers;
 my $number = Lingua::ITA::Numbers->new( 123 );
 print $number->get_string;
 print $number->get_ordinate;


=head1 DESCRIPTION

Lingua::ITA::Numbers converts arbitrary numbers into human-oriented
Italian text. The interface is sligtly different from that defined
for Lingua::EN::Numbers, for one it can be used in a procedural way,
just like Lingua::FR::Numbers, importing the B<number_to_it> function.

Remark that Lingua::ITA::Numbers object, created by the B<new> constructor
described below, are I<Two-face scalars> as described in L<overload>:
when a Lingua::ITA::Numbers object is used as a number, then it is a number,
when it is used as a string then it is its Italian representation (see
L</"OVERLOADING">)

=head2 EXPORT

Nothing is exported by default. The following function is exported.

=over

=item B<number_to_it($number,[options])>

Converts a number to its Italian string representation without building
the Lingua::ITA::Numbers instance.
  
  $string = number_to_it($number,...);

is equivalent to

  $string = do {
    my $tmp = Lingua::ITA::Numbers->new($number,...);
    $tmp->get_string();
  };

See L</"OPTIONS"> for avalaible options for B<number_to_it>

=back

=head2 METHODS

The following method compose the OO interface to Lingua::ITA::Numbers.

=over

=item B<Lingua::ITA::Numbers->new($number,[options])>

Creates and initialize an instance.

=item B<$obj-E<gt>get_number>

Returns the number contained in the instance.

=item B<$obj-E<gt>get_string()>

Returns the representation of the number as a string in Italian.

=item B<$obj-E<gt>set_number($number)>

Changes the number contained in the instance.

=back


=head1 OPTIONS

The representation of numbers by Lingua::ITA::Numbers can be influenced by means
of options. Options are given either to the exported funcion B<number_to_it> 
or to the constructor b<new> as named parameters. the following options are
defined:

=over

=item B<decimal>

If different from zero is the minimal number of decimal places a number must
have.

=item B<decmode>

Can be either I<normal> or I<fract>. This options selects the method used for writing
the fractional part of a number. Infact, in Italian there are two way to represent
fractional numbers in writing. For 345.27 you can say either "trecentoquarantacinque
virgola ventisette" or "trecentoquarantacinque e ventisette centesimi". The latter is
used mainly for mensurament. Setting the B<decmode> option to I<normal> (its default
value) selects the former method, while setting it to I<fract> selects the latter.

=item B<name>

The value of this option can be either a string or (a reference to) an array
containing two strings. If the option value is a string this is interpolated between
the integer part and the fractional part. If the option value is an array, the first
element is taken to be the singular form while the second is the plural. So that

    my $euro = Lingua::ITA::Numbers->new(253,name => "euro",
                                            decmode => 'fract',
                                            decimal => 2);
    print $euro->get_string(),"\n"

will print 'duecentocinquantatre euro e zero centesimi', while

    my $dollar = Lingua::ITA::Numbers->new(253,name => [qw(dollaro dollari)],
                                              decmode => 'fract',
                                              decimal => 2);
    print $dollar->get_string(),"\n"

will print 'duecentocinquantatre dollari e zero centesimi'.


=back


=head1 OVERLOADING

As stated above, instances of Lingua::ITA::Numbers are I<Two-face scalars> like
those described in L<overload>. This means that you can do something like:

    my $first = Lingua::ITA::Numbers->new(123);
    my $second = Lingua::ITA::Numbers->new(321);

    print $first,' + ',$second,' = ',$first+$second,"\n";
 
which will print: 'centoventitre + trecentoventuno = quattrocentoquarantaquattro'.

=head1 METHODS

=over

=item add
=item clone
=item convert_short
=item convert_to_string
=item div
=item minus
=item mult
=item parse_num_string

=back

=head1 SEE ALSO

Lingua::*::Numbers, overload.


=head1 BUGS

There is no control on options' values.

Decimals doesn't work correctly.

=head1 TODO

=over

=item * 
Add italian documentation

=item * 
Add a package Lingua::ITA::Number::Currency for handling monetary values

=item *
Check an italian grammar to verify that what I remember from primary school about 
number writing hasn't changed.



=back

=head1 AUTHOR

Leo "TheHobbit" Cacciari, E<lt>hobbit@cpan.orgE<gt>

Maintenance
PetaMem <info@petamem.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Leo "TheHobbit" Cacciari

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


=cut

# }}}
