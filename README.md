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
