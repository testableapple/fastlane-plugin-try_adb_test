gem_path = `rake build`.split(' ').last.chomp('.')
if File.file?(gem_path)
  gem_ver = 'v' + gem_path.scan(/\d/).join('.')
  puts "try_adb_test: publishing gem '#{gem_ver}', right? 🤔"
  if gets.to_s.downcase =~ /y/
    puts 'try_adb_test: okie dokie 🚀'
    output = `gem push #{gem_path} -k alteral`
    puts output
    if output.include?('Successfully registered gem')
      puts `git tag #{gem_ver} && git push origin #{gem_ver}`
    end
  else
    puts 'try_adb_test: okay 😐'
  end
else
  "try_adb_test: Something wrong with '#{gem_path}' 🏌️‍♂️"
end
