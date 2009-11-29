package HP::Proliant::Component::DiskSubsystem::Da::CLI;
our @ISA = qw(HP::Proliant::Component::DiskSubsystem::Da);

use strict;
use Nagios::Plugin;

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    controllers => [],
    accelerators => [],
    physical_drives => [],
    logical_drives => [],
    spare_drives => [],
    blacklisted => 0,
  };
  bless $self, $class;
  return $self;
}

sub init {
  my $self = shift;
  my $hpacucli = $self->{rawdata};
  my $slot = 0;
  my $type = "unkn";
  my @lines = ();
  my $thistype = 0;
  my $tmpcntl = {};
  my $tmpaccel = {};
  my $tmpld = {};
  my $tmppd = {};
  my $cntlindex = 0;
  my $ldriveindex = 0;
  my $pdriveindex = 0;
  my $incontroller = 0;
  foreach (split(/\n/, $hpacucli)) {
    next unless /^status/;
    next if /^status\s*$/;
    s/^status\s*//;
    if (/([\s\w]+) in Slot\s+(\d+)/) {
      $incontroller = 1;
      $slot = $2;
      $cntlindex++;
      $tmpcntl->{$slot}->{cpqDaCntlrIndex} = $cntlindex;
      $tmpcntl->{$slot}->{cpqDaCntlrModel} = $1;
      $tmpcntl->{$slot}->{cpqDaCntlrSlot} = $slot;
    } elsif (/Controller Status: (\w+)/) {
      $tmpcntl->{$slot}->{cpqDaCntlrBoardCondition} = lc $1;
      $tmpcntl->{$slot}->{cpqDaCntlrCondition} = lc $1;
    } elsif (/Cache Status: (\w+)/) {
      $tmpaccel->{$slot}->{cpqDaAccelCntlrIndex} = $cntlindex;
      $tmpaccel->{$slot}->{cpqDaAccelSlot} = $slot;
      $tmpaccel->{$slot}->{cpqDaAccelCondition} = lc $1;
      $tmpaccel->{$slot}->{cpqDaAccelStatus} = 'enabled';
    } elsif (/Battery.* Status: (\w+)/) {
      # sowas gibts auch Battery/Capacitor Status: OK
      $tmpaccel->{$slot}->{cpqDaAccelBattery} = lc $1;
    } elsif (/^\s*$/) {
    }
  }
  $cntlindex = 0;
  $ldriveindex = 0;
  $pdriveindex = 0;
  foreach (split(/\n/, $hpacucli)) {
    next unless /^config/;
    next if /^config\s*$/;
    s/^status\s*//;
    if (/([\s\w]+) in Slot\s+(\d+)/) {
      $slot = $2;
      $cntlindex++;
      $pdriveindex = 1;
    } elsif (/logicaldrive\s+(.+?)\s+\((.*)\)/) {
      $tmpld = {};
      # logicaldrive 1 (683.5 GB, RAID 5, OK)
      # logicaldrive 1 (683.5 GB, RAID 5, OK)
      # logicaldrive 2 (442 MB, RAID 1+0, OK)
      $ldriveindex = $1;
      $tmpld->{$slot}->{$ldriveindex}->{cpqDaLogDrvCntlrIndex} = $cntlindex;
      $tmpld->{$slot}->{$ldriveindex}->{cpqDaLogDrvIndex} = $ldriveindex;
      ($tmpld->{$slot}->{$ldriveindex}->{cpqDaLogDrvSize},
          $tmpld->{$slot}->{$ldriveindex}->{cpqDaLogDrvFaultTol},
          $tmpld->{$slot}->{$ldriveindex}->{cpqDaLogDrvCondition}) =
          map { lc $_ } split(/,\s*/, $2);
      $tmpld->{$slot}->{$ldriveindex}->{cpqDaLogDrvStatus} =
          $tmpld->{$slot}->{$ldriveindex}->{cpqDaLogDrvCondition};
      $tmpld->{$slot}->{$ldriveindex}->{cpqDaLogDrvPhyDrvIDs} = 'unknown';
    } elsif (/physicaldrive\s+(.+?)\s+\((.*)\)/) {
      # physicaldrive 2:0   (port 2:id 0 , Parallel SCSI, 36.4 GB, OK)
      # physicaldrive 2I:1:6 (port 2I:box 1:bay 6, SAS, 146 GB, OK)
      my $name = $1;
      my($location, $type, $size, $status) = split(/,/, $2);
      $status =~ s/^\s+//g;
      $status =~ s/\s+$//g;
      $status = lc $status;
      my %location = ();
      foreach (split(/:/, $location)) {
        $location{$1} = $2 if /(\w+)\s+(\w+)/;
      }
      $location{box} ||= 0;
      $location{id} ||= $pdriveindex;
      $location{bay} ||= $location{id};
      $tmppd->{$slot}->{$name}->{name} = lc $name;
      $tmppd->{$slot}->{$name}->{cpqDaPhyDrvCntlrIndex} = $cntlindex;
      $tmppd->{$slot}->{$name}->{cpqDaPhyDrvIndex} = $location{id};
      $tmppd->{$slot}->{$name}->{cpqDaPhyDrvBay} = $location{bay};
      $tmppd->{$slot}->{$name}->{cpqDaPhyDrvBusNumber} = $location{port};
      $tmppd->{$slot}->{$name}->{cpqDaPhyDrvSize} = $size;
      $tmppd->{$slot}->{$name}->{cpqDaPhyDrvStatus} = $status;
      $tmppd->{$slot}->{$name}->{cpqDaPhyDrvCondition} = $status;
#printf "loc %s\n", Data::Dumper::Dumper(\%location);
      foreach (keys %{$tmppd->{$slot}->{$name}}) {
#printf "key %s is %s\n", $_, $tmppd->{$slot}->{$name}->{$_};
        $tmppd->{$slot}->{$name}->{$_} =~ s/^\s+//g;
        $tmppd->{$slot}->{$name}->{$_} =~ s/\s+$//g;
        $tmppd->{$slot}->{$name}->{$_} = lc $tmppd->{$slot}->{$name}->{$_};
      }
    }
  }
#$self->dumper($tmppd);

    #cpqDaPhyDrvCntlrIndex => $params{cpqDaPhyDrvCntlrIndex},
    #cpqDaPhyDrvIndex => $params{cpqDaPhyDrvIndex},
    #cpqDaPhyDrvBay => $params{cpqDaPhyDrvBay},
    #cpqDaPhyDrvBusNumber => $params{cpqDaPhyDrvBusNumber},
    #cpqDaPhyDrvSize => $params{cpqDaPhyDrvSize},
    #cpqDaPhyDrvStatus => $params{cpqDaPhyDrvStatus},
    #cpqDaPhyDrvCondition => $params{cpqDaPhyDrvCondition},


  foreach my $slot (keys %{$tmpcntl}) {
    if (exists $tmpcntl->{$slot}->{cpqDaCntlrModel} &&
        ! $self->identified($tmpcntl->{$slot}->{cpqDaCntlrModel})) {
      delete $tmpcntl->{$slot};
      delete $tmpaccel->{$slot};
      delete $tmpld->{$slot};
      delete $tmppd->{$slot};
    }
  }

#printf "%s\n", Data::Dumper::Dumper($tmpcntl);
#printf "%s\n", Data::Dumper::Dumper($tmpaccel);
#printf "%s\n", Data::Dumper::Dumper($tmpld);
#printf "%s\n", Data::Dumper::Dumper($tmppd);
  foreach my $slot (keys %{$tmpcntl}) {
    $tmpcntl->{$slot}->{runtime} = $self->{runtime};
    push(@{$self->{controllers}},
        HP::Proliant::Component::DiskSubsystem::Da::Controller->new(
            %{$tmpcntl->{$slot}}));
  }
  foreach my $slot (keys %{$tmpaccel}) {
    $tmpaccel->{$slot}->{runtime} = $self->{runtime};
    push(@{$self->{accelerators}},
        HP::Proliant::Component::DiskSubsystem::Da::Accelerator->new(
            %{$tmpaccel->{$slot}}));
  }
  foreach my $slot (keys %{$tmpld}) {
    foreach my $ldriveindex (keys %{$tmpld->{$slot}}) {
      $tmpld->{$slot}->{$ldriveindex}->{runtime} = $self->{runtime};
      push(@{$self->{logical_drives}},
          HP::Proliant::Component::DiskSubsystem::Da::LogicalDrive->new(
              %{$tmpld->{$slot}->{$ldriveindex}}));
    }
    foreach my $pdriveindex (keys %{$tmppd->{$slot}}) {
      $tmppd->{$slot}->{$pdriveindex}->{runtime} = $self->{runtime};
      push(@{$self->{physical_drives}},
          HP::Proliant::Component::DiskSubsystem::Da::PhysicalDrive->new(
              %{$tmppd->{$slot}->{$pdriveindex}}));
    }
  }
}

sub identified {
  my $self = shift;
  my $info = shift;
  return 1 if $info =~ /Parallel SCSI/;
  return 1 if $info =~ /Smart Array (5|6)/;
  return 1 if $info =~ /Smart Array P400i/; # snmp sagt Da, trotz SAS in cli
  return 1 if $info =~ /Smart Array P410i/; # dto
  return 0;
}
