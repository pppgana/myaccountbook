#!/usr/bin/perl
#---+---1----+----2----+----3----+----4----+----5----+----6----+
# netstatコマンドを実行し、その結果を解析する
#
# Author M.Iwanaga (IBM)
# 
#---+---1----+----2----+----3----+----4----+----5----+----6----+
use strict;
use warnings;
use Getopt::Std;
use Getopt::Long qw(:config posix_default no_ignore_case gnu_compat);
use Time::Local;

my ($sec, $min, $hh, $dd, $mm, $yy, $weak, $yday, $opt);
my ($year, $month);
my $time_stamp = "";

my $netstat_cmd = "netstat -an";
my @cmd_outlines = "";
my $sleep_time = 30;
my $times = 2;

my %recorded_sockets = (
  "test" => "0.0.0.0:135",
	"pc-80"   => "10.240.144.2.80" , # pc:80
	"pc-443"  => "10.240.144.2.443", # pc:443
	"net-80"  => "10.240.144.3.80" ,	# net:80
	"net-443" => "10.240.144.3.443",	# net:443
	"scs-80"  => "10.240.144.4.80" ,	# scs:80
	"scs-443" => "10.240.144.4.443", # scs:443
	"mymobi-80"  => "10.240.144.5.80" ,	# mymobi:80
	"mymobi-443" => "10.240.144.5.443"	# mymobi:443
);

my %CLOSED_CNT;
my %LISTEN_CNT;
my %CLOSING_CNT;
my %SYN_SENT_CNT;
my %SYN_RCVD_CNT;
my %LAST_ACK_CNT;
my %TIME_WAIT_CNT;
my %FIN_WAIT_1_CNT;
my %FIN_WAIT_2_CNT;
my %ESTABLISHED_CNT;
my %CLOSE_WAIT_CNT;

my %sockets_cnt;

#---+---1----+----2----+----3----+----4----+----5----+----6----+
# オプションの処理
#--------------------------------------
my %opts;
getopts ('t:s:' => \%opts);
$sleep_time = $opts{'s'};
$times = $opts{'t'};


@cmd_outlines =  `$netstat_cmd`;

foreach my $line (@cmd_outlines) {
	foreach my $socket_name (keys %recorded_sockets) {
		if ( $line =~ /$recorded_sockets{$socket_name} / ) {
			print $line;
    }
  }
}


($sec,$min,$hh,$dd,$mm,$yy,$weak,$yday,$opt) = localtime();
$year = $yy + 1900;
$month = $mm + 1;

$time_stamp =  sprintf ("%4d\/%02d\/%02d %02d:%02d:%02d", $year, $month, $dd, $hh, $min, $sec);

sub hoge() {
  my ($line, $socket_name) = @_;
  if    ( $line =~ /CLOSED$/ ) 
    { $CLOSED_CNT{$socket_name} = $CLOSED_CNT{$socket_name}++; }
  elsif ( $line =~ /LISTEN$/ ) 
    { $LISTEN_CNT{$socket_name} = $LISTEN_CNT{$socket_name}++; }
  elsif ( $line =~ /CLOSING$/ ) 
    { $CLOSING_CNT{$socket_name} = $CLOSING_CNT{$socket_name}++; }
  elsif ( $line =~ /SYN_SENT$/ ) 
    { $SYN_SENT_CNT{$socket_name} = $SYN_SENT_CNT{$socket_name}++; }
  elsif ( $line =~ /SYN_RCVD$/ ) 
    { $SYN_RCVD_CNT{$socket_name} = $SYN_RCVD_CNT{$socket_name}++; }
  elsif ( $line =~ /LAST_ACK$/ ) 
    {$LAST_ACK_CNT{$socket_name} = $LAST_ACK_CNT{$socket_name}++; }
  elsif ( $line =~ /TIME_WAIT$/ ) 
    {$TIME_WAIT_CNT{$socket_name} = $TIME_WAIT_CNT{$socket_name}++; }
  elsif ( $line =~ /FIN_WAIT_1$/ ) 
    {$FIN_WAIT_1_CNT{$socket_name} = $FIN_WAIT_1_CNT{$socket_name}++; }
  elsif ( $line =~ /FIN_WAIT_2$/ ) 
    {$FIN_WAIT_2_CNT{$socket_name} = $FIN_WAIT_2_CNT{$socket_name}++; }
  elsif ( $line =~ /CLOSE_WAIT$/ ) 
    {$CLOSE_WAIT_CNT{$socket_name} = $CLOSE_WAIT_CNT{$socket_name}++; }
  elsif ( $line =~ /ESTABLISHED$/ ) 
    {$ESTABLISHED_CNT{$socket_name} = $ESTABLISHED_CNT{$socket_name}++; }
}