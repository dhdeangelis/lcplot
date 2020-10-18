#!/usr/local/bin/perl

# LCplot
# Plots light curves from AAVSO data (aavso.org)
# version 1.4
# 2020-07-20

# USAGE:
#
# To plot visual estimates and V band observations for
# a star during the last N days use:
#
# perl lcplot.pl STAR CONSTELLATION NDAYS
#
# 
# To optionally highlight observations done by OBSERVER.
#
# perl lcplot.pl STAR CONSTELLATION NDAYS OBSERVER
#
# where OBSERVER is the AAVSO observer code
# 
# The result is a PNG file with the plot.
# 
# EXAMPLE:
# perl lcplot.pl khi Cyg 200 
# This will plot the last 200 days of observations for khi Cygni, without highlighting any observer
#
# This script is written in Perl and plots using gnuplot (gnuplot.info).
# It requires gnuplot, perl and some perl modules listed below.
# Tested in Linux. Should also work on other platforms.

# pragmas
use warnings;
use strict;

# modules
use DateTime qw (now jd);
use Astro::Time qw(mjd2cal);
use LWP::Simple qw(getstore);

# reads input from command line
my ($star, $const, $ndays, $observer) = @ARGV;

# sorts out dates, converts to julian date
my $today = DateTime->now;
my $jd = $today->jd();
my $lastdate = $jd - $ndays;

# ensembles request
my $request = qq(https://www.aavso.org/vsx/index.php?view=api.delim&ident="$star $const"&fromjd=$lastdate&tojd=$jd&delimiter=,);

# gets data from aavso.org and writes a file 
my @data = getstore($request, "rawdata.fooz");

# opens temporary output files
open (OF1, '>', 'visALL.fooz');
open (OF2, '>', 'Vband.fooz');

# if OBSERVER was given, then open a file for observer
if (defined $observer) {
	open (OF3, '>', 'visOBS.fooz');
	}
	
# opens raw data file and parses data into different sets
open (RAW, "<", "rawdata.fooz");
while (<RAW>) {
    next if $. == 1;
    chomp;
    s/"//g;
    my @values = split(',', $_);
    # identify and avoid discrepant values
    next if $values[12] eq "T";
    # identify and avoid fainter than
    next if $values[22] eq "T";
    # identify and avoid fainter than
    next if $values[22] =~ m/1/gx;
    
# 	# ta bort detta efter artikeln!
# 	next if ($values[4] eq 'VFK');
    
    my ($Xday, $Xmonth, $Xyear, $Xut) = mjd2cal($values[0] - 2400000.5); $Xut *= 24;
    
    # if observer was given, then prepare set, otherwise just separate visual and V band
    if (defined $observer) {
		if (defined $values[1] && $values[3] =~ m/Vis/ && $values[4] ne $observer) { 
			print OF1 "$Xyear-$Xmonth-$Xday $Xut \t $values[1] \n";
			}
		if (defined $values[1] && defined $values[2] && $values[3] =~ m/V{1}/ && $values[3] !~ m/Vis/ ) { 
			print OF2 "$Xyear-$Xmonth-$Xday $Xut \t $values[1] \n";
			}
		if (defined $values[1] && $values[3] =~ m/Vis/ && $values[4] eq $observer) {
			print OF3 "$Xyear-$Xmonth-$Xday $Xut \t $values[1] \n";
			}
		}
	elsif (!defined $observer) {
		if (defined $values[1] && $values[3] =~ m/Vis/) {
# 			# ta bort detta efter artikeln!
# 			next if ($star eq 'T' && $const eq 'Tau' && $values[1] < 8.7);
			print OF1 "$Xyear-$Xmonth-$Xday $Xut \t $values[1] \n";
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

# converts a DateTime object to calendar
# extend last day by one day, to be sure include last observations made today
$today = $today->add( days => 1 );
my $yrlast = $today->year();
my $molast = $today->month();
my $dylast = $today->day();

# converts the AstroTime object to calendar
my ($Iday, $Imonth, $Iyear, $Iut) = mjd2cal($lastdate - 2400000.5);

# chooses format for x axis based on period length
my $formatx;
my $xtics;

if ($ndays <= 300) {
	$formatx = qw("%Y-%m-%d");
	$xtics = $ndays*86400/8;
	}
elsif ($ndays > 300 && $ndays < 2000 ) {
	$formatx = qw("%Y-%m");
# 	$xtics = $ndays*86400/8;
	$xtics = qw(autofreq);
	}
else {
	$formatx = qw("%Y");
	$xtics = qw(autofreq);
	}


# prepares gnuplot config file
my $gnuplotcf = <<EOF;
set terminal pngcairo enhanced size 960,640 font "Bitstream-Vera-Sans,9"
set output '$plotname.png'
set title '$title' font "Bitstream-Vera-Sans-Bold',18"
set bmargin 6
set rmargin 6
set lmargin 6
# set label "Observations from the AAVSO International Database (www.aavso.org)" at screen 0.5, 0.07 center
set label "Observationer från AAVSO International Database (www.aavso.org)" at screen 0.5, 0.07 center
set key outside bottom center horizontal
set grid
set yrange [] reverse
set xdata time
set timefmt "%Y-%m-%d %H"
set format x $formatx
set xtics $xtics
set xrange ['$Iyear-$Imonth-$Iday':'$yrlast-$molast-$dylast']
set format y "%.1f"
plot 'visALL.fooz' u 1:3 w points pt 7 ps 0.25 lc rgbcolor "black" title "visual obs", 'Vband.fooz' u 1:3 w points pt 5 ps 0.5 lc rgbcolor "green" title "V band"
EOF

# adds optional line for OBSERVER
if (defined $observer) {
	chomp $gnuplotcf;
	$gnuplotcf .= qq(, 'visOBS.fooz' u 1:3 w points pt 1 ps 3 lw 2 lc rgbcolor "blue" title "obs by $observer");
	}

# prints config file
open (GNUPLOTCF,">", "gnuplot.conf");
print GNUPLOTCF $gnuplotcf;
close GNUPLOTCF;

# executes gnuplot
system "gnuplot 'gnuplot.conf'";

# deletes temporary files
unlink "gnuplot.conf";
unlink glob "*.fooz";
