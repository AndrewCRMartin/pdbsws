#########################################################################
# You NEED to alter these...
############################
# The SwissProt file
# SPROT_DATA      = /home/bsm/martin/pdbcec_new/test.sprot
SPROT_DATA      = /acrm/data/swissprot/full/uniprot_sprot.fasta
TREMBL_DATA     = /acrm/data/swissprot/full/uniprot_trembl.fasta
SPROT_TREMBL	= /acrm/data/tmp/sprottrembl.faa

sprottrembl : $(SPROT_TREMBL)


$(SPROT_TREMBL) : $(SPROT_DATA) $(TREMBL_DATA)
	cat $(SPROT_DATA) $(TREMBL_DATA) > $(SPROT_TREMBL)

