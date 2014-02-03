package HP::Storage::Component::CpuSubsystem::SNMP;
our @ISA = qw(HP::Storage::Component::CpuSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

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
  $self->init();
  return $self;
}

sub init {
  my $self = shift;
  my $snmpwalk = $self->{rawdata};
  # CPQSTDEQ-MIB
  my $cpqSeCpuEntry = "1.3.6.1.4.1.232.1.2.2.1.1";
  my $cpqSeCpuUnitIndex = "1.3.6.1.4.1.232.1.2.2.1.1.1";
  my $cpqSeCpuName = "1.3.6.1.4.1.232.1.2.2.1.1.3";
  my $cpqSeCpuStatus = "1.3.6.1.4.1.232.1.2.2.1.1.6";
  my $cpqSeCpuStatusValues = {
      1 => "unknown",
      2 => "ok",
      3 => "degraded",
      4 => "failed",
      5 => "disabled",
  };

  # INDEX { cpqSeCpuUnitIndex }
  my @indexes = SNMP::Utils::get_indices($snmpwalk, $cpqSeCpuEntry);
  foreach (@indexes) {
    my $idx1 = $_->[0];
    push(@{$self->{cpus}},
        HP::Storage::Component::CpuSubsystem::Cpu->new(
      runtime => $self->{runtime},
      name =>
        SNMP::Utils::get_object($snmpwalk, $cpqSeCpuUnitIndex, $idx1),
      status =>
        lc SNMP::Utils::get_object_value(
            $snmpwalk, $cpqSeCpuStatus,
            $cpqSeCpuStatusValues,
            $idx1),
    ));
  }
}

1;
