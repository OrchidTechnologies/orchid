#!/usr/bin/env perl
use warnings; use strict; $| = 1;
use Fcntl qw(:flock);
open my $fh, '+<&=', 3 or die $!;
flock $fh, LOCK_EX or die $!;
system { $ARGV[0] } @ARGV;
