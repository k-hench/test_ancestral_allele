cat ancestral.bed | bgzip > ancestral.bed.gz
tabix ancestral.bed.gz 

cat dummy.vcf | \
	vcf-annotate -a ancestral.bed.gz \
	-d key=INFO,ID=AA,Number=1,Type=String,Description='Ancestral Allele' \
	-c CHROM,FROM,TO,INFO/AA | \
	sed 's/LG//g'  \
	> annotated.vcf

java -jar /software/jvarkit/dist/vcffilterjdk.jar \
	-f ./script.js annotated.vcf | \
	bgzip > ancestral.vcf.gz

cat dummy_phased.vcf | \
	vcf-annotate -a ancestral.bed.gz \
	-d key=INFO,ID=AA,Number=1,Type=String,Description='Ancestral Allele' \
	-c CHROM,FROM,TO,INFO/AA | \
	sed 's/LG//g'  \
	> annotated_phased.vcf

java -jar /software/jvarkit/dist/vcffilterjdk.jar \
	-f ./script.js annotated_phased.vcf | \
	bgzip > ancestral_phased.vcf.gz
