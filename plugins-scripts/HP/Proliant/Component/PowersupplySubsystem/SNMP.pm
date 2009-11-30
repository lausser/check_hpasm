package HP::Proliant::Component::PowersupplySubsystem::SNMP;
our @ISA = qw(HP::Proliant::Component::PowersupplySubsystem
    HP::Proliant::Component::SNMP);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    rawdata => $params{rawdata},
    powersupplies => [],
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
  my $snmpwalk = $self->{rawdata};
  my $oids = {
      cpqHeFltTolPowerSupplyEntry => "1.3.6.1.4.1.232.6.2.9.3.1",
      cpqHeFltTolPowerSupplyChassis => "1.3.6.1.4.1.232.6.2.9.3.1.1",
      cpqHeFltTolPowerSupplyBay => "1.3.6.1.4.1.232.6.2.9.3.1.2",
      cpqHeFltTolPowerSupplyPresent => "1.3.6.1.4.1.232.6.2.9.3.1.3",
      cpqHeFltTolPowerSupplyCondition => "1.3.6.1.4.1.232.6.2.9.3.1.4",
      cpqHeFltTolPowerSupplyRedundant => "1.3.6.1.4.1.232.6.2.9.3.1.9",
      cpqHeFltTolPowerSupplyPresentValue => {
          1 => "other",
          2 => "absent",
          3 => "present",
      },
      cpqHeFltTolPowerSupplyConditionValue => {
          1 => "other",
          2 => "ok",
          3 => "degraded",
          4 => "failed",
      },
      cpqHeFltTolPowerSupplyRedundantValue => {
          1 => "other",
          2 => "notRedundant",
          3 => "redundant",
      },
  };

  # INDEX { cpqHeFltTolPowerSupplyChassis, cpqHeFltTolPowerSupplyBay }
  foreach ($self->get_entries($oids, 'cpqHeFltTolPowerSupplyEntry')) {
    push(@{$self->{powersupplies}},
        HP::Proliant::Component::PowersupplySubsystem::Powersupply->new(%{$_}));
  }
}

