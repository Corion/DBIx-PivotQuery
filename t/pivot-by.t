#!perl -w
use strict;
use Test::More tests => 7;
use DBIx::PivotQuery 'pivot_by';
use DBIx::RunSQL;
use DBD::SQLite;

my $sql = join "", <DATA>;

my $test_dbh = DBIx::RunSQL->create(
    dsn     => 'dbi:SQLite:dbname=:memory:',
    sql     => \$sql,
);

my $l = pivot_by(
    dbh     => $test_dbh,
    rows    => ['region'],
    columns => ['date'],
    aggregate => ['sum(amount) as amount'],
    placeholder_values => [],
    sql => <<'SQL',
  select
      region
    , "date"
    , amount
    , customer
  from mytable
SQL
);

is_deeply $l->[0],
          [qw(region Q1 Q2 Q3 Q4)], "We find all values for the 'date' column and use them as column headers";

is_deeply [map { $_->[0]} @$l],
          [qw(region East North South West)], "We find all values for the 'region' column and use them as row headers";

is $l->[4]->[1], 100, "Available values get preserved";
is $l->[4]->[2], undef, "Missing values get preserved";
is $l->[4]->[3], 100, "Available values get preserved";

# Swap rows and columns
$l = pivot_by(
    dbh     => $test_dbh,
    columns => ['region'],
    rows    => ['date'],
    aggregate => ['sum(amount) as amount'],
    placeholder_values => [],
    sql => <<'SQL',
  select
      region
    , "date"
    , amount
    , customer
  from mytable
SQL
);

is_deeply [map { $_->[0]} @$l],
          [qw(date Q1 Q2 Q3 Q4)], "We find all values for the 'date' column and use them as row headers";

is_deeply $l->[0],
          [qw(date East North South West)], "We find all values for the 'region' column and use them as column headers";

__DATA__

create table mytable (
    region varchar(10) not null
  , "date" varchar(2) not null
  , amount decimal(18,2) not null
  , customer integer
);
insert into mytable ("date",region,amount,customer) values ('Q1','North',150,1);
insert into mytable ("date",region,amount,customer) values ('Q2','North',50 ,1);
insert into mytable ("date",region,amount,customer) values ('Q3','North',50 ,1);
insert into mytable ("date",region,amount,customer) values ('Q4','North',10 ,1);
insert into mytable ("date",region,amount,customer) values ('Q1','West', 100,1);
insert into mytable ("date",region,amount,customer) values ('Q3','West', 100,1);
insert into mytable ("date",region,amount,customer) values ('Q4','West', 200,1);
insert into mytable ("date",region,amount,customer) values ('Q1','East', 75 ,1);
insert into mytable ("date",region,amount,customer) values ('Q2','East', 75 ,1);
insert into mytable ("date",region,amount,customer) values ('Q3','East', 75 ,1);
insert into mytable ("date",region,amount,customer) values ('Q4','East', 175,1);
insert into mytable ("date",region,amount,customer) values ('Q1','South',125,1);
insert into mytable ("date",region,amount,customer) values ('Q2','South',125,1);
insert into mytable ("date",region,amount,customer) values ('Q3','South',0  ,1);
insert into mytable ("date",region,amount,customer) values ('Q4','South',20 ,1);

insert into mytable ("date",region,amount,customer) values ('Q1','South',125,2);
insert into mytable ("date",region,amount,customer) values ('Q2','South',125,2);
insert into mytable ("date",region,amount,customer) values ('Q3','South',0  ,2);
insert into mytable ("date",region,amount,customer) values ('Q4','South',20 ,2);
