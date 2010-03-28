# $Id$
use strict;
use warnings;
use inc::Module::Install 0.65;

name 'Data-Money';
license 'perl';
perl_version '5.006001';
all_from 'lib/Data/Money.pm';

test_requires 'Test::utf8';
test_requires 'Test::Exception';

requires 'Check::ISA';
requires 'Locale::Currency'         => '2.07';
requires 'Locale::Currency::Format' => '1.22';
requires 'Moose';
requires 'MooseX::Clone';
requires 'MooseX::Types';
requires 'Math::BigFloat';

eval {
    system 'pod2text lib/Data/Money.pm > README';
};

WriteAll;
