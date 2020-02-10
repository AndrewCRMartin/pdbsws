#!/usr/bin/perl -s

use CGI;
use DBI;

$::dbname    = "pdbsws" if(!defined($::dbname));
$::dbhost    = $ACRMPerlVars::pghost if(!defined($::dbhost));

# Connect to the database

$::dbh  = DBI->connect("dbi:Pg:dbname=$::dbname;host=$::dbhost");
die "Could not connect to database: $DBI::errstr" if(!$::dbh);

$sql = "select p.pdb, p.chain from pdbsws p, pdbsws q where p.pdb = q.pdb and p.chain = q.chain and p.ac = q.ac and p.start = '?' and q.start != '?'";
$sth = $::dbh->prepare($sql);
$rv = $sth->execute;

while(@results = $sth->fetchrow_array)
{
    push @pdbs, $results[0];
    push @chains, $results[1];
}

for ($i=0; $i<@pdbs; $i++)
{
    print "INFO: deleting duplicate $pdbs[$i] chain '$chains[$i]'\n";
    $sql = "delete from pdbsws where pdb = '$pdbs[$i]' and chain = '$chains[$i]' and start = '?'";
    $::dbh->do($sql);
}

