#################################################################
# Dockerfile
# Software:         AltAnalyze
# Software Version: commit 5ca1017133a51256a066f260809bcd948d51f2b1
# Description:      An automated cross-platform workflow for RNA-Seq gene,
#                   splicing and pathway analysis
# Website:          http://www.altanalyze.org/
# Provides:         AltAnalyze
# Base Image:       python:2.7
# Build Cmd:        docker build .
# Pull Cmd:         docker pull haysb1991/altanalyze-test:version7
# Run Cmd:          docker run -ti haysb1991/altanalyze-test:version7 /bin/bash
#################################################################


FROM python:2.7
ENV DEBIAN_FRONTEND noninteractive

WORKDIR /tmp

ENV COMMIT "5ca1017133a51256a066f260809bcd948d51f2b1"
ENV URL "https://github.com/nsalomonis/altanalyze.git"

COPY ./requirements/altanalyze_requirements.txt altanalyze_requirements.txt

### Installing dependencies
RUN apt-get update && \
    apt install libcairo2-dev pkg-config && \
    apt install r-base -y && \
    pip install -r altanalyze_requirements.txt && \
### Installing AltAnalyze
    cd /opt && \
    git clone ${URL} && \
    cd altanalyze && \
    git checkout ${COMMIT} && \
### Cleaning
    apt-get clean && \
    apt-get purge && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/* && \
    strip /usr/local/bin/*; true