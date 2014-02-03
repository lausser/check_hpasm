package HP::Storage::Component::DiskSubsystem::Da;
our @ISA = qw(HP::Storage::Component::DiskSubsystem);

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
    accelerators => [],
    physical_drives => [],
    logical_drives => [],
    spare_drives => [],
    condition => undef,
    blacklisted => 0,
  };
  bless $self, $class;
  if ($self->{method} eq 'snmp') {
    bless $self, 'HP::Storage::Component::DiskSubsystem::Da::SNMP';
  } else {
    bless $self, 'HP::Storage::Component::DiskSubsystem::Da::CLI';
  }
  $self->init();
  $self->assemble();
  return $self;
}

sub assemble {
  my $self = shift;
#printf "controllers und platten zusammenführen\n";
#printf "da has %d controllers\n", scalar(@{$self->{controllers}});
#printf "da has %d accelerators\n", scalar(@{$self->{accelerators}});
#printf "da has %d physical_drives\n", scalar(@{$self->{physical_drives}});
#printf "da has %d logical_drives\n", scalar(@{$self->{logical_drives}});
#printf "da has %d spare_drives\n", scalar(@{$self->{spare_drives}});
  my $found = {
      accelerators => {},
      logical_drives => {},
      physical_drives => {},
      spare_drives => {},
  };
  # found->{komponente}->{controllerindex} ist ein array
  # von teilen, die zu einem controller gehoeren
  foreach my $item (qw(accelerators logical_drives physical_drives 
      spare_drives)) {
    foreach (@{$self->{$item}}) {
      $found->{item}->{$_->{cntrlindex}} = []
          unless exists $found->{$item}->{$_->{cntrlindex}};
      push(@{$found->{$item}->{$_->{cntrlindex}}}, $_);
    }
  }
  foreach my $item (qw(accelerators logical_drives physical_drives 
      spare_drives)) {
    foreach (@{$self->{controllers}}) {
      if (exists $found->{$item}->{$_->{index}}) {
        $_->{$item} = $found->{$item}->{$_->{index}};
        delete $found->{$item}->{$_->{index}};
      }
    }
  }
  # was jetzt noch in $found uebrig ist, gehoert zu keinem controller
  # d.h. komponenten mit ungueltigen cnrtlindex wurden gefunden
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

package HP::Storage::Component::DiskSubsystem::Da::Controller;
our @ISA = qw(HP::Storage::Component::DiskSubsystem::Da);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    index => $params{index},
    slot => $params{slot},
    model => $params{model},
    condition => $params{condition},
    boardcondition => $params{boardcondition},
    name => $params{slot},
    blacklisted => 0,
  };
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  if ($self->{condition} eq 'other') {
    if (scalar(@{$self->{physical_disks}})) {
      $self->add_message(CRITICAL,
          sprintf 'da controller in slot %s needs attention', $self->{slot});
      $self->add_info(sprintf 'da controller in slot %s needs attention',
          $self->{slot});
    } else {
      $self->add_info(sprintf 'da controller in slot %s is ok and unused',
          $self->{slot});
      $self->{blacklisted} = 1;
    }
  } elsif ($self->{condition} ne 'ok') {
    $self->add_message(CRITICAL,
        sprintf 'da controller in slot %s needs attention', $self->{slot});
    $self->add_info(sprintf 'da controller in slot %s needs attention',
        $self->{slot});
  } else {
    $self->add_info(sprintf 'da controller in slot %s is ok', $self->{slot});
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
  foreach (@{$self->{spare_drives}}) {
    $_->check();
  } 
} 

sub dump {
  my $self = shift;
  printf "[DA_CONTROLLER_%s]\n", $self->{name};
  foreach (qw(slot index condition model)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "\n";
  foreach (@{$self->{accelerators}}) {
    $_->dump();
  }
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


package HP::Storage::Component::DiskSubsystem::Da::Accelerator;
our @ISA = qw(HP::Storage::Component::DiskSubsystem::Da);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    cntrlindex => $params{cntrlindex},
    battery => $params{battery},
    condition => $params{condition},
    blacklisted => 0,
  };
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  if ($self->{condition} ne "ok") {
    $self->add_message(CRITICAL, "controller cache needs attention");
  }
  if ($self->{battery} eq "notpresent") {
  } elsif ($self->{battery} eq "recharging") {
    $self->add_message(WARNING, "controller battery recharging");
  } elsif ($self->{battery} ne "ok") {
    # (other) failed degraded
    $self->add_message(CRITICAL, "controller battery needs attention");
  } 
  $self->add_info(sprintf 'controller cache is %s', $self->{condition});
  $self->add_info(sprintf 'controller battery is %s', $self->{battery});
}

sub dump {
  my $self = shift;
  printf "[ACCELERATOR]\n";
  foreach (qw(cntrlindex battery condition)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "\n";
}


package HP::Storage::Component::DiskSubsystem::Da::LogicalDrive;
our @ISA = qw(HP::Storage::Component::DiskSubsystem::Da);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    cntrlindex => $params{cntrlindex},
    index => $params{index},
    size => $params{size},
    level => $params{level},
    percentrebuild => $params{percentrebuild},
    status => $params{status},
    condition => $params{condition},
    blacklisted => 0,
  };
  bless $self, $class;
  $self->{name} = $self->{index}; ####vorerst
  if (! $self->{percentrebuild} || $self->{percentrebuild} == 4294967295) {
    $self->{percentrebuild} = 100;
  }
  return $self;
}

sub check {
  my $self = shift;
  if ($self->{condition} ne "ok") {
    if ($self->{status} =~ 
        /rebuild|recovering|expanding|queued/) {
      $self->add_message(WARNING,
          sprintf "logical drive %s is %s", $self->{name}, $self->{status});
    } else {
      $self->add_message(CRITICAL,
          sprintf "logical drive %s is %s", $self->{name}, $self->{status});
    }
  } 
  $self->add_info(
      sprintf "logical drive %s is %s", $self->{name}, $self->{status});
}

sub dump {
  my $self = shift;
  printf "[LOGICAL_DRIVE]\n";
  foreach (qw(cntrlindex index size level status condition percentrebuild)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "\n";
}


package HP::Storage::Component::DiskSubsystem::Da::PhysicalDrive;
our @ISA = qw(HP::Storage::Component::DiskSubsystem::Da);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    cntrlindex => $params{cntrlindex},
    index => $params{index},
    bay => $params{bay},
    busnumber => $params{busnumber},
    size => $params{size},
    status => $params{status},
    condition => $params{condition},
    blacklisted => 0,
  };
  bless $self, $class;
  $self->{name} = $self->{index}; ####vorerst
  return $self;
}

sub check {
  my $self = shift;
  if ($self->{condition} ne 'ok') {
    $self->add_message(CRITICAL,
        sprintf "physical drive %s is %s", $self->{name}, $self->{condition});
  }
  $self->add_info(
      sprintf "physical drive %s is %s", $self->{name}, $self->{condition});
}

sub dump {
  my $self = shift;
  printf "[PHYSICAL_DRIVE]\n";
  foreach (qw(cntrlindex index bay busnumber size status condition)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "\n";
}


package HP::Storage::Component::DiskSubsystem::Da::SpareDrive;
our @ISA = qw(HP::Storage::Component::DiskSubsystem::Da);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub dump {
  my $self = shift;
  printf "[LOGICAL_DRIVE]\n";
  foreach (qw(cntrlindex index size level status condition)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "\n";
}


1;
