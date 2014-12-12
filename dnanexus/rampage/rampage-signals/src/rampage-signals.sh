#!/bin/bash
# rampage-signals 0.0.1

main() {
    # Now in resources/usr/bin
    #echo "* Download and install STAR..."
    #git clone https://github.com/alexdobin/STAR
    #(cd STAR; git checkout tags/STAR_2.4.0g1)
    #(cd STAR; make)
    #wget https://github.com/ENCODE-DCC/kentUtils/archive/v302.1.0.tar.gz

    echo "*****"
    echo "* Running: rampage-signals.sh [v0.0.1]"
    echo "* STAR version:     ["`STAR --version | awk '{print $1}' | cut -d _ -f 2-`"]"
    echo "* bedGraphToBigWig version: "`bedGraphToBigWig 2>&1 | grep "bedGraphToBigWig v" | awk '{print $2$3}'`
    echo "*****"

    echo "Value of bam_file:    '$rampage_marked_bam'"
    echo "Value of chrom_sizes: '$chrom_sizes'"

    echo "* Download files..."
    bam_fn=`dx describe "$rampage_marked_bam" --name`
    bam_fn=${bam_fn%_rampage_star_marked.bam}
    bam_fn=${bam_fn%.bam}
    dx download "$rampage_marked_bam" -o "$bam_fn".bam
    echo "* Bam file: '${bam_fn}.bam'"

    dx download "$chrom_sizes" -o chromSizes.txt
    
    signal_root=${bam_fn}_rampage_5p
    echo "* Signal files root: '${signal_root}'"

    echo "* Make signals..."
    mkdir -p Signal
    STAR --runMode inputAlignmentsFromBAM --inputBAMfile ${bam_fn}.bam --outWigType bedGraph read1_5p \
         --outWigStrand Stranded --outFileNamePrefix read1_5p. --outWigReferencesPrefix chr

    echo "* Convert bedGraph to bigWigs..."
    bedGraphToBigWig read1_5p.Signal.UniqueMultiple.str2.out.bg chromSizes.txt ${signal_root}_minusAll.bw
    bedGraphToBigWig read1_5p.Signal.Unique.str2.out.bg         chromSizes.txt ${signal_root}_minusUniq.bw
    bedGraphToBigWig read1_5p.Signal.UniqueMultiple.str1.out.bg chromSizes.txt ${signal_root}_plusAll.bw
    bedGraphToBigWig read1_5p.Signal.Unique.str1.out.bg         chromSizes.txt ${signal_root}_plusUniq.bw
    echo `ls`

    echo "* Upload results..."
    all_minus_bw=$(dx upload ${signal_root}_minusAll.bw --brief)
    all_plus_bw=$(dx upload ${signal_root}_plusAll.bw --brief)
    unique_minus_bw=$(dx upload ${signal_root}_minusUniq.bw --brief)
    unique_plus_bw=$(dx upload ${signal_root}_plusUniq.bw --brief)

    dx-jobutil-add-output all_minus_bw "$all_minus_bw" --class=file
    dx-jobutil-add-output all_plus_bw "$all_plus_bw" --class=file
    dx-jobutil-add-output unique_minus_bw "$unique_minus_bw" --class=file
    dx-jobutil-add-output unique_plus_bw "$unique_plus_bw" --class=file

    #echo "* Temporary uploads..."
    # temprary for comparison only!
    mv read1_5p.Signal.UniqueMultiple.str2.out.bg ${signal_root}_minusAll.bg
    mv read1_5p.Signal.Unique.str2.out.bg         ${signal_root}_minusUniq.bg
    mv read1_5p.Signal.UniqueMultiple.str1.out.bg ${signal_root}_plusAll.bg
    mv read1_5p.Signal.Unique.str1.out.bg         ${signal_root}_plusUniq.bg
    all_minus_bg=$(dx upload ${signal_root}_minusAll.bg --brief)
    all_plus_bg=$(dx upload ${signal_root}_plusAll.bg --brief)
    unique_minus_bg=$(dx upload ${signal_root}_minusUniq.bg --brief)
    unique_plus_bg=$(dx upload ${signal_root}_plusUniq.bg --brief)
    dx-jobutil-add-output all_minus_bg "$all_minus_bg" --class=file
    dx-jobutil-add-output all_plus_bg "$all_plus_bg" --class=file
    dx-jobutil-add-output unique_minus_bg "$unique_minus_bg" --class=file
    dx-jobutil-add-output unique_plus_bg "$unique_plus_bg" --class=file
    echo "* Finished."
}
