FROM condaforge/mambaforge:latest

# In production these should be the only things required
# RUN mamba install -c conda-forge rt-eqcorrscan  # rt-eqcorrscan install currently broken by lack of pyrpoj

# Including a text editor for tweaks
RUN apt-get update && apt-get install -y vim

# In development we need to install the development branches
RUN apt-get update && apt-get install -y git

# Install requirements
RUN git clone --depth 1 --branch master https://github.com/eqcorrscan/RT_EQcorrscan.git && \
    cd RT_EQcorrscan && mamba install --file requirements.txt -y && cd ..

# Install RTEQC
RUN cd RT_EQcorrscan && pip install . --no-deps && cd ..

# Version 0.2.5 of obsplus is reporting version 0.0.0, which recreates the db every time :(
RUN echo "__version__ = '0.2.5'\n__last_version__ = '0.2.5'" > /opt/conda/lib/python3.10/site-packages/obsplus/version.py

# Copy simulation config file
COPY RCET_RTEQC_config.yml RCET_RTEQC_config.yml
