package HP::Storage::Component::MemorySubsystem::SNMP;
our @ISA = qw(HP::Storage::Component::MemorySubsystem);

use strict;

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    rawdata => $params{rawdata},
    dimms => [],
    si_dimms => [],
    he_dimms => [],
    h2_dimms => [],
    he_cartridges => [],
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  $self->si_init();
  $self->he_init();
  $self->he_cartridge_init();
#printf "%s\n", Data::Dumper::Dumper($self->{he_cartridges});
  $self->h2_init();
  $self->condense();
  return $self;
}

sub si_init {
  my $self = shift;
  my $snmpwalk = $self->{rawdata};
  my $cpqSiMemModuleEntry = "1.3.6.1.4.1.232.2.2.4.5.1";
  my $cpqSiMemBoardIndex = "1.3.6.1.4.1.232.2.2.4.5.1.1"; # 0 = on system board
  my $cpqSiMemModuleIndex = "1.3.6.1.4.1.232.2.2.4.5.1.2";
  my $cpqSiMemModuleSize = "1.3.6.1.4.1.232.2.2.4.5.1.3";
  my $cpqSiMemModuleType = "1.3.6.1.4.1.232.2.2.4.5.1.4";
  my $cpqSiMemECCStatus = "1.3.6.1.4.1.232.2.2.4.5.1.11";
  my $cpqSiMemModuleHwLocation = "1.3.6.1.4.1.232.2.2.4.5.1.12";
  my $cpqSiMemModuleTypeValue = {
      1 => 'other',
      2 => 'board',
      3 => 'cpqSingleWidthModule',
      4 => 'cpqDoubleWidthModule',
      5 => 'simm',
      6 => 'pcmcia',
      7 => 'compaq-specific',
      8 => 'dimm',
      9 => 'smallOutlineDimm',
      10 => 'rimm',
      11 => 'srimm',
  };
  my $cpqSiMemECCStatusValue = {
      0 => "n/a",
      1 => "other",
      2 => "ok",
      3 => "degraded",
      4 => "degradedModuleIndexUnknown",
      34 => 'n/a', # es ist zum kotzen...
      104 => 'n/a',
  };
  # INDEX { cpqSiMemBoardIndex, cpqSiMemModuleIndex }
  my @si_indexes =
      SNMP::Utils::get_indices($snmpwalk, $cpqSiMemModuleEntry);
  foreach (sort {
    $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] #board, module
  } @si_indexes) {
    my($idx1, $idx2) = ($_->[0], $_->[1]);
    my $board = SNMP::Utils::get_object(
        $snmpwalk, $cpqSiMemBoardIndex,
        $idx1, $idx2);
    my $module = SNMP::Utils::get_object(
        $snmpwalk, $cpqSiMemModuleIndex,
        $idx1, $idx2);
    my $size = SNMP::Utils::get_object(
        $snmpwalk, $cpqSiMemModuleSize,
        $idx1, $idx2);
    my $sitype = lc SNMP::Utils::get_object_value(
        $snmpwalk, $cpqSiMemModuleType,
        $cpqSiMemModuleTypeValue,
        $idx1, $idx2);
    my $sicondition = lc SNMP::Utils::get_object_value(
        $snmpwalk, $cpqSiMemECCStatus,
        $cpqSiMemECCStatusValue,
        $idx1, $idx2);
    push(@{$self->{si_dimms}}, HP::Storage::Component::MemorySubsystem::Dimm->new(
      runtime => $self->{runtime},
      cartridge => $board,
      module => $module,
      status => ($size > 0) ? "present" : "notpresent", # kuenstlich
      condition => $sicondition,
      size => $size,
      type => $sitype,
    )) unless (! defined $board || ! defined $module);
  }
}

sub he_init {
  my $self = shift;
  my $snmpwalk = $self->{rawdata};
  my $cpqHeResMemModuleEntry = "1.3.6.1.4.1.232.6.2.14.11.1";
  my $cpqHeResMemBoardIndex = "1.3.6.1.4.1.232.6.2.14.11.1.1"; # 0 = on system board
  my $cpqHeResMemModuleIndex = "1.3.6.1.4.1.232.6.2.14.11.1.2";
  my $cpqHeResMemModuleStatus = "1.3.6.1.4.1.232.6.2.14.11.1.4";
  my $cpqHeResMemModuleCondition = "1.3.6.1.4.1.232.6.2.14.11.1.5";
 
  my $cpqHeResMemModuleStatusValue = {
      1 => "other",         # unknown or could not be determined
      2 => "notPresent",    # not present or un-initialized
      3 => "present",       # present but not in use
      4 => "good",          # present and in use. ecc threshold not exceeded
      5 => "add",           # added but not yet in use 
      6 => "upgrade",       # upgraded but not yet in use
      7 => "missing",       # expected but missing
      8 => "doesNotMatch",  # does not match the other modules in the bank
      9 => "notSupported",  # module not supported 
      10 => "badConfig",    # violates add/upgrade configuration
      11 => "degraded",     # ecc exceeds threshold
  };
  # condition = status of the correctable memory errors
  my $cpqHeResMemModuleConditionValue = {
      0 => "n/a", # this appears only with buggy firmwares.
      # (only 1 module shows up)
      1 => "other",
      2 => "ok",
      3 => "degraded",
  };
  my $tablesize = SNMP::Utils::get_size($snmpwalk, $cpqHeResMemModuleEntry);
  # INDEX { cpqHeResMemBoardIndex, cpqHeResMemModuleIndex }
  my @he_indexes =
      SNMP::Utils::get_indices($snmpwalk, $cpqHeResMemModuleEntry);
  foreach (sort {
    $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] #board, module
  } @he_indexes) {
    my($idx1, $idx2) = ($_->[0], $_->[1]);
    my $board = SNMP::Utils::get_object(
        $snmpwalk, $cpqHeResMemBoardIndex,
        $idx1, $idx2);
    my $module = SNMP::Utils::get_object(
        $snmpwalk, $cpqHeResMemModuleIndex,
        $idx1, $idx2);
    my $hestatus = lc SNMP::Utils::get_object_value(
        $snmpwalk, $cpqHeResMemModuleStatus,
        $cpqHeResMemModuleStatusValue,
        $idx1, $idx2);
    my $hecondition = lc SNMP::Utils::get_object_value(
        $snmpwalk, $cpqHeResMemModuleCondition,
        $cpqHeResMemModuleConditionValue,
        $idx1, $idx2);
    if ((! defined $module) && ($board == 0)) {
      $module = $idx2; # auf dem systemboard verbaut
    }
    push(@{$self->{he_dimms}}, 
        HP::Storage::Component::MemorySubsystem::Dimm->new(
      runtime => $self->{runtime},
      cartridge => $board,
      module => $module,
      present => $hestatus,
      status => $hestatus,
      condition => $hecondition,
    )) unless (! defined $board || ! defined $module || $tablesize == 1);
  }
}

sub he_cartridge_init {
  my $self = shift;
  my $snmpwalk = $self->{rawdata};
  my $cpqHeResMemBoardEntry = "1.3.6.1.4.1.232.6.2.14.10.1";
  my $cpqHeResMemBoardSlotIndex = "1.3.6.1.4.1.232.6.2.14.10.1.1";
  my $cpqHeResMemBoardOnlineStatus = "1.3.6.1.4.1.232.6.2.14.10.1.2";
  my $cpqHeResMemBoardErrorStatus = "1.3.6.1.4.1.232.6.2.14.10.1.3";
  my $cpqHeResMemBoardNumSockets = "1.3.6.1.4.1.232.6.2.14.10.1.5";
  my $cpqHeResMemBoardOsMemSize = "1.3.6.1.4.1.232.6.2.14.10.1.6";
  my $cpqHeResMemBoardTotalMemSize = "1.3.6.1.4.1.232.6.2.14.10.1.7";
  my $cpqHeResMemBoardCondition = "1.3.6.1.4.1.232.6.2.14.10.1.8";
  # onlinestatus
  my $cpqHeResMemBoardOnlineStatusValue = {
      0 => "n/a", # this appears only with buggy firmwares.
      # (only 1 module shows up)
      1 => "other",
      2 => "present",
      3 => "absent",
  };
  my $cpqHeResMemBoardErrorStatusValue = {
      1 => "other",         #
      2 => "noError",       #
      3 => "dimmEccError",  #
      4 => "unlockError",   #
      5 => "configError",   #
      6 => "busError",      #
      7 => "powerError",    #
  };
  # condition = status of the correctable memory errors
  my $cpqHeResMemBoardConditionValue = {
      0 => "n/a", # this appears only with buggy firmwares.
      # (only 1 module shows up)
      1 => "other",
      2 => "ok",
      3 => "degraded",
  };
  my $tablesize = SNMP::Utils::get_size($snmpwalk, $cpqHeResMemBoardEntry);
  # INDEX { cpqHeResMemBoardIndex, cpqHeResMemBoardIndex }
  my @he_board_indexes =
      SNMP::Utils::get_indices($snmpwalk, $cpqHeResMemBoardEntry);
  foreach (sort {
    $a->[0] <=> $b->[0] #board
  } @he_board_indexes) {
    my($idx1) = ($_->[0]);
    my $slot = SNMP::Utils::get_object(
        $snmpwalk, $cpqHeResMemBoardSlotIndex,
        $idx1);
    my $onlinestatus = lc SNMP::Utils::get_object_value(
        $snmpwalk, $cpqHeResMemBoardOnlineStatus,
        $cpqHeResMemBoardOnlineStatusValue,
        $idx1);
    my $numsockets = SNMP::Utils::get_object(
        $snmpwalk, $cpqHeResMemBoardNumSockets,
        $idx1);
    my $osmemsize = SNMP::Utils::get_object(
        $snmpwalk, $cpqHeResMemBoardOsMemSize,
        $idx1);
    my $totalmemsize = SNMP::Utils::get_object(
        $snmpwalk, $cpqHeResMemBoardTotalMemSize,
        $idx1);
    my $errorstatus = lc SNMP::Utils::get_object_value(
        $snmpwalk, $cpqHeResMemBoardErrorStatus,
        $cpqHeResMemBoardErrorStatusValue,
        $idx1);
    my $condition = lc SNMP::Utils::get_object_value(
        $snmpwalk, $cpqHeResMemBoardCondition,
        $cpqHeResMemBoardConditionValue,
        $idx1);
    push(@{$self->{he_cartridges}}, HP::Storage::Component::MemorySubsystem::Cartridge->new(
      runtime => $self->{runtime},
      cartridge => $idx1,
      slot => $slot,
      onlinestatus => $onlinestatus,
      errorstatus => $errorstatus,
      numsockets => $numsockets,
      osmemsize => $osmemsize,
      totalmemsize => $totalmemsize,
      condition => $condition,
    )) unless (! defined $slot || $tablesize == 1);
  }
}

sub h2_init {
  my $self = shift;
  my $snmpwalk = $self->{rawdata};
  my $cpqHeResMem2ModuleEntry = "1.3.6.1.4.1.232.6.2.14.13.1";
  my $cpqHeResMem2BoardNum = "1.3.6.1.4.1.232.6.2.14.13.1.2"; # 0 = on system board
  my $cpqHeResMem2ModuleNum = "1.3.6.1.4.1.232.6.2.14.13.1.5";
  my $cpqHeResMem2ModuleStatus = "1.3.6.1.4.1.232.6.2.14.13.1.19";
  my $cpqHeResMem2ModuleCondition = "1.3.6.1.4.1.232.6.2.14.13.1.20";
  my $cpqHeResMem2ModuleSize = "1.3.6.1.4.1.232.6.2.14.13.1.6";
 
  my $cpqHeResMem2ModuleStatusValue = {
      1 => "other",         # unknown or could not be determined
      2 => "notPresent",    # not present or un-initialized
      3 => "present",       # present but not in use
      4 => "good",          # present and in use. ecc threshold not exceeded
      5 => "add",           # added but not yet in use 
      6 => "upgrade",       # upgraded but not yet in use
      7 => "missing",       # expected but missing
      8 => "doesNotMatch",  # does not match the other modules in the bank
      9 => "notSupported",  # module not supported 
      10 => "badConfig",    # violates add/upgrade configuration
      11 => "degraded",     # ecc exceeds threshold
  };
  # condition = status of the correctable memory errors
  my $cpqHeResMem2ModuleConditionValue = {
      0 => "n/a", # this appears only with buggy firmwares.
      # (only 1 module shows up)
      1 => "other",
      2 => "ok",
      3 => "degraded",
  };
  # INDEX { cpqHeResMem2BoardNum, cpqHeResMem2ModuleNum }
  my @h2_indexes =
      SNMP::Utils::get_indices($snmpwalk, $cpqHeResMem2ModuleEntry);
  my $lastboard = 0;
  my $lastmodule = 0;
  my $myboard= 0;
  my $hpboard = 0;
  foreach (sort {
    #$a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] #board, module
    $a->[0] <=> $b->[0]
  } @h2_indexes) {
    my($idx1) = ($_->[0]);
    my $board = SNMP::Utils::get_object(
        $snmpwalk, $cpqHeResMem2BoardNum,
        $idx1); 
        # dass hier faelschlicherweise 0 zurueckkommt, wundert mich schon
        # gar nicht mehr
    $hpboard = $board;
    my $module = SNMP::Utils::get_object(
        $snmpwalk, $cpqHeResMem2ModuleNum,
        $idx1);
    if ($module < $lastmodule) {
      # sieht so aus, als haette man es mit einem neuen board zu tun
      # da hp zu bloed ist, selber hochzuzaehlen, muss ich das tun
      $myboard++; 
    }
    $lastmodule = $module; # das ist das von hp gelieferte
    my $size = SNMP::Utils::get_object(
        $snmpwalk, $cpqHeResMem2ModuleSize,
        $idx1);
    my $hestatus = lc SNMP::Utils::get_object_value(
        $snmpwalk, $cpqHeResMem2ModuleStatus,
        $cpqHeResMem2ModuleStatusValue,
        $idx1);
    my $hecondition = lc SNMP::Utils::get_object_value(
        $snmpwalk, $cpqHeResMem2ModuleCondition,
        $cpqHeResMem2ModuleConditionValue,
        $idx1);
    push(@{$self->{h2_dimms}}, HP::Storage::Component::MemorySubsystem::Dimm->new(
      runtime => $self->{runtime},
      cartridge => ($myboard != $hpboard) ? $myboard : $hpboard,
      module => $module,
      present => $hestatus,
      status => $hestatus,
      condition => $hecondition,
      size => $size,
    )) unless (! defined $board || ! defined $module);
  }
}

sub condense {
  my $self = shift;
  my $snmpwalk = $self->{rawdata};
  # wenn saemtliche dimms n/a sind
  #  wenn ignore dimms: ignoring %d dimms with status 'n/a'
  #  wenn buggyfirmware: ignoring %d dimms with status 'n/a' because of buggy firmware
  # if buggy firmware : condition n/a ist normal
  # ignore-dimms :
  # es gibt si_dimms und he_dimms
  my $si_dimms = scalar(@{$self->{si_dimms}});
  my $he_dimms = scalar(@{$self->{he_dimms}});
  my $h2_dimms = scalar(@{$self->{h2_dimms}});
  printf "SI: %02d   HE: %02d   H2: %02d\n", $si_dimms, $he_dimms, $h2_dimms
      if ($self->{runtime}->{options}->{verbose} >= 2);
  foreach ($self->get_si_boards()) {
    printf "SI%02d-> ", $_ if ($self->{runtime}->{options}->{verbose} >= 2);
    foreach ($self->get_si_modules($_)) {
      printf "%02d ", $_ if ($self->{runtime}->{options}->{verbose} >= 2);
    }
    printf "\n" if ($self->{runtime}->{options}->{verbose} >= 2);
  }
  foreach ($self->get_he_boards()) {
    printf "HE%02d-> ", $_ if ($self->{runtime}->{options}->{verbose} >= 2);
    foreach ($self->get_he_modules($_)) {
      printf "%02d ", $_ if ($self->{runtime}->{options}->{verbose} >= 2);
    }
    printf "\n" if ($self->{runtime}->{options}->{verbose} >= 2);
  }
  foreach ($self->get_h2_boards()) {
    printf "H2%02d-> ", $_ if ($self->{runtime}->{options}->{verbose} >= 2);
    foreach ($self->get_h2_modules($_)) {
      printf "%02d ", $_ if ($self->{runtime}->{options}->{verbose} >= 2);
    }
    printf "\n" if ($self->{runtime}->{options}->{verbose} >= 2);
  }
  if (($si_dimms > 0) && ($he_dimms == 0) && ($h2_dimms == 0)) {
    # alte modelle
    printf "TYP1 %s\n", $self->{runtime}->{product}
        if ($self->{runtime}->{options}->{verbose} >= 2);
    $self->{memconfig} = 1;
    # wenn si keine statusinformationen liefert, dann besteht die chance
    # dass ein undokumentiertes he-fragment vorliegt
    # 1.3.6.1.4.1.232.6.2.14.11.1.1.0.<anzahl der dimms>
    my $repaircondition = undef;
    my $cpqHeResMemModuleEntry = "1.3.6.1.4.1.232.6.2.14.11.1";
    if (SNMP::Utils::get_size($snmpwalk, $cpqHeResMemModuleEntry) == 1) {
      $repaircondition = lc SNMP::Utils::get_object(
          $snmpwalk, $cpqHeResMemModuleEntry.'.1.0.'.$si_dimms);
      # repaircondition 0 (ok) biegt alles wieder gerade
    }
    foreach my $si_dimm (@{$self->{si_dimms}}) {
      if (($si_dimm->{condition} eq 'n/a') || 
          ($si_dimm->{condition} eq 'other')) {
        $si_dimm->{condition} = 'ok' if
            (defined $repaircondition && $repaircondition == 0);
      }
      push(@{$self->{dimms}},
          HP::Storage::Component::MemorySubsystem::Dimm->new(
              cartridge => $si_dimm->{cartridge},
              module => $si_dimm->{module},
              size => $si_dimm->{size},
              status => $si_dimm->{status},
              condition => $si_dimm->{condition},
      ));
    }
  } elsif (($si_dimms > 0) && ($si_dimms == $he_dimms)) {
    # neuere modelle 580 g2/3/4/5
    printf "TYP2 %s\n", $self->{runtime}->{product}
        if ($self->{runtime}->{options}->{verbose} >= 2);
    $self->{memconfig} = 2;
    @{$self->{dimms}} = $self->update_si_with_he();
  } elsif (($si_dimms > 0) && ($si_dimms == 2 * $he_dimms)) {
    # neuere modelle mit memory-raid ? 580 g2/3/4/5
    # meistens ist es so, dass die unbestueckten cartridges nicht in he 
    # auftauchen. si_dimms koennen genauso wie bei typ1 repariert werden.
    printf "TYP3 %s\n", $self->{runtime}->{product}
        if ($self->{runtime}->{options}->{verbose} >= 2);
    $self->{memconfig} = 3;
    @{$self->{dimms}} = $self->update_si_with_he();
  } elsif (($si_dimms > 0) && ($si_dimms == 4 * $he_dimms)) {
    # neuere modelle mit memory-raid ?
    # wie bei typ3. z.b. 4 cartridges, aber nur die erste mit 4 modulen
    # bestueckt. in he taucht dann nur diese cartridge auf.
    printf "TYP4 %s\n", $self->{runtime}->{product}
        if ($self->{runtime}->{options}->{verbose} >= 2);
    $self->{memconfig} = 4;
    @{$self->{dimms}} = $self->update_si_with_he();
  } elsif (($si_dimms == 0) && ($he_dimms > 0) && ($h2_dimms == 0)) {
    # nagelneue modelle
    printf "TYP5 %s\n", $self->{runtime}->{product}
        if ($self->{runtime}->{options}->{verbose} >= 2);
    $self->{memconfig} = 5;
  } elsif (($si_dimms == 0) && ($he_dimms > 0) && ($he_dimms == $h2_dimms)) {
    # nagelneue modelle
    printf "TYP6 %s\n", $self->{runtime}->{product}
        if ($self->{runtime}->{options}->{verbose} >= 2);
    $self->{memconfig} = 6;
    @{$self->{dimms}} = $self->update_he_with_h2();
  } elsif (($si_dimms == 0) && ($he_dimms > 0) && ($he_dimms == 2*$h2_dimms)) {
    # nagelneue modelle
    printf "TYP7 %s\n", $self->{runtime}->{product}
        if ($self->{runtime}->{options}->{verbose} >= 2);
    $self->{memconfig} = 7;
  } elsif (($si_dimms > 1) && ($he_dimms == 1) && 
      (($self->get_si_boards())[0] > ($self->get_he_boards())[0])) {
    # schrott
    printf "TYP8 %s\n", $self->{runtime}->{product}
        if ($self->{runtime}->{options}->{verbose} >= 2);
    $self->{memconfig} = 8;
  } else {
    # es gaebe zwar auch si_dimms > 1 && he_dimms = 1 bei gleichen boards
    # z.b. 8239JZG11749, aber irgenwann ist hopfen und malz verloren
    printf "TYPX %s %d %d %d\n", $self->{runtime}->{product},
        $si_dimms, $he_dimms, $h2_dimms
        if ($self->{runtime}->{options}->{verbose} >= 2);
    $self->{memconfig} = 999;
    my $repaircondition = undef;
    my $cpqHeResMemModuleEntry = "1.3.6.1.4.1.232.6.2.14.11.1";
    if (SNMP::Utils::get_size($snmpwalk, $cpqHeResMemModuleEntry) == 1) {
      $repaircondition = lc SNMP::Utils::get_object(
          $snmpwalk, $cpqHeResMemModuleEntry.'.1.0.'.$si_dimms);
      # repaircondition 0 (ok) biegt alles wieder gerade
    }
    foreach my $si_dimm (@{$self->{si_dimms}}) {
      if (($si_dimm->{condition} eq 'n/a') ||
          ($si_dimm->{condition} eq 'other')) {
        $si_dimm->{condition} = 'ok' if
            (defined $repaircondition && $repaircondition == 0);
      }
      push(@{$self->{dimms}},
          HP::Storage::Component::MemorySubsystem::Dimm->new(
              cartridge => $si_dimm->{cartridge},
              module => $si_dimm->{module},
              size => $si_dimm->{size},
              status => $si_dimm->{status},
              condition => $si_dimm->{condition},
      ));
    }
  }
}

sub dump {
  my $self = shift;
  if ($self->{runtime}->{options}->{verbose} > 2) {
    printf "[SI]\n";
    foreach (@{$self->{si_dimms}}) {
      $_->dump();
    }
    printf "[HE]\n";
    foreach (@{$self->{he_dimms}}) {
      $_->dump();
    }
    printf "[H2]\n";
    foreach (@{$self->{h2_dimms}}) {
      $_->dump();
    }
  }
  $self->SUPER::dump();
}

sub update_si_with_he {
  my $self = shift;
  my @dimms = ();
  my $first_si_cartridge = ($self->get_si_boards())[0];
  my $first_he_cartridge = ($self->get_he_boards())[0];
  my $offset = 0;
  # aufpassen! sowas kann vorkommen: si cartridge 0...6, he cartridge 1...7
  if ($first_si_cartridge != $first_he_cartridge) {
    # README case 5
    $offset = $first_si_cartridge - $first_he_cartridge;
  }
  foreach my $si_dimm (@{$self->{si_dimms}}) {
    if (($si_dimm->{condition} eq 'n/a') || 
        ($si_dimm->{condition} eq 'other')) {
      if (my $he_dimm = $self->get_he_module(
          $si_dimm->{cartridge} - $offset, $si_dimm->{module})) {
        # vielleicht hat he mehr ahnung
        $si_dimm->{condition} = $he_dimm->{condition};
        if (1) {
          # ist zwar da, aber irgendwie auskonfiguriert
          $si_dimm->{status} = 'notpresent' if $he_dimm->{status} eq 'other';
        }
      } else {
        # in dem fall zeigt si unbestueckte cartridges an
      }
    }
    push(@dimms,
        HP::Storage::Component::MemorySubsystem::Dimm->new(
            runtime => $self->{runtime},
            cartridge => $si_dimm->{cartridge},
            module => $si_dimm->{module},
            size => $si_dimm->{size},
            status => $si_dimm->{status},
            condition => $si_dimm->{condition},
    ));
  }
  return @dimms;
}

sub update_he_with_h2 {
  my $self = shift;
  my @dimms = ();
  my $first_he_cartridge = ($self->get_he_boards())[0];
  my $first_h2_cartridge = ($self->get_h2_boards())[0];
  my $offset = 0;
  # auch hier koennte sowas u.u.vorkommen: he cartridge 0..6, h2 cartridge 1..7
  # ich habs zwar nie gesehen, aber wer weiss...
  if ($first_h2_cartridge != $first_he_cartridge) {
    $offset = $first_h2_cartridge - $first_he_cartridge;
  }
  foreach my $he_dimm (@{$self->{he_dimms}}) {
    if (($he_dimm->{condition} eq 'n/a') || 
        ($he_dimm->{condition} eq 'other')) {
      if (my $h2_dimm = $self->get_h2_module(
          $he_dimm->{cartridge} + $offset, $he_dimm->{module})) {
        # vielleicht hat h2 mehr ahnung
        $he_dimm->{condition} = $h2_dimm->{condition};
        if (1) {
          # ist zwar da, aber irgendwie auskonfiguriert
          $he_dimm->{status} = 'notpresent' if $h2_dimm->{status} eq 'other';
        }
      } else {
        # in dem fall weiss he mehr als h2
      }
    }
    if ($he_dimm->{size} == 0) {
      if (my $h2_dimm = $self->get_h2_module(
          $he_dimm->{cartridge} + $offset, $he_dimm->{module})) {
        $he_dimm->{size} = $h2_dimm->{size};
        # h2 beinhaltet eine size-oid
      }
    }
    push(@dimms,
        HP::Storage::Component::MemorySubsystem::Dimm->new(
            runtime => $self->{runtime},
            cartridge => $he_dimm->{cartridge},
            module => $he_dimm->{module},
            size => $he_dimm->{size},
            status => $he_dimm->{status},
            condition => $he_dimm->{condition},
    ));
  }
  return @dimms;
}

sub is_faulty {
  my $self = shift;
  my $cpqHeResilientMemStatus = '1.3.6.1.4.1.232.6.2.14.3.0';
  my $cpqHeResilientMemStatusValue = {
    1 => 'other',
    2 => 'notProtected',
    3 => 'protected',
    4 => 'degraded',
    5 => 'dimmEcc',
    6 => 'mirrorNoFaults',
    7 => 'mirrorWithFaults',
    8 => 'hotSpareNoFaults',
    9 => 'hotSpareWithFaults',
    10 => 'xorNoFaults',
    11 => 'xorWithFaults',
    12 => 'advancedEcc',
    13 => 'undocumentedWithFaults',
  };
  $self->{memstatus} = lc SNMP::Utils::get_object_value(
        $self->{rawdata}, $cpqHeResilientMemStatus,
        $cpqHeResilientMemStatusValue);
  return $self->{memstatus} =~ /(degraded)|(withfaults)/;
}

sub get_si_boards {
  my $self = shift;
  my %found = ();
  foreach (@{$self->{si_dimms}}) {
    $found{$_->{cartridge}} = 1;
  }
  return sort { $a <=> $b } keys %found;
}

sub get_si_modules {
  my $self = shift;
  my $board = shift;
  my %found = ();
  foreach (grep { $_->{cartridge} == $board } @{$self->{si_dimms}}) {
    $found{$_->{module}} = 1;
  }
  return sort { $a <=> $b } keys %found;
}

sub get_he_boards {
  my $self = shift;
  my %found = ();
  foreach (@{$self->{he_dimms}}) {
    $found{$_->{cartridge}} = 1;
  }
  return sort { $a <=> $b } keys %found;
}

sub get_he_modules {
  my $self = shift;
  my $board = shift;
  my %found = ();
  foreach (grep { $_->{cartridge} == $board } @{$self->{he_dimms}}) {
    $found{$_->{module}} = 1;
  }
  return sort { $a <=> $b } keys %found;
}

sub get_he_module {
  my $self = shift;
  my $board = shift;
  my $module = shift;
  my $found = (grep { $_->{cartridge} == $board && $_->{module} == $module } 
      @{$self->{he_dimms}})[0];
  return $found;
}

sub get_h2_boards {
  my $self = shift;
  my %found = ();
  # 
  foreach (@{$self->{h2_dimms}}) {
    $found{$_->{cartridge}} = 1;
  }
  return sort { $a <=> $b } keys %found;
}

sub get_h2_modules {
  my $self = shift;
  my $board = shift;
  my %found = ();
  foreach (grep { $_->{cartridge} == $board } @{$self->{h2_dimms}}) {
    $found{$_->{module}} = 1;
  }
  return sort { $a <=> $b } keys %found;
}

sub get_h2_module {
  my $self = shift;
  my $board = shift;
  my $module = shift;
  my $found = (grep { $_->{cartridge} == $board && $_->{module} == $module } 
      @{$self->{h2_dimms}})[0];
  return $found;
}


