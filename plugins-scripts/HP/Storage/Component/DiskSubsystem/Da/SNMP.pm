package HP::Storage::Component::DiskSubsystem::Da::SNMP;
our @ISA = qw(HP::Storage::Component::DiskSubsystem::Da);

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
  my $cpqDaCntlrEntry = "1.3.6.1.4.1.232.3.2.2.1.1";
  my $cpqDaCntlrIndex = "1.3.6.1.4.1.232.3.2.2.1.1.1";
  my $cpqDaCntlrModel = "1.3.6.1.4.1.232.3.2.2.1.1.2";
  my $cpqDaCntlrSlot = "1.3.6.1.4.1.232.3.2.2.1.1.5";
  my $cpqDaCntlrCondition  = "1.3.6.1.4.1.232.3.2.2.1.1.6";
  my $cpqDaCntlrBoardCondition  = "1.3.6.1.4.1.232.3.2.2.1.1.12";
  my $cpqDaCntlrModelValue = {
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
  };
  my $cpqDaCntlrConditionValue = {
      1 => "other",
      2 => "ok",
      3 => "degraded",
      4 => "failed",
  };
  my $cpqDaCntlrBoardConditionValue = $cpqDaCntlrConditionValue;

  # INDEX { cpqDaCntlrIndex }
  my @indices = SNMP::Utils::get_indices($snmpwalk, $cpqDaCntlrEntry);
  foreach (@indices) {
    my $idx1 = $_->[0];
    my $index = SNMP::Utils::get_object($snmpwalk, $cpqDaCntlrIndex, $idx1);
    my $model = SNMP::Utils::get_object_value($snmpwalk, $cpqDaCntlrModel,
        $cpqDaCntlrModelValue, $idx1) || 'unknown';
    my $slot = SNMP::Utils::get_object($snmpwalk, $cpqDaCntlrSlot, $idx1);
    # overall device, accel, phys., log.
    my $condition = SNMP::Utils::get_object_value($snmpwalk, 
        $cpqDaCntlrCondition, $cpqDaCntlrConditionValue, $idx1);
    my $boardcondition = SNMP::Utils::get_object_value($snmpwalk, 
        $cpqDaCntlrBoardCondition, $cpqDaCntlrBoardConditionValue, $idx1);

    push(@{$self->{controllers}},
        HP::Storage::Component::DiskSubsystem::Da::Controller->new(
            runtime => $self->{runtime},
            index => $index,
            slot => $slot,
            model => $model,
            condition => $condition,
            boardcondition => $boardcondition,
    ));
  }

  my $cpqDaAccelEntry = "1.3.6.1.4.1.232.3.2.2.2.1";
  my $cpqDaAccelCntlrIndex = "1.3.6.1.4.1.232.3.2.2.2.1.1";
  my $cpqDaAccelStatus = "1.3.6.1.4.1.232.3.2.2.2.1.2";
  my $cpqDaAccelSlot = "1.3.6.1.4.1.232.3.2.2.2.1.5";
  my $cpqDaAccelBattery  = "1.3.6.1.4.1.232.3.2.2.2.1.6";
  my $cpqDaAccelCondition  = "1.3.6.1.4.1.232.3.2.2.2.1.9";
  my $cpqDaAccelBatteryValue = {
      1 => 'other',
      2 => 'ok',
      3 => 'recharging',
      4 => 'failed',
      5 => 'degraded',
      6 => 'notPresent',
  };
  my $cpqDaAccelConditionValue = {
      1 => "other",
      2 => "ok",
      3 => "degraded",
      4 => "failed",
  };
    
  # INDEX { cpqDaAccelCntlrIndex }
  @indices = SNMP::Utils::get_indices($snmpwalk, $cpqDaAccelEntry);
  foreach (@indices) {
    my $idx1 = $_->[0];
    my $status = lc SNMP::Utils::get_object(
        $snmpwalk, $cpqDaAccelStatus, $idx1);
    my $ctrlindex =
        SNMP::Utils::get_object($snmpwalk, $cpqDaAccelCntlrIndex, $idx1);
    my $battery = lc SNMP::Utils::get_object_value(
        $snmpwalk, $cpqDaAccelBattery,
        $cpqDaAccelBatteryValue, $idx1);
    my $condition = lc SNMP::Utils::get_object_value(
        $snmpwalk, $cpqDaAccelCondition,
        $cpqDaAccelConditionValue, $idx1);
    push(@{$self->{accelerators}},
       HP::Storage::Component::DiskSubsystem::Da::Accelerator->new(
            runtime => $self->{runtime},
        cntrlindex => $ctrlindex,
        battery => $battery,
        condition => $condition,
    ));
  }

  my $cpqDaLogDrvEntry = "1.3.6.1.4.1.232.3.2.3.1.1";
  my $cpqDaLogDrvCntlrIndex = "1.3.6.1.4.1.232.3.2.3.1.1.1";
  my $cpqDaLogDrvIndex = "1.3.6.1.4.1.232.3.2.3.1.1.2";
  my $cpqDaLogDrvFaultTol = "1.3.6.1.4.1.232.3.2.3.1.1.3";
  my $cpqDaLogDrvStatus = "1.3.6.1.4.1.232.3.2.3.1.1.4";
  my $cpqDaLogDrvSize = "1.3.6.1.4.1.232.3.2.3.1.1.9";
  my $cpqDaLogDrvCondition = "1.3.6.1.4.1.232.3.2.3.1.1.11";
  my $cpqDaLogDrvPercentRebuild = "1.3.6.1.4.1.232.3.2.3.1.1.12";
  my $cpqDaLogDrvFaultTolValue = {
      1 => "other",
      2 => "none",
      3 => "mirroring",
      4 => "dataGuard",
      5 => "distribDataGuard",
      7 => "advancedDataGuard",
  };
  my $cpqDaLogDrvConditionValue = {
      1 => "other",
      2 => "ok",
      3 => "degraded",
      4 => "failed",
  };
  my $cpqDaLogDrvStatusValue = {
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
  };

  # INDEX { cpqDaLogDrvCntlrIndex, cpqDaLogDrvIndex }
  @indices = SNMP::Utils::get_indices($snmpwalk, $cpqDaLogDrvEntry);
  foreach (@indices) {
    my($idx1, $idx2) = ($_->[0], $_->[1]);
    my $cntrlindex = 
       SNMP::Utils::get_object($snmpwalk, $cpqDaLogDrvCntlrIndex, $idx1, $idx2);
    my $index =
        SNMP::Utils::get_object($snmpwalk, $cpqDaLogDrvIndex, $idx1, $idx2);
    my $size =
        SNMP::Utils::get_object($snmpwalk, $cpqDaLogDrvSize, $idx1, $idx2);
    #my $size = SNMP::Utils::get_number(\@indices, $idx1, $idx2);
    my $level = lc SNMP::Utils::get_object_value(
        $snmpwalk, $cpqDaLogDrvFaultTol,
        $cpqDaLogDrvFaultTolValue, $idx1, $idx2);
    my $status = lc SNMP::Utils::get_object_value(
        $snmpwalk, $cpqDaLogDrvStatus,
        $cpqDaLogDrvStatusValue, $idx1, $idx2);
    my $condition = lc SNMP::Utils::get_object_value(
        $snmpwalk, $cpqDaLogDrvCondition,
        $cpqDaLogDrvConditionValue, $idx1, $idx2);
    my $percentrebuild = SNMP::Utils::get_object($snmpwalk,
        $cpqDaLogDrvPercentRebuild, $idx1, $idx2);
#printf "LOLO cntrlindex %s index %s size %s level %s sttaus %s cond %s\n", 
#  $cntrlindex, $index, $size, $level, $status,  $condition;
    push(@{$self->{logical_drives}},
     HP::Storage::Component::DiskSubsystem::Da::LogicalDrive->new(
            runtime => $self->{runtime},
      cntrlindex => $cntrlindex,
      index => $index,
      size => $size,
      level => $level,
      status => $status,
      condition => $condition,
    ));
  }

  my $cpqDaPhyDrvEntry = "1.3.6.1.4.1.232.3.2.5.1.1";
  my $cpqDaPhyDrvCntlrIndex = "1.3.6.1.4.1.232.3.2.5.1.1.1";
  my $cpqDaPhyDrvIndex = "1.3.6.1.4.1.232.3.2.5.1.1.2";
  my $cpqDaPhyDrvBay = "1.3.6.1.4.1.232.3.2.5.1.1.5";
  my $cpqDaPhyDrvStatus = "1.3.6.1.4.1.232.3.2.5.1.1.6";
  my $cpqDaPhyDrvSize = "1.3.6.1.4.1.232.3.2.5.1.1.9";
  my $cpqDaPhyDrvCondition = "1.3.6.1.4.1.232.3.2.5.1.1.37";
  my $cpqDaPhyDrvBusNumber = "1.3.6.1.4.1.232.3.2.5.1.1.50";
  my $cpqDaPhyDrvConditionValue = {
      1 => "other",
      2 => "ok",
      3 => "degraded",
      4 => "failed",
  };
  my $cpqDaPhyDrvStatusValue = {
      1 => "other",
      2 => "ok",
      3 => "failed",
      4 => "predictiveFailure",
  };
    
  # INDEX { cpqDaLogDrvCntlrIndex, cpqDaLogDrvIndex }
  @indices = SNMP::Utils::get_indices($snmpwalk, $cpqDaPhyDrvEntry);
  foreach (@indices) {
    my($idx1, $idx2) = ($_->[0], $_->[1]);
    my $cntrlindex = SNMP::Utils::get_object($snmpwalk, 
        $cpqDaPhyDrvCntlrIndex, $idx1, $idx2);
    my $index =  SNMP::Utils::get_object($snmpwalk,
        $cpqDaPhyDrvIndex, $idx1, $idx2),
    my $bay = SNMP::Utils::get_object($snmpwalk,
        $cpqDaPhyDrvBay, $idx1, $idx2),
    my $size = SNMP::Utils::get_object($snmpwalk,
        $cpqDaPhyDrvSize, $idx1, $idx2),
    my $busnumber =  SNMP::Utils::get_object($snmpwalk,
        $cpqDaPhyDrvBusNumber, $idx1, $idx2),
    my $status = lc SNMP::Utils::get_object_value(
        $snmpwalk, $cpqDaPhyDrvStatus,
        $cpqDaPhyDrvStatusValue, $idx1, $idx2);
    my $con = lc SNMP::Utils::get_object(
        $snmpwalk, $cpqDaPhyDrvCondition, $idx1, $idx2);
    my $condition = lc SNMP::Utils::get_object_value(
        $snmpwalk, $cpqDaPhyDrvCondition,
        $cpqDaPhyDrvConditionValue, $idx1, $idx2);
#printf "PYPY cntrlindex %s index %s size %s sttaus %s cond %s\n", 
#  $cntrlindex, $index, $size, $status,  $con;
    push(@{$self->{physical_drives}},
        HP::Storage::Component::DiskSubsystem::Da::PhysicalDrive->new(
            runtime => $self->{runtime},
            cntrlindex => $cntrlindex,
            index => $index,
            bay => $bay,
            busnumber => $busnumber,
            size => $size,
            status => $status,
            condition => $condition,
    ));
  }


}
