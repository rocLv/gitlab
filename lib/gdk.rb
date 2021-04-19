# frozen_string_literal: true

# GitLab Development Kit CLI parser / executor
#
# This file is loaded by the 'gdk' command in the gem. This file is NOT
# part of the gitlab-development-kit gem so that we can iterate faster.

$LOAD_PATH.unshift(__dir__)

require 'pathname'
require 'securerandom'
require_relative 'runit'
autoload :Shellout, 'shellout'

# GitLab Development Kit
module GDK
  HookCommandError = Class.new(StandardError)

  PROGNAME = 'gdk'
  MAKE = RUBY_PLATFORM.include?('bsd') ? 'gmake' : 'make'

  # dependencies are always declared via autoload
  # this allows for any dependent project require only `lib/gdk`
  # and load only what it really needs
  autoload :Command, 'gdk/command'
  autoload :Config, 'gdk/config'
  autoload :Dependencies, 'gdk/dependencies'
  autoload :Diagnostic, 'gdk/diagnostic'
  autoload :Env, 'gdk/env'
  autoload :ErbRenderer, 'gdk/erb_renderer'
  autoload :Hooks, 'gdk/hooks'
  autoload :HTTPHelper, 'gdk/http_helper'
  autoload :Logo, 'gdk/logo'
  autoload :Output, 'gdk/output'
  autoload :Postgresql, 'gdk/postgresql'
  autoload :PostgresqlGeo, 'gdk/postgresql_geo'
  autoload :Services, 'gdk/services'
  autoload :Shellout, 'shellout'

  # This function is called from bin/gdk. It must return true/false or
  # an exit code.
  def self.main
    if !install_root_ok? && ARGV.first != 'reconfigure'
      puts <<~GDK_MOVED
        According to #{ROOT_CHECK_FILE} this gitlab-development-kit
        installation was moved. Run 'gdk reconfigure' to update hard-coded
        paths.
      GDK_MOVED
      return false
    end

    validate_yaml!

    subcommand = ARGV.shift

    if ::GDK::Command::COMMANDS.key?(subcommand)
      ::GDK::Command::COMMANDS[subcommand].call.new.run(ARGV)

      return true
    end

    case subcommand
    when 'status'
      exit(GDK::Command::Status.new.run(ARGV))
    when 'start'
      exit(GDK::Command::Start.new.run(ARGV))
    when 'restart'
      exit(GDK::Command::Restart.new.run(ARGV))
    when 'stop'
      exit(GDK::Command::Stop.new.run(ARGV))
    when /-{0,2}help/, '-h', nil
      GDK::Command::Help.new.run(ARGV)
    else
      GDK::Output.notice "gdk: #{subcommand} is not a gdk command."
      GDK::Output.notice "See 'gdk help' for more detail."
      false
    end
  end

  def self.config
    @config ||= GDK::Config.new
  end

  def self.puts_separator(msg = nil)
    GDK::Output.puts('-------------------------------------------------------')
    return unless msg

    GDK::Output.puts(msg)
    puts_separator
  end

  def self.install_root_ok?
    expected_root = GDK.root.join(ROOT_CHECK_FILE).read.chomp
    Pathname.new(expected_root).realpath == GDK.root
  rescue StandardError => e
    warn e
    false
  end

  # Return the path to the GDK base path
  #
  # @return [Pathname] path to GDK base directory
  def self.root
    Pathname.new($gdk_root || Pathname.new(__dir__).parent) # rubocop:disable Style/GlobalVars
  end

  def self.make(*targets)
    sh = Shellout.new(MAKE, targets, chdir: GDK.root)
    sh.stream
    sh.success?
  end

  def self.validate_yaml!
    config.validate!
    nil
  rescue StandardError => e
    GDK::Output.error("Your gdk.yml is invalid.\n\n")
    GDK::Output.puts(e.message, stderr: true)
    abort('')
  end
end
