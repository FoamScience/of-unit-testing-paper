# Container image that runs your code    
FROM ghcr.io/foamscience/of-unit-testing-paper:base-2206    
SHELL ["/bin/bash", "-c"]    
# We need to set this enviroment variable    
# since different OpenFOAM versions have    
# a different name for this case    
ENV CYCLIC_CASE=periodicPlaneChannel    
# Set the PATH variable for local pip installs    
ENV PATH="${PATH}:${HOME}/.local/bin"    
                                                                                                                                                                    
# Set the default solver execution template                                                                                                                         
# we set this to explicitely allow oversubscribe                                                                                                                    
ENV OBR_RUN_CMD="mpirun --oversubscribe --bind-to core --map-by core -np {np} {solver} -parallel -case {path}/case >  {path}/case/{solver}_{timestamp}.log 2>&1"    
                                                                                                                                                                    
RUN sudo apt update && sudo apt install -y pip ninja-build    
                                                              
# update python environment                    
RUN python3.10 -m pip install pip --upgrade            
                                                       
# Clone dependencies                                   
RUN cd $HOME && \                                      
    git clone https://github.com/hpsim/OGL.git && \    
    git clone https://github.com/hpsim/OBR.git && \    
    pip install ./OBR                                  
                                                           
                                                           
# BUILD and install OGL                                             
RUN cd $HOME/OGL && \                                               
  source /usr/lib/openfoam/openfoam2206/etc/bashrc && \             
  cmake --preset ninja-cpuonly-release && \                         
  cmake --build --preset ninja-cpuonly-release  --target install    
                                                                    
# Create test cases                                               
# this creates a workspace folder with all the required           
# cases and variations as defined in the integration.yaml file    
RUN mkdir -p $HOME/OGL_integration_tests &&  cd $_ && \           
    source /usr/lib/openfoam/openfoam2206/etc/bashrc && \     
    obr init --config $HOME/OGL/test/integration.yaml && \    
    obr run -o generate                                       
                           
    
# Execute all unit test cases                                                                                                                              
# Execute all unit test cases    
# this might take a while since we set the debug flag    
RUN cd $HOME/OGL_integration_tests && \       
    source /usr/lib/openfoam/openfoam2206/etc/bashrc && \    
    obr run -o runParallelSolver              
                                              
# After running the test cases one can validate if the results     
# are reasonable                              
# in our CI/CD setup we do it by filtering different cases for a detailed example see    
# https://github.com/hpsim/OGL/blob/dev/.github/workflows/integration-tests.yml    
RUN cd $HOME/OGL_integration_tests && \    
    obr status && \    
    obr query \    
        --filter global==completed \
        -q global -q continuityErrors -q CourantNumber \    
        --validate_against=$HOME/OGL/test/validation.json
