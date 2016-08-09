# GitLab Development Kit CLI parser / executor
#
# This file is loaded by the 'gdk' command in the gem. This file is NOT
# part of the gitlab-development-kit gem so that we can iterate faster.

module GDK
  PROGNAME = 'gdk'

  # This function is called from bin/gdk. It must return true/false or
  # an exit code.
  def self.main
    case ARGV.shift
    when 'run'
      system('./run', *ARGV, chdir: $gdk_root)
    when 'install'
      system('make', *ARGV, chdir: $gdk_root)
    when 'update'
      system('make', 'update', chdir: $gdk_root)
    when 'reconfigure'
      system('make', 'clean-config', 'all', chdir: $gdk_root)
    when 'help'
      puts File.read(File.join($gdk_root, 'HELP'))
      true
    else
      puts "Usage: #{PROGNAME} run|init|install|update|reconfigure|version|help [ARGS...]"
      false
    end
  end
end
