package HP::Storage::Component::FanSubsystem::SNMP;
our @ISA = qw(HP::Storage::Component::FanSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    rawdata => $params{rawdata},
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  #  fans => [],
    fans => [],
    he_fans => [],
    th_fans => [],
  };
  bless $self, $class;
  $self->overall_init(%params);
  $self->he_init(%params);
  $self->te_init(%params);
  $self->unite();
  return $self;
}

sub overall_init {
  my $self = shift;
  my %params = @_;
  my $snmpwalk = $params{rawdata};
  # overall
  my $cpqHeThermalSystemFanStatus = '1.3.6.1.4.1.232.6.2.6.4.0';
  my $cpqHeThermalSystemFanStatusValue = {
    1 => 'other',
    2 => 'ok',
    3 => 'degraded',
    4 => 'failed',
  };
  my $cpqHeThermalCpuFanStatus = '1.3.6.1.4.1.232.6.2.6.5.0';
  my $cpqHeThermalCpuFanStatusValue = {
    1 => 'other',
    2 => 'ok',
    4 => 'failed', # shutdown
  };
  $self->{sysstatus} = lc SNMP::Utils::get_object_value(
      $snmpwalk, $cpqHeThermalSystemFanStatus,
      $cpqHeThermalSystemFanStatusValue);
  $self->{cpustatus} = lc SNMP::Utils::get_object_value(
      $snmpwalk, $cpqHeThermalCpuFanStatus,
      $cpqHeThermalCpuFanStatusValue);
}

sub te_init {
  my $self = shift;
  my %params = @_;
  my $snmpwalk = $params{rawdata};
  my $ignore_redundancy = $params{ignore_redundancy};
  # cpqHeThermalFanTable
  my $cpqHeThermalFanEntry = "1.3.6.1.4.1.232.6.2.6.6.1";
  my $cpqHeThermalFanIndex = "1.3.6.1.4.1.232.6.2.6.6.1.1";
  my $cpqHeThermalFanRequired = "1.3.6.1.4.1.232.6.2.6.6.1.2";
  my $cpqHeThermalFanPresent = "1.3.6.1.4.1.232.6.2.6.6.1.3";
  my $cpqHeThermalFanCpuFan = "1.3.6.1.4.1.232.6.2.6.6.1.4";
  my $cpqHeThermalFanStatus = "1.3.6.1.4.1.232.6.2.6.6.1.5";
  my $cpqHeThermalFanHwLocation = "1.3.6.1.4.1.232.6.2.6.6.1.6";
  my $cpqHeThermalFanRequiredValue = {
    1 => 'other',
    2 => 'nonRequired',
    3 => 'required',
  };
  my $cpqHeThermalFanPresentValue = {
    1 => 'other',
    2 => 'absent',
    3 => 'present',
  };
  my $cpqHeThermalFanCpuFanValue = {
    1 => 'other',
    2 => 'systemFan',
    3 => 'cpuFan',
  };
  my $cpqHeThermalFanStatusValue = {
    1 => 'other',
    2 => 'ok',
    4 => 'failed',
  };
  # INDEX { cpqHeThermalFanIndex }
  my @indexes = SNMP::Utils::get_indices($snmpwalk, $cpqHeThermalFanEntry);
  foreach (@indexes) {
    my($idx1) = ($_->[0]);
    my $name = SNMP::Utils::get_number(\@indexes, $idx1);
    my $required = lc SNMP::Utils::get_object_value(
        $snmpwalk, $cpqHeThermalFanRequired,
        $cpqHeThermalFanRequiredValue,
        $idx1);
    my $present = lc SNMP::Utils::get_object_value(
        $snmpwalk, $cpqHeThermalFanPresent,
        $cpqHeThermalFanPresentValue,
        $idx1);
    my $condition = lc SNMP::Utils::get_object_value(
        $snmpwalk, $cpqHeThermalFanStatus,
        $cpqHeThermalFanStatusValue, # unschoen: vermischung condition/status
        $idx1);
    my $location = lc SNMP::Utils::get_object(
        $snmpwalk, $cpqHeThermalFanHwLocation, $idx1);
    push(@{$self->{te_fans}},
        HP::Storage::Component::FanSubsystem::Fan->new(
            runtime => $params{runtime},
            name => $name,
            location => $location,
            present => $present,
            condition => $condition,
            required => $required,
    )) unless ! $present;
  }
}

sub he_init {
  my $self = shift;
  my %params = @_;
  my $snmpwalk = $params{rawdata};
  my $ignore_redundancy = $params{ignore_redundancy};
  # cpqHeFltTolFanTable
  my $cpqHeFltTolFanEntry = "1.3.6.1.4.1.232.6.2.6.7.1";
  my $cpqHeFltTolFanChassis = "1.3.6.1.4.1.232.6.2.6.7.1.1";
  my $cpqHeFltTolFanIndex = "1.3.6.1.4.1.232.6.2.6.7.1.2";
  my $cpqHeFltTolFanLocale = "1.3.6.1.4.1.232.6.2.6.7.1.3";
  my $cpqHeFltTolFanPresent = "1.3.6.1.4.1.232.6.2.6.7.1.4";
  my $cpqHeFltTolFanType = "1.3.6.1.4.1.232.6.2.6.7.1.5";
  my $cpqHeFltTolFanSpeed = "1.3.6.1.4.1.232.6.2.6.7.1.6";
  my $cpqHeFltTolFanRedundant = "1.3.6.1.4.1.232.6.2.6.7.1.7";
  my $cpqHeFltTolFanRedundantPartner = "1.3.6.1.4.1.232.6.2.6.7.1.8";
  my $cpqHeFltTolFanCondition = "1.3.6.1.4.1.232.6.2.6.7.1.9";
  my $cpqHeFltTolFanLocaleValue = {
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
  my $cpqHeFltTolFanPresentValue = {
      1 => "other",
      2 => "absent",
      3 => "present",
  };
  my $cpqHeFltTolFanSpeedValue = {
      1 => "other",
      2 => "normal",
      3 => "high",
  };
  my $cpqHeFltTolFanRedundantValue = {
      1 => "other",
      2 => "notRedundant",
      3 => "redundant",
  };
  my $cpqHeFltTolFanTypeValue = {
      1 => "other",
      2 => "tachInput",
      3 => "spinDetect",
  };
  my $cpqHeFltTolFanConditionValue = {
      1 => "other",
      2 => "ok",
      3 => "degraded",
      4 => "failed",
  };
  # INDEX { cpqHeFltTolFanChassis, cpqHeFltTolFanIndex }
  my @indexes = SNMP::Utils::get_indices($snmpwalk, $cpqHeFltTolFanEntry);
  foreach (@indexes) {
    my($idx1, $idx2) = ($_->[0], $_->[1]);
    my $name = SNMP::Utils::get_number(\@indexes, $idx1, $idx2);
    my $location = lc SNMP::Utils::get_object_value(
        $snmpwalk, $cpqHeFltTolFanLocale,
        $cpqHeFltTolFanLocaleValue,
        $idx1, $idx2);
    my $present = lc SNMP::Utils::get_object_value(
        $snmpwalk, $cpqHeFltTolFanPresent,
        $cpqHeFltTolFanPresentValue,
        $idx1, $idx2);
    my $condition = lc SNMP::Utils::get_object_value(
        $snmpwalk, $cpqHeFltTolFanCondition,
        $cpqHeFltTolFanConditionValue,
        $idx1, $idx2);
    my $speed = lc SNMP::Utils::get_object_value(
        $snmpwalk, $cpqHeFltTolFanSpeed,
        $cpqHeFltTolFanSpeedValue,
        $idx1, $idx2);
# nur mit spindetect getestet. gibts bei tachinput evt eine zahl?
    my $pctmax = 50; # if absent 0
    my $redundant = lc SNMP::Utils::get_object_value(
        $snmpwalk, $cpqHeFltTolFanRedundant,
        $cpqHeFltTolFanRedundantValue,
        $idx1, $idx2);
    my $partner = SNMP::Utils::get_object(
        $snmpwalk, $cpqHeFltTolFanRedundantPartner,
        $idx1, $idx2) || 'n/a';
    push(@{$self->{he_fans}},
        HP::Storage::Component::FanSubsystem::Fan->new(
            runtime => $params{runtime},
            name => $name,
            location => $location,
            present => $present,
            condition => $condition,
            speed => $speed,
# nur mit spindetect getestet. gibts bei tachinput evt eine zahl?
            pctmax => $pctmax,
            redundant => $redundant,
            partner => $partner,
    )) unless ! $present;
    # z.b. USM65201WS hat nur solche fragmente. die werden erst gar nicht
    # als fans akzeptiert. dafuer gibts dann die overall condition
    # SNMPv2-SMI::enterprises.232.6.2.6.7.1.1.0.1 = INTEGER: 0
    # SNMPv2-SMI::enterprises.232.6.2.6.7.1.1.0.2 = INTEGER: 0

  }
}

sub unite {
  my $self = shift;
  @{$self->{fans}} = @{$self->{he_fans}};
}

sub overall_check {
  my $self = shift;
  if ($self->{sysstatus} ne 'ok') {
    $self->add_message(CRITICAL, 'system fan overall status is %s', \'sysstatus');
  } 
  if ($self->{cpustatus} ne 'ok') {
    $self->add_message(CRITICAL, 'cpu fan overall status is %s', \'cpustatus');
  } 
  $self->add_info('overall fan status: fan=%s, cpu=%s', \'sysstatus', \'cpustatus');
}

1;

