package Versioning::Scheme::Perl;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use Role::Tiny;
use Role::Tiny::With;
with 'Role::Versioning::Scheme';
use version;

sub is_valid_version {
    my ($self, $v) = @_;
    eval { version->parse($v) };
    $@ ? 0:1;
}

sub parse_version {
    my ($self, $v) = @_;

    my $vp;
    eval { $vp = version->parse($v) };
    return undef if $@;
    $vp =~ s/\Av//;
    {parts => [split /\./, $vp]};
}

sub normalize_version {
    my ($self, $v) = @_;
    version->parse($v)->normal;
}

sub cmp_version {
    my ($self, $v1, $v2) = @_;

    version->parse($v1) <=> version->parse($v2);
}

sub bump_version {
    my ($self, $v, $opts) = @_;
    $opts //= {};
    $opts->{num} //= 1;
    $opts->{part} //= -1;
    $opts->{reset_smaller} //= 1;

    my $vn = version->parse($v)->normal; $vn =~ s/\Av//;
    die "Invalid 'num', must be non-zero" unless $opts->{num} != 0;
    my @parts = split /\./, $vn;
    die "Invalid 'part', must not be smaller than -".@parts
        if $opts->{part} < -@parts;
    die "Invalid 'part', must not be larger than ".$#parts
        if $opts->{part} > $#parts;

    my $idx = $opts->{part}; $idx = @parts + $idx if $idx < 0;
    # for now, we do not allow decreasing that overflow to the next more
    # significant part
    die "Cannot decrease version, would result in a negative part"
        if $parts[$idx] + $opts->{num} < 0;
    my $i = $idx;
    my $left = $opts->{num};
    while (1) {
        if ($i == 0 || $parts[$i]+$left < 1000) {
            $parts[$i] += $left;
            $left = 0;
            last;
        } else {
            my $tmp = $parts[$i] + $left;
            $parts[$i] = $tmp % 1000;
            $left = int($tmp / 1000);
            $i--;
            next;
        }
    }
    if ($opts->{reset_smaller} && $opts->{num} > 0) {
        $idx = @parts + $idx if $idx < 0;
        for my $i ($idx+1 .. $#parts) {
            $parts[$i] //= 0;
            $parts[$i] = sprintf("%0".length($parts[$i])."d", 0);
        }
    }
    version->parse(join(".", @parts))->normal;
}

1;
# ABSTRACT: Version as dotted numbers

=head1 SYNOPSIS

 use Versioning::Scheme::Perl;

 # checking validity
 Versioning::Scheme::Perl->is_valid('1.02');     # 1
 Versioning::Scheme::Perl->is_valid('1.0.0');    # 1
 Versioning::Scheme::Perl->is_valid('v1.0.0.0'); # 1
 Versioning::Scheme::Perl->is_valid('1.2beta');  # 0

 # normalizing
 Versioning::Scheme::Perl->normalize('0.1.2');             # => 'v0.1.2'
 Versioning::Scheme::Perl->normalize('1.02');              # => 'v1.20.0'

 # comparing
 Versioning::Scheme::Perl->compare('1.2.3', '1.2.3.0'); # 0
 Versioning::Scheme::Perl->compare('1.2.3', '1.2.4');   # -1
 Versioning::Scheme::Perl->compare('1.3.1', '1.2.4');   # 1

 # bumping
 Versioning::Scheme::Perl->bump('1.2.3');                               # => 'v1.2.4'
 Versioning::Scheme::Perl->bump('1.2.999');                             # => 'v1.3.0'
 Versioning::Scheme::Perl->bump('1.2.3', {num=>2});                     # => 'v1.2.5'
 Versioning::Scheme::Perl->bump('1.2.3', {num=>-1});                    # => 'v1.2.2'
 Versioning::Scheme::Perl->bump('1.2.3', {part=>-2});                   # => 'v1.3.0'
 Versioning::Scheme::Perl->bump('1.2.3', {part=>0});                    # => 'v2.0.0'
 Versioning::Scheme::Perl->bump('1.2.3', {part=>-2, reset_smaller=>0}); # => 'v1.3.3'

You can also mix this role into your class.


=head1 DESCRIPTION

This role is basically a glue between L<Role::Versioning::Scheme> and
L<version>.pm.


=head1 METHODS

=head2 is_valid_version

Uses L<version>.pm's C<parse()>.

=head2 normalize_version

Equivalent to:

 version->parse($v)->normal

=head2 cmp_version

Equivalent to:

 version->parse($v1) <=> version->parse($v2)

=head2 bump_version

Will first normalize the version using:

 version->parse($v1)->normal

followed by bumping the part. Except for the first (most significant) part, if a
number is bumped beyond 999 it will overflow to the next more significant part,
for example: bumping v1.0.999 will result in v1.1.0.


=head1 SEE ALSO

L<version>

Other C<Versioning::Scheme::*> modules.
