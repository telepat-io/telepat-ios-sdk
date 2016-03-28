require 'cocoapods-core'

task :docs do
	sh "appledoc --project-name Telepat --project-company Appscend --company-id io.telepat.ios --no-create-docset --output ./Docs Telepat || true"
end

task :releasepod, [:commit_msg] => :docs do |t, args|
	spec = eval(File.read('Telepat.podspec'))
	puts "Release pod version #{spec.version} with commit message: #{args[:commit_msg]}"

	sh "git add . --all"
	sh "git commit -m \"#{args[:commit_msg]}\""
	sh "git tag #{spec.version}"
	sh "git push origin master --tags"
	sh "pod trunk push Telepat.podspec --allow-warnings"
end