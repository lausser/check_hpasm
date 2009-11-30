package HP::Storage::Component::CpuSubsystem;
our @ISA = qw(HP::Storage::Component);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
################################## scrapiron ##########
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    rawdata => $params{rawdata},
    method => $params{method},
    condition => $params{condition},
    status => $params{status},
    cpus => [],
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  if ($self->{method} eq 'snmp') {
    return HP::Storage::Component::CpuSubsystem::SNMP->new(%params);
  } elsif ($self->{method} eq 'cli') {
    return HP::Storage::Component::CpuSubsystem::CLI->new(%params);
  } else {
    die "unknown method";
  }
  return $self;
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  if (scalar (@{$self->{cpus}}) == 0) {
    # sachen gibts.....
  #  $self->overall_check(); # sowas ist mir nur einmal untergekommen
  } else {
    foreach (@{$self->{cpus}}) {
      $_->check();
    }
  }
}

sub dump {
  my $self = shift;
  foreach (@{$self->{cpus}}) {
    $_->dump();
  }
}


package HP::Storage::Component::CpuSubsystem::Cpu;
our @ISA = qw(HP::Storage::Component::CpuSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    name => $params{name},
    status => $params{status},
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  if ($self->{status} ne "ok") {
    if ($self->{runtime}->{options}{scrapiron} &&
        ($self->{status} eq "unknown")) {
      $self->add_info(sprintf "cpu #%d probably ok (%s)",
          $self->{name}, $self->{status});
    } else {
      $self->add_info(sprintf "cpu #%d needs attention (%s)",
          $self->{name}, $self->{status});
      $self->add_message(CRITICAL, $self->{info});
    }
  } else {
    $self->add_info(sprintf "cpu #%d is %s", $self->{name}, $self->{status});
  }
  $self->add_extendedinfo(sprintf "cpu_%s=%s",
      $self->{name}, $self->{status});
}

sub dump {
  my $self = shift;
  printf "[CPU_%s]\n", $self->{name};
  printf "name: %s\n", $self->{name};
  printf "status: %s\n", $self->{status};
  printf "blacklisted: %s\n", $self->{blacklisted};
  printf "scrapiron: %s\n", $self->{runtime}->{options}->{scrapiron};
  printf "info: %s\n\n", $self->{info};
}
