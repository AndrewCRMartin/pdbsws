echo "Number matched through brute force scan:"
psql -c "select count(*) from pdbsws where ac != 'DNA' and valid = 't' and source = 'brute' and ac != 'SHORT'" pdbsws

echo "Number of these for which a cross-reference was in SProt"
echo "but were ignored as they weren't the best match"
psql pdbsws < count_brute_where_have_sprot.sql

