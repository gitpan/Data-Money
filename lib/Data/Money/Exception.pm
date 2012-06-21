package Data::Money::Exception;

use strict;
use warnings;

use Moose;
with 'Throwable';

use overload '""' => sub { shift->error };

has error => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

__PACKAGE__->meta->make_immutable;

no Moose;

1;

__END__
