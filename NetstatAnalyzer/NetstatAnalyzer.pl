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
#use Getopt::Long qw(:config posix_default no_ignore_case gnu_compat);
use Time::Local;
use YAML::Tiny;
use Data::Dumper;

#---+---1----+----2----+----3----+----4----+----5----+----6----+
# YAML属性名 (定数)
use constant NETSTAT_CMD => "NETSTAT_CMD";
#use constant LOGROOT_DIR => "LOGROOT_DIR";
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
my $times;
my $config_file = "target.yaml";
my $stop_trigger = 1;

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
#  -s ： sleep時間 [秒]
#  -c : YAML設定ファイルの場所
#  -t : 計測回数
my %opts;
getopts ('t:s:c:' => \%opts);
if ( defined $opts{'s'} ) {
  $sleep_time = $opts{'s'};
}
if ( defined $opts{'c'} ) {
  $config_file = $opts{'c'};
}
if ( defined $opts{'t'} ) {
  $times = $opts{'t'};
  $stop_trigger = 1;
} else {
  $times = 0;
  $stop_trigger = 0;
}
print Dumper(%opts);

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
# レポート・ヘッダーを出力
print "ScktName" . " " . "DATE" . " " . "TIME" . " ";
foreach my $s_status (keys %s_status_cnt_hash) {
  print $s_status . " ";
}
print "\n";

#---+---1----+----2----+----3----+----4----+----5----+----6----+
# ソケット数カウント部
while ( $stop_trigger <= $times ) {
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
  if ( $stop_trigger == 1 ) {
    $times = $times - 1;
  }
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
      #print "[$socket_name / $s_status] " . $s_status_cnt_hash{$s_status} -> {$socket_name} . "\n";
    }
  }
}

sub print_counter () {
  foreach my $socket_name (keys %recorded_sockets) {
    my $report_line = "[" . $socket_name . "] " . &get_time_stamp . " ";
    foreach my $s_status (keys %s_status_cnt_hash) {
      $report_line = $report_line . $s_status_cnt_hash{$s_status} -> {$socket_name} . " ";
    }
    print $report_line . "\n";
  }
}

sub reset_counter () {
  foreach my $socket_name (keys %recorded_sockets) {
    foreach my $s_status (keys %s_status_cnt_hash) {
      $s_status_cnt_hash{$s_status} -> {$socket_name} = 0;
    }
  }
}
