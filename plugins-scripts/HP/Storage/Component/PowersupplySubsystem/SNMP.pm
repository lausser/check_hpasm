package HP::Storage::Component::PowersupplySubsystem::SNMP;
our @ISA = qw(HP::Storage::Component::PowersupplySubsystem);

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
  my $cpqHeFltTolPowerSupplyEntry = "1.3.6.1.4.1.232.6.2.9.3.1";
  my $cpqHeFltTolPowerSupplyChassis = "1.3.6.1.4.1.232.6.2.9.3.1.1";
  my $cpqHeFltTolPowerSupplyBay = "1.3.6.1.4.1.232.6.2.9.3.1.2";
  my $cpqHeFltTolPowerSupplyPresent = "1.3.6.1.4.1.232.6.2.9.3.1.3";
  my $cpqHeFltTolPowerSupplyCondition = "1.3.6.1.4.1.232.6.2.9.3.1.4";
  my $cpqHeFltTolPowerSupplyRedundant = "1.3.6.1.4.1.232.6.2.9.3.1.9";
  my $cpqSeCpuStatus = "1.3.6.1.4.1.232.1.2.2.1.1.6";
  my $cpqHeFltTolPowerSupplyPresentValues = {
      1 => "other",
      2 => "absent",
      3 => "present",
  };
  my $cpqHeFltTolPowerSupplyConditionValues = {
      1 => "other",
      2 => "ok",
      3 => "degraded",
      4 => "failed",
  };
  my $cpqHeFltTolPowerSupplyRedundantValues = {
      1 => "other",
      2 => "notRedundant",
      3 => "redundant",
  };

  # INDEX { cpqHeFltTolPowerSupplyChassis, cpqHeFltTolPowerSupplyBay }
  my @indexes =
      SNMP::Utils::get_indices($snmpwalk, $cpqHeFltTolPowerSupplyEntry);
  foreach (@indexes) {
    my($idx1, $idx2) = ($_->[0], $_->[1]);
    push(@{$self->{powersupplies}},
        HP::Storage::Component::PowersupplySubsystem::Powersupply->new(
      runtime => $params{runtime},
      name =>
        SNMP::Utils::get_number(\@indexes, $idx1, $idx2),
      present =>
        lc SNMP::Utils::get_object_value(
            $snmpwalk, $cpqHeFltTolPowerSupplyPresent,
            $cpqHeFltTolPowerSupplyPresentValues,
            $idx1, $idx2),
      condition =>
        lc SNMP::Utils::get_object_value(
            $snmpwalk, $cpqHeFltTolPowerSupplyCondition,
            $cpqHeFltTolPowerSupplyConditionValues,
            $idx1, $idx2),
      redundant =>
        lc SNMP::Utils::get_object_value(
            $snmpwalk, $cpqHeFltTolPowerSupplyRedundant,
            $cpqHeFltTolPowerSupplyRedundantValues,
            $idx1, $idx2),
    ));
  }
}

