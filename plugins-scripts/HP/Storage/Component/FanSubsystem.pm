package HP::Storage::Component::FanSubsystem;
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
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  if ($self->{method} eq 'snmp') {
    return HP::Storage::Component::FanSubsystem::SNMP->new(%params);
  } elsif ($self->{method} eq 'cli') {
    return HP::Storage::Component::FanSubsystem::CLI->new(%params);
  } else {
    die "unknown method";
  }
  return $self;
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  if (scalar (@{$self->{fans}}) == 0) {
    $self->overall_check(); # sowas ist mir nur einmal untergekommen
    # die maschine hatte alles in allem nur 2 oids (cpqHeFltTolFanChassis)
    # SNMPv2-SMI::enterprises.232.6.2.6.7.1.1.0.1 = INTEGER: 0
    # SNMPv2-SMI::enterprises.232.6.2.6.7.1.1.0.2 = INTEGER: 0
  } else {
    foreach (@{$self->{fans}}) {
      $_->check();
    }
  }
}

sub dump {
  my $self = shift;
  foreach (@{$self->{fans}}) {
    $_->dump();
  }
}

package HP::Storage::Component::FanSubsystem::Fan;
our @ISA = qw(HP::Storage::Component::FanSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  if (exists $params{redundant}) {
    return HP::Storage::Component::FanSubsystem::Fan::FTol->new(%params);
  } else {
    return HP::Storage::Component::FanSubsystem::Fan::Thermal->new(%params);
  }
}


package HP::Storage::Component::FanSubsystem::Fan::FTol;
our @ISA = qw(HP::Storage::Component::FanSubsystem::Fan);


use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    name => $params{name}, 
    location => $params{location},
    present => $params{present},
    speed => $params{speed},
    pctmax => $params{pctmax},
    redundant => $params{redundant}, # n/a koennte other bedeuten
    condition => $params{condition},
    partner => $params{partner},
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  return $self;
} 

sub check { 
  my $self = shift;
  $self->add_info("fan #%d is %s, speed is %s, pctmax is %s%%, ".
      "location is %s, redundance is %s, partner is %s",
      \'name', \'present', \'speed', \'pctmax',
      \'location', \'redundant', \'partner');
  $self->add_extendedinfo("fan_%s=%d%%", \'name', \'pctmax');
  if ($self->{present} eq "present") {
    if ($self->{speed} eq "high") { 
      $self->add_info("fan #%d (%s) runs at high speed", \'name', \'location');
      $self->add_message(CRITICAL, $self->{info});
    } elsif ($self->{speed} ne "normal") {
      $self->add_info("fan #%d (%s) needs attention", \'name', \'location');
      $self->add_message(CRITICAL, $self->{info});
    }
    if ($self->{condition} eq "failed") {
      $self->add_info("fan #%d (%s) failed", \'name', \'location');
      $self->add_message(CRITICAL, $self->{info});
    } elsif ($self->{condition} eq "degraded") {
      $self->add_info("fan #%d (%s) degraded", \'name', \'location');
      $self->add_message(WARNING, $self->{info});
    } elsif ($self->{condition} ne "ok") {
      $self->add_info("fan #%d (%s) is not ok", \'name', \'location');
      $self->add_message(WARNING, $self->{info});
    }
    if ($self->{redundant} eq "redundant") {
      if ((! defined $self->{partner}) || ($self->{partner} eq "n/a")){
        $self->add_info("fan #%d (%s) is not redundant", \'name', \'location');
        $self->add_message(WARNING, $self->{info});
      }
    } elsif ($self->{redundant} eq "notredundant") {
      if (! $self->{runtime}->{options}->{ignore_fan_redundancy}) {
        if (defined $self->{partner} && $self->{partner} ne "n/a") {
          $self->add_info("fan #%d (%s) is not redundant", \'name', \'location');
          $self->add_message(WARNING, $self->{info});
        }
      }
    } elsif ($self->{redundant} eq "n/a") {
      #seen on a dl320 g5p with bios from 2008.
      # maybe redundancy is not supported at all
    }
  } elsif ($self->{present} eq "failed") { # from cli
    $self->add_info("fan #%d (%s) failed", \'name', \'location');
    $self->add_message(CRITICAL, $self->{info});
  } elsif ($self->{present} eq "absent") {
    $self->add_info("fan #%d (%s) needs attention (is absent)", \'name', \'location');
    # weiss nicht, ob absent auch kaputt bedeuten kann
    # wenn nicht, dann wuerde man sich hier dumm und daemlich blacklisten
    #$self->add_message(CRITICAL, $self->{info});
    $self->add_message(WARNING, $self->{info});
  }
  if ($self->{runtime}->{options}->{perfdata}) {
    $self->{runtime}->{plugin}->add_perfdata(
        label => sprintf('fan_%s', $self->{name}),
        value => $self->{pctmax},
        uom => "%",
    );
  }
}

sub dump {
  my $self = shift;
  printf "[FAN_%s]\n", $self->{name};
  foreach (qw(name location present speed pctmax redundant condition
      partner blacklisted info)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "\n";
}


package HP::Storage::Component::FanSubsystem::Fan::Thermal;
our @ISA = qw(HP::Storage::Component::FanSubsystem::Fan);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    name => $params{name},
    location => $params{location},
    present => $params{present},
    speed => $params{speed},
    pctmax => $params{pctmax},
    redundant => $params{redundant}, # n/a koennte other bedeuten
    condition => $params{condition},
    partner => $params{partner},
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  return $self;
}

