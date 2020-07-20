# lcplot
LCplot – a program to plot light curves of variable stars

# About
LCplot is a Perl program that plots light curves for variable stars using data from the American Association of Variable Star Observers (AAVSO, aavso.org).

LCplot is written in Perl 5. It needs the Perl executable and the modules DateTime, Astro::Time, and LWP::Simple, and [gnuplot](http://www.gnuplot.info/) as plotting routine.

# USAGE
To plot visual estimates and V band observations for
a star during the last N days use:

perl LCplot.pl STAR CONSTELLATION NDAYS

 
To optionally highlight observations done by OBSERVER.

perl LCplot.pl STAR CONSTELLATION NDAYS OBSERVER

where OBSERVER is the AAVSO observer code

In both cases the result is a PNG file with the plot.

# EXAMPLE:

This will plot the last 200 days of observations for khi Cygni, without highlighting any observer:

perl LCplot.pl khi Cyg 200 

It will produce a PNG image with name "Cyg-khi.png".
