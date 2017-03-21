require 'fileutils'
module Utilities
	class FileHelper
		def FileHelper.scp_folder_to_remote(src, remote_host, destination)
			if (!File.exist?(src))
				puts "The folder #{src} does not exist"
				return
			end
			system("scp -r #{src}/* #{remote_host}:#{destination}")
		end

		def FileHelper.clear_remote_folder(remote_host, folder)
			puts "Clear the files under folder of #{folder}"
			system("ssh #{remote_host} 'rm -rf #{folder}/*'")
		end
		
		def FileHelper.move_folder_content(origin, destination)
			Dir.glob(File.join(origin, '*')).each do |file|
				#puts "File: #{file}"
  				if File.exists? File.join(destination, File.basename(file))
					#puts "File exists on destination #{File.join(destination, File.basename(file))}"
    					FileUtils.move file, File.join(destination, "1-#{File.basename(file)}")
				else
					#puts "File not exist on destination,  #{File.join(destination, File.basename(file))}, just move it"
    					FileUtils.move file, File.join(destination, File.basename(file))
  				end
			end		
		end
	end
end
