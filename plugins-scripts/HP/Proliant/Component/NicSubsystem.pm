package HP::Proliant::Component::NicSubsystem;
our @ISA = qw(HP::Proliant::Component);

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
    status => $params{status},
    logical_nics => [],
    physical_nics => [],
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  if ($self->{method} eq 'snmp') {
    return HP::Proliant::Component::NicSubsystem::SNMP->new(%params);
  } elsif ($self->{method} eq 'cli') {
    return HP::Proliant::Component::NicSubsystem::CLI->new(%params);
  } else {
    die "unknown method";
  }
  return $self;
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking nic teams');
  if (scalar (@{$self->{logical_nics}}) == 0) {
    $self->add_info('no logical nics found');
    $self->overall_check();
  } else {
    foreach (@{$self->{logical_nics}}) {
      $_->check();
    }
  }
  if (scalar (@{$self->{physical_nics}}) == 0) {
    $self->add_info('no physical nics found. do you connect with slip?');
  } else {
    foreach (@{$self->{physical_nics}}) {
      $_->check();
    }
  }
}

sub num_logical_nics {
  my $self = shift;
  return scalar @{$self->{logical_nics}};
}

sub num_physical_nics {
  my $self = shift;
  return scalar @{$self->{physical_nics}};
}

sub dump {
  my $self = shift;
  foreach (@{$self->{logical_nics}}) {
    $_->dump();
  }
  foreach (@{$self->{physical_nics}}) {
    $_->dump();
  }
}

sub overall_check {
  my $self = shift;
  if ($self->{lognicstatus} ne "ok") {
    $self->add_info('overall logical nic status is %s', \'lognicstatus');
  }
}


package HP::Proliant::Component::NicSubsystem::LogicalNic;
our @ISA = qw(HP::Proliant::Component::NicSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  foreach (qw(cpqNicIfLogMapIndex cpqNicIfLogMapIfNumber cpqNicIfLogMapDescription cpqNicIfLogMapGroupType cpqNicIfLogMapAdapterCount cpqNicIfLogMapAdapterOKCount cpqNicIfLogMapPhysicalAdapters cpqNicIfLogMapSwitchoverMode cpqNicIfLogMapCondition cpqNicIfLogMapStatus cpqNicIfLogMapNumSwitchovers cpqNicIfLogMapHwLocation cpqNicIfLogMapSpeed cpqNicIfLogMapVlanCount cpqNicIfLogMapVlans)) {
    $self->{$_} = $params{$_};
  }
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('lni', $self->{cpqNicIfLogMapIndex});
  if ($self->{cpqNicIfLogMapAdapterCount} > 0) {
    if ($self->{cpqNicIfLogMapCondition} eq "other") {
      # simply ignore this. if there is a physical nic
      # it is usually unknown/other/scheissegal
      $self->add_info("logical nic %d (%s) is %s",
          \'cpqNicIfLogMapIndex', \'cpqNicIfLogMapDescription',
          \'cpqNicIfLogMapCondition');
    } elsif ($self->{cpqNicIfLogMapCondition} ne "ok") {
      $self->add_info("logical nic %d (%s) is %s (%s)",
          \'cpqNicIfLogMapIndex', \'cpqNicIfLogMapDescription',
          \'cpqNicIfLogMapCondition', \'cpqNicIfLogMapStatus');
      $self->add_message(CRITICAL, $self->{info});
    } else {
      $self->add_info("logical nic %d (%s) is %s",
          \'cpqNicIfLogMapIndex', \'cpqNicIfLogMapDescription',
          \'cpqNicIfLogMapCondition');
    }
  } else {
    $self->add_info("logical nic %d (%s) has 0 physical nics",
        \'cpqNicIfLogMapIndex', \'cpqNicIfLogMapDescription');
  }
}

sub dump {
  my $self = shift;
  printf "[LNIC_%s]\n", $self->{cpqNicIfLogMapIndex};
  foreach (qw(cpqNicIfLogMapIndex cpqNicIfLogMapIfNumber cpqNicIfLogMapDescription cpqNicIfLogMapAdapterCount cpqNicIfLogMapGroupType cpqNicIfLogMapSwitchoverMode cpqNicIfLogMapCondition cpqNicIfLogMapStatus cpqNicIfLogMapNumSwitchovers cpqNicIfLogMapHwLocation cpqNicIfLogMapSpeed)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}


package HP::Proliant::Component::NicSubsystem::PhysicalNic;
our @ISA = qw(HP::Proliant::Component::NicSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  foreach (qw(cpqNicIfPhysAdapterIndex cpqNicIfPhysAdapterIfNumber cpqNicIfPhysAdapterRole cpqNicIfPhysAdapterDuplexState cpqNicIfPhysAdapterCondition cpqNicIfPhysAdapterState cpqNicIfPhysAdapterStatus cpqNicIfPhysAdapterBadTransmits cpqNicIfPhysAdapterBadReceives)) {
    $self->{$_} = $params{$_};
  }
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('pni', $self->{cpqNicIfPhysAdapterIndex});
  if ($self->{cpqNicIfPhysAdapterCondition} eq "other") {
    # hp doesnt output a clear status. i am optimistic, unknown/other
    # means "dont care"
    $self->add_info("physical nic %d (%s) is %s",
        \'cpqNicIfPhysAdapterIndex', \'cpqNicIfPhysAdapterRole',
        \'cpqNicIfPhysAdapterCondition');
  } elsif ($self->{cpqNicIfPhysAdapterCondition} ne "ok") {
    $self->add_info("physical nic %d (%s) is %s (%s,%s)",
        \'cpqNicIfPhysAdapterIndex', \'cpqNicIfPhysAdapterRole',
        \'cpqNicIfPhysAdapterCondition',
        \'cpqNicIfPhysAdapterState', \'cpqNicIfPhysAdapterStatus');
    $self->add_message(CRITICAL, $self->{info});
  } else {
    if ($self->{cpqNicIfPhysAdapterDuplexState} ne "full") {
      $self->add_info("physical nic %d (%s) is %s duplex",
          \'cpqNicIfPhysAdapterIndex', \'cpqNicIfPhysAdapterRole',
          \'cpqNicIfPhysAdapterDuplexState');
    } else {
      $self->add_info("physical nic %d (%s) is %s",
          \'cpqNicIfPhysAdapterIndex', \'cpqNicIfPhysAdapterRole',
          \'cpqNicIfPhysAdapterCondition');
    }
  }
}

sub dump {
  my $self = shift;
  printf "[PNIC_%s]\n", $self->{cpqNicIfPhysAdapterIndex};
  foreach (qw(cpqNicIfPhysAdapterIndex cpqNicIfPhysAdapterIfNumber cpqNicIfPhysAdapterRole cpqNicIfPhysAdapterDuplexState cpqNicIfPhysAdapterCondition cpqNicIfPhysAdapterState cpqNicIfPhysAdapterStatus cpqNicIfPhysAdapterBadTransmits cpqNicIfPhysAdapterBadReceives)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}


