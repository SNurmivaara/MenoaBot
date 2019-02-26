require 'telegram/bot'
require 'net/http'
require 'json'
require 'active_support/time'

# bot stuff
token = 'INSERT YOUR TELEGRAM BOT TOKEN HERE'
url = 'CERTAIN API WHICH ANSWERS ROOM USAGE STATISTIC IN JSON FORMAT'

# Store cooldown values as key value pairs as [chat id][timestamp of last command]
cooldown = Hash.new

Telegram::Bot::Client.run(token) do |bot|
  begin
    bot.listen do |message|
      case message.text
      when '/start', '/start@MenoaBot'
        bot.api.send_message(chat_id: message.chat.id, text: "Tekeekö mieli pongia #{message.from.first_name}? Kokeile /onko seuraa.")
      when '/onko', '/onko@MenoaBot'
        current = Time.now.in_time_zone('Europe/Helsinki')

        #Cooldown handling. If the last command in the chat has been received under 10 seconds ago, skip answering to reduce spammability
        puts "Called in chat #{message.chat.id}"
        unless cooldown[message.chat.id].nil?
          if current - cooldown[message.chat.id] < 10.second
            next
          end
        end

        # Get data from JSON api
        uri = URI(url)
        response = Net::HTTP.get(uri)
        response = JSON.parse(response)

        # Parse time into relevant time zone. The API used while developing this has Events, where the 0 entry is the latest one and has a timestamp field.
        lastopened = Time.parse(response['events'][0]['timestamp']).in_time_zone('Europe/Helsinki')

        # Get difference and round to nearest hour
        difference = ((current - lastopened) / 1.hour).round

        bot.api.send_message(chat_id: message.chat.id, text: "Bmur-aktiivisuutta havaittu noin #{difference} tuntia sitten")
        cooldown[message.chat.id] = Time.now.in_time_zone('Europe/Helsinki')
      end
    end
  rescue Telegram::Bot::Exceptions::ResponseError => e
    retry
  end
end
