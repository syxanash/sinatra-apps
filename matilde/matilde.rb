require 'sinatra'
require 'magick_title'
require 'date'
require './passwordgenerator'

helpers do

  # if user decide to generate a picture the following helper
  # is not required...

  def h(text)
    Rack::Utils.escape_html(text)
  end

  # remove all password from magick titles directory

  def clear_files(directory)
    if File.directory? directory
      Dir.foreach(directory) do |file|
        fn = File.join(directory, file)
        File.delete(fn) if file != '.' && file != '..'
      end
    end
  end

  # write the current date into a file

  def write_date(filename, date)
    begin
      filehandle = File.open(filename, "w")
      filehandle.write(date) 
    rescue IOError => e
      "Can't write into log file!"
    ensure
      filehandle.close unless filehandle == nil
    end
  end
end

get '/' do
  # check the time in order to clear the
  # password previously stored

  file_check_time = "public/time_check.log"
  current_date = Date.today

  if File.exist? file_check_time
    log_date = File.read(file_check_time)

    # if last password was generated more than
    # a day ago, clear all passwords from folder
    # and update the log date

    if Date.parse(log_date) < current_date
      clear_files("public/system/titles/")
      write_date(file_check_time, current_date)
    end
  else
    write_date(file_check_time, current_date)
  end

  # finally generate the index

  erb :index
end

get '/generate' do
  redirect '/wrong' if params[:size].to_i > 30

  # ZXX fonts
  fonts = [
    "zxx-xed.otf",
    "zxx-noise.otf"
  ]

  # if parameter unrecognizable for OCR was set
  # then remove all url unsafe extra characters
  # because incompatible with ZXX fonts

  if params[:unrec]
    params[:url_unsafe] = true

    # set a random ZXX font
    MagickTitle.options[:font] = fonts[Random.rand(fonts.size)]
  else
    MagickTitle.options[:font] = 'Ubuntu-L.ttf'
  end

  # generate a random color
  
  random_colors = [
    "be3f3f", # red
    "be983f", # yellow
    "3fbe4a", # green
    "3f78be"  # blue
  ]

  @string_color = random_colors[Random.rand(random_colors.size)]

  # generate the final password

  @generator = PasswordGenerator.new(
    :size => params[:size],

    :lowercase => params[:lowercase],
    :uppercase => params[:uppercase],
    :numbers   => params[:numbers],
    :extra     => params[:extra],

    :url_unsafe => params[:url_unsafe],
  )

  if params[:mnemonic]
    @generator.mnemonic = "models" # set the directory for word lists
    @password, @words_used = @generator.generate_mnemonic
  else
    @password = @generator.generate
  end

  erb :generate
end

get '/wrong' do
  erb :wrong
end