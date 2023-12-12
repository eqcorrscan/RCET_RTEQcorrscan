FROM condaforge/mambaforge:latest

# In production these should be the only things required
# RUN mamba install -c conda-forge rt-eqcorrscan  # rt-eqcorrscan install currently broken by lack of pyrpoj


# This line should not be needed, but scipy requires a specific window of numpy, and mamba doesn't actually provide it
# RUN mamba install -c conda-forge scipy 'numpy<1.25' -y
RUN mamba install -c conda-forge obsplus eqcorrscan geographiclib 'pandas>=1.0' progressbar2 'pydantic>=1.8.2' pytables -y

# Version 0.2.5 of obsplus is reporting version 0.0.0, which recreates the db every time :(
RUN echo "__version__ = '0.2.5'\n__last_version__ = '0.2.5'" > /opt/conda/lib/python3.10/site-packages/obsplus/version.py

# Including a text editor for tweaks
RUN apt-get update && apt-get install -y vim

# In development we need to install the development branches
RUN apt-get update && apt-get install -y git

# Install develop branch of EQCorrscan
# RUN git clone --depth 1 --branch develop https://github.com/eqcorrscan/EQcorrscan.git && \
#     cd EQcorrscan && \
#     mamba install gcc -y && rm -r /opt/conda/lib/python3.10/site-packages/eqcorrscan && \
#     python setup.py install && cd ..
# Install obsplus github - bug fixes over conda version
#RUN git clone --depth 1 --branch master https://github.com/niosh-mining/obsplus.git && \
#    cd obsplus && \
#    pip install . && cd ..
# Install master testing branch of RT-EQcorrscan
RUN git clone --depth 1 --branch master https://github.com/eqcorrscan/RT_EQcorrscan.git && \
    cd RT_EQcorrscan && \
    mamba install pympler psutil -y && mamba install --file requirements.txt -y && \
    pip install . && cd ..

# Copy simulation config file
COPY RCET_RTEQC_config.yml RCET_RTEQC_config.yml
