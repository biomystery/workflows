#!/usr/bin/env Rscript
options(warn=-1)
options("width"=100)


suppressMessages(library("argparse"))
suppressMessages(library("preprocessCore"))
suppressMessages(library("rtracklayer"))


DATA_COLUMNS  = c("seqnames", "start", "end", "strand", "score")
INTERSECT_BY  = c("seqnames", "start", "end", "strand")
INP_SCORE     = "inp_score"
REF_SCORE     = "ref_score"
SUM_SCORE     = "sum_score"
SEQ_COLUMNS   = c("chr", "length")


load_coverage_data <- function(filenames, bin_size, score_column) {
    collected_binned_data = NULL
    collected_sequence_lengths = NULL
    for (i in 1:length(filenames)) {
        raw_coverage_data <- import.bw(filenames[i])
        binned_data = as.data.frame(binnedAverage(tileGenome(seqlengths=seqinfo(raw_coverage_data), tilewidth=bin_size, cut.last.tile.in.chrom=TRUE), coverage(raw_coverage_data, weight="score"), "score"))
        binned_data = binned_data[,DATA_COLUMNS]
        colnames(binned_data)[colnames(binned_data) == "score"] = paste(i, score_column, sep="_")
        print(paste("Loaded ", nrow(binned_data), " ranges from ", filenames[i], " (bin size = ", bin_size, ")", sep=""))

        sequence_lengths = t(data.frame(as.list(seqlengths(seqinfo(raw_coverage_data)))))
        sequence_lengths = data.frame("_" = rownames(sequence_lengths), sequence_lengths)
        rownames(sequence_lengths) = NULL
        colnames(sequence_lengths) = SEQ_COLUMNS
        print("Chromosome list")
        print(sequence_lengths)

        if (is.null(collected_binned_data)){
            collected_binned_data = binned_data
            collected_sequence_lengths = sequence_lengths
        } else {
            print("Merging data")
            collected_binned_data = merge(collected_binned_data, binned_data, by=INTERSECT_BY, sort = FALSE)
            collected_sequence_lengths = merge(collected_sequence_lengths, sequence_lengths, by=SEQ_COLUMNS, sort = FALSE)
        }
    }
    return( list(binned_data=collected_binned_data, sequence_lengths=collected_sequence_lengths) )
}


build_boxplots <- function(score_data, reference_score_data){
    legend_names = colnames(score_data)
    if (!is.null(reference_score_data)){
        legend_names = append(legend_names, "reference")
        boxplot(cbind(score_data, reference_score_data), main="Distribution boxplot", names=legend_names, outline=FALSE)
    } else {
        boxplot(score_data, main="Distribution boxplot", names=legend_names, outline=FALSE)
    }
}

export_results <- function(coverage_data, sequence_info, filenames, prefix, suffix, sum_signal){
    if (sum_signal && length(filenames) > 1){
        output_filename = paste(prefix, "combined", suffix, ".bigwig", sep="")
        print(paste("Export combined normalized bigwig to", output_filename, sep=" "))
        df = coverage_data[,INTERSECT_BY]
        df[,"score"] = coverage_data[,SUM_SCORE]
        gr = makeGRangesFromDataFrame(df, seqinfo=sequence_info, keep.extra.columns=TRUE)
        export.bw(gr, output_filename)
    } else {
        for (i in 1:length(filenames)) {
            output_filename = paste(prefix, head(unlist(strsplit(basename(filenames[i]), ".", fixed = TRUE)), 1), suffix, ".bigwig", sep="")
            print(paste("Export normalized bigwig to", output_filename, sep=" "))
            df = coverage_data[,INTERSECT_BY]
            df[,"score"] = coverage_data[, paste(i, INP_SCORE, sep="_")]
            gr = makeGRangesFromDataFrame(df, seqinfo=sequence_info, keep.extra.columns=TRUE)
            export.bw(gr, output_filename)
        }
    }
}


get_args <- function(){
    parser <- ArgumentParser(description="BigWig quantile normalization with or without a reference distribution")
    parser$add_argument("--input",     help='Input bigwig files to be normalized', type="character", required="True", nargs='+')
    parser$add_argument("--reference", help='Opitional input reference bigwig file to be used as reference distribution', type="character")
    parser$add_argument("--bin",       help='Bin size for normalization. We will take mean of a bin before normalization. Default: 50', type="integer", default=50)
    parser$add_argument("--prefix",    help='Output prefix for normalized files. Default: ./', type="character", default="./")
    parser$add_argument("--suffix",    help='Output suffix for normalized files. Default: _normalized', type="character", default="_normalized")
    parser$add_argument("--sum",       help='Sum signal from input bigwigs before running normalization. Default: False', action='store_true' )
    args <- parser$parse_args(commandArgs(trailingOnly = TRUE))
    return (args)
}


# Parse arguments
args <- get_args()

# Set default output for generated plots
png(filename=paste(args$prefix, "plot", args$suffix, "_%03d.png", sep=""))

# Load coverage data from bigwigs
print(paste("Load data from", length(args$input), "bigwig(s) for quantile normalization",sep=" "))
raw_data <- load_coverage_data(args$input, args$bin, INP_SCORE)
coverage_data = raw_data$binned_data
sequence_lengths = raw_data$sequence_lengths

if (length(args$input) > 1){
    print(paste("Number of common ranges", nrow(coverage_data), sep=" "))
    print("Common chromosome list")
    print(sequence_lengths)
}


if (args$sum && length(args$input) > 1){
    print("Sum score signal from the loaded bigwigs")
    coverage_data[,SUM_SCORE] = rowSums(coverage_data[, !colnames(coverage_data) %in% INTERSECT_BY])
    coverage_data = coverage_data[,c(INTERSECT_BY,SUM_SCORE)]
}


# Normalize score data
reference_score_data = NULL
if (!is.null(args$reference)){
    print(paste("Normalize score data based on reference distribution from", args$reference, sep=" "))
    reference_raw_data = load_coverage_data(args$reference, args$bin, REF_SCORE)
    reference_coverage_data <- reference_raw_data$binned_data
    reference_sequence_lengths = reference_raw_data$sequence_lengths
    
    print("Intersect ranges and chromosome lists between input and reference data")
    coverage_data = merge(coverage_data, reference_coverage_data, by=INTERSECT_BY, sort = FALSE)
    sequence_lengths = merge(sequence_lengths, reference_sequence_lengths, by=SEQ_COLUMNS, sort = FALSE)
    print(head(coverage_data))

    reference_coverage_data = coverage_data[, !colnames(coverage_data) %in% c(grep(INP_SCORE, colnames(coverage_data), value=TRUE, ignore.case=TRUE), SUM_SCORE)]
    print(head(reference_coverage_data))
    coverage_data = coverage_data[, !colnames(coverage_data) %in% c(grep(REF_SCORE, colnames(coverage_data), value=TRUE, ignore.case=TRUE))]
    print(head(coverage_data))

    
    print(paste("Number of ranges common with reference data", nrow(coverage_data), sep=" "))
    print("Chromosome list common for all bigwig files and reference")
    print(sequence_lengths)

    print("Extract score data from bigwigs")
    score_data = coverage_data[, !colnames(coverage_data) %in% INTERSECT_BY, drop = FALSE]
    print("Extract score data from reference ditribution")
    reference_score_data = reference_coverage_data[, !colnames(reference_coverage_data) %in% INTERSECT_BY, drop = FALSE]

    norm_score_data = as.data.frame(normalize.quantiles.use.target(as.matrix(score_data), reference_score_data[,1]))
} else {
    print("Extract score data from bigwigs")
    score_data = coverage_data[, !colnames(coverage_data) %in% INTERSECT_BY, drop = FALSE]
    print("Normalize score data between input samples")
    norm_score_data = as.data.frame(normalize.quantiles(as.matrix(score_data)))
}

colnames(norm_score_data) = colnames(score_data)

print("Build plots")
build_boxplots(score_data, reference_score_data)
build_boxplots(norm_score_data, reference_score_data)


# Save normalized data to bigwigs
print("Export results")
coverage_data[,!colnames(coverage_data) %in% INTERSECT_BY] = norm_score_data

print(head(coverage_data))
sequence_info = Seqinfo(seqnames=as.character(sequence_lengths[,SEQ_COLUMNS[1]]),
                        seqlengths=sequence_lengths[,SEQ_COLUMNS[2]],
                        isCircular=rep(FALSE, nrow(sequence_lengths)),
                        genome="custom")
export_results(coverage_data, sequence_info, args$input, args$prefix, args$suffix, args$sum)

