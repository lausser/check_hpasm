package HP::FCMGMT::Component::SensorSubsystem::SNMP;
our @ISA = qw(HP::FCMGMT::Component::SensorSubsystem
    HP::Proliant::Component::SNMP);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    rawdata => $params{rawdata},
    sensors => [],
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
  # FCMGMT-MIB
  my $oids = {
      connUnitSensorEntry => '1.3.6.1.3.94.1.8.1',
      connUnitSensorUnitId => '1.3.6.1.3.94.1.8.1.1',
      connUnitSensorIndex => '1.3.6.1.3.94.1.8.1.2',
      connUnitSensorName => '1.3.6.1.3.94.1.8.1.3',
      connUnitSensorStatus => '1.3.6.1.3.94.1.8.1.4',
      connUnitSensorInfo => '1.3.6.1.3.94.1.8.1.5',
      connUnitSensorMessage => '1.3.6.1.3.94.1.8.1.6',
      connUnitSensorType => '1.3.6.1.3.94.1.8.1.7',
      connUnitSensorCharacteristic => '1.3.6.1.3.94.1.8.1.8',
      connUnitSensorStatusValue => {
          1 => "unknown",
          2 => "other",
          3 => "ok",
          4 => "warning",
          5 => "failed",
      },
      connUnitSensorTypeValue => {
          1 => "unknown",
          2 => "other",
          3 => "battery",
          4 => "fan",
          5 => "power-supply",
          6 => "transmitter",
          7 => "enclosure",
          8 => "board",
          9 => "receiver",
      },
      connUnitSensorCharacteristicValue => {
          1 => "unknown",
          2 => "other",
          3 => "temperature",
          4 => "pressure",
          5 => "emf",
          6 => "current",
          7 => "airflow",
          8 => "frequency",
          9 => "power",
          10 => "door",
      },

  };

  # INDEX { connUnitSensorUnitId, connUnitSensorIndex }
  foreach ($self->get_entries($oids, 'connUnitSensorEntry')) {
    push(@{$self->{sensors}},
        HP::FCMGMT::Component::SensorSubsystem::Sensor->new(%{$_}));
  }
}

1;
