require "spec_helper"
require "pathname"
require "shellwords"

RSpec.describe(Tapioca::Cli) do
  let(:outdir) { @outdir }
  let(:repo_path) { Pathname.new(__dir__) / ".." / "support" / "repo" }
  let(:exe_path) { Pathname.new(__dir__) / ".." / ".." / "exe" }
  let(:exec_command) { @exec_command.join(" ") }

  def run(command, args = [], flags = {})
    Dir.chdir(exe_path) do
      flags = {
        outdir: outdir,
        gemfile: (repo_path / "Gemfile").to_s
      }.merge(flags)

      @exec_command = [
        "tapioca",
        command,
        *flags.flat_map { |k,v| ["--#{k}", v] },
        *args
      ]
      IO.popen(@exec_command).read
    end
  end

  around(:each) do |example|
    Dir.mktmpdir do |outdir|
      @outdir = outdir
      example.run
    end
  end

  describe("#generate") do
    def foo_rbi_contents
      <<~CONTENTS
        # This file is autogenerated. Do not edit it by hand. Regenerate it with:
        #   #{exec_command}

        # typed: true

        module Foo
          def self.bar(a = _, b: _, **opts); end
        end

        Foo::PI = T.let(T.unsafe(nil), Float)
      CONTENTS
    end

    def bar_rbi_contents
      <<~CONTENTS
        # This file is autogenerated. Do not edit it by hand. Regenerate it with:
        #   #{exec_command}

        # typed: true

        module Bar
          def self.bar(a = _, b: _, **opts); end
        end

        Bar::PI = T.let(T.unsafe(nil), Float)
      CONTENTS
    end

    def baz_rbi_contents
      <<~CONTENTS
        # This file is autogenerated. Do not edit it by hand. Regenerate it with:
        #   #{exec_command}

        # typed: true

        module Baz
        end

        class Baz::Test
          def fizz; end
        end
      CONTENTS
    end

    it 'must generate a single gem RBI' do
      output = run("generate", "foo")

      expect(File).to     exist("#{outdir}/foo@0.0.1.rbi")

      expect(File.read("#{outdir}/foo@0.0.1.rbi"))
        .to eq(foo_rbi_contents)

      expect(File).to_not exist("#{outdir}/bar@0.3.0.rbi")
      expect(File).to_not exist("#{outdir}/baz@0.0.2.rbi")
    end

    it 'must perform postrequire properly' do
      output = run("generate", "foo", postrequire: (repo_path / "postrequire.rb").to_s)

      expect(File).to     exist("#{outdir}/foo@0.0.1.rbi")

      expect(File.read("#{outdir}/foo@0.0.1.rbi")).to eq(<<~CONTENTS)
        #{foo_rbi_contents}
        class Foo::Secret
        end

        Foo::Secret::VALUE = T.let(T.unsafe(nil), Integer)
      CONTENTS

      expect(File).to_not exist("#{outdir}/bar@0.3.0.rbi")
      expect(File).to_not exist("#{outdir}/baz@0.0.2.rbi")
    end

    it 'must generate multiple gem RBIs' do
      output = run("generate", ["foo", "bar"])

      expect(File).to     exist("#{outdir}/foo@0.0.1.rbi")
      expect(File).to     exist("#{outdir}/bar@0.3.0.rbi")

      expect(File.read("#{outdir}/foo@0.0.1.rbi")).to eq(foo_rbi_contents)
      expect(File.read("#{outdir}/bar@0.3.0.rbi")).to eq(bar_rbi_contents)

      expect(File).to_not exist("#{outdir}/baz@0.0.2.rbi")
    end

    it 'must generate RBIs for all gems in the Gemfile' do
      output = run("generate")

      expect(File).to exist("#{outdir}/foo@0.0.1.rbi")
      expect(File).to exist("#{outdir}/bar@0.3.0.rbi")
      expect(File).to exist("#{outdir}/baz@0.0.2.rbi")

      expect(File.read("#{outdir}/foo@0.0.1.rbi")).to eq(foo_rbi_contents)
      expect(File.read("#{outdir}/bar@0.3.0.rbi")).to eq(bar_rbi_contents)
      expect(File.read("#{outdir}/baz@0.0.2.rbi")).to eq(baz_rbi_contents)
    end
  end

  describe("#bundle") do
    it 'must perform no operations if everything is up-to-date' do
      %w{
        foo@0.0.1.rbi
        bar@0.3.0.rbi
        baz@0.0.2.rbi
      }.each do |rbi|
        FileUtils.touch "#{outdir}/#{rbi}"
      end

      output = run("bundle")

      expect(output).to_not   include("-- Removing:")
      expect(output).to_not   include("++ Adding:")
      expect(output).to_not   include("-> Moving:")

      expect(output).to   include(<<~OUTPUT)
        Removing RBI files of gems that have been removed:

          Nothing to do.
      OUTPUT
      expect(output).to   include(<<~OUTPUT)
        Generating RBI files of gems that are added or updated:

          Nothing to do.
      OUTPUT

      expect(File).to     exist("#{outdir}/foo@0.0.1.rbi")
      expect(File).to     exist("#{outdir}/bar@0.3.0.rbi")
      expect(File).to     exist("#{outdir}/baz@0.0.2.rbi")
      expect(File).to_not exist("#{outdir}/outdated@5.0.0.rbi")
    end

    it 'must remove outdated RBIs' do
      %w{
        foo@0.0.1.rbi
        bar@0.3.0.rbi
        baz@0.0.2.rbi
        outdated@5.0.0.rbi
      }.each do |rbi|
        FileUtils.touch "#{outdir}/#{rbi}"
      end

      output = run("bundle")

      expect(output).to   include("-- Removing: #{outdir}/outdated@5.0.0.rbi\n")
      expect(output).to_not   include("++ Adding:")
      expect(output).to_not   include("-> Moving:")

      expect(output).to   include(<<~OUTPUT)
        Generating RBI files of gems that are added or updated:

          Nothing to do.
      OUTPUT

      expect(File).to     exist("#{outdir}/foo@0.0.1.rbi")
      expect(File).to     exist("#{outdir}/bar@0.3.0.rbi")
      expect(File).to     exist("#{outdir}/baz@0.0.2.rbi")
      expect(File).to_not exist("#{outdir}/outdated@5.0.0.rbi")
    end

    it 'must add missing RBIs' do
      %w{
        foo@0.0.1.rbi
      }.each do |rbi|
        FileUtils.touch "#{outdir}/#{rbi}"
      end

      output = run("bundle")

      expect(output).to   include("++ Adding: #{outdir}/bar@0.3.0.rbi\n")
      expect(output).to   include("++ Adding: #{outdir}/baz@0.0.2.rbi\n")
      expect(output).to_not   include("-- Removing:")
      expect(output).to_not   include("-> Moving:")

      expect(output).to   include(<<~OUTPUT)
        Removing RBI files of gems that have been removed:

          Nothing to do.
      OUTPUT

      expect(File).to     exist("#{outdir}/foo@0.0.1.rbi")
      expect(File).to     exist("#{outdir}/bar@0.3.0.rbi")
      expect(File).to     exist("#{outdir}/baz@0.0.2.rbi")
    end

    it 'must move outdated RBIs' do
      %w{
        foo@0.0.1.rbi
        bar@0.0.1.rbi
        baz@0.0.1.rbi
      }.each do |rbi|
        FileUtils.touch "#{outdir}/#{rbi}"
      end

      output = run("bundle")

      expect(output).to   include("-> Moving: #{outdir}/bar@0.0.1.rbi to #{outdir}/bar@0.3.0.rbi\n")
      expect(output).to   include("++ Adding: #{outdir}/bar@0.3.0.rbi\n")
      expect(output).to   include("-> Moving: #{outdir}/baz@0.0.1.rbi to #{outdir}/baz@0.0.2.rbi\n")
      expect(output).to   include("++ Adding: #{outdir}/baz@0.0.2.rbi\n")
      expect(output).to_not   include("-- Removing:")

      expect(output).to   include(<<~OUTPUT)
        Removing RBI files of gems that have been removed:

          Nothing to do.
      OUTPUT

      expect(File).to     exist("#{outdir}/foo@0.0.1.rbi")
      expect(File).to     exist("#{outdir}/bar@0.3.0.rbi")
      expect(File).to     exist("#{outdir}/baz@0.0.2.rbi")

      expect(File).to_not exist("#{outdir}/bar@0.0.1.rbi")
      expect(File).to_not exist("#{outdir}/baz@0.0.1.rbi")
    end
  end
end
