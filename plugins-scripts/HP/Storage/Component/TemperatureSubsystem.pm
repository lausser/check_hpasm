package HP::Storage::Component::TemperatureSubsystem;
our @ISA = qw(HP::Storage::Component);

use strict;
use Nagios::Plugin;

sub new {
  my $class = shift;
################################## custom_thresholds
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    rawdata => $params{rawdata},
    method => $params{method},
    condition => $params{condition},
    status => $params{status},
    temperatures => [],
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  if ($params{runtime}->{options}->{customthresholds}) {
    if (-f $params{runtime}->{options}->{customthresholds}) {
      open CT, $params{runtime}->{options}->{customthresholds};
      $params{runtime}->{options}->{customthresholds} = <CT>;
      close CT;
    }
    foreach my $ct_items
        (split(/\//, $params{runtime}->{options}->{customthresholds})) {
      if ($ct_items =~ /^(\d+):(\d+)$/) {
        my $temp = $2;
        $params{runtime}->{options}->{thresholds}->{$1} = $temp;
      } else {
        die sprintf "invalid threshold %s", $ct_items;
      }
    }
  }
  if ($self->{method} eq 'snmp') {
    return HP::Storage::Component::TemperatureSubsystem::SNMP->new(%params);
  } elsif ($self->{method} eq 'cli') {
    return HP::Storage::Component::TemperatureSubsystem::CLI->new(%params);
  } else {
    die "unknown method";
  }
  return $self;
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  if (scalar (@{$self->{temperatures}}) == 0) {
    #$self->overall_check(); 
  } else {
    foreach (@{$self->{temperatures}}) {
      $_->check();
    }
  }
}

sub dump {
  my $self = shift;
  foreach (@{$self->{temperatures}}) {
    $_->dump();
  }
}


package HP::Storage::Component::TemperatureSubsystem::Temperature;
our @ISA = qw(HP::Storage::Component::TemperatureSubsystem);

use strict;
use Nagios::Plugin;

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    name => $params{name},
    location => $params{location},
    degrees => $params{degrees},
    threshold => $params{threshold},
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  if ($self->{degrees} > $self->{threshold}) {
    $self->add_info(sprintf "%s temperature too high (%d%s)",
        $self->{location}, $self->{degrees},
        $self->{runtime}->{options}->{celsius} ? "C" : "F");
    $self->add_message(CRITICAL, $self->{info});
  } else {
    $self->add_info(sprintf "%d %s temperature is %d (%d max)",
        $self->{name}, $self->{location}, 
        $self->{degrees}, $self->{threshold});
  }
  if ($self->{runtime}->{options}->{perfdata} == 2) {
    $self->{runtime}->{plugin}->add_perfdata(
        label => sprintf('temp_%s', $self->{name}),
        value => $self->{degrees},
        warning => $self->{threshold},
        critical => $self->{threshold}
    );
  } elsif ($self->{runtime}->{options}->{perfdata} == 1) {
    $self->{runtime}->{plugin}->add_perfdata(
        label => sprintf('temp_%s_%s', $self->{name}, $self->{location}),
        value => $self->{degrees},
        warning => $self->{threshold},
        critical => $self->{threshold}
    );
  } 
  $self->add_extendedinfo(sprintf "temp_%s=%d",
      $self->{name},
      $self->{degrees});
}

sub dump { 
  my $self = shift;
  printf "[TEMP_%s]\n", $self->{name};
  printf "name: %s\n", $self->{name};
  printf "location: %s\n", $self->{location};
  printf "degrees: %s%s\n", $self->{degrees},
      $self->{runtime}->{options}->{celsius} ? 'C' : 'F';
  printf "threshold: %s\n", $self->{threshold};
  printf "blacklisted: %s\n", $self->{blacklisted};
  printf "info: %s\n\n", $self->{info};
}

1;

