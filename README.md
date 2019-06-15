# lcplot
LCplot – a program to plot light curves of variable stars

# About
LCplot is a perl program that plots light curves for variable stars using data from the American Association of Variable Star Observers (AAVSO, aavso.org).

LCplot is written in Perl and needs the Perl executable, the Perl modules DateTime, Astro::Time, and LWP::Simple, and gnuplot.

# USAGE
To plot visual estimates and V band observations for
a star during the last N days use:

perl LCplot.pl STAR CONSTELLATION NDAYS

 
To optionally highlight observations done by OBSERVER.

perl LCplot.pl STAR CONSTELLATION NDAYS OBSERVER

where OBSERVER is the AAVSO observer code

In both cases the result is a PNG file with the plot.
