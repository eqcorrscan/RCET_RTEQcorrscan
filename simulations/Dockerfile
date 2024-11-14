FROM condaforge/mambaforge:latest
ARG DEBIAN_FRONTEND=noninteractive

################## SEISAN ###################
# Get SEISAN deps
RUN apt-get update && apt-get install -yq --no-install-recommends curl tar gfortran libx11-6 libx11-dev g++ make git gcc libfftw3-dev cmake && apt-get clean
# Download seisan

RUN curl "https://www.geo.uib.no/seismo/SOFTWARE/SEISAN/OLDER_VERSIONS/seisan_v13.5_linux_64.tar.gz" -o "seisan.tar.gz" && \
    mkdir seisan && mv seisan.tar.gz seisan/. && cd seisan && \
    tar -xzf seisan.tar.gz && rm seisan.tar.gz
# Build seisan
RUN cd seisan/PRO && make clean && \
    export SEISARCH=linux64 && make all
# Install SEISAN
RUN cp -v /seisan/PRO/* /usr/local/bin/. && cp -v /seisan/COM/* /usr/local/bin/.

################### JULIA etc ################################

RUN curl -L --insecure https://julialang-s3.julialang.org/bin/linux/x64/1.10/julia-1.10.4-linux-x86_64.tar.gz -o julia.tar.gz && \
    tar -xzf julia.tar.gz && \
    rm julia.tar.gz

# Add julia to path
ENV PATH="${PATH}:/julia-1.10.4/bin"

# GrowClust3D has to be installed from github as of August 2022
# Install dependencies and Growclust3D from github
RUN julia -e 'import Pkg; Pkg.update()' && \
   julia -e 'import Pkg; Pkg.add("DataFrames")' && \
   julia -e 'import Pkg; Pkg.add("Proj")' && \
   julia -e 'import Pkg; Pkg.add("ArgParse")' && \
   julia -e 'import Pkg; Pkg.add("JLD")' && \
   julia -e 'import Pkg; Pkg.add(url="https://github.com/dttrugman/GrowClust3D.jl"); using GrowClust3D'


####################### NonLinLoc #################################
RUN git clone --depth 1 https://github.com/ut-beg-texnet/NonLinLoc.git && \
   cd NonLinLoc && cd src && mkdir bin && cmake . && make

# Add NLL to path
ENV PATH="${PATH}:/NonLinLoc/src/bin"

############### EQCorrscan etc #####################

# Need to set up a conda env - pygmt libgdal does not play nice in base
COPY rteqc_env.yml rteqc_env.yml 
RUN mamba env create -f rteqc_env.yml
# RUN mamba install --override-channels -c conda-forge pympler psutil -y
RUN echo "conda activate rteqc" >> ~/.bashrc
# Make RUN commands use this environment
SHELL ["conda", "run", "-n", "rteqc", "/bin/bash", "-c"]
# SHELL ["/bin/bash", "--login", "-c"]

# Install relevant branch of EQcorrscan if needed
# Disable cache from here on while in development
# ADD "https://www.random.org/cgi-bin/randbyte?nbytes=10&format=h" skipcache
RUN git clone --depth 1 --branch develop https://github.com/eqcorrscan/EQcorrscan.git && \
    cd EQcorrscan && pip install . --no-deps && cd ..


# Disable cache from here on while in development
ADD "https://www.random.org/cgi-bin/randbyte?nbytes=10&format=h" skipcache
# Install branch of RT-EQcorrscan
# RUN git clone --depth 1 --branch master https://github.com/eqcorrscan/RT_EQcorrscan.git && \
RUN git clone --depth 1 --branch reloc-plugin https://github.com/eqcorrscan/RT_EQcorrscan.git && \
    cd RT_EQcorrscan && pip install . --no-deps && cd ..

# Version 0.2.5 of obsplus is reporting version 0.0.0, which recreates the db every time :(
#RUN echo "__version__ = '0.2.5'\n__last_version__ = '0.2.5'" > /opt/conda/lib/python3.10/site-packages/obsplus/version.py

############## CONFIG FILES #####################


# Copy simulation config file
COPY NZ_past_seq_config.yml NZ_past_seq_config.yml

# Copy velocity model - TODO this should be the 3D model and we should sample from it
COPY vmodel.txt vmodel.txt

# Copy NonLinLoc files
ADD nonlinloc_files nonlinloc_files
