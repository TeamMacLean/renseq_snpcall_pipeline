ENV["R1"] ? @read1 = ENV["R1"] : nil
#@read1 ? @R1_dir=ENV["R1"].pathmap("%d") : nil
#@read1 ? @R1_basename=ENV["R1"].pathmap("%n") : nil
@read1 ? @R1_basename  = "#{@read1}".split(".")[0].split("/")[-1] : nil
@R1R1_basename? @sampleid = "#{@R1_basename}".split("_L1_")[0].split("/")[-1] : nil
#@read1 ? @R1_basename  = File.basename("#{read1}", ".fq.gz") : nil
ENV["R2"] ? @read2 = ENV["R2"] : nil
#@read2 ? @R2_dir=ENV["R2"].pathmap("%d") :nil
#@read2 ? @R2_basename=ENV["R2"].pathmap("%n") : nil
@read2 ? @R2_basename = "#{@read2}".split(".")[0].split("/")[-1] : nil
#ENV["samplename"] ? @sample=ENV["samplename"] : nil
ENV["sample"] ? @sample=ENV["sample"] : nil
ENV["reference"] ? @reference=ENV["reference"] : nil
ENV["projectdir"] ? @projectdir=ENV["projectdir"] : nil


#check if reference sequence
if !@reference
  puts "Reference sequence not provided. Please supply reference using reference= in the command"
  exit
end

'''
if !@read1
  puts "R1 Fastq not provided. Please supply read1 using R1= in the command"
  exit
end
if !@read2
  puts "R2 Fastq not provided. Please supply read2 using R2= in the command"
  exit
end
'''
if !@sample
  puts "Sample name not provided. Please supply sample name using sample= in the command"
  exit
end


directory  "results"

namespace :fastqc  do
  desc "Do fastqc quality check of the input data reads"
  directory  "results/#{@sample}"
  desc "do fastqc for R1"

  file "results/#{@sample}/#{@R1_basename}_fastqc.html" => [ "results/#{@sample}", "#{@read1}"] do
    sh "source fastqc-0.11.5; fastqc -outdir results/#{@sample} -extract #{@read1}"
  end
  file "results/#{@sample}/#{@R1_basename}_fastqc.zip" => [ "results/#{@sample}", "#{@read1}"] do
  end
  file "results/#{@sample}/#{@R1_basename}_fastqc" => [ "results/#{@sample}", "#{@read1}"] do
  end

  task :R1 => ["results/#{@sample}/#{@R1_basename}_fastqc.html", "results/#{@sample}/#{@R1_basename}_fastqc.zip", "results/#{@sample}/#{@R1_basename}_fastqc"] do
    puts "R1 FASTQC completed"
  end

  desc "do fastqc for R2"
  file "results/#{@sample}/#{@R2_basename}_fastqc.html" => [ "results/#{@sample}", "#{@read2}"] do
    sh "source fastqc-0.11.5;fastqc -outdir results/#{@sample} -extract #{@read2}"
  end
  file "results/#{@sample}/#{@R2_basename}_fastqc.zip" => [ "results/#{@sample}", "#{@read2}"] do
  end
  file "results/#{@sample}/#{@R2_basename}_fastqc" => [ "results/#{@sample}", "#{@read2}"] do
  end

  task :R2 => ["results/#{@sample}/#{@R2_basename}_fastqc.html", "results/#{@sample}/#{@R2_basename}_fastqc.zip", "results/#{@sample}/#{@R2_basename}_fastqc"] do
    puts "R2 FASTQC completed"
  end
  task :runR1 => ["R1"] #these tasks are in case if you are running single end reads
  task :runR2 => ["R2"]

  multitask :run => [:runR1, :runR2] do
    puts "FASTQC completed"
  end


end

namespace :trimmomatic do
  desc "Runs Trimmomatic quality trimming tool"

  file "results/#{@sample}/#{@R1_basename}_trimmed_paired.fastq" => ["#{@read1}", "#{@read2}"] do
    sh "source trimmomatic-0.36; source jre-1.7.0.11; trimmomatic PE -threads 2 -phred33 -trimlog results/#{@sample}/trimmomatic.log -quiet -validatePairs  #{@read1} #{@read2} results/#{@sample}/#{@R1_basename}_trimmed_paired.fastq results/#{@sample}/#{@R1_basename}_unpaired.fastq results/#{@sample}/#{@R2_basename}_trimmed_paired.fastq results/#{@sample}/#{@R2_basename}_unpaired.fastq ILLUMINACLIP:/tsl/software/testing/trimmomatic/0.36/x86_64/share/trimmomatic/adapters/ilmn_adapters.fa:2:30:10 LEADING:15 SLIDINGWINDOW:4:20 TRAILING:15 MINLEN:65"
  end

  file "results/#{@sample}/#{@R2_basename}_trimmed_paired.fastq" => ["#{@read1}", "#{@read2}"] do
  end

  multitask :run =>  ["fastqc:run", "results/#{@sample}/#{@R1_basename}_trimmed_paired.fastq", "results/#{@sample}/#{@R2_basename}_trimmed_paired.fastq"] do
    puts "Trimmomatic completed"
  end

end

namespace :BowtieIndex do

 file "#{@reference}.1.bt2" => ["#{@reference}"] do
   sh "source bowtie2-2.1.0;  bowtie2-build -f   #{@reference}  #{@reference} "
 end
 file "#{@reference}.2.bt2" => ["#{@reference}"] do
 end
 file "#{@reference}.3.bt2" => ["#{@reference}"] do
 end
 file "#{@reference}.4.bt2" => ["#{@reference}"] do
 end
 file "#{@reference}.rev.1.bt2" => ["#{@reference}"] do
 end
 file "#{@reference}.rev.2.bt2" => ["#{@reference}"] do
 end

 task :run => ["#{@reference}.1.bt2", "#{@reference}.2.bt2", "#{@reference}.3.bt2", "#{@reference}.4.bt2", "#{@reference}.rev.1.bt2", "#{@reference}.rev.2.bt2" ] do
   if !@reference
     puts "Reference sequence not provided"
     exit
   else
     puts "Bowtie reference indexing completed"
   end
 end

end
 namespace :bowtie do


   file "#{@reference}.dict" => ["#{@reference}"] do
     sh "source samtools-1.3.1; samtools dict -o #{@reference}.dict #{@reference}"
   end
   file "#{@reference}.dict" => ["#{@reference}"] do
     sh "source samtools-1.3.1; samtools dict -o #{@reference}.dict #{@reference}"
   end

  file "results/#{@sample}/#{@sampleid}_paired_aligned.sam" => ["results/#{@sample}", "#{@reference}", "results/#{@sample}/#{@R1_basename}_trimmed_paired.fastq",  "results/#{@sample}/#{@R2_basename}_trimmed_paired.fastq"] do
   sh "source bowtie2-2.1.0; bowtie2 -q --phred33 -k 1 --reorder --very-sensitive-local --no-mixed --no-dovetail --no-discordant --no-unal --rg-id #{@sample} --rg \"platform:Illumina\" --no-unal -x #{@reference} -1 results/#{@sample}/#{@R1_basename}_trimmed_paired.fastq -2 results/#{@sample}/#{@R2_basename}_trimmed_paired.fastq -S results/#{@sample}/#{@sampleid}_paired_aligned.sam 2> results/#{@sample}/#{@sampleid}_aligned.log; "
  end

  file "results/#{@sample}/#{@sampleid}_paired_aligned.bam" => [ "#{@reference}.dict", "results/#{@sample}/#{@sampleid}_paired_aligned.sam" ] do
    sh "source samtools-1.3.1; samtools view -bS -t #{@reference}.dict -o results/#{@sample}/#{@sampleid}_paired_aligned.bam results/#{@sample}/#{@sampleid}_paired_aligned.sam"
  end

  multitask :run => ["BowtieIndex:run", "results/#{@sample}/#{@sampleid}_paired_aligned.bam"] do
    puts "Bowtie mapping completed. SAM file converted to BAM. Original SAM file removed."
  end

end


namespace :samtools do

  bamfiles=FileList["results/bulksus/*_paired_aligned.bam"]
  bamfilesorted=bamfiles.pathmap("%XSorted.bam")
  indexedfiles=bamfiles.pathmap("%XSorted.bam.bai")
  merged="results/bulksus/merged.bam"
  merged_sorted=merged.pathmap("%d/merged_sorted.bam")
  merged_sorted_bai=merged.pathmap("%d/merged_sorted.bam.bai")

  bamfiles.zip(bamfilesorted, indexedfiles).each do |bam, sorted, bai|
    file sorted => [bam] do
      sh "source samtools-1.3.1;  samtools sort --threads 4 -O bam -o #{sorted} #{bam} "
    end

    file bai => [sorted] do
      sh "source samtools-1.3.1; samtools index #{sorted} #{bai}"
    end
  end

  file merged => indexedfiles do
    sh "source samtools-1.3.1; samtools merge results/bulksus/merged.bam #{bamfilesorted}"
  end
  file merged_sorted => merged do
    sh "source samtools-1.3.1; samtools sort --threads 4 --reference #{@reference} -o #{merged_sorted} #{merged}"
  end
  file merged_sorted_bai => merged_sorted do
    sh "source samtools-1.3.1; samtools index #{merged_sorted}"
  end
  file "results/bulksus/merged_sorted.bcf" => merged_sorted_bai do
    #sh "source samtools-1.3.1; samtools mpileup --fasta-ref #{@Rreference} --VCF -u --output-MQ --output-BP --output-tags DP,AD,ADF,ADR,SP --reference #{@reference} --output results/bulksus/mergedSorted.mpileup results/bulksus/mergedSorted.bam"
    sh "source samtools-1.3.1; samtools mpileup  -d 250 -m 1 -E --BCF -f #{@reference} --output results/bulksus/merged_sorted.bcf #{merged_sorted}"
  end

  parentbam=FileList["results/susparent/*_paired_aligned.bam"]
  parentbamsorted=parentbam.pathmap("%XSorted.bam")
  parentbamindexed=parentbam.pathmap("%XSorted.bam.bai")

  file parentbamsorted =>  parentbam do
      sh "source samtools-1.3.1;  samtools sort --threads 4 -O bam -o #{parentbamsorted} #{parentbam} "
  end
  file parentbamindexed => parentbamsorted do
      sh "source samtools-1.3.1; samtools index #{parentbamsorted} #{parentbamindexed}"
  end

  file "results/susparent/susparent.bcf" => [parentbamindexed] do
    #sh "source samtools-1.3.1; samtools mpileup --fasta-ref #{@Rreference} --VCF -u --output-MQ --output-BP --output-tags DP,AD,ADF,ADR,SP --reference #{@reference} --output results/susparent/mergedSorted.mpileup #{parentbamsorted}"
    sh "source samtools-1.3.1; samtools mpileup  -d 250 -m 1 -E --BCF -f #{@reference} --output results/susparent/susparent.mpileup #{parentbamsorted} "
  end

  task :bulksus => ["results/bulksus/merged_sorted.bcf"]
  task :susparent => ["results/susparent/susparent.mpileup"]

end
