"""
Require Python2 >= 2.6.6
"""
from __future__ import print_function
from pipes import quote
import commands # b/c we are missing subprocess.check_output
import collections
import contextlib
import os
import re
import shlex
import shutil
import signal
import subprocess
import sys
import warnings

__all__ = [] #['cd', 'log', 'system', 'capture', 'symlink', 'mkdirp', 'safeRm', 'safeRmTree', 'updatesymlinks', 'recdefaultdict']


recdefaultdict = lambda: collections.defaultdict(recdefaultdict)


def log(*msgs):
    sys.stderr.write(' '.join(str(m) for m in msgs) + '\n')


__cdIndent = 0
@contextlib.contextmanager
def cd(path):
    global __cdIndent
    cwd = os.getcwd()
    log('[%d] %r -> %r' %(__cdIndent, cwd, path))
    os.chdir(path)
    __cdIndent += 1
    yield
    os.chdir(cwd)
    __cdIndent -= 1
    log('[%d] %r <- %r' %(__cdIndent, cwd, path))


def system(call, dry_run=False):
    log('system(%r)' %(call))
    if not dry_run:
        subprocess.check_call(call, shell=True)


def mkdirp(dirpath):
    if not os.path.isdir(dirpath):
        os.makedirs(dirpath)
    assert os.path.isdir(dirpath)


def safeRm(path):
    if os.path.exists(path):
        log('rm -f %r' %(path))
        os.unlink(path)


def safeRmTree(dirpath):
    if os.path.exists(dirpath):
        log('rm -rf %r' %(dirpath))
        assert os.getcwd() in os.path.abspath(dirpath), dirpath
        shutil.rmtree(dirpath)


def symlink(src, dst):
    """Link from src to dst.
    Fail if any dst path exists and is not a symlink.
    """
    log('ln -sf %r %r' %(
        src, dst))
    if os.path.islink(dst):
        os.unlink(dst)
    os.symlink(src, dst)


def capture(call):
    """
    For discussion of SIGPIPE, see:
      http://bugs.python.org/issue1652
    """
    log('`%s`' %(call))
    prev = signal.getsignal(signal.SIGPIPE)
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    try:
        #output = subprocess.check_output(call, shell=True)
        # no check_output in Python2.6.6
        # Why do we need a shell? I do not remember. Try without.
        status, output = commands.getstatusoutput(call)
        if status:
            raise Exception('%d <= %r' %(status, call))
    except:
        signal.signal(signal.SIGPIPE, prev)
        raise
    return output


def updatesymlinks(to_dir, from_dir, names=None):
    """Unless 'names' is not None, symlink everything in 'to_dir'.
    """
    if names is None:
        names = os.listdir(to_dir)
    for name in names:
        symlink(os.path.join(to_dir, name),
                os.path.join(from_dir, name))


def getgithubname(remote):
    """
    >>> getgithubname('git@github.com:PacBio/Foo.git')
    'PacBio/Foo'
    >>> getgithubname('git://github.com/PacBio/Bar')
    'PacBio/Bar'
    """
    re_remote = re.compile(r'github\.com.(.*)$')
    githubname = re_remote.search(remote).group(1)
    if githubname.endswith('.git'):
        githubname = githubname[:-4]
    if '/' not in githubname:
        warnings.warn('%r does not look like a github name. It should be "account/repo". It came from %r'%(
            githubname, remote))
    return githubname


def summary2table(summary):
    """
    * pith a4069a7...882571f (1):
      > copied some files from my-ws
    
    =>
    {'pith': 'a4069a7...882571f'}
    """
    table = dict()
    re_sha1line = re.compile('^\*\s+(\S+)\s+(\S+)')
    for mo in re_sha1line.finditer(summary):
        name, crange = mo.groups()
        table[name] = crange
    return table


def yield_compare_urls(cached=True):
    """For all cached submodules, yield links like this:
        'https://github.com/PacificBiosciences/pith/compare/a4069a7...882571f'
    """
    flags = ' --cached' if cached else ''
    commit_table = summary2table(capture('git submodule summary%s' %(
        flags)))
    for (name, crange) in commit_table.items():
        url = capture('git config submodule.%s.url' %(
            name))
        githubname = getgithubname(url)
        compare_url = 'https://github.com/%s/compare/%s' %(
            githubname, crange)
        yield compare_url
