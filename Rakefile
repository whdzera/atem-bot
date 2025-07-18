require 'rake'

task default: :help

desc 'help'
task :help do
  sh 'rake -T'
end

desc 'Run RSpec tests'
task :test do
  sh 'rspec spec/index_spec.rb'
end

desc 'Run only the Discord bot'
task :discord do
  system('ruby bin/DISCORD')
end

desc 'Run only the Telegram bot'
task :telegram do
  system('ruby bin/TELEGRAM')
end

desc 'Run only the WhatsApp bot'
task :wa do
  system('ruby bin/WHATSAPP')
end

desc 'Run selected bots using ENV variables (e.g., dc=yes wa=yes)'
task :run do
  selected = []

  if ENV['dc'] == 'yes'
    puts 'Running Discord bot'
    pid = Process.spawn('ruby bin/DISCORD')
    Process.detach(pid)
    File.write('tmp/dc.pid', pid)
    selected << 'dc'
  end

  if ENV['tele'] == 'yes'
    puts 'Running Telegram bot'
    pid = Process.spawn('ruby bin/TELEGRAM')
    Process.detach(pid)
    File.write('tmp/tele.pid', pid)
    selected << 'tele'
  end

  if ENV['wa'] == 'yes'
    puts 'Running WhatsApp bot'
    pid = Process.spawn('ruby bin/WHATSAPP')
    Process.detach(pid)
    File.write('tmp/wa.pid', pid)
    selected << 'wa'
  end

  if selected.empty?
    puts "\n📌 No bots selected to run.\n\n"
    puts 'Usage examples:'
    puts '  rake run dc=yes           # Run only Discord bot'
    puts '  rake run wa=yes tele=yes  # Run WhatsApp and Telegram bots'
    puts '  rake run dc=yes wa=yes tele=yes  # Run all bots\n\n'
    puts 'Available options:'
    puts '  dc=yes     → Run Discord bot'
    puts '  wa=yes     → Run WhatsApp bot'
    puts '  tele=yes   → Run Telegram bot'
  else
    puts "\n✅ Started: #{selected.join(', ')} bot(s)."
  end
end

desc 'Kill all running bot processes and clean up PID files'
task :kill do
  %w[dc tele wa].each do |bot|
    pid_file = "tmp/#{bot}.pid"
    if File.exist?(pid_file)
      pid = File.read(pid_file).to_i
      begin
        Process.kill('TERM', pid)
        puts "Killed #{bot.upcase} process PID #{pid}"
      rescue Errno::ESRCH
        puts "#{bot.upcase} process PID #{pid} already stopped"
      end
      File.delete(pid_file)
    else
      puts "No PID file found for #{bot.upcase}"
    end
  end
  puts 'Done killing bots.'
end
