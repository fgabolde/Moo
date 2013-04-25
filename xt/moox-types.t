use strictures 1;
use Test::More;

{
  package TypeOMatic;

  use Moo::Role;
  use Sub::Quote;
  use MooX::Types::MooseLike::Base qw(Str);
  use MooX::Types::MooseLike::Numeric qw(PositiveInt);

  has named_type => (
    is => 'ro',
    isa => Str,
  );

  has named_external_type => (
    is => 'ro',
    isa => PositiveInt,
  );

  package TypeOMatic::Consumer;

  # do this as late as possible to simulate "real" behaviour
  use Moo::HandleMoose;
  use Moose;
  with 'TypeOMatic';
}

my $meta = Class::MOP::class_of('TypeOMatic::Consumer');

my ($str, $positive_int)
  = map $meta->get_attribute($_)->type_constraint->name,
      qw(named_type named_external_type);

is($str, 'Str', 'Built-in Moose type ok');
is(
  $positive_int, 'MooseX::Types::Common::Numeric::PositiveInt',
  'External (MooseX::Types type) ok'
);

local $@;
eval q {
  package Fooble;
  use Moo;
  my $isa = sub { 1 };
  $Moo::HandleMoose::TYPE_MAP{$isa} = sub { $isa };
  has barble => (is => "ro", isa => $isa);
  __PACKAGE__->meta->get_attribute("barble");
};

like(
  $@,
  qr{^error inflating attribute 'barble' for package 'Fooble': \$TYPE_MAP\{CODE\(\w+?\)\} did not return a valid type constraint},
  'error message for incorrect type constraint inflation',
);

done_testing;
