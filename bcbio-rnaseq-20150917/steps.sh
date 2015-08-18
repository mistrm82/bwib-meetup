# After bcbio installation if you clone the repository

git clone http://github.com/chapmanb/bcbio-nextgen

cd bcbio-nextgen/test

PATH_TEST=`pwd`

./run_tests.sh star

# Go to some folder
cd ~/test/rnaseq

# prepare bcbio fastq files
cp $PATH_TEST/data/110907_ERP000591/1_110907_ERP000591_*txt .

# prepare foldes and config files before run
bcbio_nextgen.py -w template template.yaml myproject.csv *fastq.txt

cd myproject/work

cp $PATH_TEST/test_automated_output/bcbio_system.yaml .

# run bcbio
bcbio_nextgen.py bcbio_system.yaml ../config/myproject.yaml
