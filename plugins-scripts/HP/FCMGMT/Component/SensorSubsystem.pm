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
      $self->add_info(sprintf "cpu %d probably ok (%s)",
          $self->{cpqSeSensorUnitIndex}, $self->{cpqSeSensorStatus});
    } else {
      $self->add_info(sprintf "cpu %d needs attention (%s)",
          $self->{cpqSeSensorUnitIndex}, $self->{cpqSeSensorStatus});
      $self->add_message(CRITICAL, $self->{info});
    }
  } else {
    $self->add_info(sprintf "cpu %d is %s", 
        $self->{cpqSeSensorUnitIndex}, $self->{cpqSeSensorStatus});
  }
  $self->add_extendedinfo(sprintf "cpu_%s=%s",
      $self->{cpqSeSensorUnitIndex}, $self->{cpqSeSensorStatus});
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
