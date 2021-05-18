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
from install import make_launcher, make_modulefile
from install.util import smart_mkdir, project_version, InvalidArgumentError

## Gitlab group and project/program name. 
DEFAULT_IMG='eic'
DEFAULT_VERSION='2.9.2'

SHORTCUTS = ['eic-shell']

## URL for the current container (git tag will be filled in by the script)
## components:
##  - {ref}:
##      - branch/tag --> git branch or tag
##      - MR XX      --> refs/merge-requests/XX/head
##      - nightly    --> just use fallback singularity pull
##  - {img}: image name
##  - {job}: the CI job that built the artifact
CONTAINER_URL = r'hhttps://eicweb.phy.anl.gov/api/v4/projects/290/jobs/artifacts/{ref}/raw/build/{img}.sif?job={job}'

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
                 'D: {} (will migrate to jug_xl for v3.0).'.format(DEFAULT_IMG))
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
    if args.version in ('master', 'testing'):
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
    container = '{}/{}.sif.{}'.format(libdir, img, version_docker)
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
