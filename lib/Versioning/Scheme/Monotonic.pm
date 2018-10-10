package Versioning::Scheme::Monotonic;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use Role::Tiny;
use Role::Versioning::Scheme;

our $re = qr/\A([1-9][0-9]*)\.([1-9][0-9]*)(\.0)?\z/;

sub is_valid_version {
    my ($self, $v) = @_;
    $v =~ $re ? 1:0;
}

sub normalize_version {
    my ($self, $v, $opts) = @_;
    $opts //= {};

    die "Invalid version '$v'" unless $v =~ $re;

    "$1.$2";
}

sub cmp_version {
    my ($self, $v1, $v2) = @_;

    die "Invalid version '$v1'" unless my ($c1, $r1) = $v1 =~ $re;
    die "Invalid version '$v2'" unless my ($c2, $r2) = $v2 =~ $re;

    ($c1 <=> $c2) || ($r1 <=> $r2);
}

sub bump_version {
    my ($self, $v, $opts) = @_;
    $opts //= {};
    $opts->{num} //= 1;
    $opts->{part} //= -1;

    die "Invalid version '$v'" unless my @parts = $v =~ $re;
    my $has_third = pop(@parts);
    die "Invalid 'num', must be non-zero" unless $opts->{num} != 0;
    die "Invalid 'part', must not be larger ".$#parts
        if $opts->{part} > $#parts;
    die "Invalid 'part', must not be smaller than -".@parts
        if $opts->{part} < -@parts;

    my $idx = $opts->{part};
    $parts[$idx] //= 0;
    if (abs($idx) == 0) {
        if ($parts[$idx] + $opts->{num} < 0) {
            die "Cannot decrease version, would result in a negative compatibility part";
        }
    } else {
        if ($parts[$idx] + $opts->{num} < 1) {
            die "Cannot decrease version, would result in a zero/negative release part";
        }
    }
    $parts[$idx] = $parts[$idx]+$opts->{num};
    if (abs($idx) != 1) {
        # keep bumping the release number
        $parts[1] = $parts[1] + ($opts->{num} < 0 ? -1 : 1);
    }
    join(".", @parts) . ($has_third || '');
}

1;
# ABSTRACT: Monotonic versioning

=head1 SYNOPSIS

 use Versioning::Scheme::Monotonic;

 # checking validity
 Versioning::Scheme::Monotonic->is_valid('1.2');   # 1
 Versioning::Scheme::Monotonic->is_valid('1.02');  # 0
 Versioning::Scheme::Monotonic->is_valid('1.2.0'); # 1
 Versioning::Scheme::Monotonic->is_valid('1.2.1'); # 0

 # normalizing
 Versioning::Scheme::Monotonic->normalize('1.2.0'); # => '1.2'

 # comparing
 Versioning::Scheme::Monotonic->compare('1.2', '1.2.0'); # 0
 Versioning::Scheme::Monotonic->compare('1.2', '1.13');  # -1
 Versioning::Scheme::Monotonic->compare('2.2', '1.13');  # 1

 # bumping
 Versioning::Scheme::Monotonic->bump('1.2');            # => '1.3'
 Versioning::Scheme::Monotonic->bump('1.2', {num=>2});  # => '1.4'
 Versioning::Scheme::Monotonic->bump('1.2', {part=>0}); # => '2.3'
 Versioning::Scheme::Monotonic->bump('1.2', {num=>-1, part=>0}); # => '0.1'

You can also mix this role into your class.


=head1 DESCRIPTION

This class implements the monotonic versioning scheme as described in [1]. A
version number comprises two whole numbers:

 COMPATIBILITY.RELEASE

where COMPATIBILITY starts at 0 and RELEASE starts at 1 with no zero prefix. An
additional ".0" is allowed for compatibility with semantic versioning:

 COMPATIBILITY.RELEASE.0

RELEASE is always increased. COMPATIBILITY is increased whenever there's a
backward-incompatibility introduced.

Normalizing just normalized COMPATIBILITY.RELEASE.0 into COMPATIBILITY.RELEASE.

Comparing is performed using this expression:

 (COMPATIBILITY1 <=> COMPATIBILITY2) || (RELEASE1 <=> RELEASE2)

Bumping by default increases RELEASE by 1. You can specify option C<num> (e.g.
2) to bump RELEASE by that number. You can specify option C<part> (e.g. 0) to
increase COMPATIBILITY instead; but in that case RELEASE will still be bumped by
1.


=head1 METHODS

=head2 is_valid_version

=head2 normalize_version

=head2 cmp_version

=head2 bump_version


=head1 SEE ALSO

[1] L<http://blog.appliedcompscilab.com/monotonic_versioning_manifesto/>

L<Version::Monotonic>, an older incantation of this module.
