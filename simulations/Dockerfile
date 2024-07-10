FROM condaforge/mambaforge:latest

################## SEISAN ###################
# Get SEISAN deps
RUN apt-get update && apt-get install -y curl tar gfortran libx11-6 libx11-dev g++ make git && apt-get clean
# Download seisan
RUN curl "https://www.geo.uib.no/seismo/SOFTWARE/SEISAN/OLDER_VERSIONS/SEISAN_12.0/seisan_v12.0_linux_64.tar.gz" -o "seisan_v12_linux_64.tar.gz" && \
    mkdir seisan && mv seisan_v12_linux_64.tar.gz seisan/. && cd seisan && \
    tar -xzf seisan_v12_linux_64.tar.gz
# Build seisan
RUN cd seisan/PRO && make clean && \
    export SEISARCH=linux64 && make all
# Install SEISAN
RUN cp -v /seisan/PRO/* /usr/local/bin/. && cp -v /seisan/COM/* /usr/local/bin/.

############### EQCorrscan etc #####################

# Need to set up a conda env - pygmt libgdal does not play nice in base
RUN conda create -n rteqc 'python=3.10'

RUN echo "conda activate rteqc" >> ~/.bashrc

# Make RUN commands use this environment
SHELL ["conda", "run", "-n", "rteqc", "/bin/bash", "-c"]
# SHELL ["/bin/bash", "--login", "-c"]

# In production these should be the only things required
# This line should not be needed, but scipy requires a specific window of numpy, and mamba doesn't actually provide it
RUN mamba install -c conda-forge scipy 'numpy<1.25' pandas pygmt xarray netcdf4 packaging gmt -y

# Install branch of RT-EQcorrscan
# RUN git clone --depth 1 --branch master https://github.com/eqcorrscan/RT_EQcorrscan.git && \
RUN git clone --depth 1 --branch reloc-plugin https://github.com/eqcorrscan/RT_EQcorrscan.git && \
    cd RT_EQcorrscan && \
    mamba install --file requirements.txt -y && \
    cd ..

# Install relevant branch of EQcorrscan if needed
RUN git clone --depth 1 --branch develop https://github.com/eqcorrscan/EQcorrscan.git && \
    apt-get update && apt-get install -y gcc libfftw3-dev && \
    cd EQcorrscan && \
    mamba remove eqcorrscan && \
    mamba install --file requirements.txt -y && \
    pip install . --no-deps && cd ..


# RUN mamba install --override-channels -c conda-forge pympler psutil -y

RUN cd RT_EQcorrscan && pip install . --no-deps && cd ..

# Version 0.2.5 of obsplus is reporting version 0.0.0, which recreates the db every time :(
#RUN echo "__version__ = '0.2.5'\n__last_version__ = '0.2.5'" > /opt/conda/lib/python3.10/site-packages/obsplus/version.py

############## CONFIG FILES #####################


# Copy simulation config file
COPY NZ_past_seq_config.yml NZ_past_seq_config.yml

# Copy velocity model - TODO this should be the 3D model and we should sample from it
COPY vmodel.txt vmodel.txt

