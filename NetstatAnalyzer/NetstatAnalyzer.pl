#!/usr/bin/perl
#====================================================================
# netstatコマンドを実行し、その結果を解析する
#
# Author M.Iwanaga (IBM)
#
#
#====================================================================
use lib 'YAML-Tiny-1.64/lib';
use strict;
use warnings;
use Getopt::Std;
use Getopt::Long qw(:config posix_default no_ignore_case gnu_compat);
use Time::Local;
use YAML::Tiny;
use Data::Dumper;

#---+---1----+----2----+----3----+----4----+----5----+----6----+
# YAML属性名 (定数)
use constant NETSTAT_CMD => "NETSTAT_CMD";
use constant LOGROOT_DIR => "LOGROOT_DIR";
use constant MONITOR_SOCKETS => "MONITOR_SOCKETS";

#---+---1----+----2----+----3----+----4----+----5----+----6----+
# 変数定義
my ($sec, $min, $hh, $dd, $mm, $yy, $weak, $yday, $opt);
my ($year, $month);
my $time_stamp = "";

my $netstat_cmd = "netstat -an";
my $logroot_dir = "/tmp";
my %recorded_sockets;

my @cmd_outlines = "";
my $sleep_time = 30;
my $times = 2;
my $config_file = "target.yaml";

=pod
my @socket_statuses = (
  "LISTEN", "CLOSED", "CLOSING", 
  "SYN_SENT", "SYN_RCVD", "LAST_ACK", 
  "TIME_WAIT", "CLOSE_WAIT", "FIN_WAIT_1", 
  "FIN_WAIT_2", "ESTABLISHED" 
);
=cut

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

my %s_status_cnt_hash = (
  LISTEN => \%LISTEN_CNT, 
  CLOSED => \%CLOSED_CNT, 
  CLOSING => \%CLOSING_CNT, 
  SYN_SENT => \%SYN_SENT_CNT, 
  SYN_RCVD => \%SYN_RCVD_CNT, 
  LAST_ACK => \%LAST_ACK_CNT, 
  TIME_WAIT => \%TIME_WAIT_CNT, 
  CLOSE_WAIT => \%CLOSE_WAIT_CNT, 
  FIN_WAIT_1 => \%FIN_WAIT_1_CNT, 
  FIN_WAIT_2 => \%FIN_WAIT_2_CNT, 
  ESTABLISHED => \%ESTABLISHED_CNT,
);

#---+---1----+----2----+----3----+----4----+----5----+----6----+
# コマンドライン・オプションの処理
my %opts;
getopts ('t:s:c:' => \%opts);
$sleep_time = $opts{'s'};
$times = $opts{'t'};
$config_file = $opts{'c'};

#---+---1----+----2----+----3----+----4----+----5----+----6----+
# YAMLより各種設定を読み込み
my $yaml = YAML::Tiny -> new;
$yaml = YAML::Tiny -> read ($config_file);
my $config = $yaml -> [0];

# NETSTATコマンドをラインを取得
$netstat_cmd = $config -> {NETSTAT_CMD};
# カウント対象とするSocket定義(Hash)を取得
%recorded_sockets =  %{$config -> {MONITOR_SOCKETS}};
# ログ出力先ディレクトリーを取得
$logroot_dir = $config -> {LOGROOT_DIR};

#print $netstat_cmd . "\n";
#print Dumper($config);
#print Dumper($config -> {MONITOR_SOCKETS});
#print Dumper(%recorded_sockets);
#print $config -> {MONITOR_SOCKETS} -> {test};
#$netstat_cmd = $config -> {NETSTAT_CMD};
#%recorded_sockets =  $config -> {MONITOR_SOCKETS};
#print Dumper(%recorded_sockets);

#---+---1----+----2----+----3----+----4----+----5----+----6----+
# ソケット数カウント部
while (1) {
  # netstat コマンドを実行
  @cmd_outlines =  `$netstat_cmd`;
  # カウンターをリセット
  &reset_counter;

  foreach my $line (@cmd_outlines) {
    foreach my $socket_name (keys %recorded_sockets) {
      if ( $line =~ /$recorded_sockets{$socket_name} / ) {
        &count_socket($line, $socket_name);
        #print $line . "\n";
      }
    }
  }
  &print_counter;
  sleep $sleep_time;
}

sub get_time_stamp () {
  ($sec, $min, $hh, $dd, $mm, $yy, $weak, $yday, $opt) = localtime();
  $year = $yy + 1900;
  $month = $mm + 1;
  return $time_stamp =  sprintf ("%4d\/%02d\/%02d %02d:%02d:%02d", $year, $month, $dd, $hh, $min, $sec);
}

sub count_socket() {
  my ($line, $socket_name) = @_;
  #print "[count_socket \$line] " . $line;

  foreach my $s_status (keys %s_status_cnt_hash) {
    if ( $line =~ /$s_status/ ) {
      $s_status_cnt_hash{$s_status} -> {$socket_name} 
        = $s_status_cnt_hash{$s_status} -> {$socket_name} + 1;
      print "[$s_status] " . $s_status_cnt_hash{$s_status} -> {$socket_name} . "\n";
    }
  }
=pod  
  if ( $line =~ /CLOSED/ ) {
    $CLOSED_CNT{$socket_name} = $CLOSED_CNT{$socket_name} + 1;
    #print "[CLOSED CNT] " . $CLOSED_CNT{$socket_name} . "\n";
  }
  elsif ( $line =~ /LISTEN/ ) {
    $LISTEN_CNT{$socket_name} = $LISTEN_CNT{$socket_name} + 1;
    #print "[LISTEN CNT] " . $LISTEN_CNT{$socket_name} . "\n";
  }
  elsif ( $line =~ /CLOSING/ ) { 
    $CLOSING_CNT{$socket_name} = $CLOSING_CNT{$socket_name} + 1;
    #print "[CLOSING CNT] " . $CLOSING_CNT{$socket_name} . "\n";
  }
  elsif ( $line =~ /SYN_SENT/ ) {
    $SYN_SENT_CNT{$socket_name} = $SYN_SENT_CNT{$socket_name} + 1; 
    #print "[SYN_SENT CNT] " . $SYN_SENT_CNT{$socket_name} . "\n";
  }
  elsif ( $line =~ /SYN_RCVD/ ) { 
    $SYN_RCVD_CNT{$socket_name} = $SYN_RCVD_CNT{$socket_name} + 1;
    #print "[SYN_RCVD CNT] " . $SYN_RCVD_CNT{$socket_name} . "\n";
  }
  elsif ( $line =~ /LAST_ACK/ ) {
    $LAST_ACK_CNT{$socket_name} = $LAST_ACK_CNT{$socket_name} + 1;
    #print [LAST_ACK　CNT] " . $LAST_ACK_CNT{$socket_name} . "\n";
  }
  elsif ( $line =~ /TIME_WAIT/ ) {
    $TIME_WAIT_CNT{$socket_name} = $TIME_WAIT_CNT{$socket_name} + 1;
    #print "[TIME_WAIT CNT] " . $TIME_WAIT_CNT{$socket_name} . "\n";
  }
  elsif ( $line =~ /FIN_WAIT_1/ ) {
    $FIN_WAIT_1_CNT{$socket_name} = $FIN_WAIT_1_CNT{$socket_name} + 1;
    #print "[FIN_WAIT_1 CNT] " . $FIN_WAIT_1_CNT{$socket_name} . "\n";
  }
  elsif ( $line =~ /FIN_WAIT_2/ ) {
    $FIN_WAIT_2_CNT{$socket_name} = $FIN_WAIT_2_CNT{$socket_name} + 1;
    #print "[FIN_WAIT_2 CNT] " . $FIN_WAIT_2_CNT{$socket_name} . "\n";
  }
  elsif ( $line =~ /CLOSE_WAIT/ ) {
    $CLOSE_WAIT_CNT{$socket_name} = $CLOSE_WAIT_CNT{$socket_name} + 1;
    print "[CLOSE_WAIT CNT] " . $CLOSE_WAIT_CNT{$socket_name} . "\n";
  }
  elsif ( $line =~ /ESTABLISHED/ ) {
    $ESTABLISHED_CNT{$socket_name} = $ESTABLISHED_CNT{$socket_name} + 1;
    print "[ESTAB CNT] " . $ESTABLISHED_CNT{$socket_name} . "\n";
  }
=cut
}

sub print_counter () {
  foreach my $socket_name (keys %recorded_sockets) {
    my $report_line = "[" . $socket_name . "] " . &get_time_stamp . " ";
    $report_line = $report_line . $CLOSED_CNT{$socket_name}. " ";
    $report_line = $report_line . $LISTEN_CNT{$socket_name}. " ";
    $report_line = $report_line . $CLOSING_CNT{$socket_name}. " ";
    $report_line = $report_line . $SYN_SENT_CNT{$socket_name}. " ";
    $report_line = $report_line . $SYN_RCVD_CNT{$socket_name}. " ";
    $report_line = $report_line . $LAST_ACK_CNT{$socket_name}. " ";
    $report_line = $report_line . $TIME_WAIT_CNT{$socket_name}. " ";
    $report_line = $report_line . $FIN_WAIT_1_CNT{$socket_name}. " ";
    $report_line = $report_line . $FIN_WAIT_2_CNT{$socket_name}. " ";
    $report_line = $report_line . $CLOSE_WAIT_CNT{$socket_name}. " ";
    $report_line = $report_line . $ESTABLISHED_CNT{$socket_name}."\n";
    print $report_line;
  }
}

sub reset_counter () {
  foreach my $socket_name (keys %recorded_sockets) {
    $CLOSED_CNT{$socket_name} = 0;
    $LISTEN_CNT{$socket_name} = 0;
    $CLOSING_CNT{$socket_name} = 0;
    $SYN_SENT_CNT{$socket_name} = 0;
    $SYN_RCVD_CNT{$socket_name} = 0;
    $LAST_ACK_CNT{$socket_name} = 0;
    $TIME_WAIT_CNT{$socket_name} = 0;
    $FIN_WAIT_1_CNT{$socket_name} = 0;
    $FIN_WAIT_2_CNT{$socket_name} = 0;
    $ESTABLISHED_CNT{$socket_name} = 0;
    $CLOSE_WAIT_CNT{$socket_name} = 0;
  }
}
