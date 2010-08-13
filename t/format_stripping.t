use Test::More;
use strict;
use Encode;

use Test::Exception;

use Data::Money;

##  test a sane value
{
    my $m = Data::Money->new(value => '$21.00');
    cmp_ok($m->as_string, 'eq', '$21.00', 'USD formatting');
};

##  test an insane one
{
    my $m = Data::Money->new(value => 'xyz234');
    cmp_ok($m->as_string, 'eq', '$234.00', 'USD formatting');
};

done_testing;
