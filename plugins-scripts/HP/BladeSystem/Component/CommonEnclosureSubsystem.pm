package HP::BladeSystem::Component::CommonEnclosureSubsystem;
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
    common_enclosures => [],
    common_enclosure_temps => [],
    common_enclosure_fan_subsys => undef,
    common_enclosure_fuses => [],
    common_enclosure_frus => [],
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
  # jeweils ein block fuer
  # enclosures, temps, fans, fuses
  # loop ueber oids und entspr. new
  my $oids = {
      cpqRackCommonEnclosureEntry => '1.3.6.1.4.1.232.22.2.3.1.1.1',
      cpqRackCommonEnclosureRack => '1.3.6.1.4.1.232.22.2.3.1.1.1.1',
      cpqRackCommonEnclosureIndex => '1.3.6.1.4.1.232.22.2.3.1.1.1.2',
      cpqRackCommonEnclosureModel => '1.3.6.1.4.1.232.22.2.3.1.1.1.3',
      cpqRackCommonEnclosureSerialNum => '1.3.6.1.4.1.232.22.2.3.1.1.1.7',
      cpqRackCommonEnclosureFWRev => '1.3.6.1.4.1.232.22.2.3.1.1.1.8',
      cpqRackCommonEnclosureName => '1.3.6.1.4.1.232.22.2.3.1.1.1.9',
      cpqRackCommonEnclosureCondition => '1.3.6.1.4.1.232.22.2.3.1.1.1.16',
      cpqRackCommonEnclosureHasServerBlades => '1.3.6.1.4.1.232.22.2.3.1.1.1.17',
      cpqRackCommonEnclosureHasPowerBlades => '1.3.6.1.4.1.232.22.2.3.1.1.1.18',
      cpqRackCommonEnclosureHasNetConnectors => '1.3.6.1.4.1.232.22.2.3.1.1.1.19',
      cpqRackCommonEnclosureHasTempSensors => '1.3.6.1.4.1.232.22.2.3.1.1.1.20',
      cpqRackCommonEnclosureHasFans => '1.3.6.1.4.1.232.22.2.3.1.1.1.21',
      cpqRackCommonEnclosureHasFuses => '1.3.6.1.4.1.232.22.2.3.1.1.1.22',
      cpqRackCommonEnclosureConditionValue => {
          1 => 'other',
          2 => 'ok',
          3 => 'degraded',
          4 => 'failed',
      },
      cpqRackCommonEnclosureHasServerBladesValue => {
          1 => 'false',
          2 => 'true',
      },
  };
  $oids->{cpqRackCommonEnclosureHasPowerBladesValue} =
    $oids->{cpqRackCommonEnclosureHasServerBladesValue};
  $oids->{cpqRackCommonEnclosureHasNetConnectorsValue} =
    $oids->{cpqRackCommonEnclosureHasServerBladesValue};
  $oids->{cpqRackCommonEnclosureHasTempSensorsValue} =
    $oids->{cpqRackCommonEnclosureHasServerBladesValue};
  $oids->{cpqRackCommonEnclosureHasFansValue} =
    $oids->{cpqRackCommonEnclosureHasServerBladesValue};
  $oids->{cpqRackCommonEnclosureHasServerBladesValue} =
    $oids->{cpqRackCommonEnclosureHasServerBladesValue};
  # INDEX { cpqRackCommonEnclosureRack cpqRackCommonEnclosureIndex }
  foreach ($self->get_entries($oids, 'cpqRackCommonEnclosureEntry')) {
    push(@{$self->{common_enclosures}},
        HP::BladeSystem::Component::CommonEnclosureSubsystem::CommonEnclosure->new(%{$_}));
  }

  $self->{common_enclosure_fan_subsys} = HP::BladeSystem::Component::CommonEnclosureSubsystem::FanSubsystem->new(
      rawdata => $self->{rawdata},
      method => $self->{method},
      runtime => $self->{runtime},
  );
}

sub check {
  my $self = shift;
  foreach (@{$self->{common_enclosures}}) {
    $_->check();
  }
  $self->{common_enclosure_fan_subsys}->check();
}

sub dump {
  my $self = shift;
  foreach (@{$self->{common_enclosures}}) {
    $_->dump();
  }
  $self->{common_enclosure_fan_subsys}->dump();
}


package HP::BladeSystem::Component::CommonEnclosureSubsystem::CommonEnclosure;
our @ISA = qw(HP::BladeSystem::Component::CommonEnclosureSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift; 
  my %params = @_;
  my $self = { 
    runtime => $params{runtime},
    rawdata => $params{rawdata},
    cpqRackCommonEnclosureRack => $params{cpqRackCommonEnclosureRack},
    cpqRackCommonEnclosureIndex => $params{cpqRackCommonEnclosureIndex},
    cpqRackCommonEnclosureModel => $params{cpqRackCommonEnclosureModel},
    cpqRackCommonEnclosureSerialNum => $params{cpqRackCommonEnclosureSerialNum},
    cpqRackCommonEnclosureFWRev => $params{cpqRackCommonEnclosureFWRev},
    cpqRackCommonEnclosureName => $params{cpqRackCommonEnclosureName},
    cpqRackCommonEnclosureCondition => $params{cpqRackCommonEnclosureCondition},
    cpqRackCommonEnclosureHasServerBlades => $params{cpqRackCommonEnclosureHasServerBlades},
    cpqRackCommonEnclosureHasPowerBlades => $params{cpqRackCommonEnclosureHasPowerBlades},
    cpqRackCommonEnclosureHasNetConnectors => $params{cpqRackCommonEnclosureHasNetConnectors},
    cpqRackCommonEnclosureHasTempSensors => $params{cpqRackCommonEnclosureHasTempSensors},
    cpqRackCommonEnclosureHasFans => $params{cpqRackCommonEnclosureHasFans},
    cpqRackCommonEnclosureHasFuses => $params{cpqRackCommonEnclosureHasFuses},
    blacklisted => 0,
    info => undef, 
    extendedinfo => undef,
  };
  $self->{name} = $self->{cpqRackCommonEnclosureRack}.':'.$self->{cpqRackCommonEnclosureIndex};
  bless $self, $class;
  return $self;
}


sub check {
  my $self = shift;
  $self->blacklist('ce', $self->{cpqRackCommonEnclosureName});
  my $info = sprintf 'common enclosure %s condition is %s',
      $self->{cpqRackCommonEnclosureName}, $self->{cpqRackCommonEnclosureCondition};
  $self->add_info($info);
  if ($self->{cpqRackCommonEnclosureCondition} eq 'failed') {
    $self->add_message(CRITICAL, $info);
  } elsif ($self->{cpqRackCommonEnclosureCondition} eq 'degraded') {
    $self->add_message(WARNING, $info);
  } 
}

sub dump {
  my $self = shift;
    printf "[COMMON_ENCLOSURE_%s]\n", $self->{cpqRackCommonEnclosureName};
  foreach (qw(cpqRackCommonEnclosureRack cpqRackCommonEnclosureIndex cpqRackCommonEnclosureModel
      cpqRackCommonEnclosureSerialNum cpqRackCommonEnclosureFWRev cpqRackCommonEnclosureName
      cpqRackCommonEnclosureCondition cpqRackCommonEnclosureHasServerBlades 
      cpqRackCommonEnclosureHasPowerBlades cpqRackCommonEnclosureHasNetConnectors 
      cpqRackCommonEnclosureHasTempSensors cpqRackCommonEnclosureHasFans cpqRackCommonEnclosureHasFuses)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "\n";
}

1;
