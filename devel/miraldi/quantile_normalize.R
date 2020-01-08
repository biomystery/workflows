#!/usr/bin/env Rscript
options(warn=-1)
options("width"=100)


suppressMessages(library("argparse"))
suppressMessages(library("preprocessCore"))
suppressMessages(library("rtracklayer"))


load_coverage_data <- function(filenames, bin_size, sum_signal) {
    collected_binned_data = NULL
    previous_sequence_info = NULL
    previous_strand_info = NULL
    for (i in 1:length(filenames)) {
        raw_coverage_data <- import.bw(filenames[i])
        sequence_info = seqinfo(raw_coverage_data)
        if (is.null(previous_sequence_info)){
            previous_sequence_info = sequence_info
        } else if (seqnames(previous_sequence_info)!=seqnames(sequence_info) || seqlengths(previous_sequence_info)!=seqlengths(sequence_info)) {
            print("Exiting: sequence info is different for input bigwig files")
            quit(save = "no", status = 1, runLast = FALSE)
        }
        binned_data <- as.data.frame(binnedAverage(tileGenome(seqlengths=sequence_info,
                                                              tilewidth=bin_size,
                                                              cut.last.tile.in.chrom=TRUE) ,
                                                   coverage(raw_coverage_data, weight="score"),
                                                   "score"))
        binned_data = binned_data[,c("seqnames", "start", "end", "strand", "score")]
        print(paste("Loaded ", nrow(binned_data), " ranges from ", filenames[i], " (bin size = ", bin_size, ")", sep=""))
        if (is.null(previous_strand_info)){
            previous_strand_info = binned_data[,"strand"]
        } else if (previous_strand_info != binned_data[,"strand"]) {
            print("Exiting: strand info is different for input bigwig files")
            quit(save = "no", status = 1, runLast = FALSE)
        }
        score_column_name = paste(i, "score", sep="_")
        strand_column_name = paste(i, "strand", sep="_")
        colnames(binned_data)[colnames(binned_data) == "score"] = score_column_name
        colnames(binned_data)[colnames(binned_data) == "strand"] = strand_column_name
        if (is.null(collected_binned_data)){
            collected_binned_data = binned_data
        } else {
            if(sum_signal){
                print("Add signal to the previous bigwig")
                collected_binned_data[,"1_score"] = collected_binned_data[,"1_score"] + binned_data[,score_column_name]
            } else {
                collected_binned_data[,score_column_name] = binned_data[,score_column_name]
                collected_binned_data[,strand_column_name] = binned_data[,strand_column_name]
            }
        }
    }
    return( list(coverage_data=collected_binned_data, sequence_info=previous_sequence_info) )
}


build_plots <- function(score_data, colors, reference_score_data){
    icolor <- colorRampPalette(colors)(length(colnames(score_data))+1)
    plot(density(score_data[,1]), col=icolor[1], lwd=3, main="Density plot of intensities", ylab="Density", xlab="Coverage")
    legend_names = colnames(score_data[,1, drop = FALSE])
    legend_colors = c(icolor[1])
    if (ncol(score_data) > 1){
        for(i in 2:ncol(score_data)){
            lines(density(score_data[,i]), col=icolor[i], lwd=3)
            legend_names = append(legend_names, colnames(score_data[,i, drop = FALSE]))
            legend_colors = append(legend_colors, icolor[i])
        }
    }
    if (!is.null(reference_score_data)){
        lines(density(reference_score_data[,1]), col=icolor[length(icolor)], lwd=3)
        legend_names = append(legend_names, "reference")
        legend_colors = append(legend_colors, icolor[length(icolor)])
    }
    legend("topleft", legend=legend_names, col=legend_colors, lwd=3)
    
    if (!is.null(reference_score_data)){
        boxplot(cbind(score_data, reference_score_data), main="Distribution boxplot", names=legend_names, outline=FALSE)
    } else {
        boxplot(score_data, main="Distribution boxplot", names=legend_names, outline=FALSE)
    }
    

}

export_results <- function(coverage_data, sequence_info, filenames, prefix, suffix, sum_signal){
    if (sum_signal){
        output_filename = paste(prefix, "combined", suffix, ".bigwig", sep="")
        print(paste("Export combined normalized bigwig to", output_filename, sep=" "))
        df = coverage_data[,c(1,2,3)]
        df[,"score"] = coverage_data[,"1_score"]
        df[,"strand"] = coverage_data[,"1_strand"]
        gr = makeGRangesFromDataFrame(df, seqinfo=sequence_info, keep.extra.columns=TRUE)
        export.bw(gr, output_filename)
    } else {
        for (i in 1:length(filenames)) {
            output_filename = paste(prefix, head(unlist(strsplit(basename(filenames[i]), ".", fixed = TRUE)), 1), suffix, ".bigwig", sep="")
            print(paste("Export normalized bigwig to", output_filename, sep=" "))
            df = coverage_data[,c(1,2,3)]
            df[,"score"] = coverage_data[, paste(i, "score", sep="_")]
            df[,"strand"] = coverage_data[, paste(i, "strand", sep="_")]
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
    parser$add_argument("--palette",   help='Palette color names. Default: red, black, green, yellow, blue, pink, brown', type="character", nargs='+', default=c("red", "black", "green", "yellow", "blue", "pink", "brown"))
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
raw_data <- load_coverage_data(args$input, args$bin, args$sum)
coverage_data = raw_data$coverage_data
sequence_info = raw_data$sequence_info

# Extract score data
print("Extract score data")
score_columns = grep("score", colnames(coverage_data), value = TRUE, ignore.case = TRUE)
score_data = coverage_data[,score_columns, drop = FALSE]



# Normalize score data
reference_score_data = NULL
if (!is.null(args$reference)){
    print(paste("Normalize score data based on reference distribution from", args$reference, sep=" "))
    reference_data <- load_coverage_data(args$reference, args$bin)
    reference_coverage_data = reference_data$coverage_data
    reference_sequence_info = reference_data$sequence_info
    reference_score_data = reference_coverage_data[,"1_score", drop = FALSE]
    if (seqnames(reference_sequence_info)!=seqnames(sequence_info) || seqlengths(reference_sequence_info)!=seqlengths(sequence_info)) {
        print("Exiting: reference sequence info is different from the sequence info of loaded bigwig files")
        quit(save = "no", status = 1, runLast = FALSE)
    }
    norm_score_data = as.data.frame(normalize.quantiles.use.target(as.matrix(score_data), reference_score_data[,1]))
} else {
    print("Normalize score data between input samples")
    norm_score_data = as.data.frame(normalize.quantiles(as.matrix(score_data)))
}

colnames(norm_score_data) = colnames(score_data)
rownames(norm_score_data) = rownames(score_data)
coverage_data[,score_columns] = norm_score_data

print("Build plots")
build_plots(score_data, args$palette, reference_score_data)
build_plots(norm_score_data, args$palette, reference_score_data)

# Save normalized data to bigwigs
export_results(coverage_data, sequence_info, args$input, args$prefix, args$suffix, args$sum)

