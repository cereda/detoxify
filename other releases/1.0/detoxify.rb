###########################################################################
# Detoxify 1.0
# Copyright (c) 2011, Paulo Roberto Massa Cereda
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or
# without modification, are permitted provided that the following
# conditions are met:
#
#  1. Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#
#  2. Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in
#     the documentation and/or other materials provided with the
#     distribution.
#
#  3. Neither the name of the project's author nor the names of its
#     contributors may be used to endorse or promote products derived
#     from this software without specific prior written permission.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
#  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
#  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
#  COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
#  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
#  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
#  OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
#  TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
#  USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###########################################################################

# The following library is required to recursively remove a non empty dir,
# so we don't need to iterate through its elements.

require 'fileutils'

# Global variables defined in here.

# Acts as a flag to determine if the script executed without errors.
$success = true

# Set the verbose mode for the script, helpful for debugging.
$verbose = false

# Set the script version.
$detoxifyVersion = "1.0"

# This variable will hold the total of references found.
$total = 0

# This function is the heart of Detoxify. It goes from the top directory and
# enters in every single subdirectory searching for traces of any version
# control system. This is a proud recursive function, as it's very elegant
# to program that way, though I'm not sure about how the Ruby stack behaves
# if a project has a ton of subdirectories inside subdirectories. I hope to
# write an iterative version, but meanwhile this is the one to be used.
def detoxify(dirName)

	# This a big exception error block.
	begin
		# The following variables are the core of this function. Basically,
		# they represent which directories and files are bad and thus mark
		# them to be removed. I just hope you aren't innocent enough to name
		# an important folder of yours with any of these names described
		# as follows. If so, too bad, Detoxify will wipe it out.
		directoryNames = [".svn",".git",".cvs",".hg"]
		fileNames = [".svnignore",".gitignore",".cvsignore",".hgignore"]
		directoryReferences = [".", ".."]

		# First check, is this a directory?
		# Well, probably this very first call doesn't make sense at all,
		# but keep in mind this function will be called recursively, so
		# it's good to have some checking.
		if File::directory?(dirName) == true

			# Verbose mode if enabled.
			if ($verbose)
				puts "Entering directory '#{dirName}'."
			end

			# I had some problems when removing directories and
			# files when dealing with subdirectories. I just
			# figured out it was necessary to set the current
			# checking node as the current path, so the removal
			# works beautifully.
			Dir.chdir(dirName)
		
			# Now let's list everything this current directory
			# has in it.
			Dir.foreach(".") do |entry|

				# This checking is important, believe me.
				# Otherwise, we will have an infinite loop,
				# neat!
				if !directoryReferences.index(entry)

					# So we are dealing with "real"
					# references, so let's check if
					# this current entry is a directory.
					if File::directory?(entry)

						# Verbose mode if enabled.
						if ($verbose)
							puts "Found directory '#{entry}'."
						end

						# Let's check if the current entry
						# matches any of the tracing
						# references.
						if directoryNames.index(entry)

							# Verbose mode if enabled.
							if ($verbose)
								puts "Directory '#{entry}' matches tracing object."
							end

							# Let's surround this code
							# with an exception handling
							# block.
							begin

								# If so, let's remove the
								# bloody directory! The good
								# ol' Dir.delete(entry) also
								# works, but it fails when
								# this directory is not
								# empty. This FileUtils
								# command works perfectly.
								FileUtils.rm_rf(entry)

								# Let's increase our total.
								$total = $total + 1

							rescue
								# An exception was raised, probably related to
								# the directory removal. Let's just print an
								# error message and flag an error.

								# Print a nice error message.
								puts "-> I'm sorry, but I couldn't remove this directory: '" + dirName + "/" + entry + "'."
								puts "   Please check your permissions and try again."

								# Something wrong happened, then we should flag it.
								$success = false

							end

						else
							# OK, so we are in a "normal"
							# directory. Now the beauty
							# and magic of recursion
							# happens here, this function
							# is called with the current
							# entry as a parameter.
							detoxify(entry)

							# This line of code makes a big difference!
							# So we call our function recursively, but
							# when it returns, the current directory is
							# still set to the subdirectory. To fix this,
							# let's just call the chdir function with the
							# string ".." as parameter. The two dots mean
							# we want to go on the top directory. Just for
							# reference, one dot represents the current
							# directory.
							Dir.chdir("..")
						end
					else
						# Well, the current entry is not a
						# directory, so it's a file. Now
						# let's check if this filename
						# matches our list of tracing
						# occurrences.
						
						# Verbose mode if enabled.
						if ($verbose)
							puts "Found file '#{entry}'."
						end

						# Let's check if this file matches
						# any of the tracing references.
						if fileNames.index(entry)

							# Verbose mode if enabled.
							if ($verbose)
								puts "File '#{entry}' matches tracing object."
							end

							# I decided to surround this
							# piece of code with an
							# exception handling block.
							begin											
								# Let's delete this "bad"
								# file, and we are done!
								File.delete(entry)

								# Let's increase our total.
								$total = $total + 1

							rescue
								# An exception was raised. so let's
								# print an error message and flag an
								# error.

								# Print a nice error message. If any
								# error message is nice.
								puts "-> I'm sorry, but I couldn't remove this file: '" + dirName + "/" + entry + "'."
								puts "   Please check your permissions and try again."

								# Something wrong happened, then we should flag it.
								$success = false

							end
						end
					end
				end
			end
		end
	rescue
		# I really don't want to be in here. This block means
		# a really BAD exception happened that just compromised
		# the whole script execution. Why are you so mean?

		# Display a default error message.
		puts "-> Something REALLY bad happened, I'm sorry."

		# Something bad happened. Wait a minute, something
		# REALLY bad happened. So let's flag it.
		$success = false
	end
end

# This function just prints the script usage. No big
# deal, just some lines printed on the terminal.
def printUsage()

	# Print in the terminal
	puts "\nUsage: detoxify [-h | -v]"
	puts "-h --help\tPrint this message"
	puts "-v --verbose\tActivate verbose mode"
end

# This function prints the header information. We
# just have the script info and version, the author
# and a copyright message.
def printHeader()

	# Print some header information
	puts "Detoxify #{$detoxifyVersion} - Resistence is futile, you'll be detoxified."
	puts "Copyright (c) 2011, Paulo Roberto Massa Cereda"
	puts "All rights reserved."
end

# This function is just a helper. It will print some messages, call our
# recursive function and check if the script was executed flawlessly.
def timeToDetoxify()

	# Print the message in the beginning of the process.
	puts "\nPlease wait, detoxifying your current directory... "

	# Verbose mode if enabled.
	if ($verbose)
		puts("\nActivating verbose mode.\n\n")
	end

	# Call our recursive function passing the "." string as parameter.
	# As I said before, one dot represents the current directory.
	detoxify(".")

	# Check the execution flag if some kind of error happened.
	if ($success)

		# Everything worked just fine!
		puts "\nYour current directory was detoxified successfully!"
		puts "References removed: #{$total}"

	else

		# Ouch, something wrong happened.
		puts "\nIt seems something bad happened. Please, try to run it again."
	end
end

# Get the number of arguments passed to the script.
numberOfArguments = ARGV.length

# First, let's print the header information.
printHeader()

# We expect zero or one arguments. If there's more
# than one, we should complain.
if (numberOfArguments > 1)

	# Let's show to the user what flags are available.
	printUsage()

elsif numberOfArguments == 1

	# Now, we have one argument! We should check if it's
	# a valid option for our script.

	# If the user wants some help, let's print
	# the usage list.
	if ARGV[0] == "-h" or ARGV[0] == "--help"

		# Plain and simple. Print and exit.
		printUsage()

	elsif ARGV[0] == "-v" or ARGV[0] == "--verbose"

		# It seems the user wants some debugging
		# information. At first, we need to set
		# our verbose flag to 'true'.
		$verbose = true

		# The next step is to run our main function.
		timeToDetoxify()
	else
		# The wise guy just put some unrecognized
		# text as an argument. Let's complain.
		puts "Unrecognized option: #{ARGV[0]}\n"

		# Again, let's print the usage and exit.
		printUsage()
	end
elsif
	# So, there are no arguments provided. We will run
	# our main function with the default options.
	timeToDetoxify()
end

# That's all folks, hope you like Detoxify!

