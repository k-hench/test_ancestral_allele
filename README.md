# Setting the Ancestral Allele within a vcf file

We assume we do have two files for this:
- a `.vcf` file with the genotypes
- a `.bed` files that holds the ancestral allele for each locus within the vcf

We can the use a combination of `vcf-annotate` (supplementary script from [vcftools](https://vcftools.github.io/perl_module.html#vcf-annotate)) and `vcffilterjdk.jar` (part of [jvarkit](https://github.com/lindenb/jvarkit)) to recode the vcf in such a way that the ancestral allele is set as reference allele for each locus.

We also need a custom java script (`script.js`) that I have gathered from the depths of [biostars](https://www.biostars.org/p/266201/).

**Step 1: Indexing the `.bed` file**

The bed file is where the information about the ancestral state is stored (how we have gathered this inforation is irrelevant - in our hamlet example it was based of a hierarchical decision based on the allelic state of the outgroup and the major allele).

```sh
head -n 3 ancestral.bed
#> LG01	1	1	G
#> LG01	2	2	C
#> LG01	3	3	A
```

To be able to annotate the vcf based on this bed file, the bed file needs to be bgziped and indexed:

```sh
cat ancestral.bed | bgzip > ancestral.bed.gz
tabix ancestral.bed.gz 
```

**Step 2: annotation the vcf**

Considering the input vcf file,

```sh
cat dummy.vcf 
#> ##fileformat=VCFv4.0
#> ##source=vcfrandom
#> ##phasing=none
#> ##INFO=<ID=NS,Number=1,Type=Integer,Description="Number of samples with data">
#> ##INFO=<ID=AC,Number=1,Type=Integer,Description="Total number of alternate alleles in called genotypes">
#> ##INFO=<ID=DP,Number=1,Type=Integer,Description="Total read depth at the locus">
#> ##INFO=<ID=AN,Number=1,Type=Integer,Description="Total number of alleles in called genotypes">
#> ##INFO=<ID=AF,Number=1,Type=Float,Description="Estimated allele frequency in the range (0,1]">
#> ##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">
#> ##FORMAT=<ID=GQ,Number=1,Type=Integer,Description="Genotype Quality, the Phred-scaled marginal (or unconditional) probability of the called genotype">
#> ##FORMAT=<ID=DP,Number=1,Type=Integer,Description="Read Depth">
#> #CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	sample1	sample2
#> LG01	1	.	G	A	100	.	DP=9	GT	0/1	0/1
#> LG01	2	.	C	A	100	.	DP=41	GT	0/1	1/1
#> LG01	3	.	T	A	100	.	DP=50	GT	0/1	1/1
#> LG01	4	.	T	A	100	.	DP=18	GT	0/1	0/0
#> LG01	5	.	A	T	100	.	DP=50	GT	0/1	0/0
#> LG01	6	.	C	T	100	.	DP=57	GT	0/1	0/0
#> LG01	7	.	G	C	100	.	DP=59	GT	0/1	0/1
#> LG01	8	.	A	T	100	.	DP=62	GT	0/1	1/1
#> LG01	9	.	A	G	100	.	DP=41	GT	0/1	0/1
```

we can add the information about the ancestral allele as annotation using `vcf-annotate` and the bed file:

```sh
cat dummy.vcf | \
	vcf-annotate -a ancestral.bed.gz \
	-d key=INFO,ID=AA,Number=1,Type=String,Description='Ancestral Allele' \
	-c CHROM,FROM,TO,INFO/AA | \
	sed 's/LG//g'  \
	> annotated.vcf
```

Not how the information is added to the `INFO` column:

```sh
cat annotated.vcf |sed 's/^/#> /'
#> ##fileformat=VCFv4.0
#> ##source=vcfrandom
#> ##phasing=none
#> ##INFO=<ID=NS,Number=1,Type=Integer,Description="Number of samples with data">
#> ##INFO=<ID=AC,Number=1,Type=Integer,Description="Total number of alternate alleles in called genotypes">
#> ##INFO=<ID=DP,Number=1,Type=Integer,Description="Total read depth at the locus">
#> ##INFO=<ID=AN,Number=1,Type=Integer,Description="Total number of alleles in called genotypes">
#> ##INFO=<ID=AF,Number=1,Type=Float,Description="Estimated allele frequency in the range (0,1]">
#> ##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">
#> ##FORMAT=<ID=GQ,Number=1,Type=Integer,Description="Genotype Quality, the Phred-scaled marginal (or unconditional) probability of the called genotype">
#> ##FORMAT=<ID=DP,Number=1,Type=Integer,Description="Read Depth">
#> ##INFO=<ID=AA,Number=1,Type=String,Description="Ancestral Allele">
#> ##source_20210923.1=vcf-annotate(v0.1.14-12-gcdb80b8) -a ancestral.bed.gz -d key=INFO,ID=AA,Number=1,Type=String,Description=Ancestral Allele -c CHROM,FROM,TO,INFO/AA
#> #CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	sample1	sample2
#> 01	1	.	G	A	100	.	DP=9;AA=G	GT	0/1	0/1
#> 01	2	.	C	A	100	.	DP=41;AA=C	GT	0/1	1/1
#> 01	3	.	T	A	100	.	DP=50;AA=A	GT	0/1	1/1
#> 01	4	.	T	A	100	.	DP=18;AA=T	GT	0/1	0/0
#> 01	5	.	A	T	100	.	DP=50;AA=A	GT	0/1	0/0
#> 01	6	.	C	T	100	.	DP=57;AA=T	GT	0/1	0/0
#> 01	7	.	G	C	100	.	DP=59;AA=C	GT	0/1	0/1
#> 01	8	.	A	T	100	.	DP=62;AA=T	GT	0/1	1/1
#> 01	9	.	A	G	100	.	DP=41;AA=G	GT	0/1	0/1
```

**Step 3: re-coding the vcf**

Finally, with the help of `vcffilterjdk.jar` and our custom script, we can re-code the vcf:

```sh
java -jar /software/jvarkit/dist/vcffilterjdk.jar \
	-f ./script.js annotated.vcf | \
	bgzip > ancestral.vcf.gz
```

Note the changes in the columns `REF` and `ALT` as well as the switching of `1/0` to `0/1` for the postions 3,5,6,7,8 and 9.

```sh
zcat ancestral.vcf.gz |sed 's/^/#> /'
#> ##fileformat=VCFv4.2
#> ##FORMAT=<ID=DP,Number=1,Type=Integer,Description="Read Depth">
#> ##FORMAT=<ID=FT,Number=.,Type=String,Description="Genotype-level filter">
#> ##FORMAT=<ID=GQ,Number=1,Type=Integer,Description="Genotype Quality, the Phred-scaled marginal (or unconditional) probability of the called genotype">
#> ##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">
#> ##INFO=<ID=AA,Number=1,Type=String,Description="Ancestral Allele">
#> ##INFO=<ID=AC,Number=A,Type=Integer,Description="Allele count in genotypes, for each ALT allele, in the same order as listed">
#> ##INFO=<ID=AF,Number=A,Type=Float,Description="Allele Frequency, for each ALT allele, in the same order as listed">
#> ##INFO=<ID=AN,Number=1,Type=Integer,Description="Total number of alleles in called genotypes">
#> ##INFO=<ID=DP,Number=1,Type=Integer,Description="Total read depth at the locus">
#> ##INFO=<ID=NS,Number=1,Type=Integer,Description="Number of samples with data">
#> ##phasing=none
#> ##source=vcfrandom
#> ##source_20210923.1=vcf-annotate(v0.1.14-12-gcdb80b8) -a ancestral.bed.gz -d key=INFO,ID=AA,Number=1,Type=String,Description=Ancestral Allele -c CHROM,FROM,TO,INFO/AA
#> ##vcffilterjdk.meta=compilation:20200728171331 githash:af51aa30d htsjdk:2.22.0 date:20210923172112 cmd:-f ./script.js annotated.vcf
#> #CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	sample1	sample2
#> 01	1	.	G	A	100	.	AA=G;DP=9	GT	0/1	0/1
#> 01	2	.	C	A	100	.	AA=C;DP=41	GT	0/1	1/1
#> 01	3	.	A	T	100	.	AA=A;AC=1;DP=50	GT	1/0	0/0
#> 01	4	.	T	A	100	.	AA=T;DP=18	GT	0/1	0/0
#> 01	5	.	A	T	100	.	AA=A;DP=50	GT	0/1	0/0
#> 01	6	.	T	C	100	.	AA=T;AC=3;DP=57	GT	1/0	1/1
#> 01	7	.	C	G	100	.	AA=C;AC=2;DP=59	GT	1/0	1/0
#> 01	8	.	T	A	100	.	AA=T;AC=1;DP=62	GT	1/0	0/0
#> 01	9	.	G	A	100	.	AA=G;AC=2;DP=41	GT	1/0	1/0
```

## Same works for phased vcfs

This approach is agnostic to the phasing state of the vcf and should work generally in both cases.

```
cat dummy_phased.vcf | \
	vcf-annotate -a ancestral.bed.gz \
	-d key=INFO,ID=AA,Number=1,Type=String,Description='Ancestral Allele' \
	-c CHROM,FROM,TO,INFO/AA | \
	sed 's/LG//g'  \
	> annotated_phased.vcf
```
```
java -jar /software/jvarkit/dist/vcffilterjdk.jar \
	-f ./script.js annotated_phased.vcf | \
	bgzip > ancestral_phased.vcf.gz
```