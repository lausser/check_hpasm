package HP::Storage::Component::TemperatureSubsystem::SNMP;
our @ISA = qw(HP::Storage::Component::TemperatureSubsystem);

use strict;
use Nagios::Plugin;

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
  my $cpqHeTemperatureEntry = "1.3.6.1.4.1.232.6.2.6.8.1";
  my $cpqHeTemperatureChassis = "1.3.6.1.4.1.232.6.2.6.8.1.1";
  my $cpqHeTemperatureIndex = "1.3.6.1.4.1.232.6.2.6.8.1.2";
  my $cpqHeTemperatureLocale = "1.3.6.1.4.1.232.6.2.6.8.1.3";
  my $cpqHeTemperatureCelsius = "1.3.6.1.4.1.232.6.2.6.8.1.4";
  my $cpqHeTemperatureThreshold = "1.3.6.1.4.1.232.6.2.6.8.1.5";
  my $cpqHeTemperatureCondition = "1.3.6.1.4.1.232.6.2.6.8.1.6";
  my $cpqHeTemperatureLocaleValue = {
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
  };
  # INDEX { cpqHeTemperatureChassis, cpqHeTemperatureIndex }
  my @indexes =
      SNMP::Utils::get_indices($snmpwalk, $cpqHeTemperatureEntry);
  foreach (@indexes) {
    my($idx1, $idx2) = ($_->[0], $_->[1]);
    my $name = SNMP::Utils::get_number(\@indexes, $idx1, $idx2);
    my $degrees = SNMP::Utils::get_object(
        $snmpwalk, $cpqHeTemperatureCelsius, $idx1, $idx2);
    $degrees = ((($degrees * 9) / 5) + 32)
        unless $params{runtime}->{options}->{celsius};
    my $threshold = (exists $self->{runtime}->{options}->{thresholds}->{$name}) ?
        $self->{runtime}->{options}->{thresholds}->{$name} :
        $params{runtime}->{options}->{celsius} ?
            SNMP::Utils::get_object(
                $snmpwalk, $cpqHeTemperatureThreshold, $idx1, $idx2) :
            ((SNMP::Utils::get_object(
                $snmpwalk, $cpqHeTemperatureThreshold, $idx1, $idx2)
                * 9) / 5) + 32;
    push(@{$self->{temperatures}},
      HP::Storage::Component::TemperatureSubsystem::Temperature->new(
        runtime => $params{runtime},
        name => $name,
        location =>
          lc SNMP::Utils::get_object_value(
              $snmpwalk, $cpqHeTemperatureLocale,
              $cpqHeTemperatureLocaleValue,
              $idx1, $idx2),
        degrees => $degrees,
        threshold => $threshold,
    ));
  }
}

1;
