require 'sinatra'
require 'sinatra-websocket'
require 'securerandom'
require 'json'

set :server, 'thin'
set :sockets, []

BULBS_LIST_FILE = 'public/lightbulbs.json'

before do
  # get the first lightbulb in list
  temp_list = JSON.parse(File.read(BULBS_LIST_FILE))
  @master_bulb = temp_list.keys[0]
end

get '/' do
  redirect "/#{@master_bulb}"
end

get '/generate' do
  # generate a unique key id for each light bulbs value.
  # Update the main list of light bulbs with a new value set to 0 (light off)
  value = SecureRandom.urlsafe_base64(6)

  json_hash_values = JSON.parse(File.read(BULBS_LIST_FILE))
  json_hash_values.merge!({ value => 0 })

  File.open(BULBS_LIST_FILE, 'w') do |fh|
    fh.write(JSON.pretty_generate(json_hash_values))
  end

  redirect "/#{value}"
end

get '/:bulb_id' do
  # get the unique light bulb id, if it already exists then render the
  # page using that id, otherwise generate a new id visiting the main route '/'
  @bulb_id = params['bulb_id']

  lightbulbs_list = JSON.parse(File.read(BULBS_LIST_FILE))

  unless lightbulbs_list.has_key?(@bulb_id)
    puts "redirecting because of #{@bulb_id}"
    redirect '/'
  end

  erb :index
end

get '/value/:bulb_id' do
  if !request.websocket?
    redirect '/'
  else
    bulb_id = params['bulb_id']
    lightbulbs_list = JSON.parse(File.read(BULBS_LIST_FILE))

    unless lightbulbs_list.has_key?(bulb_id)
      redirect '/'
    end

    request.websocket do |ws|
      @conn = {path: bulb_id, socket: ws}

      ws.onopen do
        # in this block we get in every time a user
        # establishes a connection with the page

        warn("someone just connected") # warns this message on command line

        # this way we will be able to store user connection in settings.sockets
        settings.sockets << @conn

        # read the light bulb file value which can be 0 or 1
        value = lightbulbs_list[bulb_id]

        EM.next_tick {
          # send the current value of the light bulb only
          # to the new connected user
          @conn[:socket].send(value.to_s)
        }
      end

      ws.onmessage do |msg|
        # every time a user interacts with the server this
        # message is printed
        puts "apparently message received by client is: #{msg}"

        # changing the light

        # get the current light bulbs list and change the value on bulb_id key
        # otherwise we erroneously overwrite the old one
        lightbulbs_list = JSON.parse(File.read(BULBS_LIST_FILE))

        value = lightbulbs_list[bulb_id].to_i
        value = (value + 1) % 2
        lightbulbs_list[bulb_id] = value

        # after changing the light bulb value we update
        # the main light bulbs list
        File.open(BULBS_LIST_FILE, 'w') do |fh|
          fh.write(JSON.pretty_generate(lightbulbs_list))
        end

        puts "status changed to #{value}"

        EM.next_tick {
          # send the changes of the bulb light only to people visiting
          # the same unique id in URL
          settings.sockets.each do |user|
            if user[:path] == bulb_id
              user[:socket].send(value.to_s)
            end
          end
        }
      end

      ws.onclose do
        # block used when a client disconnects from the page

        warn("websocket closed by a client in #{bulb_id}")
        settings.sockets.delete(ws)
      end
    end
  end
end
