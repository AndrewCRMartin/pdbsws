# Makefile for building the EC lookup table
# The final result file is in $(LOOKUP)/pdbcec.dat
#
# Alter the variables below as needed
# Then do:
#    gmake dirs (if needed to create subdirectories)
#    gmake >& gmake.out &

#########################################################################
# You NEED to alter these...
############################
# This is our parent working directory (generally where you have put
# this makefile)
DATATOP         = /home/andrew/pdbcec_2003
# The SwissProt file
SPROT_DATA      = /home/andrew/pdbcec_2003/sprot41_updated.dat
# The enzyme database
ENZDB           = /data/enzyme/enzyme.dat
# Where the PDB lives
PDBDIR          = /data/pdb

#########################################################################
# You can alter this if you want to...
######################################
# The PDB hash file used as a database - you might want to change the name
HASHNAME        = pdb250603

#########################################################################
# You shouldn't need to alter these...
######################################
# These are the directories used - probably only need to alter DATATOP
# above. Use "make dirs" to create these sub directories
DERIVED         = $(DATATOP)/derived
LOOKUP          = $(DATATOP)/lookup

#########################################################################
# Should NEVER need to alter below here...
##########################################
PDBHASH         = $(LOOKUP)/$(HASHNAME)
MYPROGS         = /home/andrew/pdbcec_src/mysrc

# Files derived from SwissProt
SPROT_PIR_SEQ   = $(DERIVED)/sprot_pir_seq
PDB_SPROT_CODES = $(LOOKUP)/pdb_sprot_codes
ACID            = $(LOOKUP)/acid
IDAC            = $(LOOKUP)/idac
ACAC            = $(LOOKUP)/acac

# Files derived from the PDB
PDB_PIR_SEQ     = $(DERIVED)/pdb_pir_seq

# Files used in linking EC numbers to SwissProt and PDB codes
SPROTEC         = $(LOOKUP)/sprotec.dat

# This is the final target file!
PDBCEC          = $(LOOKUP)/pdbcec.dat

#####
# include $(CATH_PARAM_FILE)
#####

# This is the basic 4 stages which must be done in sequence
# ---------------------------------------------------------

all : $(PDBCEC)

# Final target is the PDBc->EC table
$(PDBCEC) : Stage5.touch
	@echo 'Marking non-protein entries'
	$(MYPROGS)/MarkNonProteins.perl $(PDBCEC) $(PDB_PIR_SEQ) $(PDB_PIR_SEQ).pos > $(LOOKUP)/temp
	mv $(LOOKUP)/temp $(PDBCEC)

Stage5.touch : $(PDBHASH) $(SPROTEC)
	@echo 'Building PDBc->EC table'
	$(MYPROGS)/BuildPDBECList.perl $(PDBHASH) $(SPROTEC) > $(PDBCEC)
	touch Stage5.touch

$(PDBHASH) : $(SPROT_PIR_SEQ) $(PDB_PIR_SEQ) $(PDB_PIR_SEQ).pos $(IDAC) Stage3.touch
	$(MYPROGS)/BruteForceScan.perl $(PDBHASH) $(SPROT_PIR_SEQ) $(PDB_PIR_SEQ) $(PDB_PIR_SEQ).pos $(IDAC) > $(LOOKUP)/BruteForceScan.log
	$(MYPROGS)/DumpHash.perl $(PDBHASH) > $(LOOKUP)/Stage4.dump
	touch Stage4.touch
	touch $(PDBHASH)

Stage3.touch : $(PDB_SPROT_CODES) $(PDB_PIR_SEQ) $(PDB_PIR_SEQ).pos $(SPROT_PIR_SEQ) $(SPROT_PIR_SEQ).pos Stage2.touch
	$(MYPROGS)/CompareSPROTPDB.pl $(PDB_SPROT_CODES) $(PDB_PIR_SEQ) $(PDB_PIR_SEQ).pos $(SPROT_PIR_SEQ) $(SPROT_PIR_SEQ).pos $(PDBHASH) > $(LOOKUP)/CompareSPROTPDB.log
	$(MYPROGS)/DumpHash.perl $(PDBHASH) > $(LOOKUP)/Stage3.dump
	touch Stage3.touch

Stage2.touch : $(ACID) $(IDAC) $(ACAC) $(SPROT_PIR_SEQ) $(SPROT_PIR_SEQ).pos $(PDB_PIR_SEQ) $(PDB_PIR_SEQ).pos Stage1.touch
	$(MYPROGS)/CheckPDBData.perl $(PDBHASH) $(ACID) $(IDAC) $(ACAC) $(SPROT_PIR_SEQ) $(SPROT_PIR_SEQ).pos $(PDB_PIR_SEQ) $(PDB_PIR_SEQ).pos > $(LOOKUP)/CheckPDBData.log
	$(MYPROGS)/DumpHash.perl $(PDBHASH) > $(LOOKUP)/Stage2.dump
	touch Stage2.touch

Stage1.touch : $(PDBDIR)
	$(MYPROGS)/BuildPDBHash.perl $(PDBDIR) $(PDBHASH) > $(LOOKUP)/BuildPDBHash.log
	$(MYPROGS)/DumpHash.perl $(PDBHASH) > $(LOOKUP)/Stage1.dump
	touch Stage1.touch

# These are the support files which are needed by the 4 stages
# ------------------------------------------------------------
# Build PIR version of PDB
$(SPROT_PIR_SEQ) : $(SPROT_DATA)
	@echo 'Building PIR format version of SwissProt data'
	$(MYPROGS)/sprot_to_pir_seq.pl $(SPROT_DATA) > $(SPROT_PIR_SEQ)
# Build an ftell index for this file
$(SPROT_PIR_SEQ).pos : $(SPROT_PIR_SEQ)
	@echo 'Building ftell index for SwissProt-PIR'
	$(MYPROGS)/pir_seq_to_filepos.pl $(SPROT_PIR_SEQ) > $(SPROT_PIR_SEQ).pos

# Build list of SPROT codes for each PDB code from info in SPROT
$(PDB_SPROT_CODES) : $(SPROT_DATA)
	@echo 'Building list of SPROT codes for each PDB code from SwissProt data'
	$(MYPROGS)/pdb_to_sprot_codes.pl $(SPROT_DATA) > $(PDB_SPROT_CODES)

# Three hashes linking SwissProt ID and AC codes
$(IDAC) : $(SPROT_DATA)
$(ACAC) : $(SPROT_DATA)
$(ACID) : $(SPROT_DATA)
	@echo 'Building ACID hash'
	$(MYPROGS)/BuildSwissACIDHash.perl $(SPROT_DATA) $(ACID) $(IDAC) $(ACAC)
	touch $(ACID)
	touch $(IDAC)
	touch $(ACAC)

# Sequence data from PDB
$(PDB_PIR_SEQ) : $(PDBDIR)
	@echo 'Extracting PIR sequence data from PDB files'
	$(MYPROGS)/AllPDB2PIR.perl $(PDBDIR) $(PDB_PIR_SEQ)
# And the ftell index
$(PDB_PIR_SEQ).pos : $(PDB_PIR_SEQ)
	@echo 'Building ftell index on PDB sequence data'
	$(MYPROGS)/pir_seq_to_filepos.pl $(PDB_PIR_SEQ) > $(PDB_PIR_SEQ).pos

# Build the SPROT->EC list from the Enzyme database
$(SPROTEC) : EnzStage1.touch $(SPROT_DATA)
	@echo 'Updating EC numbers from SwissProt'
	$(MYPROGS)/UpdateECFromSprot.perl $(SPROTEC) $(SPROT_DATA) > $(LOOKUP)/temp
	mv $(LOOKUP)/temp $(SPROTEC)
	touch EnzStage2.touch
	touch $(SPROTEC)
EnzStage1.touch : $(ENZYME)
	@echo 'Building SPROT->EC table from Enzyme data'
	$(MYPROGS)/ECFromEnzyme.perl $(ENZDB) > $(SPROTEC)
	touch EnzStage1.touch




######
# Utilities
######
clean :
	\rm $(LOOKUP)/*.log

distclean :
	\rm -rf $(LOOKUP) $(DERIVED)

dirs :
	mkdir $(DERIVED)
	mkdir $(LOOKUP)


help :
	@echo ''
	@echo 'First you need to download the latest SwissProt and the new_seq.dat'
	@echo 'Append the new_seq.dat file onto the end of the SwissPort release'
	@echo '   cat new_seq.dat >>sprot36.dat'
	@echo 'Now download the enzyme database (enzyme.dat)'
	@echo ''
	@echo 'Edit this makefile to set variables'
	@echo 'Type: gmake dirs'
	@echo '   if required to make subdirectories'
	@echo 'Type: gmake >& gmake.out &'
	@echo '   to build the PDB->EC file'
	@echo 'Final result is in:'
	@echo '   $(LOOKUP)/pdbcec.dat'
	@echo '(actual location will depend on the variables you set)'
	@echo 'The PDB-SwissProt file is in:'
	@echo '   $(LOOKUP)/Stage4.dump'
	@echo '(actual location will depend on the variables you set)'
	@echo ''
	@echo 'gmake clean'
	@echo '   will remove log files'
	@echo 'gmake distclean'
	@echo '   will remove the derived and lookup subdirectories and contents'
	@echo 'gmake touch'
	@echo '   will stop the PDB->PIR stage rerunning if you are testing and'
	@echo '   the PDB has been updated since you last ran'
	@echo ''

touch :
	touch $(PDB_PIR_SEQ)

