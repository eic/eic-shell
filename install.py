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
GROUP_NAME='containers'
PROJECT_NAME='eic_container'
IMAGE_ROOT='eic'

PROGRAMS = ['eic-shell',
            'container_dev',
            #'root', 
            'ipython']

## URL for the current container (git tag will be filled in by the script)
CONTAINER_URL = r'https://eicweb.phy.anl.gov/api/v4/projects/290/jobs/artifacts/{version}/raw/build/{img}.sif?job=singularity'
#api/v4/projects/1/jobs/artifacts/master/raw/some/release/file.pdf

## Singularity bind directive
BIND_DIRECTIVE= '-B {0}:{0}'

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
            'prefix',
            help='Install prefix. This is where the container will be deployed.')
    parser.add_argument(
            '-v', '--version',
            dest='version',
            default=project_version(),
            help='(opt.) project version. Default: current version (in repo).')
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
            help='(opt.) Root module path where you want to install a modulefile. D: <prefix>/../../etc/modulefiles')
    parser.add_argument(
            '-l', '--local',
            action='store_true',
            dest='local',
            help='Local deploy, will not install the modulefiles (you will have to run'
                  'the launchers scripts from their relative paths).')
    ## deprecated, we should just make sure the release image is good enough
    ## builder singularity image will most likely be removed from the CI
    ## in a future release
    #parser.add_argument(
            #'--install-builder',
            #dest='builder',
            #help='(opt.) Install fat builder image, instead of normal slim image')

    args = parser.parse_args()

    print('Deploying', PROJECT_NAME, 'version', args.version)

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

    version_local = None
    version_repo = None
    if args.version in ('master', 'latest'):
        version_local = 'latest'
        version_repo = 'master'
    elif re.search('[0-9]+\.[0-9]+\.[0-9]|[0-9]+\.[0-9]-stable', args.version) is not None:
        version_local = args.version
        version_repo = args.version
        if version_local[0] == 'v':
            version_local = version_local[1:]
        if version_repo[0].isdigit():
            version_repo = 'v{}'.format(args.version)
    else:
        version_local = 'unstable'
        version_repo = args.version

    ## Create our install prefix if needed and ensure it is writable
    args.prefix = os.path.abspath(args.prefix)
    if not args.module_path:
        args.module_path = os.path.abspath('{}/../../etc/modulefiles'.format(args.prefix))
    print('Install prefix:', args.prefix)
    print('Creating install prefix if needed...')
    bindir = '{}/bin'.format(args.prefix)
    libdir = '{}/lib'.format(args.prefix)
    libexecdir = '{}/libexec'.format(args.prefix)
    root_prefix = os.path.abspath('{}/..'.format(args.prefix))
    moduledir = '{}/{}'.format(args.module_path, PROJECT_NAME)
    dirs = [bindir, libdir, libexecdir]
    if not args.local:
        dirs.append(moduledir)
    for dir in dirs:
        print(' -', dir)
        smart_mkdir(dir)

    ## At this point we know we can write to our desired prefix and that we have a set of
    ## valid bind paths

    ## Get the container
    ## We want to slightly modify our version specifier: if it leads with a 'v' drop the v
    img = IMAGE_ROOT
    ## Builder SIF is not built anymore, deprecated
    #if args.builder:
        #img += "_builder"
    container = '{}/{}.sif.{}'.format(libdir, img, version_local)
    if not os.path.exists(container) or args.force:
        url = CONTAINER_URL.format(group=GROUP_NAME, project=PROJECT_NAME,
                version=version_repo, img=img)
        print('Downloading container from:', url)
        print('Destination:', container)
        urllib.request.urlretrieve(url, container)
    else:
        print('WARNING: Container found at', container)
        print(' ---> run with -f to force a re-download')

    if not args.local:
        make_modulefile(PROJECT_NAME, version_local, moduledir, bindir)

    ## configure the application launchers
    print('Configuring applications launchers: ')
    for prog in PROGRAMS:
        app = prog
        exe = prog
        if type(prog) == tuple:
            app = prog[0]
            exe = prog[1]
        make_launcher(app, container, bindir,
                      bind=bind_directive,
                      exe=exe)

    print('Container deployment successful!')
