package HP::Storage::Component::CpuSubsystem::CLI;
our @ISA = qw(HP::Storage::Component::CpuSubsystem);

use strict;
use Nagios::Plugin;

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    rawdata => $params{rawdata},
    cpus => [],
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  $self->init(%params);
  return $self;
}

sub init {
  my $self = shift;
  my %params = @_;
  my %tmpcpu = (
    runtime => $params{runtime},
  );
  my $inblock = 0;
  foreach (grep(/^server/, split(/\n/, $self->{rawdata}))) {
    if (/Processor:\s+(\d+)/) {
      $tmpcpu{name} = $1;
      $inblock = 1;
    } elsif (/Status\s*:\s+(.+?)\s*$/) {
      $tmpcpu{status} = lc $1;
    } elsif (/^server\s*$/) {
      if ($inblock) {
        $inblock = 0;
        push(@{$self->{cpus}},
            HP::Storage::Component::CpuSubsystem::Cpu->new(%tmpcpu));
        %tmpcpu = (
          runtime => $params{runtime},
        );
      }
    }
  }
  if ($inblock) {
    push(@{$self->{cpus}},
        HP::Storage::Component::CpuSubsystem::Cpu->new(%tmpcpu));
  }
}

1;
