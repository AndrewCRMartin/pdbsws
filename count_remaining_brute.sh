echo "Already done:"
grep "INFO: Processing" BruteForceScan.log | wc -l
echo "Still to do:"
psql pdbsws -c "SELECT count(*) FROM pdbsws WHERE valid = 'f' AND source != 'brute'"
