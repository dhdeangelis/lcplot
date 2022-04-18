# lcplot
lcplot – a program to plot light curves of variable stars

# About
lcplot is a command-line program that plots light curves of variable stars using data from the [American Association of Variable Star Observers (AAVSO)](https://www.aavso.org/).

lcplot is written in [Perl 5](https://github.com/Perl/perl5). Apart from the Perl executable, lcplot also needs the Perl modules [DateTime](https://metacpan.org/pod/DateTime), [Astro::Time](https://metacpan.org/pod/Astro::Time), and [LWP::Simple](https://metacpan.org/pod/LWP::Simple), and [gnuplot](http://www.gnuplot.info/) as plotting engine.

# USAGE
To plot visual estimates and V band observations for
a star during the last N days use:

`lcplot.pl STAR CONSTELLATION NDAYS`
 
To optionally highlight observations done by OBSERVER.

`lcplot.pl STAR CONSTELLATION NDAYS OBSERVER`

where OBSERVER is the AAVSO observer code

In both cases the result is a PNG file with the plot.

# EXAMPLE:

This will plot the last 200 days of observations for khi Cygni, without highlighting any observer:

`lcplot.pl khi Cyg 200`

It will produce a PNG image with name "Cyg-khi.png".
