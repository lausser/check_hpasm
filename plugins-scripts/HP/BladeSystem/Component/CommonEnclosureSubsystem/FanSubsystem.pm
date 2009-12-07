package HP::BladeSystem::Component::CommonEnclosureSubsystem::FanSubsystem;
our @ISA = qw(HP::BladeSystem::Component::CommonEnclosureSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    rawdata => $params{rawdata},
    method => $params{method},
    blacklisted => 0,
    fans => [],
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  $self->init();
  return $self;
}

sub init {
  my $self = shift;
  my $oids = {
      cpqRackCommonEnclosureFanEntry => '1.3.6.1.4.1.232.22.2.3.1.3.1',
      cpqRackCommonEnclosureFanRack => '1.3.6.1.4.1.232.22.2.3.1.3.1.1',
      cpqRackCommonEnclosureFanChassis => '1.3.6.1.4.1.232.22.2.3.1.3.1.2',
      cpqRackCommonEnclosureFanIndex => '1.3.6.1.4.1.232.22.2.3.1.3.1.3',
      cpqRackCommonEnclosureFanEnclosureName => '1.3.6.1.4.1.232.22.2.3.1.3.1.4',
      cpqRackCommonEnclosureFanLocation => '1.3.6.1.4.1.232.22.2.3.1.3.1.5',
      cpqRackCommonEnclosureFanPartNumber => '1.3.6.1.4.1.232.22.2.3.1.3.1.6',
      cpqRackCommonEnclosureFanSparePartNumber => '1.3.6.1.4.1.232.22.2.3.1.3.1.7',
      cpqRackCommonEnclosureFanPresent => '1.3.6.1.4.1.232.22.2.3.1.3.1.8',
      cpqRackCommonEnclosureFanRedundant => '1.3.6.1.4.1.232.22.2.3.1.3.1.9',
      cpqRackCommonEnclosureFanRedundantGroupId => '1.3.6.1.4.1.232.22.2.3.1.3.1.10',
      cpqRackCommonEnclosureFanCondition => '1.3.6.1.4.1.232.22.2.3.1.3.1.11',
      cpqRackCommonEnclosureFanEnclosureSerialNum => '1.3.6.1.4.1.232.22.2.3.1.3.1.12',
      cpqRackCommonEnclosureFanPresentValue => {
          1 => 'other',
          2 => 'absent',
          3 => 'present',
      },
      cpqRackCommonEnclosureFanRedundantValue => {
          0 => 'other', # meiner phantasie entsprungen, da sich hp nicht aeussert
          1 => 'other',
          2 => 'notRedundant',
          3 => 'redundant',
      },
      cpqRackCommonEnclosureFanConditionValue => {
          1 => 'other',
          2 => 'ok',
          3 => 'degraded',
          4 => 'failed',
      }
  };
  # INDEX { cpqRackCommonEnclosureFanRack, cpqRackCommonEnclosureFanChassis, cpqRackCommonEnclosureFanIndex }
  foreach ($self->get_entries($oids, 'cpqRackCommonEnclosureFanEntry')) {
    push(@{$self->{fans}},
        HP::BladeSystem::Component::CommonEnclosureSubsystem::FanSubsystem::Fan->new(%{$_}));
  }

}

sub check {
  my $self = shift;
  foreach (@{$self->{fans}}) {
    $_->check();
  }
}

sub dump {
  my $self = shift;
  foreach (@{$self->{fans}}) {
    $_->dump();
  }
}


package HP::BladeSystem::Component::CommonEnclosureSubsystem::FanSubsystem::Fan;

our @ISA = qw(HP::BladeSystem::Component::CommonEnclosureSubsystem::FanSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    rawdata => $params{rawdata},
    method => $params{method},cklisted => 0,
#params
    cpqRackCommonEnclosureFanEntry => $params{cpqRackCommonEnclosureFanEntry},
    cpqRackCommonEnclosureFanRack => $params{cpqRackCommonEnclosureFanRack},
    cpqRackCommonEnclosureFanChassis => $params{cpqRackCommonEnclosureFanChassis},
    cpqRackCommonEnclosureFanIndex => $params{cpqRackCommonEnclosureFanIndex},
    cpqRackCommonEnclosureFanEnclosureName => $params{cpqRackCommonEnclosureFanEnclosureName},
    cpqRackCommonEnclosureFanLocation => $params{cpqRackCommonEnclosureFanLocation},
    cpqRackCommonEnclosureFanPartNumber => $params{cpqRackCommonEnclosureFanPartNumber},
    cpqRackCommonEnclosureFanSparePartNumber => $params{cpqRackCommonEnclosureFanSparePartNumber},
    cpqRackCommonEnclosureFanPresent => $params{cpqRackCommonEnclosureFanPresent},
    cpqRackCommonEnclosureFanRedundant => $params{cpqRackCommonEnclosureFanRedundant},
    cpqRackCommonEnclosureFanRedundantGroupId => $params{cpqRackCommonEnclosureFanRedundantGroupId},
    cpqRackCommonEnclosureFanCondition => $params{cpqRackCommonEnclosureFanCondition},
    cpqRackCommonEnclosureFanEnclosureSerialNum => $params{cpqRackCommonEnclosureFanEnclosureSerialNum},
    info => undef,
    extendedinfo => undef,
  };
  $self->{name} = $self->{cpqRackCommonEnclosureFanRack}.':'.$self->{cpqRackCommonEnclosureFanChassis}.':'.$self->{cpqRackCommonEnclosureFanIndex};
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('f', $self->{name});
  $self->add_info(sprintf 'fan %s is %s, location is %s, redundance is %s',
      $self->{name}, $self->{cpqRackCommonEnclosureFanPresent},
      $self->{cpqRackCommonEnclosureFanLocation},
      $self->{cpqRackCommonEnclosureFanRedundant});
  if ($self->{cpqRackCommonEnclosureFanCondition} eq 'degraded') {
    $self->add_message(WARNING, 'fan %s is %s', $self->{name},
        $self->{cpqRackCommonEnclosureFanCondition});
  } elsif ($self->{cpqRackCommonEnclosureFanCondition} eq 'failed') {
    $self->add_message(CRITICAL, 'fan %s is %s', $self->{name},
        $self->{cpqRackCommonEnclosureFanCondition});
  }

}

sub dump {
  my $self = shift;
  printf "[FAN_%s]\n", $self->{name};
  foreach (qw(cpqRackCommonEnclosureFanRack cpqRackCommonEnclosureFanChassis 
      cpqRackCommonEnclosureFanIndex cpqRackCommonEnclosureFanEnclosureName 
      cpqRackCommonEnclosureFanLocation cpqRackCommonEnclosureFanPartNumber 
      cpqRackCommonEnclosureFanSparePartNumber cpqRackCommonEnclosureFanPresent 
      cpqRackCommonEnclosureFanRedundant cpqRackCommonEnclosureFanRedundantGroupId
      cpqRackCommonEnclosureFanCondition cpqRackCommonEnclosureFanEnclosureSerialNum)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

1;
