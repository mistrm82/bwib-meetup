# bash commands that run a basic Qiime analysis
# need to install qiime first on your machine (http://qiime.org/)

# set up parameters
INPUT=input_sequences.fasta
OUTDIR=output_directory
MAPPING=mappingfile.txt

PARAMS=/absolute/path/to/parameters.txt # specify qiime parameters
REF=/absolute/path/to/reference_sequences.fasta
REF_ALIGNED=/absolute/path/to/reference_sequences_aligned.fasta
REF_GOLD=/absolute/path/to/gold_16s_db.fasta # https://gold.jgi.doe.gov/
NPROC=10 # number of processors to use, modify this to something that's appropriate for your machine

# 1) Pick closed reference OTUs (match against $REF)
#    --> success_1.fasta and failures_1.fasta
# 2) Subsample failures.fasta and cluster it de novo
#    Generate a *new ref database* using each cluster centroid as a new ref sequence
# 3) Pick closed reference OTUs against Step 2 de novo OTUs
#    Do closed reference OTU picking (failures_1.fasta against *new ref database*)
#    --> success_3.fasta and failures_3.fasta
# 4) Do de novo OTU clustering on failures_3.fasta
#    --> success_4.fasta and failures_4.fasta
# 5)      final_otu_map.txt: concatenate success_1.fasta, success_3.fasta, and success_4.fasta
#    final_otu_map_mc10.txt: remove OTUs that are too small (don't pass min_otu_size cutoff)
#               rep_set.fna: contains final set of representative sequences
# 6) Make a biom table using final_otu_map_mc10.txt 
#    -->   otu_table_mc10.biom
#    Add taxonomy information --> otu_table_mc_w_tax.biom
#    Use rep_set.fna to align the sequences and build the phylogenetic tree, which includes the de novo OTUs. 
#    Any sequences that fail to align are omitted from the OTU table and tree to produce: 
#    --> otu_table_mc_no_pynast_failures.biom 
#    --> rep_set.tre
pick_open_reference_otus.py -i $INPUT -o $OUTDIR -p $PARAMS -r $REF -aO $NPROC --min_otu_size 10

# generate an easy-to-read summary file of the OTU table
biom summarize-table -i ${OUTDIR}/otu_table_mc10_w_tax_no_pynast_failures.biom -o ${OUTDIR}/otu_table_mc10_w_tax_no_pynast_failures.summary

# filter chimeras by comparing to GOLD database (small, highly curated dataset)
usearch61 --uchime_ref ${OUTDIR}/rep_set.fna -db ${REF_GOLD} -uchimeout ${OUTDIR}/uchime.out -strand plus -threads $NPROC
 
# in-house script: format uchime output into something more readable 
python /home/qiime/qiime_software/usearch61_uchime_parser.py ${OUTDIR}/uchime.out > ${OUTDIR}/chimeras.txt

# remove chimera OTUs from the big OTU table 
filter_otus_from_otu_table.py -i ${OUTDIR}/otu_table_mc10_w_tax_no_pynast_failures.biom -o ${OUTDIR}/otu_table_chiFree.biom -e ${OUTDIR}/chimeras.txt

# generate a summary for the new OTU table that has no chimeras
biom summarize-table -i ${OUTDIR}/otu_table_chiFree.biom -o ${OUTDIR}/otu_table_chiFree.summary
 
# remove the chimera sequences from the set of representative sequences
filter_fasta.py -f ${OUTDIR}/rep_set.fna -o ${OUTDIR}/rep_set_chimeraFree.fna -s ${OUTDIR}/chimeras.txt -n

# align the cleaned up set of representative sequences
parallel_align_seqs_pynast.py -i ${OUTDIR}/rep_set_chimeraFree.fna -o ${OUTDIR}/pynast_align_chiFree -T --jobs_to_start $NPROC --template_fp $REF_ALIGNED

# Filter sequence alignment by removing highly variable regions
# Needed to generate a useful tree when aligning against a template alignment
# Removes positions which are gaps in every sequence
# The lanemask file defines which positions should be included when building the tree, and which should be ignored. 
# --> information about non-conserved positions (uninformative for tree building) and conserved positions (informative for tree building)
filter_alignment.py -o ${OUTDIR}/pynast_align_chiFree -i ${OUTDIR}/pynast_align_chiFree/rep_set_chimeraFree_aligned.fasta --suppress_lane_mask_filter
 
# generate phylogenetic tree in Newick format
make_phylogeny.py -i ${OUTDIR}/pynast_align_chiFree/rep_set_chimeraFree_aligned_pfiltered.fasta -o ${OUTDIR}/rep_set_chimeraFree.tre

# remove samples that have less than 5000 observations (sequences)
# produces a biom file
filter_samples_from_otu_table.py -i ${OUTDIR}/otu_table_chiFree.biom -o ${OUTDIR}/otu_table_chiFree.LowSamRm.biom -n 5000
 
# summarize this OTU table again
biom summarize-table -i ${OUTDIR}/otu_table_chiFree.LowSamRm.biom -o ${OUTDIR}/otu_table_chiFree.LowSamRm.summary
 
# calculate beta diversity
# run once using default values
# run once setting depth of coverage for even sampling to 8000 seqs/sample
beta_diversity_through_plots.py -i ${OUTDIR}/otu_table_chiFree.LowSamRm.biom -m ${MAPPING} -p ${PARAMS} -o ${OUTDIR}/betaDiv_default -aO $NPROC -t ${OUTDIR}/rep_set_chimeraFree.tre 
beta_diversity_through_plots.py -i ${OUTDIR}/otu_table_chiFree.LowSamRm.biom -m ${MAPPING} -p ${PARAMS} -o ${OUTDIR}/betaDiv8k -aO $NPROC -t ${OUTDIR}/rep_set_chimeraFree.tre -e 8000

# run with default values
# The upper limit of rarefaction depths is median sequence/sample count [default value]
alpha_rarefaction.py -i ${OUTDIR}/otu_table_chiFree.LowSamRm.biom -m ${MAPPING} -p ${PARAMS} -o ${OUTDIR}/Allsamples_alphaDiv_default -aO $NPROC -t ${OUTDIR}/rep_set_chimeraFree.tre

# rarefied to 8,000 seqs/sample
alpha_rarefaction.py -i ${OUTDIR}/otu_table_chiFree.LowSamRm.biom -m ${MAPPING} -p ${PARAMS} -o ${OUTDIR}/Allsamples_alphaDiv8k -aO $NPROC -t ${OUTDIR}/rep_set_chimeraFree.tre -e 8000
 
# plot all samples
summarize_taxa_through_plots.py -i ${OUTDIR}/otu_table_chiFree.LowSamRm.biom -m ${MAPPING} -p ${PARAMS} -o ${OUTDIR}/taxa_summary_SampleID -s

# group samples by PBT and SampleGroup columns (see mapping file for more info) 
summarize_taxa_through_plots.py -i ${OUTDIR}/otu_table_chiFree.LowSamRm.biom -m ${MAPPING} -p ${PARAMS} -o ${OUTDIR}/taxa_summary_PBT -s -c 'PBT'
summarize_taxa_through_plots.py -i ${OUTDIR}/otu_table_chiFree.LowSamRm.biom -m ${MAPPING} -p ${PARAMS} -o ${OUTDIR}/taxa_summary_SampleGroup -s -c 'SampleGroup'
summarize_taxa_through_plots.py -i ${OUTDIR}/otu_table_chiFree.LowSamRm.biom -m ${MAPPING} -p ${PARAMS} -o ${OUTDIR}/taxa_summary_NewID -s -c 'NewID'

# convert biom format into a matrix format --> can open easily in Excel
biom convert -i ${OUTDIR}/otu_table_chiFree.LowSamRm.biom -o ${OUTDIR}/otu_table_chiFree.LowSamRm.tabSeparated.txt -b --header-key taxonomy