# frozen_string_literal: true

module GDK
  module Command
    # Handles `gdk reset-data` command execution
    class ResetData
      def run
        GDK.remember!(GDK.root)
        Runit.stop

        unless backup_data
          GDK::Output.error('Failed to backup data.')
          GDK.display_help_message
          return
        end

        reset_data
      end

      private

      def reset_data
        if GDK.make
          GDK::Output.notice('Successfully reset data!')
          GDK.start([])
        else
          GDK::Output.error('Failed to reset data.')
          GDK.display_help_message
          false
        end
      end

      def backup_data
        path = GDK.root.join('./support/backup-data')
        sh = Shellout.new(path.to_s, chdir: GDK.root)
        sh.run
        sh.success?
      end
    end
  end
end
