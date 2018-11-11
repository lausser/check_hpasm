package HP::Storage::Component::PowersupplySubsystem;
our @ISA = qw(HP::Storage::Component);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
################################## fan_redundancy ##########
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    rawdata => $params{rawdata},
    method => $params{method},
    condition => $params{condition},
    status => $params{status},
    powersupplies => [],
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  if ($self->{method} eq 'snmp') {
    return HP::Storage::Component::PowersupplySubsystem::SNMP->new(%params);
  } elsif ($self->{method} eq 'cli') {
    return HP::Storage::Component::PowersupplySubsystem::CLI->new(%params);
  } else {
    die "unknown method";
  }
  return $self;
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  if (scalar (@{$self->{powersupplies}}) == 0) {
    #$self->overall_check();
  } else {
    foreach (@{$self->{powersupplies}}) {
      $_->check();
    }
  }
}

sub dump {
  my $self = shift;
  foreach (@{$self->{powersupplies}}) {
    $_->dump();
  }
}


package HP::Storage::Component::PowersupplySubsystem::Powersupply;
our @ISA = qw(HP::Storage::Component::PowersupplySubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    name => $params{name},
    present => $params{present},
    redundant => $params{redundant},
    condition => $params{condition},
    blacklisted => 0,
    info => undef,
    extendexinfo => undef,
  };
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  if ($self->{present} eq "present") {
    if ($self->{condition} ne "ok") {
      if ($self->{condition} eq "n/a") {
        $self->add_info("powersupply #%d is missing", \'name');
      } else {
        $self->add_info("powersupply #%d needs attention (%s)", \'name', \'condition');
      }
      $self->add_message(CRITICAL, $self->{info});
    } else {
      $self->add_info("powersupply #%d is %s", \'name', \'condition');
    }
    $self->add_extendedinfo("ps_%s=%s", \'name', \'condition');
  } else {
    $self->add_info("powersupply #%d is %s", \'name', \'present');
    $self->add_extendedinfo("ps_%s=%s", \'name', \'present');
  }
}


sub dump {
  my $self = shift;
  printf "[PS_%s]\n", $self->{name};
  printf "name: %s\n", $self->{name};
  printf "present: %s\n", $self->{present};
  printf "redundant: %s\n", $self->{redundant};
  printf "condition: %s\n", $self->{condition};
  printf "blacklisted: %s\n", $self->{blacklisted};
  printf "info: %s\n\n", $self->{info};
}

1;
