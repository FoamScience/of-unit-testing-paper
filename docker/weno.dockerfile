FROM ghcr.io/foamscience/of-unit-testing-paper:base-2206

# Env. vars.
ENV DEBIAN_FRONTEND=noninteractive
ARG OPENFOAM_VERSION
ENV SHELL=/usr/bin/bash
ENV WENO_REPO="https://github.com/WENO-OF/WENOEXT.git"
ENV WENO_COMMIT="f45593a"

# ------------------------------------------------------------
# Configure Paper software
# ------------------------------------------------------------

ENV USER openfoam
ENV HOME /home/${USER}
USER ${USER}

# Download and install WENOExt
RUN git clone --recursive ${WENO_REPO} ${HOME}/WENOExt \
    && cd ${HOME}/WENOExt && git checkout ${WENO_COMMIT} \
    && bash -c 'source /usr/lib/openfoam/openfoam${OPENFOAM_VERSION}/etc/bashrc  && ./Allwmake'
