module Bot::DiscordEvents
  module Heartbeat
    extend Discordrb::EventContainer
    heartbeat { |_event| puts "Heartbeat at #{Time.now}" }
  end
end
