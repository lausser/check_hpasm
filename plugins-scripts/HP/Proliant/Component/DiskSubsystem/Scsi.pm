package HP::Proliant::Component::DiskSubsystem::Scsi;
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
    controllers => [],
    physical_drives => [],
    logical_drives => [],
    spare_drives => [],
    condition => undef,
    blacklisted => 0,
  };
  bless $self, $class;
  if ($self->{method} eq 'snmp') {
    bless $self, 'HP::Proliant::Component::DiskSubsystem::Scsi::SNMP';
  } else {
    bless $self, 'HP::Proliant::Component::DiskSubsystem::Scsi::CLI';
  }
  $self->init();
  $self->assemble();
  return $self;
}

sub check {
  my $self = shift;
  foreach (@{$self->{controllers}}) {
    $_->check();
  }
}

sub dump {
  my $self = shift;
  foreach (@{$self->{controllers}}) {
    $_->dump();
  }
}

package HP::Proliant::Component::DiskSubsystem::Scsi::Controller;
our @ISA = qw(HP::Proliant::Component::DiskSubsystem::Scsi);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    cpqScsiCntlrIndex => $params{cpqScsiCntlrIndex},
    cpqScsiCntlrBusIndex => $params{cpqScsiCntlrBusIndex},
    cpqScsiCntlrSlot => $params{cpqScsiCntlrSlot},
    cpqScsiCntlrStatus => $params{cpqScsiCntlrStatus},
    cpqScsiCntlrCondition => $params{cpqScsiCntlrCondition},
    cpqScsiCntlrHwLocation => $params{cpqScsiCntlrHwLocation},
    blacklisted => 0,
  };
  $self->{name} = $params{name} || $self->{cpqScsiCntlrIndex};
  $self->{controllerindex} = $self->{cpqScsiCntlrIndex};
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  if ($self->{cpqScsiCntlrCondition} eq 'other') {
    if (scalar(@{$self->{physical_drives}})) {
      $self->add_message(CRITICAL,
          sprintf 'scsi controller in slot %s needs attention',
              $self->{cpqScsiCntlrSlot});
      $self->add_info(sprintf 'scsi controller in slot %s needs attention',
          $self->{cpqScsiCntlrSlot});
    } else {
      $self->add_info(sprintf 'scsi controller in slot %s is ok and unused',
          $self->{cpqScsiCntlrSlot});
      $self->{blacklisted} = 1;
    }
  } elsif ($self->{cpqScsiCntlrCondition} ne 'ok') {
    $self->add_message(CRITICAL,
        sprintf 'scsi controller in slot %s needs attention',
            $self->{cpqScsiCntlrSlot});
    $self->add_info(sprintf 'scsi controller in slot %s needs attention',
        $self->{cpqScsiCntlrSlot});
  } else {
    $self->add_info(sprintf 'scsi controller in slot %s is ok',
        $self->{cpqScsiCntlrSlot});
  }
  foreach (@{$self->{logical_drives}}) {
    $_->check();
  } 
  foreach (@{$self->{physical_drives}}) {
    $_->check();
  } 
  foreach (@{$self->{spare_drives}}) {
    $_->check();
  } 
} 

sub dump {
  my $self = shift;
  printf "[SCSI_CONTROLLER_%s]\n", $self->{name};
  foreach (qw(cpqScsiCntlrIndex cpqScsiCntlrBusIndex cpqScsiCntlrSlot
      cpqScsiCntlrStatus cpqScsiCntlrCondition cpqScsiCntlrHwLocation)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "\n";
  foreach (@{$self->{logical_drives}}) {
    $_->dump();
  }
  foreach (@{$self->{physical_drives}}) {
    $_->dump();
  }
  foreach (@{$self->{spare_drives}}) {
    $_->dump();
  }
}


package HP::Proliant::Component::DiskSubsystem::Scsi::LogicalDrive;
our @ISA = qw(HP::Proliant::Component::DiskSubsystem::Scsi);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    cpqScsiLogDrvCntlrIndex => $params{cpqScsiLogDrvCntlrIndex},
    cpqScsiLogDrvBusIndex => $params{cpqScsiLogDrvBusIndex},
    cpqScsiLogDrvIndex => $params{cpqScsiLogDrvIndex},
    cpqScsiLogDrvFaultTol => $params{cpqScsiLogDrvFaultTol},
    cpqScsiLogDrvStatus => $params{cpqScsiLogDrvStatus},
    cpqScsiLogDrvSize => $params{cpqScsiLogDrvSize},
    cpqScsiLogDrvPhyDrvIDs => $params{cpqScsiLogDrvPhyDrvIDs},
    cpqScsiLogDrvCondition => $params{cpqScsiLogDrvCondition},
    blacklisted => 0,
  };
  bless $self, $class;
  $self->{name} = $params{name} || 
      $self->{cpqScsiLogDrvCntlrIndex}.':'.
      $self->{cpqScsiLogDrvBusIndex}.':'.
      $self->{cpqScsiLogDrvIndex}; ####vorerst
  $self->{controllerindex} = $self->{cpqScsiLogDrvCntlrIndex};
  return $self;
}

sub check {
  my $self = shift;
  if ($self->{cpqScsiLogDrvCondition} ne "ok") {
    if ($self->{cpqScsiLogDrvStatus} =~ 
        /rebuild|recovering/) {
      $self->add_message(WARNING,
          sprintf "logical drive %s is %s", 
              $self->{name}, $self->{cpqScsiLogDrvStatus});
    } else {
      $self->add_message(CRITICAL,
          sprintf "logical drive %s is %s",
              $self->{name}, $self->{cpqScsiLogDrvStatus});
    }
  } 
  $self->add_info(
      sprintf "logical drive %s is %s", $self->{name},
          $self->{cpqScsiLogDrvStatus});
}

sub dump {
  my $self = shift;
  printf "[LOGICAL_DRIVE]\n";
  foreach (qw(cpqScsiLogDrvCntlrIndex cpqScsiLogDrvBusIndex cpqScsiLogDrvIndex
      cpqScsiLogDrvFaultTol cpqScsiLogDrvStatus cpqScsiLogDrvSize 
      cpqScsiLogDrvPhyDrvIDs cpqScsiLogDrvCondition)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "\n";
}


package HP::Proliant::Component::DiskSubsystem::Scsi::PhysicalDrive;
our @ISA = qw(HP::Proliant::Component::DiskSubsystem::Scsi);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    cpqScsiPhyDrvCntlrIndex => $params{cpqScsiPhyDrvCntlrIndex},
    cpqScsiPhyDrvBusIndex => $params{cpqScsiPhyDrvBusIndex},
    cpqScsiPhyDrvIndex => $params{cpqScsiPhyDrvIndex},
    cpqScsiPhyDrvStatus => $params{cpqScsiPhyDrvStatus},
    cpqScsiPhyDrvSize => $params{cpqScsiPhyDrvSize},
    cpqScsiPhyDrvCondition => $params{cpqScsiPhyDrvCondition},
    blacklisted => 0,
  };
  $self->{name} = $params{name} || 
      $self->{cpqScsiPhyDrvCntlrIndex}.':'.$self->{cpqScsiPhyDrvIndex}; 
  $self->{controllerindex} = $self->{cpqScsiPhyDrvCntlrIndex};
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  if ($self->{cpqScsiPhyDrvCondition} ne 'ok') {
    $self->add_message(CRITICAL,
        sprintf "physical drive %s is %s", 
            $self->{name}, $self->{cpqScsiPhyDrvCondition});
  }
  $self->add_info(
      sprintf "physical drive %s is %s", 
          $self->{name}, $self->{cpqScsiPhyDrvCondition});
}

sub dump {
  my $self = shift;
  printf "[PHYSICAL_DRIVE]\n";
  foreach (qw(cpqScsiPhyDrvCntlrIndex cpqScsiPhyDrvBusIndex cpqScsiPhyDrvIndex
      cpqScsiPhyDrvStatus cpqScsiPhyDrvSize cpqScsiPhyDrvCondition)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "\n";
}


package HP::Proliant::Component::DiskSubsystem::Scsi::SpareDrive;
our @ISA = qw(HP::Proliant::Component::DiskSubsystem::Scsi);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub dump {
  my $self = shift;
  printf "[SPARE_DRIVE]\n";
}


1;
