package DBIx::PivotQuery;
use strict;
use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';

use Exporter 'import';
use Carp 'croak';
use vars '$VERSION';
$VERSION = '0.01';

use vars qw(@EXPORT_OK);
@EXPORT_OK = qw(pivot_by pivot_list pivot_sql);

=head1 NAME

DBIx::PivotQuery - create pivot tables from queries

=head1 SYNOPSIS

  use DBIx::PivotQuery 'pivot_by';
  my $rows = pivot_by(
      dbh => $dbh,
      columns   => ['report_year'],
      rows      => ['region'],
      aggregate => ['sum(amount) as amount'],
      sql => <<'SQL');
    select
        month(date) as report_month
      , region
      , amount
    from mytable
  SQL
  
=cut

sub pivot_sql( %options ) {
    my @columns = (@{ $options{ columns } || [] }, @{ $options{ rows } || [] });
    my $qcolumns = join "\n  ,  ", @columns, @{ $options{ aggregate }};
    my $keycolumns = join "\n  ,  ", @columns;
    my $clauses = '';
    if($keycolumns) {
    $clauses = qq{
        group by $keycolumns
        order by $keycolumns
    };
    };
    
    return qq{
    select
        $qcolumns
    from
    (
        $options{sql}
    )
    $clauses
    }
}

# Takes an AoA and derives the total order from it if possible
# Returns the total order of the keys. Not every key is expected to be available
# in every row
sub partial_order( $comparator, $keygen, @list ) {
    my %sort;
    my %keys;

    for my $row (@list) {
        my $last_key;
        for my $col (@$row) {
        # This approach doesn't have the transitive property
        # We need to place items in arrays resp. on a float lattice
        # $sort{ $item } = (max( $sort_after($item ) - min( $sort_before($item)) / 2
            my $key = $keygen->( $col );
            $keys{ $key } = 1;
            if( defined $last_key ) {
                for my $cmp (["$last_key\0$key",-1],
                             ["$key\0$last_key",1],
                            ) {
                    my ($k,$v) = @$cmp;
                    $sort{$k} = $v;
                }
            } else {
                $last_key = $key;
            };
        }
    }
    
    sort { $sort{ $a } <=> $sort{$b} } keys %keys;
}

# Pivots an AoH (or AoA?!)
# The list must already be sorted by @rows, @columns
# At least one line must contain all column values (!)
sub pivot_list( %options ) {
    use Data::Dumper;
    my @rows;
    my %colnum;
    my %rownum;
    
    my @key_cols   = @{ $options{ columns }   || [] };
    my @key_rows   = @{ $options{ rows }      || [] };
    my @aggregates = @{ $options{ aggregate } || [] };
    my @colhead;
    
    # Now we need to determine the numbers for all the columns
    if( $options{ sort_columns } ) { 
        # If we have a user-supplied sorting function, use that:
        @colnum{ sort( sub { $options{ sort_columns }->($a,$b) }, keys %colnum )}
            = (@key_rows)..((@key_rows)+(keys %colnum)-1);
        for( keys %colnum ) {
            $colhead[ $colnum{ $_ }] = $_;
        };
    } else {
        # We assume that the first row contains all columns in order.
        # Following lines may skip values or have additional columns which
        # will be appended. This could be smarter by introducing a partial
        # order in the hope that everything will work out in the end.
        my $col = @key_rows;
        for my $cell (@{ $options{ list }}) {
            my $colkey = join $;, @{ $cell }{ @key_cols };
            if( ! exists $colnum{ $colkey }) {
                $colnum{ $colkey } ||= $col++;
                push @colhead, $colkey;
            };
        };
    }
    
    if( ! @colhead) {
        @colhead = 'dummy';
    };

    my $last_row;
    my @row;
    for my $cell (@{ $options{ list }}) {
        my $colkey = join $;, @{ $cell }{ @key_cols };
        my $rowkey = join $;, @{ $cell }{ @key_rows };
        
        if( defined $last_row and $rowkey ne $last_row ) {
            push @rows, [splice @row, 0];
        };
        
        # We should have %row instead, but how to name the
        # columns and rows that are values now?!
        # prefix "pivot_" ?
        # Allow the user to supply names?
        # Expect the user to rename the keys?
        if( ! @row ) {
            @row = @{ $cell }{ @key_rows };
        };
        
        my %cellv = %$cell;
        @cellv{ @aggregates } = @{$cell}{@aggregates};
        #$row[ $colnum{ $colkey }] = \%cellv;
        $row[ $colnum{ $colkey }] = $cell->{ $aggregates[0] };
        $last_row = $rowkey;
    };
    if(@row) {
        push @rows, \@row;
    };
    
    unshift @rows, [ @key_rows, @colhead ];
    
    \@rows
}

# This should maybe return a duck-type statement handle so that people
# can fetch row-by-row to their hearts content
# row-by-row still means we need to know all values for the column key :-/
sub pivot_by( %options ) {
    croak unless $options{sql};
    croak unless $options{dbh};
    
}

1;