package HP::Storage::Component::DiskSubsystem;
our @ISA = qw(HP::Storage::Component);

use strict;
use Nagios::Plugin;

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    rawdata => $params{rawdata},
    method => $params{method},
    da_subsystem => undef,
    sas_da_subsystem => undef,
    ide_da_subsystem => undef,
    fca_da_subsystem => undef,
    ss_da_subsystem => undef,
    condition => $params{condition},
    blacklisted => 0,
  };
  bless $self, $class;
  $self->init();
  return $self;
}

sub init {
  my $self = shift;
  $self->{da_subsystem} = HP::Storage::Component::DiskSubsystem::Da->new(
    runtime => $self->{runtime},
    rawdata => $self->{rawdata},
    method => $self->{method},
  );
}

sub check {
  my $self = shift;
  $self->{da_subsystem}->check();
}

sub dump {
  my $self = shift;
  $self->{da_subsystem}->dump();
}


1;
