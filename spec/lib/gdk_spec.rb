# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK do
  let(:hooks) { %w[date] }

  before do
    stub_pg_bindir
    allow(described_class).to receive(:install_root_ok?).and_return(true)
  end

  def expect_exec(input, cmdline)
    expect(subject).to receive(:exec).with(*cmdline)

    ARGV.replace(input)
    subject.main
  end

  describe '.main' do
    GDK::Command::COMMANDS.each do |command, command_class_proc|
      context "when invoking 'gdk #{command}' from command-line" do
        it "delegates execution to #{command_class_proc.call}" do
          stub_const('ARGV', [command])

          expect_any_instance_of(command_class_proc.call).to receive(:run)
          described_class.main
        end
      end
    end
  end

  describe '.validate_yaml!' do
    let(:raw_yaml) { nil }

    before do
      described_class.instance_variable_set(:@config, nil)
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with('gdk.example.yml').and_return(raw_yaml)
    end

    context 'with valid YAML' do
      let(:raw_yaml) { "---\ngdk:\n  debug: true" }

      it 'returns nil' do
        expect(described_class.validate_yaml!).to be_nil
      end
    end

    shared_examples 'invalid YAML' do |error_message|
      it 'prints an error' do
        expect(GDK::Output).to receive(:error).with("Your gdk.yml is invalid.\n\n")
        expect(GDK::Output).to receive(:puts).with(error_message, stderr: true)

        expect { described_class.validate_yaml! }.to raise_error(SystemExit).and output("\n").to_stderr
      end
    end

    context 'with invalid YAML' do
      let(:raw_yaml) { "---\ngdk:\n  debug" }

      it_behaves_like 'invalid YAML', %(undefined method `fetch' for "debug":String)
    end

    context 'with partially invalid YAML' do
      let(:raw_yaml) { "---\ngdk:\n  debug: fals" }

      it_behaves_like 'invalid YAML', "Value 'fals' for gdk.debug is not a valid bool"
    end
  end

  describe '.execute_hooks' do
    it 'calls execute_hook_cmd for each cmd and returns true' do
      cmd = 'echo'
      description = 'example'

      allow(described_class).to receive(:execute_hook_cmd).with(cmd, description).and_return(true)

      expect(described_class.execute_hooks([cmd], description)).to be(true)
    end
  end

  describe '.execute_hook_cmd' do
    let(:cmd) { 'echo' }
    let(:description) { 'example' }

    before do
      stub_tty(false)
    end

    context 'when cmd is not a string' do
      it 'aborts with error message' do
        error_message = %(ERROR: Cannot execute 'example' hook '\\["echo"\\]')

        expect { described_class.execute_hook_cmd([cmd], description) }.to raise_error(/#{error_message}/).and output(/#{error_message}/).to_stderr
      end
    end

    context 'when cmd is a string' do
      context 'when cmd does not exist' do
        it 'aborts with error message', :hide_stdout do
          error_message = %(ERROR: No such file or directory - fail)

          expect { described_class.execute_hook_cmd('fail', description) }.to raise_error(/#{error_message}/).and output(/#{error_message}/).to_stderr
        end
      end

      context 'when cmd fails' do
        it 'aborts with error message', :hide_stdout do
          error_message = %(ERROR: 'false' has exited with code 1.)

          expect { described_class.execute_hook_cmd('false', description) }.to raise_error(/#{error_message}/).and output(/#{error_message}/).to_stderr
        end
      end

      context 'when cmd succeeds' do
        it 'returns true', :hide_stdout do
          expect(described_class.execute_hook_cmd(cmd, description)).to be(true)
        end
      end
    end
  end

  describe '.with_hooks' do
    it 'returns true' do
      before_hooks = %w[date]
      after_hooks = %w[uptime]
      hooks = { before: before_hooks, after: after_hooks }
      name = 'example'

      expect(described_class).to receive(:execute_hooks).with(before_hooks, "#{name}: before").and_return(true)
      expect(described_class).to receive(:execute_hooks).with(after_hooks, "#{name}: after").and_return(true)

      expect(described_class.with_hooks(hooks, name) { true }).to be(true)
    end
  end
end
