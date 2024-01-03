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
    powerconverters => [],
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
      cpqHeFltTolPowerSupplyStatus => "1.3.6.1.4.1.232.6.2.9.3.1.5",
      cpqHeFltTolPowerSupplyErrorCondition => "1.3.6.1.4.1.232.6.2.9.3.1.18",
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
      cpqHeFltTolPowerSupplyStatusValue => {
          1 => "noError",
          2 => "generalFailure",
          3 => "bistFailure",
          4 => "fanFailure",
          5 => "tempFailure",
          6 => "interlockOpen",
          7 => "epromFailed",
          8 => "vrefFailed",
          9 => "dacFailed",
         10 => "ramTestFailed",
         11 => "voltageChannelFailed",
         12 => "orringdiodeFailed",
         13 => "brownOut",
         14 => "giveupOnStartup",
         15 => "nvramInvalid",
         16 => "calibrationTableInvalid",
         17 => "noPowerInput",
      },
      cpqHeFltTolPowerSupplyErrorConditionValue => {
          1 => "noError",
          2 => "generalFailure",
          3 => "overvoltage",
          4 => "overcurrent",
          5 => "overtemperature",
          6 => "powerinputloss",
          7 => "fanfailure",
          8 => "vinhighwarning",
          9 => "vinlowwarning",
         10 => "vouthighwarning",
         11 => "voutlowwarning",
         12 => "inlettemphighwarning",
         13 => "iinternaltemphighwarning",
         14 => "vauxhighwarning",
         15 => "vauxlowwarning",
      },
      cpqHeFltTolPowerSupplyCapacityUsed => '1.3.6.1.4.1.232.6.2.9.3.1.7',
      cpqHeFltTolPowerSupplyCapacityMaximum => '1.3.6.1.4.1.232.6.2.9.3.1.8',
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

  $oids = {
      cpqHePowerConvEntry => "1.3.6.1.4.1.232.6.2.13.3.1",
      cpqHePowerConvChassis => "1.3.6.1.4.1.232.6.2.13.3.1.1",
      cpqHePowerConvIndex => "1.3.6.1.4.1.232.6.2.13.3.1.2",
      cpqHePowerConvPresent => "1.3.6.1.4.1.232.6.2.13.3.1.3",
      cpqHePowerConvRedundant => "1.3.6.1.4.1.232.6.2.13.3.1.6",
      cpqHePowerConvCondition => "1.3.6.1.4.1.232.6.2.13.3.1.8",
      cpqHePowerConvPresentValue => {
          1 => "other",
          2 => "absent",
          3 => "present",
      },
      cpqHePowerConvRedundantValue => {
          1 => "other",
          2 => "notRedundant",
          3 => "redundant",
      },
      cpqHePowerConvConditionValue => {
          1 => "other",
          2 => "ok",
          3 => "degraded",
          4 => "failed",
      },
      cpqHePowerConvHwLocation => "1.3.6.1.4.1.232.6.2.13.3.1.9",
  };

  # INDEX { cpqHePowerConvChassis cpqHePowerConvIndex }
  foreach ($self->get_entries($oids, 'cpqHePowerConvEntry')) {
    push(@{$self->{powerconverters}},
        HP::Proliant::Component::PowersupplySubsystem::Powerconverter->new(%{$_}));
  }
  # keine ahnung, was man damit machen kann

}

