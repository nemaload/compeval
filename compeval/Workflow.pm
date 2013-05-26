package compeval::Workflow;

use warnings;
use strict;
use v5.10;

use compeval;
use compeval::Computation;

sub new {
	my $class = shift;
	my ($dir, $basedir) = @_;

	-s "$dir/kind" or die "$dir not a workflow directory (file 'kind' not found)";
	-s "$dir/value" or die "$dir not a workflow directory (file 'value' not found)";

	my $self = {
		dir => $dir,
		kind => (slurp("$dir/kind"))[0],
		value => (slurp("$dir/value"))[0],
		basedir => $basedir,
	};

	bless $self, $class;
}

sub name {
	my $self = shift;
	($a = $self->{dir}) =~ tr#/#.#;
	$a;
}

sub kind {
	my $self = shift;
	return $self->{kind};
}

sub value {
	my $self = shift;
	return $self->{value};
}

sub outputs_slice {
	my $self = shift;
	my @slice;
	if ($self->kind eq 'computation') {
		@slice = (slurp($self->{dir}.'/outputs'));
	} else {
		@slice = (0); # Single output #0
	}
	return @slice;
}

# These make sense only for the 'computation' kind.

sub inputs {
	my $self = shift;
	my @inputnames = glob($self->{dir}.'/inputs/*');
	for (@inputnames) { s#.*/##; }

	# Process the sequence of input names, parse and verify for sanity
	my @inputs;
	my $lastseq = -1;
	for my $inputname (@inputnames) {
		my ($seqno, $seqno2, $label) = ($inputname =~ m#^(\d\d)(?:_(\d\d))?-(.*)#);

		if (not defined $seqno or not defined $label) {
			say STDERR "Warning: Cannot parse ".$self->{dir}." input name $inputname, skipping";
			next;
		}

		if ($seqno != $lastseq + 1) {
			say STDERR "Warning: Input $inputname out-of-sequence ($seqno, expected ".($lastseq+1).")";
		}
		my $seqno_end = (defined $seqno2 ? $seqno2 : $seqno);
		$lastseq = $seqno_end;

		push @inputs, { name => $inputname, seqno_start => $seqno, seqno_end => $seqno_end, label => $label };
	}

	return @inputs;
}

sub input {
	my $self = shift;
	my ($input) = @_;
	my $workflow = compeval::Workflow->new($self->{dir} . '/inputs/' . $input->{name}, $self->{basedir});

	# A sanity check - output slice should be as big as inputs count for this computation
	my $output_count = scalar $workflow->outputs_slice();
	my $expinput_count = $input->{seqno_end} + 1 - $input->{seqno_start};
	if ($output_count != $expinput_count) {
		say STDERR "Warning: ".$self->{dir}." input ".$input->{name}." returns ".$output_count." outputs but occupies ".$expinput_count." input slots";
	}

	return $workflow;
}

sub computation {
	my $self = shift;
	return compeval::Computation->new($self->{basedir} . '/computations/' . $self->value);
}

1;
