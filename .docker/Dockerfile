# Based on https://github.com/analythium/quarto-docker-examples/blob/main/Dockerfile.base
#
# This file will create a huge Docker image (around 2GB) with Quarto
# and required dependencies like pandoc, tinytext, ...

FROM eddelbuettel/r2u:20.04

RUN set -e -x && \
    apt-get update && apt-get install -y --no-install-recommends \
    pandoc \
    pandoc-citeproc \
    curl \
    gdebi-core \
    python3.8 python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN set -e -x && \
    install.r \
    shiny \
    jsonlite \
    ggplot2 \
    htmltools \
    remotes \
    renv \
    knitr \
    rmarkdown \
    quarto

# ARG QUARTO_VERSION="0.9.522"
# RUN curl -o quarto-linux-amd64.deb -L https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.deb
RUN curl -LO https://quarto.org/download/latest/quarto-linux-amd64.deb
RUN gdebi --non-interactive quarto-linux-amd64.deb

# Install tools like tinytex to allow conversion to PDF
RUN set -e -x && \
    quarto install tool chromium && \
    quarto install tool tinytex

# Install tools
RUN set -e -x && \
    python3 -m pip install jupyter matplotlib plotly

# Install pip dependencies
RUN set -e -x && \
    pip install openpyxl && \
    pip install pandas

RUN set -e -x && \
    mkdir -p /project/scripts

COPY scripts /project/scripts

RUN set -e -x && \
    chmod +x /project/scripts/entrypoint.sh

WORKDIR /project/input

CMD [ "/project/scripts/entrypoint.sh" ]
