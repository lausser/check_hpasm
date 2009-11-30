package HP::Proliant::Component::TemperatureSubsystem::SNMP;
our @ISA = qw(HP::Proliant::Component::TemperatureSubsystem
    HP::Proliant::Component::SNMP);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    rawdata => $params{rawdata},
    temperatures => [],
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
      cpqHeTemperatureEntry => "1.3.6.1.4.1.232.6.2.6.8.1",
      cpqHeTemperatureChassis => "1.3.6.1.4.1.232.6.2.6.8.1.1",
      cpqHeTemperatureIndex => "1.3.6.1.4.1.232.6.2.6.8.1.2",
      cpqHeTemperatureLocale => "1.3.6.1.4.1.232.6.2.6.8.1.3",
      cpqHeTemperatureCelsius => "1.3.6.1.4.1.232.6.2.6.8.1.4",
      cpqHeTemperatureThreshold => "1.3.6.1.4.1.232.6.2.6.8.1.5",
      cpqHeTemperatureCondition => "1.3.6.1.4.1.232.6.2.6.8.1.6",
      cpqHeTemperatureLocaleValue => {
          1 => "other",
          2 => "unknown",
          3 => "system",
          4 => "systemBoard",
          5 => "ioBoard",
          6 => "cpu",
          7 => "memory",
          8 => "storage",
          9 => "removableMedia",
          10 => "powerSupply",
          11 => "ambient",
          12 => "chassis",
          13 => "bridgeCard",
      },
      cpqHeTemperatureConditionValue => {
          1 => 'other',
          2 => 'ok',
          3 => 'degraded',
          4 => 'failed',
      }
  };
  # INDEX { cpqHeTemperatureChassis, cpqHeTemperatureIndex }
  foreach ($self->get_entries($oids, 'cpqHeTemperatureEntry')) {
    push(@{$self->{temperatures}},
        HP::Proliant::Component::TemperatureSubsystem::Temperature->new(%{$_}));
  }
}

1;
