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

  # Install memcached unless requested otherwise
  if ($reviewboard::_pkg_memcached != undef) {
    package { $reviewboard::_pkg_memcached:
      ensure => installed,
    }
  }

  # Install Reviewboard
  exec {'install reviewboard':
    command => "easy_install '${reviewboard::_egg_url}'",
    unless  => "pip freeze | grep 'ReviewBoard==${reviewboard::version}'",
    path    => [ '/bin','/usr/bin' ],
    require => Package[$reviewboard::_pkg_python_pip],
  }
}
