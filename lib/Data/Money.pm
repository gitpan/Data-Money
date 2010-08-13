package Data::Money;
use strict;
use warnings;
use Moose;

use vars qw/$VERSION/;
$VERSION = '0.02';

with qw(MooseX::Clone);

use Check::ISA qw(obj);
use Math::BigFloat;

use overload
    '+'     => \&add,
    '-'     => \&subtract,
    '*'     => sub { $_[0]->clone(value => $_[0]->value->copy->bmul($_[1])) },
    '/'     => sub { $_[0]->clone(value => scalar($_[0]->value->copy->bdiv($_[1]))) },
    '+='    => \&add_in_place,
    '-='    => \&subtract_in_place,
    '0+'    => sub { $_[0]->value->numify; },
    '""'    => sub { shift->stringify },
    fallback => 1;

use Data::Money::Types qw(Amount CurrencyCode Format);
use MooseX::Types::Moose qw(HashRef);
use Locale::Currency;
use Locale::Currency::Format;

has code => (
    is => 'rw',
    isa => CurrencyCode,
    default => 'USD'
);
has format => (
    is => 'rw',
    isa => Format,
    default => 'FMT_COMMON'
);
has value => (
    is => 'rw',
    isa => Amount,
    default => sub { Math::BigFloat->new(0) },
    coerce => 1
);

# Liberally jacked from Math::Currency

sub as_float {
    my ($self) = @_;

    return $self->value->copy->bfround(-2)->bstr;
}

# Liberally jacked from Math::Currency

sub as_int {
    my ($self) = @_;

    (my $str = $self->as_float) =~ s/\.//o;
    $str =~ s/^(\-?)0+/$1/o;
    return $str eq '' ? '0' : $str;
}

sub add {
    my ($self, $num) = @_;

    if(obj($num, 'Data::Money')) {
        return $self->clone(value => $self->value->copy->badd($num->value));
    }
    return $self->clone(value => $self->value->copy->badd(Math::BigFloat->new($num)))
}

sub add_in_place {
    my ($self, $num) = @_;

    if(obj($num, 'Data::Money')) {
        $self->value($self->value->copy->badd($num->value));
    } else {
        $self->value($self->value->copy->badd(Math::BigFloat->new($num)));
    }
    return $self;
}

sub name {
    my ($self) = @_;
    my $name = Locale::Currency::code2currency($self->code);

    ## Fix for older Locale::Currency w/mispelled Candian
    $name =~ s/Candian/Canadian/;

    return $name;
};

*as_string = \&stringify;

sub stringify {
    my $self = shift;
    my $format = shift || $self->format;
    my $code = $self->code;

    ## funky eval to get string versions of constants back into the values
    eval '$format = Locale::Currency::Format::' .  $format;

    die 'Invalid currency code:  ' . ($code || 'undef')
        unless is_CurrencyCode($code);

    return _to_utf8(
        Locale::Currency::Format::currency_format($code, $self->as_float, $format)
    );
};

sub subtract {
    my ($self, $num) = @_;

    if(obj($num, 'Data::Money')) {
        return $self->clone(value => $self->value->copy->bsub($num->value));
    }
    return $self->clone(value => $self->value->copy->bsub(Math::BigFloat->new($num)))
}

sub subtract_in_place {
    my ($self, $num) = @_;

    if(obj($num, 'Data::Money')) {
        $self->value($self->value->copy->bsub($num->value));
    } else {
        $self->value($self->value->copy->bsub(Math::BigFloat->new($num)));
    }

    return $self;
}


sub _to_utf8 {
    my $value = shift;

    if ($] >= 5.008) {
        require utf8;
        utf8::upgrade($value);
    };

    return $value;
};

1;
__END__

=head1 NAME

Data::Money - Money/currency with formatting and overloading.

=head1 SYNOPSIS

    use Data::Money;

    my $price = Data::Money->new(value => 1.2. code => 'USD');
    print $price;            # $1.20
    print $price->code;      # USD
    print $price->format;    # FMT_COMMON
    print $price->as_string; # $1.20

    # Overloading, returns new instance
    my $m2 = $price + 1;
    my $m3 = $price - 1;

    # Objects work too
    my $m4 = $m2 + $m3;
    my $m5 = $m2 - $m3;

    # Modifies in place
    $price += 1;
    $price -= 1;

    print $price->as_string('FMT_SYMBOL'); # $1.20

=head1 DESCRIPTION

The Data::Money module provides basic currency formatting and number handling
via L<Math::BigFloat>:

    my $currency = Data::Money->new(value => 1.23);

Each Data::Money object will stringify to the original value except in string
context, where it stringifies to the format specified in C<format>.

=head1 MOTIVATION

Data::Money was created to make it easy to use different currencies (leveraging
existing work in C<Locale::Currency> and L<Moose>), to allow math operations
with proper rounding (via L<Math::BigFloat>) and formatting via
L<Locale::Currency::Format>.

=head1 OPERATOR OVERLOADING

Data::Money overrides some operators.  It is important to note which
operators change the object's value and which return new ones.  Addition and
subtraction operators accept either a Data::Money argument or a normal
number via scalar.  Others expect only a number.

Data::Money overloads the following operators:

=over 4

=item +

Handled by the C<add> method.  Returns a new Data::Money object.

=item -

Handled by the C<subtract> method.  Returns a new Data::Money object.

=item *

Returns a new Data::Money object.

=item +=

Handled by the C<add_in_place> method.  Modifies the left-hand object's value.
Works with either a Data::Money argument or a normal number.

=item -=

Handled by the C<subtract_in_place> method.  Modifies the left-hand object's value.
Works with either a Data::Money argument or a normal number.

=back

=head1 ATTRIBUTES

=head2 code

Gets/sets the three letter currency code for the current currency object.
Defaults to USD

=head2 format

Gets/sets the format to be used when C<as_string> is called. See
L<Locale::Currency::Format|Locale::Currency::Format> for the available
formatting options.  Defaults to C<FMT_COMMON>.

=head2 name

Returns the currency name for the current objects currency code. If no
currency code is set the method will die.

=head2 value

The amount of money/currency.  Defaults to 0.

=head1 METHODS

=head2 add($amount)

Adds the specified amount to this Data::Money object and returns a new
Data::Money object.  You can supply either a number of a Data::Money
object.  Note that this B<does not> modify the existing object.

=head2 add_in_place($amount)

Adds the specified amount to this Data::Money object, modifying it's value.
You can supply either a number of a Data::Money object.  Note that this
B<does> modify the existing object.

=head2 as_int

Returns the object's value "in pennies" (in the US at least).  It
strips the value of formatting using C<as_float> and of any decimals.

=head2 as_float

Returns objects value without any formatting.

=head2 subtract($amount)

Subtracts the specified amount to this Data::Money object and returns a new
Data::Money object. You can supply either a number of a Data::Money
object. Note that this B<does not> modify the existing object.

=head2 subtract_in_place($amount)

Subtracts the specified amount to this Data::Money object, modifying it's
value. You can supply either a number of a Data::Money object. Note that
this B<does> modify the existing object.

=head2 clone(%params)

Returns a clone (new instance) of this Data::Money object.  You may optionally
specify some of the attributes to overwrite.

  $curr->clone({ value => 100 }); # Clones all fields but changes value to 100

See L<MooseX::Clone> for more information.

=head2 stringify

Sames as C<as_string>.

=head2 as_string

Returns the current objects value as a formatted currency string.

=head1 SEE ALSO

L<Locale::Currency>, L<Locale::Currency::Format>,

=head1 ACKNOWLEDGEMENTS

This module was originally based on L<Data::Currency> by Christopher H. Laco
but I opted to fork and create a whole new module because my work was wildly
different from the original. I decided it was better to make a new module than
to break back compat and surprise users. Many thanks to him for the great
module.

Inspiration and ideas were also drawn from L<Math::Currency> and
L<Math::BigFloat>.

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

Copyright 2010 Cory Watson
 
This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.
 
See http://dev.perl.org/licenses/ for more information.
