FROM ghcr.io/foamscience/of-unit-testing-paper:base-2206

# Env. vars.
ENV DEBIAN_FRONTEND=noninteractive
ARG OPENFOAM_VERSION
ENV SHELL=/usr/bin/bash
ENV BLASTAMR_REPO="https://github.com/STFS-TUDa/blastAMR"
ENV BLASTAMR_COMMIT="fe84d74dc92a13e00478f1738c6988ac9a0bacee"
ENV FOAM_UT_REPO="https://github.com/FoamScience/foamUT"
ENV FOAM_UT_COMMIT="09995decce904577d4a393079184e6c7d48795fc"

# ------------------------------------------------------------
# Configure Paper software
# ------------------------------------------------------------

ENV USER openfoam
ENV HOME /home/${USER}
USER ${USER}

# FOAMUT & BLASTAMR
RUN git clone ${FOAM_UT_REPO} ${HOME}/foamUT \
    && cd ${HOME}/foamUT && git checkout ${FOAM_UT_COMMIT} \
    && bash -c 'source /usr/lib/openfoam/openfoam${OPENFOAM_VERSION}/etc/bashrc  && ./Alltest'
RUN git clone ${BLASTAMR_REPO} ${HOME}/blastAMR \
    && cd ${HOME}/blastAMR && git checkout ${BLASTAMR_COMMIT} \
    && bash -c 'source /usr/lib/openfoam/openfoam${OPENFOAM_VERSION}/etc/bashrc && ./Allwmake'

COPY foamut.alltest ${HOME}/foamut.alltest
