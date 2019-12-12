#################################################################
# Dockerfile
#
# Software:         diffbind
# Software Version: v0.0.7
# Description:      Differential Binding Analysis of ChIP-Seq Peak Data
# Website:          http://www.bioconductor.org/packages/release/bioc/html/DiffBind.html
# Provides:         diffbind 2.14.0
# Base Image:       r-base:3.6.0
# Build Cmd:        docker build --rm -t biowardrobe2/diffbind:v0.0.7 -f diffbind-Dockerfile .
# Pull Cmd:         docker pull biowardrobe2/diffbind:v0.0.7
# Run Cmd:          docker run --rm -ti biowardrobe2/diffbind:v0.0.7 /bin/bash
#################################################################
#
# v0.0.7
# - add tryCatch to all optional outputs
#
# v0.0.6
# - filtering by P-value or FDR
#
# v0.0.5
# - add P-value cutoff for reported results
#
# v0.0.4
# - increased default padding for generated heatmaps
#
# v0.0.3
# - allows to control threads number
#
# v0.0.2
#   - exports
#     * peak overlap correlation heatmap
#     * counts correlation heatmap
#     * correlation heatmap based on all normalized data
#     * correlation heatmap based on DB sites only
#     * PCA plot using affinity data for only differentially bound sites
#     * MA plot
#     * volcano plot
#     * box plots of read distributions for significantly differentially bound (DB) sites
#   - allows to choose from deseq2 or edger
#
# v0.0.1
#   Use run_diffbind.R script
#      - use DiffBind with default parameters
#      - use only condition option in comparison
#      - export results as TSV
#
#################################################################


### Base Image
FROM r-base:3.6.0
LABEL maintainer="misha.kotliar@gmail.com"
ENV DEBIAN_FRONTEND noninteractive

################## BEGIN INSTALLATION ######################

WORKDIR /tmp

ENV VERSION_BIOCMANAGER 1.30.10
ENV URL_BIOCMANAGER "https://cran.r-project.org/src/contrib/BiocManager_${VERSION_BIOCMANAGER}.tar.gz"

COPY ./scripts/install_from_source.R /tmp/install_from_source.R
COPY ./scripts/run_diffbind.R /usr/local/bin/run_diffbind.R

### Installing dependencies
RUN apt-get update && \
    apt-get install -y python3-dev python3-pip libssl-dev libxml2-dev libcurl4-openssl-dev && \
    pip3 install argparse && \
### Installing biocmanager, argparse, diffbind
    Rscript /tmp/install_from_source.R "${URL_BIOCMANAGER}" && \
    R -e 'install.packages("argparse", repo = "https://cloud.r-project.org/")' && \
    R -e "BiocManager::install(c('DiffBind'))" && \
### Installing hopach_order.R script
    chmod +x /usr/local/bin/run_diffbind.R && \
### Cleaning
    apt-get clean && \
    apt-get purge && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/* && \
    strip /usr/local/bin/*; true
