use Data::Dumper;
use Time::Local;
my $val = "07 D8 0B 1B 13 03";
my $val2 = $val;
$val2 =~ s/ //;
print $val2;
my  ($year, $month, $day, $hour, $min) = map { hex($_) } split(/\s+/, $val2);
my  @x = map { hex($_) } split(/\s+/, $val2);
my $now = timelocal(0, $min, $hour, $day, $month - 1, $year);
printf "%s\n", scalar localtime $now;
printf "%s\n", Data::Dumper::Dumper(\@x);

