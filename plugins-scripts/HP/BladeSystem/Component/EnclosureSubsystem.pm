package HP::BladeSystem::Component::EnclosureSubsystem;
our @ISA = qw(HP::BladeSystem::Component);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    rawdata => $params{rawdata},
    method => $params{method},
    condition => $params{condition},
    common_enclosures => [],
    server_enclosures => [],
    power_enclosures => [],
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
  # cpqRackCommonEnclosureTable
  my $cpqRackCommonEnclosureEntry = '1.3.6.1.4.1.232.22.2.3.1.1.1';
  my $cpqRackCommonEnclosureRack = '1.3.6.1.4.1.232.22.2.3.1.1.1.1';
  my $cpqRackCommonEnclosureIndex = '1.3.6.1.4.1.232.22.2.3.1.1.1.2';
  my $cpqRackCommonEnclosureModel = '1.3.6.1.4.1.232.22.2.3.1.1.1.3';
  my $cpqRackCommonEnclosureSerialNum = '1.3.6.1.4.1.232.22.2.3.1.1.1.7';
  my $cpqRackCommonEnclosureFWRev = '1.3.6.1.4.1.232.22.2.3.1.1.1.8';
  my $cpqRackCommonEnclosureName = '1.3.6.1.4.1.232.22.2.3.1.1.1.9';
  my $cpqRackCommonEnclosureCondition = '1.3.6.1.4.1.232.22.2.3.1.1.1.16';
  my $cpqRackCommonEnclosureHasServerBlades = '1.3.6.1.4.1.232.22.2.3.1.1.1.17';
  my $cpqRackCommonEnclosureHasPowerBlades = '1.3.6.1.4.1.232.22.2.3.1.1.1.18';
  my $cpqRackCommonEnclosureHasNetConnectors = '1.3.6.1.4.1.232.22.2.3.1.1.1.19';
  my $cpqRackCommonEnclosureHasTempSensors = '1.3.6.1.4.1.232.22.2.3.1.1.1.20';
  my $cpqRackCommonEnclosureHasFans = '1.3.6.1.4.1.232.22.2.3.1.1.1.21';
  my $cpqRackCommonEnclosureHasFuses = '1.3.6.1.4.1.232.22.2.3.1.1.1.22';
  my $cpqRackCommonEnclosureConditionValue = {
      1 => 'other',
      2 => 'ok',
      3 => 'degraded',
      4 => 'failed',
  };
  my $cpqRackCommonEnclosureHasServerBladesValue = {
      1 => 'false',
      2 => 'true',
  };
  my $cpqRackCommonEnclosureHasPowerBladesValue = 
      $cpqRackCommonEnclosureHasServerBladesValue;
  my $cpqRackCommonEnclosureHasNetConnectorsValue = 
      $cpqRackCommonEnclosureHasServerBladesValue;
  my $cpqRackCommonEnclosureHasTempSensorsValue = 
      $cpqRackCommonEnclosureHasServerBladesValue;
  my $cpqRackCommonEnclosureHasFansValue = 
      $cpqRackCommonEnclosureHasServerBladesValue;
  my $cpqRackCommonEnclosureHasFusesValue = 
      $cpqRackCommonEnclosureHasServerBladesValue;

  # INDEX { cpqRackCommonEnclosureRack, cpqRackCommonEnclosureIndex }
  # die drecksdoku beschreibt eine doppelte indizierung.
  # tatsächlich gibt es aber nur eine fortlaufende nummer
  my @indexes =
      SNMP::Utils::get_indices($snmpwalk, $cpqRackCommonEnclosureEntry);
  foreach (@indexes) {
    my($idx1) = ($_->[0]);
    my $rack = lc SNMP::Utils::get_object(
        $snmpwalk, $cpqRackCommonEnclosureRack, $idx1);
    my $index = lc SNMP::Utils::get_object(
        $snmpwalk, $cpqRackCommonEnclosureIndex, $idx1);
    my $model = lc SNMP::Utils::get_object(
        $snmpwalk, $cpqRackCommonEnclosureModel, $idx1);
    my $serial = lc SNMP::Utils::get_object(
        $snmpwalk, $cpqRackCommonEnclosureSerialNum, $idx1);
    my $fwrev = lc SNMP::Utils::get_object(
        $snmpwalk, $cpqRackCommonEnclosureFWRev, $idx1);
    my $name = lc SNMP::Utils::get_object(
        $snmpwalk, $cpqRackCommonEnclosureName, $idx1);
    my $condition = lc SNMP::Utils::get_object_value(
        $snmpwalk, $cpqRackCommonEnclosureCondition,
            $cpqRackCommonEnclosureConditionValue, $idx1);
    my $has_serverblades = lc SNMP::Utils::get_object_value(
        $snmpwalk, $cpqRackCommonEnclosureHasServerBlades,
            $cpqRackCommonEnclosureHasServerBladesValue, $idx1);
    my $has_powerblades = lc SNMP::Utils::get_object_value(
        $snmpwalk, $cpqRackCommonEnclosureHasPowerBlades,
            $cpqRackCommonEnclosureHasPowerBladesValue, $idx1);
    my $has_netconnectors = lc SNMP::Utils::get_object_value(
        $snmpwalk, $cpqRackCommonEnclosureHasNetConnectors,
            $cpqRackCommonEnclosureHasNetConnectorsValue, $idx1);
    my $has_tempsensors = lc SNMP::Utils::get_object_value(
        $snmpwalk, $cpqRackCommonEnclosureHasTempSensors,
            $cpqRackCommonEnclosureHasTempSensorsValue, $idx1);
    my $has_fans = lc SNMP::Utils::get_object_value(
        $snmpwalk, $cpqRackCommonEnclosureHasFans,
            $cpqRackCommonEnclosureHasFansValue, $idx1);
    my $has_fuses = lc SNMP::Utils::get_object_value(
        $snmpwalk, $cpqRackCommonEnclosureHasFuses,
            $cpqRackCommonEnclosureHasFusesValue, $idx1);
    push(@{$self->{common_enclosures}},
        HP::BladeSystem::Component::EnclosureSubsystem::CommonEnclosure->new(
            runtime => $self->{runtime},
            rack => $rack,
            enclosure => $index,
            model => $model,
            serial => $serial,
            fwrev => $fwrev,
            name => $name,
            condition => $condition,
            has_serverblades => $has_serverblades,
            has_powerblades => $has_powerblades,
            has_netconnectors => $has_netconnectors,
            has_tempsensors => $has_tempsensors,
            has_fans => $has_fans,
            has_fuses => $has_fuses,
        ));
  }

  # cpqRackServerEnclosureTable
  my $cpqRackServerEnclosureEntry = '1.3.6.1.4.1.232.22.2.3.2.1.1';
  my $cpqRackServerEnclosureRack = '1.3.6.1.4.1.232.22.2.3.2.1.1.1';
  my $cpqRackServerEnclosureIndex = '1.3.6.1.4.1.232.22.2.3.2.1.1.2';
  my $cpqRackServerEnclosureName = '1.3.6.1.4.1.232.22.2.3.2.1.1.3';
  my $cpqRackServerEnclosureMaxNumBlades = '1.3.6.1.4.1.232.22.2.3.2.1.1.4';
  # INDEX { cpqRackServerEnclosureRack, cpqRackServerEnclosureIndex }
  # der gleiche dreck...
  @indexes = 
      SNMP::Utils::get_indices($snmpwalk, $cpqRackServerEnclosureEntry);
  foreach (@indexes) {
    my($idx1) = ($_->[0]);
    my $rack = lc SNMP::Utils::get_object(
        $snmpwalk, $cpqRackServerEnclosureRack, $idx1);
    my $index = lc SNMP::Utils::get_object(
        $snmpwalk, $cpqRackServerEnclosureIndex, $idx1);
    my $name = lc SNMP::Utils::get_object(
        $snmpwalk, $cpqRackServerEnclosureName, $idx1);
    my $maxnumblades = lc SNMP::Utils::get_object(
        $snmpwalk, $cpqRackServerEnclosureMaxNumBlades, $idx1);
    push(@{$self->{server_enclosures}},
        HP::BladeSystem::Component::EnclosureSubsystem::ServerEnclosure->new(
            runtime => $self->{runtime},
            rack => $rack,
            enclosure => $index,
            name => $name,
            maxnumblades => $maxnumblades,
        ));
  }

  # cpqRackPowerEnclosureTable
  my $cpqRackPowerEnclosureEntry = '1.3.6.1.4.1.232.22.2.3.3.1.1';
  my $cpqRackPowerEnclosureRack = '1.3.6.1.4.1.232.22.2.3.3.1.1.1';
  my $cpqRackPowerEnclosureIndex = '1.3.6.1.4.1.232.22.2.3.3.1.1.2';
  my $cpqRackPowerEnclosureName = '1.3.6.1.4.1.232.22.2.3.3.1.1.3';
  my $cpqRackPowerEnclosureMgmgtBoardSerialNum = '1.3.6.1.4.1.232.22.2.3.3.1.1.4';
  my $cpqRackPowerEnclosureRedundant = '1.3.6.1.4.1.232.22.2.3.3.1.1.5';
  my $cpqRackPowerEnclosureLoadBalanced = '1.3.6.1.4.1.232.22.2.3.3.1.1.6';
  my $cpqRackPowerEnclosureInputPwrType = '1.3.6.1.4.1.232.22.2.3.3.1.1.7';
  my $cpqRackPowerEnclosurePwrFeedMax = '1.3.6.1.4.1.232.22.2.3.3.1.1.8';
  my $cpqRackPowerEnclosureCondition = '1.3.6.1.4.1.232.22.2.3.3.1.1.9';
  my $cpqRackPowerEnclosureRedundantValue = {
      1 => 'other',
      2 => 'notRedundant',
      3 => 'redundant',
  };
  my $cpqRackPowerEnclosureLoadBalancedValue = {
      -1 => 'aechz',
      1 => 'other',
      2 => 'notLoadBalanced',
      3 => 'loadBalanced',
  };
  my $cpqRackPowerEnclosureInputPwrTypeValue = {
      1 => 'other',
      2 => 'singlePhase',
      3 => 'threePhase',
      4 => 'directCurrent',
  };
  my $cpqRackPowerEnclosureConditionValue = {
      1 => 'other',
      2 => 'ok',
      3 => 'degraded',
  };
  
  # INDEX { cpqRackPowerEnclosureRack, cpqRackPowerEnclosureIndex }
  # dreckada dreck, dreckada
  @indexes = 
      SNMP::Utils::get_indices($snmpwalk, $cpqRackPowerEnclosureEntry);
  foreach (@indexes) {
    my($idx1) = ($_->[0]);
    my $rack = lc SNMP::Utils::get_object(
        $snmpwalk, $cpqRackServerEnclosureRack, $idx1);
    my $index = lc SNMP::Utils::get_object(
        $snmpwalk, $cpqRackServerEnclosureIndex, $idx1);
    my $name = lc SNMP::Utils::get_object(
        $snmpwalk, $cpqRackServerEnclosureName, $idx1);
    my $serial = lc SNMP::Utils::get_object(
        $snmpwalk, $cpqRackPowerEnclosureMgmgtBoardSerialNum, $idx1);
    my $redundant = lc SNMP::Utils::get_object_value(
        $snmpwalk, $cpqRackPowerEnclosureRedundant,
        $cpqRackPowerEnclosureRedundantValue, $idx1);
    my $loadbalanced = lc SNMP::Utils::get_object_value(
        $snmpwalk, $cpqRackPowerEnclosureLoadBalanced,
        $cpqRackPowerEnclosureLoadBalancedValue, $idx1);
    my $pwrtype = lc SNMP::Utils::get_object_value(
        $snmpwalk, $cpqRackPowerEnclosureInputPwrType,
        $cpqRackPowerEnclosureInputPwrTypeValue, $idx1);
    my $pwrfeedmax = lc SNMP::Utils::get_object(
        $snmpwalk, $cpqRackPowerEnclosurePwrFeedMax, $idx1);
    my $condition = lc SNMP::Utils::get_object_value(
        $snmpwalk, $cpqRackPowerEnclosureCondition,
        $cpqRackPowerEnclosureConditionValue, $idx1);
    push(@{$self->{power_enclosures}},
        HP::BladeSystem::Component::EnclosureSubsystem::PowerEnclosure->new(
            runtime => $self->{runtime},
            rack => $rack,
            enclosure => $index,
            name => $name,
            serial => $serial,
            redundant => $redundant,
            loadbalanced => $loadbalanced,
            pwrtype => $pwrtype,
            pwrfeedmax => $pwrfeedmax,
            condition => $condition,
        ));
  }

}

sub check {
  my $self = shift;
  foreach (@{$self->{common_enclosures}}) {
    $_->check();
  }
}

sub dump {
  my $self = shift;
  foreach (@{$self->{common_enclosures}}) {
    $_->dump();
  }
  foreach (@{$self->{server_enclosures}}) {
    $_->dump();
  }
  foreach (@{$self->{power_enclosures}}) {
    $_->dump();
  }
}


package HP::BladeSystem::Component::EnclosureSubsystem::CommonEnclosure;
our @ISA = qw(HP::BladeSystem::Component::EnclosureSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    rawdata => $params{rawdata},
    method => $params{method},
    rack => $params{rack},
    enclosure => $params{enclosure},
    model => $params{model},
    serial => $params{serial},
    fwrev => $params{fwrev},
    name => $params{name},
    condition => $params{condition},
    has_serverblades => $params{has_serverblades},
    has_powerblades => $params{has_powerblades},
    has_netconnectors => $params{has_netconnectors},
    has_tempsensors => $params{has_tempsensors},
    has_fans => $params{has_fans},
    has_fuses => $params{has_fuses},
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  $self->init();
  return $self;
}

sub init {
}

sub check {
  my $self = shift;
  if ($self->{condition} ne 'ok') {
    $self->add_message(CRITICAL,
        sprintf 'enclosure %s needs attention', $self->{name});
  }
  $self->add_info(sprintf 'enclosure %s is %s',
      $self->{name}, $self->{condition});
}

sub dump {
  my $self = shift;
  printf "[ENCLOSURE_%s]\n", $self->{name};
  foreach (qw(rack enclosure model serial fwrev condition has_serverblades 
      has_powerblades has_netconnectors has_tempsensors has_fans has_fuses)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "\n";
}


package HP::BladeSystem::Component::EnclosureSubsystem::ServerEnclosure;
our @ISA = qw(HP::BladeSystem::Component::EnclosureSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    rawdata => $params{rawdata},
    method => $params{method},
    rack => $params{rack},
    enclosure => $params{enclosure},
    name => $params{name},
    maxnumblades => $params{maxnumblades},
    condition => $params{condition},
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  $self->init();
  return $self;
}

sub init {
}

sub dump {
  my $self = shift;
  printf "[SERVER_ENCLOSURE_%s]\n", $self->{name};
  foreach (qw(rack enclosure maxnumblades)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "\n";
}


package HP::BladeSystem::Component::EnclosureSubsystem::PowerEnclosure;
our @ISA = qw(HP::BladeSystem::Component::EnclosureSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    rawdata => $params{rawdata},
    method => $params{method},
    rack => $params{rack},
    enclosure => $params{enclosure},
    name => $params{name},
    serial => $params{serial},
    redundant => $params{redundant},
    loadbalanced => $params{loadbalanced},
    pwrtype => $params{pwrtype},
    pwrfeedmax => $params{pwrfeedmax},
    condition => $params{condition},
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  $self->init();
  return $self;
}

sub init {
}

sub dump {
  my $self = shift;
  printf "[POWER_ENCLOSURE_%s]\n", $self->{name};
  foreach (qw(rack enclosure serial redundant loadbalanced pwrtype pwrfeedmax
      condition)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "\n";
}

1;

