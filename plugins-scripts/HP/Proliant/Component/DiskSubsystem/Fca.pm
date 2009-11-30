package HP::Proliant::Component::DiskSubsystem::Fca;
our @ISA = qw(HP::Proliant::Component::DiskSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    rawdata => $params{rawdata},
    method => $params{method},
    host_controllers => [],
    controllers => [],
    accelerators => [],
    physical_drives => [],
    logical_drives => [],
    spare_drives => [],
    global_status => undef,
    blacklisted => 0,
  };
  bless $self, $class;
  if ($self->{method} eq 'snmp') {
    bless $self, 'HP::Proliant::Component::DiskSubsystem::Fca::SNMP';
  } else {
    bless $self, 'HP::Proliant::Component::DiskSubsystem::Fca::CLI';
  }
  $self->init();
  $self->assemble();
  return $self;
}

sub assemble {
  my $self = shift;
  $self->trace(3, sprintf "%s controllers und platten zusammenführen",
      ref($self));
  $self->trace(3, sprintf "has %d host controllers", 
      scalar(@{$self->{host_controllers}}));
  $self->trace(3, sprintf "has %d controllers",
      scalar(@{$self->{controllers}}));
  $self->trace(3, sprintf "has %d physical_drives",
      scalar(@{$self->{physical_drives}}));
  $self->trace(3, sprintf "has %d logical_drives",
      scalar(@{$self->{logical_drives}}));
  $self->trace(3, sprintf "has %d spare_drives",
      scalar(@{$self->{spare_drives}}));
}

sub check {
  my $self = shift;
  foreach (@{$self->{host_controllers}}) {
    $_->check();
  }
  foreach (@{$self->{controllers}}) {
    $_->check();
  }
  foreach (@{$self->{accelerators}}) {
    $_->check();
  }
  foreach (@{$self->{logical_drives}}) {
    $_->check();
  }
  foreach (@{$self->{physical_drives}}) {
    $_->check();
  }
  # wozu eigentlich?
  #if (! $self->has_controllers()) {
    #$self->{global_status}->check();
  #}
}

sub dump {
  my $self = shift;
  foreach (@{$self->{host_controllers}}) {
    $_->dump();
  }
  foreach (@{$self->{controllers}}) {
    $_->dump();
  }
  foreach (@{$self->{accelerators}}) {
    $_->dump();
  }
  foreach (@{$self->{logical_drives}}) {
    $_->dump();
  }
  foreach (@{$self->{physical_drives}}) {
    $_->dump();
  }
  #$self->{global_status}->dump();
}


package HP::Proliant::Component::DiskSubsystem::Fca::GlobalStatus;
our @ISA = qw(HP::Proliant::Component::DiskSubsystem::Fca);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    cpqFcaMibCondition => $params{cpqFcaMibCondition},
  };
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  if ($self->{cpqFcaMibCondition} ne 'ok') {
    $self->add_message(CRITICAL, 
        sprintf 'fcal overall condition is %s', $self->{cpqFcaMibCondition});
  }
  $self->{info} = 
      sprintf 'fcal overall condition is %s', $self->{cpqFcaMibCondition};
}

sub dump {
  my $self = shift;
  printf "[FCAL]\n";
  foreach (qw(cpqFcaMibCondition)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "\n";
}


package HP::Proliant::Component::DiskSubsystem::Fca::HostController;
our @ISA = qw(HP::Proliant::Component::DiskSubsystem::Fca);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    cpqFcaHostCntlrIndex => $params{cpqFcaHostCntlrIndex},
    cpqFcaHostCntlrSlot => $params{cpqFcaHostCntlrSlot},
    cpqFcaHostCntlrModel => $params{cpqFcaHostCntlrModel},
    cpqFcaHostCntlrStatus => $params{cpqFcaHostCntlrStatus},
    cpqFcaHostCntlrCondition => $params{cpqFcaHostCntlrCondition},
    cpqFcaHostCntlrOverallCondition => $params{cpqFcaHostCntlrOverallCondition},
    blacklisted => 0,
  };
  $self->{name} = $params{name} || $self->{cpqFcaHostCntlrIndex};
  $self->{controllerindex} = $self->{cpqFcaHostCntlrIndex};
  $self->{ident} = sprintf '%s in slot %s',
      $self->{cpqFcaHostCntlrIndex}, $self->{cpqFcaHostCntlrSlot};
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  if ($self->is_blacklisted('fcahc',
      $self->{cpqFcaHostCntlrSlot}.'-'.$self->{cpqFcaHostCntlrIndex})) {
    $self->add_info(sprintf 'fcal host controller %s is %s (blacklisted)',
        $self->{ident}, $self->{cpqFcaHostCntlrCondition});
  } elsif ($self->{cpqFcaHostCntlrCondition} eq 'other') {
    $self->add_message(CRITICAL, 
        sprintf 'fcal host controller %s needs attention (%s)',
            $self->{ident}, $self->{cpqFcaHostCntlrStatus});
    $self->add_info(sprintf 'fcal host controller %s needs attention (%s)',
        $self->{ident}, $self->{cpqFcaHostCntlrStatus});
  } elsif ($self->{cpqFcaHostCntlrCondition} ne 'ok') {
    $self->add_message(CRITICAL, 
        sprintf 'fcal host controller %s needs attention (%s)',
            $self->{ident}, $self->{cpqFcaHostCntlrStatus});
    $self->add_info(sprintf 'fcal host controller %s needs attention (%s)',
        $self->{ident}, $self->{cpqFcaHostCntlrStatus});
  } else {
    $self->add_info(sprintf 'fcal host controller %s is ok',
        $self->{ident});
  }
  if ($self->is_blacklisted('fcahc',
      $self->{cpqFcaHostCntlrSlot}.'-'.$self->{cpqFcaHostCntlrIndex})) {
  } elsif ($self->{cpqFcaHostCntlrOverallCondition} ne 'ok') {
    $self->add_message(CRITICAL, 
        sprintf 'fcal host controller %s reports problems (%s)',
            $self->{ident}, $self->{cpqFcaHostCntlrStatus});
    $self->add_info(sprintf 'fcal host controller %s reports problems (%s)',
        $self->{ident}, $self->{cpqFcaHostCntlrStatus});
  }
}

sub dump { 
  my $self = shift;
  printf "[FCAL_HOST_CONTROLLER_%s]\n", $self->{name};
  foreach (qw(cpqFcaHostCntlrIndex cpqFcaHostCntlrSlot
      cpqFcaHostCntlrModel cpqFcaHostCntlrStatus cpqFcaHostCntlrCondition
      cpqFcaHostCntlrOverallCondition)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "\n";
}


package HP::Proliant::Component::DiskSubsystem::Fca::Controller;
our @ISA = qw(HP::Proliant::Component::DiskSubsystem::Fca);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    cpqFcaCntlrBoxIndex => $params{cpqFcaCntlrBoxIndex},
    cpqFcaCntlrBoxIoSlot => $params{cpqFcaCntlrBoxIoSlot},
    cpqFcaCntlrModel => $params{cpqFcaCntlrModel},
    cpqFcaCntlrStatus => $params{cpqFcaCntlrStatus},
    cpqFcaCntlrCondition => $params{cpqFcaCntlrCondition},
    blacklisted => 0,
  };
  $self->{name} = $params{name} || 
      $self->{cpqFcaCntlrBoxIndex}.':'.$self->{cpqFcaCntlrBoxIoSlot};
  $self->{controllerindex} = $self->{cpqFcaCntlrBoxIndex};
  $self->{ident} = sprintf 'in box %s/slot %s',
      $self->{cpqFcaCntlrBoxIndex}, $self->{cpqFcaCntlrBoxIoSlot};
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('fcac', $self->{name});
  if ($self->{cpqFcaCntlrCondition} eq 'other') {
    if (1) { # was ist mit phys. drives?
      $self->add_message(CRITICAL,
          sprintf 'fcal controller %s needs attention (%s)',
              $self->{ident}, $self->{cpqFcaCntlrStatus});
      $self->add_info(sprintf 'fcal controller %s %s needs attention (%s)',
          $self->{name}, $self->{ident}, $self->{cpqFcaCntlrStatus});
    } else {
      $self->add_info(sprintf 'fcal controller %s is ok and unused',
          $self->{ident});
      $self->{blacklisted} = 1;
    }
  } elsif ($self->{cpqFcaCntlrCondition} ne 'ok') {
    $self->add_message(CRITICAL,
        sprintf 'fcal controller %s needs attention',
            $self->{ident});
    $self->add_info(sprintf 'fcal controller %s %s needs attention (%s)',
        $self->{name}, $self->{ident}, $self->{cpqFcaCntlrCondition});
  } else {
    $self->add_info(sprintf 'fcal controller %s is ok',
        $self->{ident});
  }
} 

sub dump {
  my $self = shift;
  printf "[FCAL_CONTROLLER_%s]\n", $self->{name};
  foreach (qw(cpqFcaCntlrBoxIndex cpqFcaCntlrBoxIoSlot cpqFcaCntlrModel
      cpqFcaCntlrStatus cpqFcaCntlrCondition)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "\n";
}


package HP::Proliant::Component::DiskSubsystem::Fca::Accelerator;
our @ISA = qw(HP::Proliant::Component::DiskSubsystem::Fca);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    cpqFcaAccelBoxIndex => $params{cpqFcaAccelBoxIndex},
    cpqFcaAccelBoxIoSlot => $params{cpqFcaAccelBoxIoSlot},
    cpqFcaAccelStatus => $params{cpqFcaAccelStatus},
    cpqFcaAccelErrCode => $params{cpqFcaAccelErrCode},
    cpqFcaAccelBatteryStatus => $params{cpqFcaAccelBatteryStatus},
    cpqFcaAccelCondition => $params{cpqFcaAccelCondition},
    blacklisted => 0,
  };
  $self->{name} = $params{name} ||
      $self->{cpqFcaAccelBoxIndex}.':'.$self->{cpqFcaAccelBoxIoSlot};
  $self->{controllerindex} = $self->{cpqFcaAccelBoxIndex};
  $self->{ident} = sprintf 'in box %s/slot %s',
      $self->{cpqFcaAccelBoxIndex}, $self->{cpqFcaAccelBoxIoSlot};
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  # !!! cpqFcaAccelStatus
  if ($self->{cpqFcaAccelStatus} eq 'invalid') {
    $self->add_info(sprintf 'fcal accelerator %s is not installed',
        $self->{ident});
  } elsif ($self->{cpqFcaAccelStatus} eq 'tmpDisabled') {
    $self->add_info(sprintf 'fcal accelerator %s is temp disabled',
        $self->{ident});
  } elsif ($self->{cpqFcaAccelCondition} eq 'other') {
    $self->add_message(CRITICAL,
        sprintf 'fcal accelerator %s needs attention (%s)',
            $self->{ident}, $self->{cpqFcaAccelErrCode});
    $self->add_info(sprintf 'fcal accelerator %s needs attention (%s)',
        $self->{ident}, $self->{cpqFcaAccelErrCode});
  } elsif ($self->{cpqFcaAccelCondition} ne 'ok') {
    $self->add_message(CRITICAL,
        sprintf 'fcal accelerator %s needs attention (%s)',
            $self->{ident}, $self->{cpqFcaAccelErrCode});
    $self->add_info(sprintf 'fcal accelerator %s needs attention (%s)',
        $self->{ident}, $self->{cpqFcaAccelErrCode});
  } else {
    $self->add_info(sprintf 'fcal accelerator %s is ok',
        $self->{ident});
  }
}

sub dump {
  my $self = shift;
  printf "[FCAL_ACCELERATOR_%s]\n", $self->{name};
  foreach (qw(cpqFcaAccelBoxIndex cpqFcaAccelBoxIoSlot cpqFcaAccelStatus
      cpqFcaAccelErrCode cpqFcaAccelBatteryStatus cpqFcaAccelCondition)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "\n";
}


package HP::Proliant::Component::DiskSubsystem::Fca::LogicalDrive;
our @ISA = qw(HP::Proliant::Component::DiskSubsystem::Fca);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    cpqFcaLogDrvBoxIndex => $params{cpqFcaLogDrvBoxIndex},
    cpqFcaLogDrvIndex => $params{cpqFcaLogDrvIndex},
    cpqFcaLogDrvFaultTol => $params{cpqFcaLogDrvFaultTol},
    cpqFcaLogDrvStatus => $params{cpqFcaLogDrvStatus},
    cpqFcaLogDrvPercentRebuild => $params{cpqFcaLogDrvPercentRebuild},
    cpqFcaLogDrvSize => $params{cpqFcaLogDrvSize},
    cpqFcaLogDrvPhyDrvIDs => $params{cpqFcaLogDrvPhyDrvIDs},
    cpqFcaLogDrvCondition => $params{cpqFcaLogDrvCondition},
    blacklisted => 0,
  };
  bless $self, $class;
  $self->{name} = $params{name} || 
      $self->{cpqFcaLogDrvBoxIndex}.':'.
      $self->{cpqFcaLogDrvIndex};
  $self->{controllerindex} = $self->{cpqFcaLogDrvBoxIndex};
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('fcald', $self->{name});
  if ($self->{cpqFcaLogDrvCondition} ne "ok") {
    if ($self->{cpqFcaLogDrvStatus} =~ 
        /rebuild|recovering|expand/) {
      $self->add_message(WARNING,
          sprintf "logical drive %s is %s (%s)", 
              $self->{name}, $self->{cpqFcaLogDrvStatus},
              $self->{cpqFcaLogDrvFaultTol});
    } else {
      $self->add_message(CRITICAL,
          sprintf "logical drive %s is %s (%s)",
              $self->{name}, $self->{cpqFcaLogDrvStatus},
              $self->{cpqFcaLogDrvFaultTol});
    }
  } 
  $self->add_info(
      sprintf "logical drive %s is %s (%s)", $self->{name},
          $self->{cpqFcaLogDrvStatus}, $self->{cpqFcaLogDrvFaultTol});
}

sub dump {
  my $self = shift;
  printf "[LOGICAL_DRIVE]\n";
  foreach (qw(cpqFcaLogDrvBoxIndex cpqFcaLogDrvIndex cpqFcaLogDrvFaultTol
      cpqFcaLogDrvStatus cpqFcaLogDrvPercentRebuild cpqFcaLogDrvSize 
      cpqFcaLogDrvPhyDrvIDs cpqFcaLogDrvCondition)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "\n";
}


package HP::Proliant::Component::DiskSubsystem::Fca::PhysicalDrive;
our @ISA = qw(HP::Proliant::Component::DiskSubsystem::Fca);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    cpqFcaPhyDrvBoxIndex => $params{cpqFcaPhyDrvBoxIndex},
    cpqFcaPhyDrvIndex => $params{cpqFcaPhyDrvIndex},
    cpqFcaPhyDrvModel => $params{cpqFcaPhyDrvModel},
    cpqFcaPhyDrvBay => $params{cpqFcaPhyDrvBay},
    cpqFcaPhyDrvStatus => $params{cpqFcaPhyDrvStatus},
    cpqFcaPhyDrvCondition => $params{cpqFcaPhyDrvCondition},
    cpqFcaPhyDrvSize => $params{cpqFcaPhyDrvSize},
    cpqFcaPhyDrvBusNumber => $params{cpqFcaPhyDrvBusNumber},
    blacklisted => 0,
  };
  $self->{name} = $params{name} || 
      $self->{cpqFcaPhyDrvBoxIndex}.':'.$self->{cpqFcaPhyDrvIndex}; ####vorerst
  $self->{controllerindex} = $self->{cpqScsiPhyDrvCntlrIndex};
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('fcapd', $self->{name});
  if ($self->{cpqFcaPhyDrvStatus} eq 'unconfigured') {
    # not part of a logical drive
    # condition will surely be other
  } elsif ($self->{cpqFcaPhyDrvCondition} ne 'ok') {
    $self->add_message(CRITICAL,
        sprintf "physical drive %s is %s", 
            $self->{name}, $self->{cpqFcaPhyDrvStatus});
  }
  $self->add_info(
      sprintf "physical drive %s is %s", 
          $self->{name}, $self->{cpqFcaPhyDrvStatus});
}

sub dump {
  my $self = shift;
  printf "[PHYSICAL_DRIVE]\n";
  foreach (qw(cpqFcaPhyDrvBoxIndex cpqFcaPhyDrvIndex cpqFcaPhyDrvModel
      cpqFcaPhyDrvBay cpqFcaPhyDrvStatus cpqFcaPhyDrvCondition
      cpqFcaPhyDrvSize cpqFcaPhyDrvBusNumber)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "\n";
}


package HP::Proliant::Component::DiskSubsystem::Fca::SpareDrive;
our @ISA = qw(HP::Proliant::Component::DiskSubsystem::Fca);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub dump {
  my $self = shift;
  printf "[SPARE_DRIVE]\n";
}


1;
