package compeval::Docker;

use warnings;
use strict;
use v5.10;

use compeval;

sub pull {
	my ($image, $tag) = @_;
	system('lxc-docker', 'pull', '-t', $tag, $image);
}

sub image_id {
	my ($image, $tag) = @_;
	# `docker images -q` is a nice idea but can't limit by tag
	my $idline = `lxc-docker images $image | grep ' $tag ' | awk '{print\$3}' | head -n 1`;
	chomp $idline;
	return $idline;
}

sub run {
	my ($image, $tag, $argv, $opts) = @_;

	# To make GFS available within the Docker container, we use
	# docker run -b which is currently not merged in trunk but
	# the situation seems hopeful:
	#   https://github.com/dotcloud/docker/pull/602

	my @runargs;
	if ($opts->{binds}) {
		push @runargs, '-b', (map { $_->[0].':'.$_->[1] } @{$opts->{binds}});
	}

	system('lxc-docker', 'run', @runargs, image_id($image, $tag), @$argv);
}

1;
