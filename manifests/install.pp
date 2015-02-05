# Class: reviewboard::install
#
# This class installs various dependencies for reviewboard.
#
# == Variables
#
# Refer to the reviewboard class for the variables defined here.
#
# == Usage
#
# This class is not intended to be used directly.
#
class reviewboard::install inherits reviewboard {
  # RedHat requires the epel repo for python packages
  if ($::osfamily == 'RedHat') {
    include epel
    Class['epel'] -> Package[$reviewboard::_pkg_python_pip, $reviewboard::_pkg_python_dev]
  }

  # Install python pip installer
  ensure_packages($reviewboard::_pkg_python_pip)

  # Install python dev libs
  ensure_packages($reviewboard::_pkg_python_dev)

  # Configure dependencies for pip provider
  Package[$reviewboard::_pkg_python_pip, $reviewboard::_pkg_python_dev] -> Package<|provider==pip|>

  # Install Reviewboard
  exec {'install reviewboard':
    command => "easy_install '${reviewboard::_egg_url}'",
    unless  => "pip freeze | grep 'ReviewBoard==${reviewboard::version}'",
    path    => [ '/bin','/usr/bin' ],
    require => Package[$reviewboard::_pkg_python_pip],
  }

  # Install memcached unless requested otherwise
  if ($reviewboard::_pkg_memcached != undef) {
    ensure_packages($reviewboard::_pkg_memcached)
  }

  # Install CVS support if requested
  if member($reviewboard::_install_vcs, 'cvs') {
    ensure_packages($reviewboard::_pkg_vcs_cvs)
  }

  # Install SVN support if requested
  if member($reviewboard::_install_vcs, 'svn') {
    ensure_packages($reviewboard::_pkg_vcs_svn)
  }

  # Install git support if requested
  if member($reviewboard::_install_vcs, 'git') {
    ensure_packages($reviewboard::_pkg_vcs_git)
  }

  # Install mercurial support if requested
  if member($reviewboard::_install_vcs, 'mercurial') {
    ensure_packages($reviewboard::_pkg_vcs_mercurial)
  }

  # Install support for other VCS if requested
  if member($reviewboard::_install_vcs, 'other') {
    ensure_packages($reviewboard::pkg_vcs_other)
  }
}
