#!/usr/bin/env python3

## eic_container: Argonne Universal EIC Container

'''
Deploy the singularity container built by the CI for this version of the software.

The current version is determined from the currently loaded git branch or tag,
unless it is explicitly set on the command line.

Authors:
    - Whitney Armstrong <warmstrong@anl.gov>
    - Sylvester Joosten <sjoosten@anl.gov>
'''

import os
import argparse
import re
import urllib.request

## Gitlab group and project/program name. 
DEFAULT_IMG='jug_xl'
DEFAULT_VERSION='3.0.1'

SHORTCUTS = ['eic-shell']

## URL for the current container (git tag will be filled in by the script)
## components:
##  - {ref}:
##      - branch/tag --> git branch or tag
##      - MR XX      --> refs/merge-requests/XX/head
##      - nightly    --> just use fallback singularity pull
##  - {img}: image name
##  - {job}: the CI job that built the artifact
CONTAINER_URL = r'https://eicweb.phy.anl.gov/api/v4/projects/290/jobs/artifacts/{ref}/raw/build/{img}.sif?job={job}'

## Docker ref is used as fallback in case regular artifact download fails
## The components are:
## - {img}: image name
## - {tag}: docker tag associated with image
##      - master        --> testing
##      - branch/tag    --> branch/tag without leading v
##      - MR XX         --> unstable (may be incorrect if multiple MRs active)
##      - nightly       --> nightly
DOCKER_REF = r'docker://eicweb/{img}:{tag}'

## Singularity bind directive
BIND_DIRECTIVE= '-B {0}:{0}'

class UnknownVersionError(Exception):
    pass
class ContainerDownloadError(Exception):
    pass
class InvalidArgumentError(Exception):
    pass

def smart_mkdir(dir):
    '''functions as mkdir -p, with a write-check.
    
    Raises an exception if the directory is not writeable.
    '''
    if not os.path.exists(dir):
        try:
            os.makedirs(dir)
        except Exception as e:
            print('ERROR: unable to create directory', dir)
            raise e
    if not os.access(dir, os.W_OK):
        print('ERROR: We do not have the write privileges to', dir)
        raise InvalidArgumentError()

## generic launcher bash script to launch the application
_LAUNCHER='''#!/usr/bin/env bash

## Boilerplate to make pipes work
piped_args=
if [ -p /dev/stdin ]; then
  # If we want to read the input line by line
  while IFS= read line; do
    if [ -z "$piped_args" ]; then
      piped_args="${{line}}"
    else 
      piped_args="${{piped_args}}\n${{line}}"
    fi
  done
fi

## Fire off the application wrapper
if [ ${{piped_args}} ]  ; then
    echo -e ${{piped_args}} | singularity exec {bind} {container} {exe} $@
else
    singularity exec {bind} {container} {exe} $@
fi
'''

def _write_script(path, content):
    print(' - creating', path)
    with open(path, 'w') as file:
        file.write(content)
    os.system('chmod +x {}'.format(path))
    
def make_launcher(app, container, bindir, 
                  bind='', exe=None):
    '''Configure and install a launcher.

    Generic launcher script to launch applications in this container.

    The launcher script calls the desired executable from the singularity image.
    As the new images have the environment properly setup, we can accomplish this
    without using any wrapper scripts.

    Arguments:
        - app: our application
        - container: absolute path to container
        - bindir: absolute launcher install path
    Optional:
        - bind: singularity bind directives
        - exe: executable to be associated with app. 
               Default is app.
        - env: environment directives to be added to the wrapper. 
               Multiline string. Default is nothing
    '''
    if not exe:
        exe = app

    ## paths
    launcher_path = '{}/{}'.format(bindir, app)

    ## scripts --> use absolute path for wrapper path inside launcher
    launcher = _LAUNCHER.format(container=container, 
                                bind=bind,
                                exe=exe)

    ## write our scripts
    _write_script(launcher_path, launcher)

## Generic module file
_MODULEFILE='''#%Module1.0#####################################################################
##
## for {name} {version}
##
proc ModulesHelp {{ }} {{
    puts stderr "This module sets up the environment for the {name} container"
}}
module-whatis "{name} {version}"

# For Tcl script use only
set version 4.1.4

prepend-path    PATH    {bindir}
'''

def make_modulefile(project, version, moduledir, bindir):
    '''Configure and install a modulefile for this project.

    Arguments:
        - project: project name
        - version: project version
        - moduledir: root modulefile directory
        - bindir: where executables for this project are located
    '''

    ## create our modulefile
    content = _MODULEFILE.format(name=project, version=version, bindir=bindir)
    fname = '{}/{}'.format(moduledir, version)
    print(' - creating', fname)
    with open(fname, 'w') as file:
        file.write(content)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
            'prefix',
            help='Install prefix. This is where the container will be deployed.')
    parser.add_argument(
            '-c', '--container',
            dest='container',
            default=DEFAULT_IMG,
            help='(opt.) Container to install. '
                 'D: {} (also available: jug_dev, and legacy "eic" container).')
    parser.add_argument(
            '-v', '--version',
            dest='version',
#            default=project_version(),
            default=DEFAULT_VERSION,
            help='(opt.) project version. '
                 'D: {}. For MRs, use mr-XXX.'.format(DEFAULT_VERSION))
    parser.add_argument(
            '-f', '--force',
            action='store_true',
            help='Force-overwrite already downloaded container',
            default=False)
    parser.add_argument(
            '-b', '--bind-path',
            dest='bind_paths',
            action='append',
            help='(opt.) extra bind paths for singularity.')
    parser.add_argument(
            '-m', '--module-path',
            dest='module_path',
            help='(opt.) Root module path to install a modulefile. '
                 'D: Do not install a modulefile')

    args = parser.parse_args()

    print('Deploying', args.container, 'version', args.version)

    ## Check if our bind paths are valid
    bind_directive = ''
    if args.bind_paths and len(args.bind_paths):
        print('Singularity bind paths:')
        for path in args.bind_paths:
            print(' -', path)
            if not os.path.exists(path):
                print('ERROR: path', path, 'does not exist.')
                raise InvalidArgumentError()
        bind_directive = ' '.join([BIND_DIRECTIVE.format(path) for path in args.bind_paths])

    ## Naming schemes:
    ## We need to deduce both the correct git branch and an appropriate
    ## local version number from the desired version number
    ## by default we use whatever version number is given in VERSION, but we want
    ## to allow users to specify either X.Y.Z or vX.Y.Z for versions (same for stable
    ## branches).
    ## 
    ## Policy:
    ## numbered releases: (v)X.Y.Z --> git vX.Y.Z and local X.Y.Z
    ## stable branches: (v)X.Y-stable --> git vX.Y-stable and local X.Y-stable
    ## master branch: latest/master --> git master and local stable
    ## for other branches --> git <BRANCH> and local unstable

    version_docker = None
    version_gitlab = None
    build_job = '{}:singularity:default'.format(args.container)
    ## firs tlook for spacialty containers
    if args.container == 'acts_material_scan':
        version_docker = args.version
        version_gitlab = args.container
    elif args.version in ('master', 'testing'):
        version_docker = 'testing'
        version_gitlab = 'master'
    elif re.search('[0-9]+\.[0-9]+\.[0-9]|[0-9]+\.[0-9]-stable', args.version) is not None:
        version_docker = args.version
        version_gitlab = args.version
        if version_docker[0] == 'v':
            version_docker = version_docker[1:]
        if version_gitlab[0].isdigit():
            version_gitlab = 'v{}'.format(args.version)
    elif args.version[:3] == 'mr-':
        version_docker = 'unstable'
        version_gitlab = 'refs/merge-requests/{}/head'.format(args.version[3:])
    elif args.version == 'nightly':
        version_docker = 'nightly'
        version_gitlab = 'master'
        build_job = '{}:singularity:nightly'.format(args.container)
    else:
        ## fixme add proper error handling
        print('Unknown requested version:', args.version)
        raise UnknownVersionError()

    ## 'master' is always docker-tagged as testing
    if version_docker == 'master':
        version_docker = testing

    ## when working with the old container, the build job is just 'singularity'
    if args.container == 'eic':
        build_job = 'singularity'

    ## Create our install prefix if needed and ensure it is writable
    args.prefix = os.path.abspath(args.prefix)
    if not args.module_path:
        deploy_local=True
    else:
        deploy_local=False
    print('Install prefix:', args.prefix)
    print('Creating install prefix if needed...')
    bindir = '{}/bin'.format(args.prefix)
    libdir = '{}/lib'.format(args.prefix)
    libexecdir = '{}/libexec'.format(args.prefix)
    root_prefix = os.path.abspath('{}/..'.format(args.prefix))
    dirs = [bindir, libdir, libexecdir]
    if not deploy_local:
        moduledir = '{}/{}'.format(args.module_path, args.container)
        dirs.append(moduledir)
    for dir in dirs:
        print(' -', dir)
        smart_mkdir(dir)

    ## At this point we know we can write to our desired prefix and that we have a set of
    ## valid bind paths

    ## Get the container
    ## We want to slightly modify our version specifier: if it leads with a 'v' drop the v
    img = args.container
    ## Builder SIF is not built anymore, deprecated
    #if args.builder:
        #img += "_builder"
    container = '{}/{}-{}.sif'.format(libdir, img, version_docker)
    if not os.path.exists(container) or args.force:
        url = CONTAINER_URL.format(ref=version_gitlab, img=img, job=build_job)
        print('Downloading container from:', url)
        print('Destination:', container)
        try:
            urllib.request.urlretrieve(url, container)
        except:
            print('WARNING: failed to retrieve container artifact')
            print('Attempting alternative download from docker registry')
            cmd = ['singularity pull', '--force', container, DOCKER_REF.format(img=img, tag=version_docker)]
            cmd = ' '.join(cmd)
            print('Executing:', cmd)
            err = os.system(cmd)
            if err:
                raise ContainerDownloadError()
    else:
        print('WARNING: Container found at', container)
        print(' ---> run with -f to force a re-download')

    if not deploy_local:
        make_modulefile(args.container, version_docker, moduledir, bindir)

    ## configure the application launchers
    print('Configuring applications launchers: ')
    for prog in SHORTCUTS:
        app = prog
        exe = prog
        if type(prog) == tuple:
            app = prog[0]
            exe = prog[1]
        make_launcher(app, container, bindir,
                      bind=bind_directive,
                      exe=exe)

    print('Container deployment successful!')
