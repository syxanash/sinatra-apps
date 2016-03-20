require 'sinatra'
require 'magick_title'
require 'date'

helpers do
  # remove all pictures from magick titles directory

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
  # pictures previously stored

  file_check_time = "public/time_check.log"
  current_date = Date.today

  if File.exist? file_check_time
    log_date = File.read(file_check_time)

    # if last picture was generated more than
    # a day ago, clear all pictures from folder
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

post '/generate' do
  @text = params[:text]
  erb :generate
end

get '/:text' do
  @text = params[:text]
  erb :generate
end

get '/generate/error' do
  erb :error
end