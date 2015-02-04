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
  package { $reviewboard::_pkg_python_pip:
    ensure => installed,
  }

  # Install python dev libs
  package { $reviewboard::_pkg_python_dev:
    ensure => installed,
  }

  # Configure dependencies for pip provider
  Package[$reviewboard::_pkg_python_pip, $reviewboard::_pkg_python_dev] -> Package<|provider==pip|>

  # Install memcached
  package { $reviewboard::_pkg_memcache:
    ensure => installed,
  }

  class { 'reviewboard::package':
    version        => $reviewboard::version,
    pkg_python_pip => $reviewboard::_pkg_python_pip,
  }
}
