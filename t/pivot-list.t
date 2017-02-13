#!perl -w
use strict;
use Test::More tests => 1;
use DBIx::PivotQuery 'pivot_list';
use Text::Table;

my @list = (
    { date => 'Q1', region => 'North', amount => 150 },
    { date => 'Q2', region => 'North', amount => 50 },
    { date => 'Q3', region => 'North', amount => 50 },
    { date => 'Q4', region => 'North', amount => 10 },

    { date => 'Q1', region => 'West',  amount => 100 },
    { date => 'Q3', region => 'West',  amount => 100 },
    { date => 'Q4', region => 'West',  amount => 200 },

    { date => 'Q1', region => 'East',  amount => 75 },
    { date => 'Q2', region => 'East',  amount => 75 },
    { date => 'Q3', region => 'East',  amount => 75 },
    { date => 'Q4', region => 'East',  amount => 175 },


    { date => 'Q1', region => 'South', amount => 125 },
    { date => 'Q2', region => 'South', amount => 125 },
    { date => 'Q3', region => 'South', amount => 0 },
    { date => 'Q4', region => 'South', amount => 20 },
);

use Data::Dumper;
my $l = pivot_list(
    rows    => ['region'],
    columns => ['date'],
    aggregate => ['amount'],
    list => \@list,
);
warn Dumper $l;

use Text::Table;
my $t = Text::Table->new( @{ shift @$l });
$t->load(@$l);
diag "$t";