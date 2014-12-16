require 'spec_helper'

describe 'reviewboard' do
  let (:facts) { $default_facts }

  context 'with default parameters' do
    it { should compile.with_all_deps }
    it { should contain_class('reviewboard') }
    it { should contain_class('reviewboard::package') }
  end
end
