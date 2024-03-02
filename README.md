# Docker images for featured software pieces in the OpenFOAM Unit testing paper

This repository hosts docker files for building images of the software pieces used in the OpenFOAM Unit testing paper.
The images are built on top of a base image that has OpenFOAM installed in such a way the containers can participate
in Docker swarms and communicate through SSH and MPI.

|                                               | Description |
|-----------------------------------------------|-------------|
| [base.dockerfile](docker/base.dockerfile)     | Base image for OpenFOAM and MPI. |
| [foamut.dockerfile](docker/foamut.dockerfile) | Image for [foamUT](https://github.com/FoamScience/foamUT) and [blastAMR](https://github.com/STFS-TUDa/blastAMR).|
| [obr.dockerfile](docker/ogl_obr.dockerfile)   | Image for [OBR](https://github.com/hpsim/OBR). |
| [weno.dockerfile](docker/weno.dockerfile)     | Image for [WENOExt](https://github.com/WENO-OF/WENOEXT). |

To build the base image (inside the [docker](docker) folder):
```bash
docker build --build-arg OPENFOAM_VERSION=2206 -f base.dockerfile -t of-unit-testing-paper:base-2206 .
```
or, you can pull from Github registry:
```bash
docker pull ghcr.io/foamscience/of-unit-testing-paper:base-2206
```
The same applies to the other images; instead of `base`, use either `foamut`, `obr`, or `weno`.

Here is a list of published images you can immediately use:
- [of-unit-testing-paper:base-2206](https://github.com/FoamScience/of-unit-testing-paper/pkgs/container/of-unit-testing-paper/184606004?tag=base-2206)
- [of-unit-testing-paper:foamut-2206](https://github.com/FoamScience/of-unit-testing-paper/pkgs/container/of-unit-testing-paper/184608592?tag=foamut-2206)
- [of-unit-testing-paper:weno-2206](https://github.com/FoamScience/of-unit-testing-paper/pkgs/container/of-unit-testing-paper/184671721?tag=weno-2206)

## General Notes on the images

- By default, containers will start an SSH process to stay alive. If you prefer a shell instead, you can use:
    ```bash
    docker run -it --rm ghcr.io/foamscience/of-unit-testing-paper:base-2206 bash
    ```
- You will find OpenFOAM installed in `/usr/lib/openfoam` and the specific paper software piece in
  the home folder of the `openfoam` user.
- Thanks to some UID and GID magic, you can mount your local folders (preferably inside `/home/openfoam/data`)
  without worrying about file permission shenanigans.
- The features software pieces are frozen to hard-coded commits, if you want the latest versions, you can always
  fetch and pull the desired branch.

## Specific image notes

### blastAMR and foamUT

To test out `foamUT`, you can just `cd /home/openfoam/foamUT && ./Alltest`.

To run unit tests for `blastAMR`, you can do the following:
```bash
(openfoam@container)> cd ~/blastAMR
# create a test file with steps from the Github actions, see bellow
(openfoam@container)> vim Alltest
# Run the test file
(openfoam@container)> export FOAM_FOAMUT=/home/openfoam/foamUT
(openfoam@container)> ./Alltest
```
where `Alltest` is a BASH file with the following content (extracted from the Github action workflows):
```bash
#!/usr/bin/bash
mkdir -p $FOAM_USER_LIBBIN
./Allwmake
sed -i 's/mpirun/mpirun --oversubscribe/g' $FOAM_FOAMUT/Alltest
ln -s "$PWD"/tests/adaptiveFvMeshTests "$FOAM_FOAMUT/tests/adaptiveFvMeshTests"
rm -rf "$FOAM_FOAMUT/cases"
cp -r tests/testCases "$FOAM_FOAMUT/cases"
cd $FOAM_FOAMUT || exit 1
rm -rf tests/exampleTests
./Alltest "$@"
if [ -f $FOAM_FOAMUT/tests/adaptiveFvMeshTests/log.wmake ]; then cat $FOAM_FOAMUT/tests/adaptiveFvMeshTests/log.wmake; fi 
```

### WENOExt

**Note:** The WENOExt dockerfile will download and install WENOExt but not execute tests. This is due to one multicore test which requires at least 8 mpi slots**

Start the docker container in an interactive session:
```bash
docker run -it --rm ghcr.io/foamscience/of-unit-testing-paper:weno-2206 bash
```
Inside the container navigate to the WENOExt tests folder and execute the runTest command
```
(openfoam@container)> cd /home/openfoam/WENOExt/tests && ./runTest
```
This will run the most important unit and integration tests of WENOExt. There is also the option 
to run all tests with: 
```
(openfoam@container)> cd /home/openfoam/WENOExt/tests && ./runTest --runAll
```

### OGL/OBR
This section contains details of the docker file for the [OGL](https://github.com/hpsim/OGL) integration tests with [OBR](https://github.com/OBR).

**Note:** The docker file builds the complete workflow, including running the integration tests and doing data validation. The complete integration test folder can be found under `$HOME/OGL_integration_tests`. The folder contains a workspace folder with the integration test cases identified by a UID and a view folder with descriptive names of the test cases and symlinks to the original workspace folder. The view is structured as follows, with different subfolders representing different parameter variations.  

```
view/
`-- base
    |-- cavity
    |   |-- linearSolver
    |   |   `-- GKOCGnonereference
    |   |       `-- decomposition
    |   |           |-- scotch-8 -> ../../../../../../workspace/b1936074e6f9a8f60288b60a6161661e
    |   |           |-- simple-2 -> ../../../../../../workspace/64eba5418b557773e831b9de567fd7fb
    |   |           `-- simple-8 -> ../../../../../../workspace/d54a6083686b37d773263c771cf1ff35
    |   |-- matrixFormat
    |   |   |-- Csr -> ../../../../workspace/f4900c7aed8b77c2f51e27d20606a5cb
    |   |   `-- Ell -> ../../../../workspace/26cf0b6abd668aca841f45b97c744462
    |   `-- preconditioner
    |       |-- BJ -> ../../../../workspace/8fd1e23e6e9b5bdba4e00beb3522118c
    |       |-- GISAI -> ../../../../workspace/e22be50783dd41a2ac53a5513d38f074
    |       `-- ILU -> ../../../../workspace/d50855b021666504e6bc39cbc437f992
    `-- periodicPlaneChannel
        |-- linearSolver
        |   `-- GKOCGnonereference
        |       `-- decomposition
        |           |-- scotch-8 -> ../../../../../../workspace/9d906954c59d9a186b9f419bc1c7877a
        |           |-- simple-2 -> ../../../../../../workspace/971606d96eba44b5b9571752e2095a1a
        |           `-- simple-8 -> ../../../../../../workspace/55487f8d7b2b950da6e5bc388c56cda4
        |-- matrixFormat
        |   |-- Csr -> ../../../../workspace/94812a3cf3e12d1bb12e8825997a93fd
        |   `-- Ell -> ../../../../workspace/2eb7592339748028ac023915b06e4e7f
        `-- preconditioner
            |-- BJ -> ../../../../workspace/245dc39882db608fb0eddd286b14ae8a
            |-- GISAI -> ../../../../workspace/7d9204b713b87cdeb3681a68cb358a6f
            `-- ILU -> ../../../../workspace/e13b57a14604fc4bf9a637bc14cbd98f
```

Data validation is done with the following command. In this example the `continuityErrors` and the `CourntNumber` are validated against requirements specified in validation.json file.  

```
obr query \
    -q global -q continuityErrors -q CourantNumber \
    --validate_against=$HOME/OGL/test/validation.json
```

If one desires to rerun the test cases, one can use  `obr reset --case` to reset the workspace followedby `obr run -o runParallelSolver`. This will create a new set of log files which can again be validate  with the obr query command.
