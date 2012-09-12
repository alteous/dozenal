#!/usr/bin/perl
# +AMDG  This document was begun on 8 Sept 11E8, the feast
# of the Nativity of the Blessed Virgin Mary and the Comm.
# of St. Hadrian, Martyr, and it is humbly dedicated to them
# for their prayers, and to the Sacred Heart of Jesus for
# His mercy.

use strict;
use POSIX;
use Time::Piece;
use Date::Day;
use Date::Easter;
use Date::Pcalc qw(Add_Delta_Days
	Date_to_Days);
use Getopt::Std;
getopts('f:');
our($opt_f);

# define our exit codes

my $SUCCESS = 0;
my $BAD_INPUT_FILE = 1;
my $INPUT_FILE_NOT_EXIST = 2;

# define our mod functions; both take two arguments, x and
# y, and return an integer

sub mod($$)
{
	return $_[0] - $_[1] * ($_[0] / $_[1]);
}
sub amod($$)
{
	return $_[1] + mod($_[0],-$_[1]);
}

# get the julian date; takes year, month, day

sub julday($$$)
{
	return 1721423.5 + Date_to_Days($_[0],$_[1],$_[2]) + 1;
}

# convert julian date back to gregorian date; takes the
# julian day, returns an array of year, month, day

sub jultogreg($)
{
	return Add_Delta_Days(1,1,1,$_[0] - 1721423.5 - 2);
}

# define @calendar; this array eats the contents of our
# data file

my $calfile;
my @calendar;

# define @eventlist; this array takes the calendar data,
# converted into absolute dates

my @eventlist;

# takes a filehandle; returns no value; populates @calendar

sub popsched(*)
{
	my $i = 0;
	my $j = 0;
	my $k = 0;
	my @row = ();			# placeholder to feed into @calndar
	open($calfile,"<","$_[0]") || die $!;
	while (<$calfile>) {
		$k++;
		if ($_ !~ /(.*)\t(.*)\t(.*)\t(.*)/) {
			print STDERR "dozcal error:  malformation in data ";
			print STDERR "file $_[0] at line $k\n";
			exit $BAD_INPUT_FILE;
		}
		@row = ($_ =~ /(.*)\t(.*)\t(.*)\t(.*)/);
		push @{$calendar[$i]},@row;
		$i++;
	}
	close $calfile;
}

sub use_input_file()
{
	if ($opt_f) {
		if (!-e $opt_f) {
			print STDERR "dozcal error:  data file $opt_f ";
			print STDERR "does not exist\n";
			exit $INPUT_FILE_NOT_EXIST;
		} else {
			popsched($opt_f);
		}
	} else {
		popsched('sampdata');
	}
}

# takes the first and last days of a range and returns a
# list of all the dates between them, including them
# themselves

sub fill_range($$)
{
	my $firstmon = -1;		# first month in range
	my $lastmon = -1;			# second month in range
	my $firstyear = -1;		# first year in range
	my $lastyear = -1;		# last year in range
	my $firstday = -1;		# first day in range
	my $lastday = -1;			# last day in range
	my @range = ();			# range of dates to return

	my @months = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec Irv );
	for (my $i = 0; $i < 13; $i++) {
		$firstmon = $i if ($_[0] =~ /$months[$i]/);
		$lastmon = $i if ($_[1] =~ /$months[$i]/);
	}
	$firstmon = $lastmon if (($firstmon == -1) && ($lastmon > -1));
	$lastmon = $firstmon if (($firstmon > -1) && ($lastmon == -1));
	$firstyear = $1 if $_[0] =~ /([\dXE]{4,4})/;
	$lastyear = $1 if $_[1] =~ /([\dXE]{4,4})/;
	$firstyear = $lastyear if (($firstyear == -1) && ($lastyear > -1));
	$lastyear = $firstyear if (($firstyear > -1) && ($lastyear == -1));
	$firstday = $1 if $_[0] =~ /([\d\dXE]{1,2})/;
	$lastday = $1 if $_[1] =~ /([\d\dXE]{1,2})/;
	$firstday = qx(dec $firstday);
	$lastday = qx(dec $lastday);
	$firstyear = qx(dec $firstyear);
	$lastyear = qx(dec $lastyear);
	$firstmon++;
	$lastmon++;
	$firstday = julday($firstyear,$firstmon,$firstday);
	$lastday = julday($lastyear,$lastmon,$lastday);
	my $i = 0;
	$range[$i++] = $firstday++ while $firstday <= $lastday;
	return @range;
}

# before passing to the range and list functions (if
# applicable), parse the date and put it into a standard
# form (e.g., 4 Mar 11E8); accepts variety of dates in
# little-endian or big-endian formats, but not the strange
# American way; requires four-digit year; returns a string,
# or -1 if a valid date isn't found

sub parse_dates($)
{
	my $flag = 0;					# set to 1 if found valid date
	my $temp = $_[0];				# variable to deal with in calcs
	my $year;
	my $month;
	my $day;
	my $standate = -1;
	my @months = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec Irv );

	if ($temp =~ /([\dXE]{2,4})[-|\/]([\dXE]{1,2})[-\/]([\dXE]{1,2})/) {
		$flag = 1;
		($year,$month,$day) = ($1,$2,$3);
	} elsif ($temp =~ /(\w{3,9}).*([\dXE]{1,2}).*,.*([\dXE]{2,4})/) {
		$flag = 1;
		($year,$month,$day) = ($3,$1,$2);
	} elsif ($temp =~ /([\dXE]{1,2})[-|\/]([\dXE]{1,2})[-\/]([\dXE]{2,4})/) {
		$flag = 1;
		($year,$month,$day) = ($3,$1,$2);
	}
	if ($flag == 1) {
		$month = "Oct" if $month eq "X";
		$month = "Nov" if $month eq "E";
		$month = "Dec" if $month eq "10";
		if ($month =~ /[\dXE]+/) {
			$month--;
			$month = $months[$month];
		}
		$standate = $day." ".$month." ".$year;
	}
	return $standate;
}

# takes an individual date as scalar string, returns it as
# julian day

sub ind_date($)
{
	my $year;
	my $month;
	my $day;
	my @months = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec Irv );

	for (my $i = 0; $i < 13; $i++) {
		$month = $i if ($_[0] =~ /$months[$i]/);
	}
	$year = $1 if $_[0] =~ /([\dXE]{4,4})/;
	$day = $1 if $_[0] =~ /([\d\dXE]{1,2})/;
	$day = qx(dec $day);
	$year = qx(dec $year);
	$month++;
	return julday($year,$month,$day);
}

# takes a scalar (a date field from @calendar); parses it; 
# returns a list of dates which meet the requirements

sub get_dates($)
{
	my $first = "";	# first date of a range
	my $last = "";		# last date of a range
	my @range = ();	# the array of dates which match the field
	my $temp;			# placeholder so we don't clobber $_[0]

	$temp = $_[0];
	$temp =~ s/\s//g;
	while ($temp =~ /--/) {
		($first,$last)=($temp=~/[^\s\w\d]*([\/-\s\w\d]+)--([\/-\s\w\d]+)/);
		$temp =~ s/$first--$last//;
		$first = parse_dates($first) if parse_dates($first) != -1;
		$last = parse_dates($last) if parse_dates($last) != -1;
		push(@range,fill_range($first,$last));
	}
	while ($temp =~ /,/) {
		($first) = ($temp =~ /[^\s\w\d]*([\/-\s\w\d]+),/);
		$temp =~ s/$first,//;
		$first = parse_dates($first) if parse_dates($first) != -1;
		push(@range,ind_date($first));
	}
	push(@range,ind_date(parse_dates($temp))) if parse_dates($temp) != -1;
#	print @range; print "\n";
	return @range;
}

# after @calendar is populated, creates the date ranges with
# the events associated with them; takes no args, returns
# nothing

sub parse_input_file()
{
	my @range;
	my @exceptions;
	my @row;
	my @final_range;
	my $j = 0;

	for (my $i=0; $i <= $#calendar; ++$i) {
		@range = get_dates($calendar[$i][1]);
		@exceptions = get_dates($calendar[$i][2]);
		foreach my $var (@range) {
			@row = ($var,$calendar[$i][0],$calendar[$i][3]);
			push @{$eventlist[$j++]},@row if !grep(/$var/,@exceptions);
		}
	}
	for (my $i = 0; $i <= $#eventlist; $i++) {
		for ($j = 0; $j < 3; $j++) {
			print $eventlist[$i][$j]."\n";
		}
	}
}

# we all know what this one's for

sub main()
{
	use_input_file();
	parse_input_file();
}

main();
