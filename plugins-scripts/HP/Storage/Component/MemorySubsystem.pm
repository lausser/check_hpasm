package HP::Storage::Component::MemorySubsystem;
our @ISA = qw(HP::Storage::Component);

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
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
    dimms => [],
  };
  bless $self, $class;
  if ($self->{method} eq 'snmp') {
    return HP::Storage::Component::MemorySubsystem::SNMP->new(%params);
  } elsif ($self->{method} eq 'cli') {
    return HP::Storage::Component::MemorySubsystem::CLI->new(%params);
  } else {
    die "unknown method";
  }
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  foreach (@{$self->{dimms}}) {
    $_->check(); # info ausfuellen
  }
  if ((scalar(grep {
      $_->is_present() && 
      ($_->{condition} ne 'n/a' && $_->{condition} ne 'other' ) 
  } @{$self->{dimms}})) != 0) {
    foreach (@{$self->{dimms}}) {
      if (($_->is_present()) && ($_->{condition} ne 'ok')) {
        $self->add_message(CRITICAL, $_->{info});
        $errorfound++;
      }
    }
  } else {
    if ($self->{runtime}->{options}->{ignore_dimms}) {
      $self->add_message(OK,
          "ignoring %d dimms with status 'n/a' ",
          scalar(grep { ($_->is_present()) } @{$self->{dimms}}));
    } elsif ($self->{runtime}->{options}->{buggy_firmware}) {
      $self->add_message(OK,
          "ignoring %d dimms with status 'n/a' because of buggy firmware",
          scalar(grep { ($_->is_present()) } @{$self->{dimms}}));
    } else {
      $self->add_message(WARNING,
        "status of all %d dimms is n/a (please upgrade firmware)",
        scalar(grep { $_->is_present() } @{$self->{dimms}}));
        $errorfound++;
    }
  }
  foreach (@{$self->{dimms}}) {
    printf "%s\n", $_->{info} if $self->{runtime}->{options}->{verbose} >= 2;
  }
  #if (! $errorfound && $self->is_faulty()) {
  if ($self->is_faulty()) {
    $self->add_message(WARNING, 'overall memory error %s found', \'memstatus');
  }
}

sub dump {
  my $self = shift;
 printf "i dump the memory\n";
  foreach (@{$self->{dimms}}) {
    $_->dump();
  }
}

package HP::Storage::Component::MemorySubsystem::Dimm;
our @ISA = qw(HP::Storage::Component::MemorySubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    cartridge => $params{cartridge},
    module => $params{module},
    size => $params{size} || 0,
    status => $params{status},
    condition => $params{condition},
    type => $params{type},
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  return $self;
}  

sub check {
  my $self = shift;
  # check dient nur dazu, info und extended_info zu füllen
  # die eigentliche bewertung findet eins höher statt
  if (($self->{status} eq 'present') || ($self->{status} eq 'good')) {
    if ($self->{condition} eq 'other') {
      $self->add_info('dimm module %d @ cartridge %d is n/a',
          \'module', \'cartridge');
    } elsif ($self->{condition} ne 'ok') {
      $self->add_info('dimm module %d @ cartridge %d needs attention (%s)',
        \'module', \'cartridge', \'condition');
    } else {
      $self->add_info('dimm module %d @ cartridge %d is %s',
          \'module', \'cartridge', \'condition');
    }
  } else {
    $self->add_info('dimm module %d @ cartridge %d is not present',
        \'module', \'cartridge');
  }
}

sub is_present {
  my $self = shift;
  my @signs_of_presence = (qw(present good add upgraded doesnotmatch 
      notsupported badconfig degraded));
  return scalar(grep { $self->{status} eq $_ } @signs_of_presence);
}

sub is_blacklisted {
  my $self = shift;
}

sub dump {
  my $self = shift;
  #printf "[DIMM_%s_%s]\n", $self->{cartridge}, $self->{module};
  #foreach (qw(cartridge module size status condition info)) {
  #  printf "%s: %s\n", $_, $self->{$_};
  #}
  #printf "status: %s\n", $self->{status} if exists $self->{status};
  #printf "\n";
  printf "car %02d  mod %02d  siz %.0f  sta %-12s  con %-10s  typ %s\n",
    $self->{cartridge}, $self->{module}, $self->{size}, 
    $self->{status}, $self->{condition}, defined $self->{type} ? $self->{type} : "";
}


package HP::Storage::Component::MemorySubsystem::Cartridge;
our @ISA = qw(HP::Storage::Component::MemorySubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    cartridge => $params{cartridge},
    slot => $params{slot},
    onlinestatus => $params{onlinestatus},
    errorstatus => $params{errorstatus},
    condition => $params{condition},
    numsockets => $params{numsockets},
    osmemsize => $params{osmemsize},
    totalmemsize => $params{totalmemsize},
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  return $self;
}  

sub dump {
  my $self = shift;
  #printf "[DIMM_%s_%s]\n", $self->{cartridge}, $self->{module};
  #foreach (qw(cartridge module size status condition info)) {
  #  printf "%s: %s\n", $_, $self->{$_};
  #}
  #printf "status: %s\n", $self->{status} if exists $self->{status};
  #printf "\n";
  printf "car %02d  mod %02d  siz %08d  sta %-12s  con %-10s  typ %s\n",
    $self->{cartridge}, $self->{module}, $self->{size}, 
    $self->{status}, $self->{condition}, defined $self->{type} ? $self->{type} : "";
}


