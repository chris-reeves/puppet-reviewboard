require 'spec_helper'

describe 'reviewboard' do
  let (:facts) { $default_facts }

  it { should contain_class('reviewboard') }
end
