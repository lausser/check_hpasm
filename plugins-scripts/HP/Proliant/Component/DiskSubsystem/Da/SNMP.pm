package HP::Proliant::Component::DiskSubsystem::Da::SNMP;
our @ISA = qw(HP::Proliant::Component::DiskSubsystem::Da
    HP::Proliant::Component::SNMP);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

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
  my $snmpwalk = $self->{rawdata};

  # CPQIDA-MIB
  my $oids = {
    cpqDaCntlrEntry => "1.3.6.1.4.1.232.3.2.2.1.1",
    cpqDaCntlrIndex => "1.3.6.1.4.1.232.3.2.2.1.1.1",
    cpqDaCntlrModel => "1.3.6.1.4.1.232.3.2.2.1.1.2",
    cpqDaCntlrSlot => "1.3.6.1.4.1.232.3.2.2.1.1.5",
    cpqDaCntlrCondition => "1.3.6.1.4.1.232.3.2.2.1.1.6",
    cpqDaCntlrBoardCondition => "1.3.6.1.4.1.232.3.2.2.1.1.12",
    cpqDaCntlrModelValue => {
        1 => 'other',
        2 => 'ida',
        3 => 'idaExpansion',
        4 => 'ida-2',
        5 => 'smart',
        6 => 'smart-2e',
        7 => 'smart-2p',
        8 => 'smart-2sl',
        9 => 'smart-3100es',
        10 => 'smart-3200',
        11 => 'smart-2dh',
        12 => 'smart-221',
        13 => 'sa-4250es',
        14 => 'sa-4200',
        15 => 'sa-integrated',
        16 => 'sa-431',
        17 => 'sa-5300',
        18 => 'raidLc2',
        19 => 'sa-5i',
        20 => 'sa-532',
        21 => 'sa-5312',
        22 => 'sa-641',
        23 => 'sa-642',
        24 => 'sa-6400',
        25 => 'sa-6400em',
        26 => 'sa-6i',
        27 => 'sa-generic',
        29 => 'sa-p600',
        30 => 'sa-p400',
        31 => 'sa-e200',
        32 => 'sa-e200i',
        33 => 'sa-p400i',
        34 => 'sa-p800',
        35 => 'sa-e500' ,
        36 => 'sa-p700m',
        37 => 'sa-p212',
        38 => 'sa-p410',
        39 => 'sa-p410i',
        40 => 'sa-p411',
        41 => 'sa-b110i',
        42 => 'sa-p712m',
        43 => 'sa-p711m',
        44 => 'sa-p812',
        45 => 'sw-1210m',
        49 => 'sa-p420i',
        52 => 'sa-p822'
        
    },
    cpqDaCntlrConditionValue => {
        1 => "other",
        2 => "ok",
        3 => "degraded",
        4 => "failed",
    },
    cpqDaCntlrBoardConditionValue => {
        1 => "other",
        2 => "ok",
        3 => "degraded",
        4 => "failed",
    },
  };

  # INDEX { cpqDaCntlrIndex }
  foreach ($self->get_entries($oids, 'cpqDaCntlrEntry')) {
    push(@{$self->{controllers}},
        HP::Proliant::Component::DiskSubsystem::Da::Controller->new(%{$_}));
  }

  $oids = {
      cpqDaAccelEntry => "1.3.6.1.4.1.232.3.2.2.2.1",
      cpqDaAccelCntlrIndex => "1.3.6.1.4.1.232.3.2.2.2.1.1",
      cpqDaAccelStatus => "1.3.6.1.4.1.232.3.2.2.2.1.2",
      cpqDaAccelSlot => "1.3.6.1.4.1.232.3.2.2.2.1.5",
      cpqDaAccelBattery  => "1.3.6.1.4.1.232.3.2.2.2.1.6",
      cpqDaAccelCondition  => "1.3.6.1.4.1.232.3.2.2.2.1.9",
      cpqDaAccelBatteryValue => {
          1 => 'other',
          2 => 'ok',
          3 => 'recharging',
          4 => 'failed',
          5 => 'degraded',
          6 => 'notPresent',
      },
      cpqDaAccelConditionValue => {
          1 => "other",
          2 => "ok",
          3 => "degraded",
          4 => "failed",
      },
      cpqDaAccelStatusValue => {
          1 => "other",
          2 => "invalid",
          3 => "enabled",
          4 => "tmpDisabled",
          5 => "permDisabled",
      }
  };
    
  # INDEX { cpqDaAccelCntlrIndex }
  foreach ($self->get_entries($oids, 'cpqDaAccelEntry')) {
    push(@{$self->{accelerators}},
        HP::Proliant::Component::DiskSubsystem::Da::Accelerator->new(%{$_}));
  }

  $oids = {
      cpqDaLogDrvEntry => "1.3.6.1.4.1.232.3.2.3.1.1",
      cpqDaLogDrvCntlrIndex => "1.3.6.1.4.1.232.3.2.3.1.1.1",
      cpqDaLogDrvIndex => "1.3.6.1.4.1.232.3.2.3.1.1.2",
      cpqDaLogDrvFaultTol => "1.3.6.1.4.1.232.3.2.3.1.1.3",
      cpqDaLogDrvStatus => "1.3.6.1.4.1.232.3.2.3.1.1.4",
      cpqDaLogDrvSize => "1.3.6.1.4.1.232.3.2.3.1.1.9",
      cpqDaLogDrvPhyDrvIDs => "1.3.6.1.4.1.232.3.2.3.1.1.10",
      cpqDaLogDrvCondition => "1.3.6.1.4.1.232.3.2.3.1.1.11",
      cpqDaLogDrvPercentRebuild => "1.3.6.1.4.1.232.3.2.3.1.1.12",
      cpqDaLogDrvFaultTolValue => {
          1 => "other",
          2 => "none",
          3 => "mirroring",
          4 => "dataGuard",
          5 => "distribDataGuard",
          7 => "advancedDataGuard",
      },
      cpqDaLogDrvConditionValue => {
          1 => "other",
          2 => "ok",
          3 => "degraded",
          4 => "failed",
      },
      cpqDaLogDrvStatusValue => {
          1 => "other",
          2 => "ok",
          3 => "failed",
          4 => "unconfigured",
          5 => "recovering",
          6 => "readyForRebuild",
          7 => "rebuilding",
          8 => "wrongDrive",
          9 => "badConnect",
          10 => "overheating",
          11 => "shutdown",
          12 => "expanding",
          13 => "notAvailable",
          14 => "queuedForExpansion",
      },
  };

  # INDEX { cpqDaLogDrvCntlrIndex, cpqDaLogDrvIndex }
  foreach ($self->get_entries($oids, 'cpqDaLogDrvEntry')) {
    $_->{cpqDaLogDrvPhyDrvIDs} ||= 'empty';
    push(@{$self->{logical_drives}},
        HP::Proliant::Component::DiskSubsystem::Da::LogicalDrive->new(%{$_}));
  }

  $oids = {
      cpqDaPhyDrvEntry => "1.3.6.1.4.1.232.3.2.5.1.1",
      cpqDaPhyDrvCntlrIndex => "1.3.6.1.4.1.232.3.2.5.1.1.1",
      cpqDaPhyDrvIndex => "1.3.6.1.4.1.232.3.2.5.1.1.2",
      cpqDaPhyDrvBay => "1.3.6.1.4.1.232.3.2.5.1.1.5",
      cpqDaPhyDrvStatus => "1.3.6.1.4.1.232.3.2.5.1.1.6",
      cpqDaPhyDrvSize => "1.3.6.1.4.1.232.3.2.5.1.1.9",
      cpqDaPhyDrvCondition => "1.3.6.1.4.1.232.3.2.5.1.1.37",
      cpqDaPhyDrvBusNumber => "1.3.6.1.4.1.232.3.2.5.1.1.50",
      cpqDaPhyDrvModel => "1.3.6.1.4.1.232.3.2.5.1.1.3",
      cpqDaPhyDrvConditionValue => {
          1 => "other",
          2 => "ok",
          3 => "degraded",
          4 => "failed",
      },
      cpqDaPhyDrvStatusValue => {
          1 => "other",
          2 => "ok",
          3 => "failed",
          4 => "predictiveFailure",
      },
  };
    
  # INDEX { cpqDaPhyDrvCntlrIndex, cpqDaPhyDrvIndex }
  foreach ($self->get_entries($oids, 'cpqDaPhyDrvEntry')) {
    push(@{$self->{physical_drives}},
        HP::Proliant::Component::DiskSubsystem::Da::PhysicalDrive->new(%{$_}));
  }

}
