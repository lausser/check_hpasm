package HP::FCMGMT::Component::SensorSubsystem;
our @ISA = qw(HP::FCMGMT::Component);

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
  if ($self->{method} eq 'snmp') {
    return HP::FCMGMT::SensorSubsystem::SNMP->new(%params);
  } else {
    die "unknown method";
  }
  return $self;
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking cpus');
  if (scalar (@{$self->{sensors}}) == 0) {
  } else {
    foreach (@{$self->{sensors}}) {
      $_->check();
    }
  }
}

sub dump {
  my $self = shift;
  foreach (@{$self->{sensors}}) {
    $_->dump();
  }
}


package HP::FCMGMT::Component::SensorSubsystem::Sensor;
our @ISA = qw(HP::FCMGMT::Component::SensorSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    cpqSeSensorSlot => $params{cpqSeSensorSlot},
    cpqSeSensorUnitIndex => $params{cpqSeSensorUnitIndex},
    cpqSeSensorName => $params{cpqSeSensorName},
    cpqSeSensorStatus => $params{cpqSeSensorStatus},
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('c', $self->{cpqSeSensorUnitIndex});
  if ($self->{cpqSeSensorStatus} ne "ok") {
    if ($self->{runtime}->{options}{scrapiron} &&
        ($self->{cpqSeSensorStatus} eq "unknown")) {
      $self->add_info("cpu %d probably ok (%s)", \'cpqSeSensorUnitIndex', \'cpqSeSensorStatus');
    } else {
      $self->add_info("cpu %d needs attention (%s)", \'cpqSeSensorUnitIndex', \'cpqSeSensorStatus');
      $self->add_message(CRITICAL, $self->{info});
    }
  } else {
    $self->add_info("cpu %d is %s", \'cpqSeSensorUnitIndex', \'cpqSeSensorStatus');
  }
  $self->add_extendedinfo("cpu_%s=%s", \'cpqSeSensorUnitIndex', \'cpqSeSensorStatus');
}

sub dump {
  my $self = shift;
  printf "[CPU_%s]\n", $self->{cpqSeSensorUnitIndex};
  foreach (qw(cpqSeSensorSlot cpqSeSensorUnitIndex cpqSeSensorName cpqSeSensorStatus)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}
