package Data::Money::Types;
use warnings;
use strict;

use MooseX::Types -declare => [ qw(Amount CurrencyCode DataMoney Format) ];

use MooseX::Types::Moose qw(Num Str Undef);
use Locale::Currency qw(code2currency);

use vars qw/$VERSION/;
$VERSION = '0.04';

class_type Amount, { class => 'Math::BigFloat' };
class_type DataMoney, { class => 'Data::Money' };

coerce Amount,
    from Num,
    via { Math::BigFloat->new($_) };

coerce Amount,
    from Str,
    via {
        # strip out formatting characters
        $_ =~ tr/-()0-9.//cd;
        if($_) {
            Math::BigFloat->new($_)
        } else {
            Math::BigFloat->new(0)
        }
    };

coerce Amount,
    from DataMoney,
    via { Math::BigFloat->new($_->value) };

coerce Amount,
    from Undef,
    via { Math::BigFloat->new(0) };

subtype CurrencyCode,
    as Str,
    where { !defined $_ || ($_ =~ /^[A-Z]{3}$/mxs && defined code2currency($_)) },
    message { 'String is not a valid 3 letter currency code.' };

enum Format,
    ( qw(FMT_COMMON FMT_HTML FMT_NAME FMT_STANDARD FMT_SYMBOL) );

1;
