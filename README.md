# Documentation

This repository provides:
1. bash script for building [Codethink's GCC](https://github.com/CodethinkLabs/gcc)
   with [Omnibus](https://github.com/CodethinkLabs/omnibus-codethink-toolchain)
   (gcc_omnibus_build_script.sh).
    - Example usage: `./gcc_omnibus_build_script -g "fortran-extra-legacy-7.2"`.
2. bash script for running available tests suites for Codethink's GCC
   (gcc_test_script.sh).
3. bash script for deploying directory with artifacts to a deployment server.
    - Example usage:
        ```
        ./gcc_deployment_script.sh
            -a "/home/deployment/artifacts"
            -n "gcc"
            -g "1.0"
            -u "deployment"
            -i "10.24.4.3"
            -t "/home/deployment/server"
         ```
