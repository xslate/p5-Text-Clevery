#!perl -w

use strict;
use Test::More;

use Text::Clevy;
use Text::Clevy::Parser;

use Time::Piece ();
use POSIX ();
POSIX::setlocale(POSIX::LC_ALL(), 'C');
my $now;
BEGIN{
    $now = Time::Piece->strptime(
        '2010-7-18 23:12:34',
        '%Y-%m-%d %H:%M:%S'
    )->epoch;
    *CORE::GLOBAL::time = sub { $now }; # mock
}

my $tc = Text::Clevy->new(verbose => 2);

my @set = (
    [<<'T', <<'X'],
{html_select_date}
T
<select name="Date_Month">
<option value="01">January</option>
<option value="02">February</option>
<option value="03">March</option>
<option value="04">April</option>
<option value="05">May</option>
<option value="06">June</option>
<option value="07">July</option>
<option value="08">August</option>
<option value="09">September</option>
<option value="10">October</option>
<option value="11">November</option>
<option value="12">December</option>
</select>
<select name="Date_Day">
<option value="1">01</option>
<option value="2">02</option>
<option value="3">03</option>
<option value="4">04</option>
<option value="5">05</option>
<option value="6">06</option>
<option value="7">07</option>
<option value="8">08</option>
<option value="9">09</option>
<option value="10">10</option>
<option value="11">11</option>
<option value="12">12</option>
<option value="13">13</option>
<option value="14">14</option>
<option value="15">15</option>
<option value="16">16</option>
<option value="17">17</option>
<option value="18">18</option>
<option value="19">19</option>
<option value="20">20</option>
<option value="21">21</option>
<option value="22">22</option>
<option value="23">23</option>
<option value="24">24</option>
<option value="25">25</option>
<option value="26">26</option>
<option value="27">27</option>
<option value="28">28</option>
<option value="29">29</option>
<option value="30">30</option>
<option value="31">31</option>
</select>
<select name="Date_Year">
<option value="2010">2010</option>
</select>
X

    [<<'T', <<'X'],
{html_select_date start_year='-1' end_year='+2' display_days=false display_months=false}
T
<select name="Date_Year">
<option value="2009">2009</option>
<option value="2010">2010</option>
<option value="2011">2011</option>
<option value="2012">2012</option>
</select>
X

    [<<'T', <<'X'],
{html_select_date
    start_year='-1' end_year='+1'
    year_empty="please select an year"
    display_days=false
    display_months=false}
T
<select name="Date_Year">
<option value="">please select an year</option>
<option value="2009">2009</option>
<option value="2010">2010</option>
<option value="2011">2011</option>
</select>
X

);

for my $d(@set) {
    my($source, $expected, $msg) = @{$d};
    is eval { $tc->render_string($source) }, $expected, $msg
        or do { ($@ && diag $@); diag $source };
}

done_testing;
