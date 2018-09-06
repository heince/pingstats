#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: pingstats.pl
#
#        USAGE: ./pingstats.pl [start time] [end time] [ping log file]
#               time format: yy/mm/dd hh:mm:ss
#  DESCRIPTION: 
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Heince Kurniawan
#       EMAIL : heince.kurniawan@itgroupinc.asia
# ORGANIZATION: IT Group Indonesia
#      VERSION: 1.0
#      CREATED: 08/10/18 14:04:02
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use List::Util qw/sum max/;

my $stime = $ARGV[0] or &usage();
my $etime = $ARGV[1] or &usage();
my $file  = $ARGV[2] or &usage();

#-------------------------------------------------------------------------------
#  pre run check
#-------------------------------------------------------------------------------
die "linux only\n" unless $^O eq 'linux';

#-------------------------------------------------------------------------------
# validate input  
#-------------------------------------------------------------------------------
die "stime not valid\n" unless validate_time($stime);
die "etime not valid\n" unless validate_time($etime);
die "etime must be greater than stime\n" unless convert_date_time($etime) > convert_date_time($stime);
die "file is empty\n" unless -s $file;

my $record = 0;
my @time;
my @rtt;

open my $fh, '<', $file or die "$!\n";

while (<$fh>)
{
    chomp;
    my $ds = parse_line($_);

    next unless is_time_in_range($ds->{datetime});
    next unless is_ok($ds->{host_status});

    push @time, $ds->{datetime};
    push @rtt,  get_rtt($ds->{stats});

    $record++;
}

close $fh;

&generate_result();

sub generate_result()
{
    print "Total Record: $record\n";
    print "Ping OK: "       . get_ok_record() . "\n";
    print "Average Ping: "  . get_avg_rtt() . " ms\n";
    print "Max Ping: "      . get_max_rtt() . " ms\n";
}

sub get_max_rtt
{
    return max @rtt;
}

sub get_avg_rtt
{
    return 0 unless get_total_rtt();

    my $avg = get_total_rtt() / get_ok_record();
    return sprintf("%.3f", $avg);
}

sub get_total_rtt
{
    if (@rtt)
    {
        return sum @rtt;
    }
    else
    {
        return 0;
    }
}

sub get_ok_record
{
    return $record - get_not_ok_record();
}

sub get_not_ok_record
{
    if ($record > 0)
    {
        if (@time)
        {
            return $record - ($#time +1);
        }
        else
        {
            return $record;
        }
    }
    else
    {
        die "no record found\n";
    }
}

sub get_rtt
{
    my $stat = shift;

    if ($stat =~ /time=(.*) ms$/)
    {
        return $1;
    }
    else
    {
        die "rtt not found on $stat : $!\n";
    }
}

sub is_ok
{
    my $status = shift;

    if ($status =~ /is ok $/)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

sub is_time_in_range
{
    my $time = shift;

    my $dt  = convert_date_time($time);

    if ($dt >= convert_date_time($stime) and $dt <= convert_date_time($etime))
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

#-------------------------------------------------------------------------------
#  return scalar data structure for a line
#-------------------------------------------------------------------------------
sub parse_line
{
    my $line = shift;

    my @result  = split '-' => $line;
    my $ds  =   { 
                    datetime    => $result[0], 
                    host_status => $result[1], 
                    stats       => $result[2] 
                };

    return $ds;
}

#-------------------------------------------------------------------------------
#  process line if time equal or between stime and etime
#-------------------------------------------------------------------------------
sub process_line
{
    my $line = shift;
}

sub convert_date_time
{
    my $date = shift;

    my $cmd     = date_cmd($date);
    my $result  = `$cmd`;
    chomp $result;

    return $result;
}

sub date_cmd
{
    my $date = shift;

    my $cmd  = qq|date -d '$date' +\%s|;
    return $cmd;
}

sub validate_time
{
    my $date = shift;
    
    my $cmd  = date_cmd($date); 
    `$cmd`;

    return 1 if $? == 0;
    return 0;
}

sub usage()
{
    print "Usage: $0 [stime] [etime] [ping log file]\n";   
    print "Time format: yy/mm/dd hh:mm:ss\n";
    exit 1;
}



