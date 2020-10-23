require 'spec_helper'

describe Puppet::Moddeps::Installer do

  before(:all) do
    if (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RbConfig::CONFIG['host_os']) != nil
      @expected_path = %x(puppet config print modulepath).split(';')[0].strip
    else
      @expected_path = %x(puppet config print modulepath).split(':')[0].strip
    end
  end

  describe '.initialize(module_path, puppet_version)' do
    it 'should set the default module path and puppet version' do
      base_obj = Puppet::Moddeps::Installer.new

      expect(base_obj.module_path).to eq(@expected_path)
      expect(base_obj.puppet_version).to be_nil
    end

    it 'should use the provided values' do
      base_obj = Puppet::Moddeps::Installer.new('/tmp', '6.18.0')
      expect(base_obj.module_path).to eq('/tmp')
      expect(base_obj.puppet_version).to eq('6.18.0')
    end

    it 'should fail when an array is passed to path' do
      expect {
        Puppet::Moddeps::Installer.new(['path1', 'path2'])
      }.to raise_error(SystemExit, 'The provided module path was not a string.' )
    end

    it 'should fail when an array is passed to puppet_version' do
      expect {
        Puppet::Moddeps::Installer.new('/tmp', ['arg1', 'arg2'])
      }.to raise_error(SystemExit, 'The provided puppet version was not a string.' )
    end
  end

  describe '.install(puppet_module) feedback verification' do
    before(:each) do
      @base_object = Puppet::Moddeps::Installer.new
    end

    context 'with no parameters' do
      it 'should print usage info' do
        expect { @base_object.install }.to raise_error(SystemExit, /Usage.*/)
      end
    end

    it 'should print usage if an element of the array is not a string' do
      allow(@base_object).to receive(:installed?).and_return(true)
      expect { @base_object.install(['arg1', ['arg2']]) }.to raise_error(SystemExit, /Usage.*/)
      expect { @base_object.install([['arg1'], 'arg2']) }.to raise_error(SystemExit, /Usage.*/)
      expect { @base_object.install([{'arg1' => 'arg2'}]) }.to raise_error(SystemExit, /Usage.*/)
    end

    it 'should print usage if an empty array is passed in' do
      params = []
      expect { @base_object.install(params) }.to raise_error(SystemExit, /Usage.*/)
    end

    it 'should fail if the parameter is not an installed module' do
      expect { @base_object.install(['fake_missing_module']) }.to raise_error(SystemExit, /Can\'t find fake_missing_module in.*/)
    end
  end

  describe '.path_separator' do

    subject { Puppet::Moddeps::Installer.new }

    context 'on Windows' do
      it 'should return ; as the path separator' do
        expect(subject.path_separator('mingw32')).to eq(';')
      end
    end

    context 'on Linux' do
      it 'should return : as the path separator' do
        expect(subject.path_separator('linux-gnu')).to eq(':')
      end
    end
  end

  describe '.install Puppet modules' do
     it "should install dependencies for a single module" do
       base_object = Puppet::Moddeps::Installer.new
       module_to_install = Puppet::Moddeps::Module.new("owner", "name", "version")
       allow(base_object).to receive(:installed?).and_return(true)
       allow(base_object).to receive(:module_versions_match?).and_return(false)
       allow(base_object).to receive(:resolve_local_module_deps).and_return([module_to_install])
       allow(base_object).to receive(:call_puppet)

       apache_model = double('model')
       allow(apache_model).to receive(:title).and_return('apache')
       allow(apache_model).to receive(:name).and_return('apache')
       allow(apache_model).to receive(:version).and_return('5.6.0')
       allow(apache_model).to receive(:module_type).and_return(:local)
       allow(apache_model).to receive(:resolver_flags).and_return([])
       allow(PuppetfileResolver::Puppetfile::LocalModule).to receive(:new).with('apache').and_return(apache_model)

       base_object.install(['apache'])
       expect(base_object).to have_received(:call_puppet).at_least(:once)
     end

     it "should install dependencies for multiple modules" do
       base_object = Puppet::Moddeps::Installer.new
       module_to_install = Puppet::Moddeps::Module.new("owner", "name", "version")
       allow(base_object).to receive(:installed?).and_return(true)
       allow(base_object).to receive(:module_versions_match?).and_return(false)
       allow(base_object).to receive(:resolve_local_module_deps).and_return([module_to_install])
       allow(base_object).to receive(:call_puppet)

       apache_model = double('model')
       allow(apache_model).to receive(:title).and_return('apache')
       allow(apache_model).to receive(:name).and_return('apache')
       allow(apache_model).to receive(:version).and_return('5.6.0')
       allow(apache_model).to receive(:module_type).and_return(:local)
       allow(apache_model).to receive(:resolver_flags).and_return([])
       allow(PuppetfileResolver::Puppetfile::LocalModule).to receive(:new).with('apache').and_return(apache_model)

       nginx_model = double('model')
       allow(nginx_model).to receive(:title).and_return('nginx')
       allow(nginx_model).to receive(:name).and_return('nginx')
       allow(nginx_model).to receive(:version).and_return('2.0.0')
       allow(nginx_model).to receive(:module_type).and_return(:local)
       allow(nginx_model).to receive(:resolver_flags).and_return([])
       allow(PuppetfileResolver::Puppetfile::LocalModule).to receive(:new).with('nginx').and_return(nginx_model)

       base_object.install(['apache', 'nginx'])
       expect(base_object).to have_received(:call_puppet).at_least(:once)
     end
  end
end
