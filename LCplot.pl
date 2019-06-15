#!/usr/local/bin/perl

# LCplot
# Plots light curves from AAVSO data (aavso.org)
# version 1.3
# 2019-06-15

# USAGE:
#
# To plot visual estimates and V band observations for
# a star during the last N days use:
#
# perl LCplot.pl STAR CONSTELLATION NDAYS
#
# 
# To optionally highlight observations done by OBSERVER.
#
# perl LCplot.pl STAR CONSTELLATION NDAYS OBSERVER
#
# where OBSERVER is the AAVSO observer code
# 
# The result is a PNG file with the plot.
# 
# 
# To plot visual estimates and V band observations for
# a star during between FIRSTDATE and LASTDATE use:
#
# perl LCplot.pl STAR CONSTELLATION FIRSTDATE LASTDATE OBSERVER
# where dates are expressed as ISO8601 dates, i.e. 2018-09-14
# 
#
# EXAMPLE:
# perl LCplot.pl khi Cyg 200 
# This will plot the last 200 days of observations for khi Cygni, without highlighting any observer
#
# This script is written in Perl and plots using gnuplot (gnuplot.info).
# It requires gnuplot, perl and some perl modules listed below.
# Tested in Linux. Should also work on other platforms.

# pragmas
use warnings;
use strict;

# modules
use DateTime qw(now jd);
use Astro::Time qw(mjd2cal);
use LWP::Simple qw(getstore);

# reads input from command line
my ($star, $const, $ndays, $observer) = @ARGV;
# my ($star, $const, $a, $b, $c) = @ARGV;

# sorts out dates, converts to julian date
my $today = DateTime->now;
my $jd = $today->jd();
my $lastdate = $jd - $ndays;

# ensembles request
my $request = qq(https://www.aavso.org/vsx/index.php?view=api.delim&ident="$star $const"&fromjd=$lastdate&tojd=$jd&delimiter=,);

# gets data from aavso.org and writes a file 
my @data = getstore($request, "rawdata.dat");

# opens temporary output files
open (OF1, ">", "visALL.dat");
open (OF2, ">", "Vband.dat");

# if OBSERVER was given, then open a file for observer
if (defined $observer) {
	open (OF3, ">", "visOBS.dat");
	}

# opens raw data file and parses data into different sets
open (RAW, "<", "rawdata.dat");
while (<RAW>) {
    next if $. == 1;
    chomp;
    s/"//g;
    my @values = split(',', $_);
    # identify and avoid discrepant values
    next if $values[12] eq "T";
    # identify and avoid fainter than
    next if $values[22] eq "T";
    my ($Xday, $Xmonth, $Xyear, $Xut) = mjd2cal($values[0] - 2400000.5); $Xut *= 24;
    
    # if observer was given, then prepare set, otherwise just separate visual and V band
    if (defined $observer) {
		if (defined $values[1] && $values[3] =~ m/Vis/ && $values[4] ne $observer) { 
			print OF1 "$Xyear-$Xmonth-$Xday $Xut \t $values[1] \n" 
			}
		if (defined $values[1] && defined $values[2] && $values[3] =~ m/V{1}/ && $values[3] !~ m/Vis/ ) { 
			print OF2 "$Xyear-$Xmonth-$Xday $Xut \t $values[1] \n" 
			}
		if (defined $values[1] && $values[3] =~ m/Vis/ && $values[4] eq $observer) { 
			print OF3 "$Xyear-$Xmonth-$Xday $Xut \t $values[1] \n" 
			}
		}
	elsif (!defined $observer) {
		if (defined $values[1] && $values[3] =~ m/Vis/ && $values[4]) {	
			print OF1 "$Xyear-$Xmonth-$Xday $Xut \t $values[1] \n" 
			}
		if (defined $values[1] && defined $values[2] && $values[3] =~ m/V{1}/ && $values[3] !~ m/Vis/ ) {
			print OF2 "$Xyear-$Xmonth-$Xday $Xut \t $values[1] \n" 
			}
		}
	}

close RAW; 
close OF1;
close OF2;
close OF3;

my $plotname = $const.'-'.$star;
my $title = $star.' '.$const;

# prepares gnuplot config file
my $gnuplotcf = <<EOF;
set terminal pngcairo enhanced size 960,640 font "Bitstream-Vera-Sans,9"
set output '$plotname.png'
set title '$title' font "Bitstream-Vera-Sans-Bold',18"
set bmargin 6
set rmargin 6
set lmargin 6
set label "Observations from the AAVSO International Database (www.aavso.org)" at screen 0.5, 0.07 center
set key outside bottom center horizontal
set grid
set yrange [] reverse
set xdata time
set timefmt "%Y-%m-%d %H"
set format x "%Y-%m"
set format y "%.1f"
plot 'visALL.dat' u 1:3 w points pt 7 ps 0.25 lc rgbcolor "black" title "visual obs", 'Vband.dat' u 1:3 w points pt 5 ps 0.5 lc rgbcolor "green" title "V band"
EOF

# adds optional line for OBSERVER
if (defined $observer) {
	chomp $gnuplotcf;
	$gnuplotcf .= qq(, 'visOBS.dat' u 1:3 w points pt 1 ps 3 lw 2 lc rgbcolor "blue" title "obs by $observer");
	}

# prints config file
open (GNUPLOTCF,">", "gnuplot.conf");
print GNUPLOTCF $gnuplotcf;
close GNUPLOTCF;

# executes gnuplot
system "gnuplot 'gnuplot.conf'";

# deletes temporary files
unlink "gnuplot.conf";
unlink glob "*.dat";
