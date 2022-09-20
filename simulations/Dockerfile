FROM condaforge/mambaforge:latest

# In production these should be the only things required
# RUN mamba install -c conda-forge rt-eqcorrscan  # rt-eqcorrscan install currently broken by lack of pyrpoj
RUN mamba install -c conda-forge eqcorrscan geographiclib -y

# In development we need to install the development branches
RUN apt-get update && apt-get install -y git
# Install RCET enhancements branch of EQCorrscan
RUN git clone https://github.com/eqcorrscan/EQcorrscan.git && \
    cd EQcorrscan && git checkout RCET-enhancements && \
    mamba install gcc -y && rm -r /opt/conda/lib/python3.10/site-packages/eqcorrscan && \
    python setup.py install && cd ..
# Install simulation testing branch of RT-EQcorrscan
RUN git clone https://github.com/eqcorrscan/RT_EQcorrscan.git && \
    cd RT_EQcorrscan && git checkout simulation-testing && \
    mamba install pympler psutil -y && mamba install --file requirements.txt -y && \
    python setup.py install && cd ..

# Copy simulation config file
COPY NZ_past_seq_config.yml NZ_past_seq_config.yml
