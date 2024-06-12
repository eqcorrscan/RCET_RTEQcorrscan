FROM condaforge/mambaforge:latest

# In production these should be the only things required
# This line should not be needed, but scipy requires a speccific window of numpy, and mamba doesn't actually provide it
# RUN mamba install -c conda-forge scipy 'numpy<1.25' -y
# RUN mamba install -c conda-forge 'python=3.11' obsplus eqcorrscan geographiclib 'pandas>=1.0' progressbar2 'pydantic>=1.8.2' pytables -y
RUN conda config --show

# In development we need to install the development branches
RUN apt-get update && apt-get install -y git

# Install master testing branch of RT-EQcorrscan
# RUN git clone --depth 1 --branch master https://github.com/eqcorrscan/RT_EQcorrscan.git && \
RUN git clone --depth 1 --branch reloc-plugin https://github.com/eqcorrscan/RT_EQcorrscan.git && \
    cd RT_EQcorrscan && \
    mamba install --override-channels -c conda-forge --file requirements.txt -y && \
    cd ..

# RUN mamba install --override-channels -c conda-forge pympler psutil -y

RUN cd RT_EQcorrscan && pip install . --no-deps && cd ..

# Version 0.2.5 of obsplus is reporting version 0.0.0, which recreates the db every time :(
RUN echo "__version__ = '0.2.5'\n__last_version__ = '0.2.5'" > /opt/conda/lib/python3.10/site-packages/obsplus/version.py

# Copy simulation config file
COPY NZ_past_seq_config.yml NZ_past_seq_config.yml
