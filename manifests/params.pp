# Class: reviewboard::params
#
# This class defines default parameters used by the main module class
# reviewboard. OS differences in names and paths are addressed here.
#
# == Variables
#
# Refer to the reviewboard class for the variables defined here.
#
# == Usage
#
# This class is not intended to be used directly.
# It may be imported or inherited by other classes
#
class reviewboard::params {
  case $::osfamily {
    'Debian': {
      $rbsitepath = '/usr/local/bin'
      $pkg_python_pip = 'python-pip'
      $pkg_python_dev = 'python-dev'
      $pkg_memcached = [ 'memcached', 'python-memcache' ]
      $pkg_vcs_cvs = 'cvs'
      $pkg_vcs_svn = [ 'subversion', 'python-svn']
      $pkg_vcs_git = 'git'
      $pkg_vcs_mercurial = 'mercurial'
    }
    'RedHat': {
      $rbsitepath = '/usr/bin'
      $pkg_python_pip = 'python-pip'
      $pkg_python_dev = 'python-devel'
      $pkg_memcached = [ 'memcached', 'python-memcached' ]
      $pkg_vcs_cvs = 'cvs'
      $pkg_vcs_svn = [ 'subversion', 'pysvn']
      $pkg_vcs_git = 'git'
      $pkg_vcs_mercurial = 'mercurial'
    }
    default: {
      fail("Reviewboard module has not been tested on OS ${::osfamily}")
    }
  }
}
