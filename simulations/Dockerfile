FROM condaforge/mambaforge:latest

# In production these should be the only things required
# RUN mamba install -c conda-forge rt-eqcorrscan  # rt-eqcorrscan install currently broken by lack of pyrpoj
RUN mamba install -c conda-forge eqcorrscan geographiclib 'pandas>=1.0' progressbar2 'pydantic>=1.8.2' pytables -y

# In development we need to install the development branches
RUN apt-get update && apt-get install -y git
# Install develop branch of EQCorrscan
RUN git clone --depth 1 --branch develop https://github.com/eqcorrscan/EQcorrscan.git && \
    cd EQcorrscan && \
    mamba install gcc -y && rm -r /opt/conda/lib/python3.10/site-packages/eqcorrscan && \
    python setup.py install && cd ..
# Install obsplus github - bug fixes over conda version
RUN git clone --depth 1 --branch master https://github.com/niosh-mining/obsplus.git && \
    cd obsplus && \
    pip install . && cd ..
# Install master testing branch of RT-EQcorrscan
RUN git clone --depth 1 --branch master https://github.com/eqcorrscan/RT_EQcorrscan.git && \
    cd RT_EQcorrscan && \
    mamba install pympler psutil -y && mamba install --file requirements.txt -y && \
    python setup.py install && cd ..

# Copy simulation config file
COPY NZ_past_seq_config.yml NZ_past_seq_config.yml
