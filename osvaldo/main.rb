require 'sinatra'

########## helpers ##########

helpers do
  def bb_convert(content)
    regex = Array.new
    replace = Array.new

    regex[0] = /\[quote\](.+?)\[\/quote\]/
    replace[0] = "<blockquote>\\1</blockquote>"

    regex[1] = /\[sub\](.+?)\[\/sub\]/
    replace[1] = "<h2>\\1</h2>"

    regex[2] = /\[u\](.+?)\[\/u\]/
    replace[2] = "<u>\\1</u>"

    regex[3] = /\[b\](.+?)\[\/b\]/
    replace[3] = "<b>\\1</b>"

    regex[4] = /\[i\](.+?)\[\/i\]/
    replace[4] = "<i>\\1</i>"

    regex[5] = /\[c\](.+?)\[\/c\]/
    replace[5] = '<center>\\1</center>'
            
    regex[6] = /\[image:([^\]]*)\]/
    replace[6] = '<img src="\\1"></img>'

    regex[7] = /\[mail:([^\]]*)\|([^\]]*)\]/
    replace[7] = '<a href="mailto:\\1">\\2</a>'

    regex[8] = /\[mail:([^\]]*)\]/
    replace[8] = '<a href="mailto:\\1">\\1</a>'

    regex[9] = /\[link:([^\]]*)\|([^\]]*)\]/
    replace[9] = '<a href="\\1" target="_blank">\\2</a>'

    regex[10] = /\[link:([^\]]*)\]/;
    replace[10] = '<a href="\\1" target="_blank">\\1</a>'

    regex[11] = "[line]"
    replace[11] = "<hr>"

    regex[12] = "\n\n"
    replace[12] = "<p>"

    regex[13] = "\n"
    replace[13] = "<br>"

    regex.zip(replace).each do |pattern, replacement|
      content = content.gsub(pattern, replacement)
    end

    # returns the page decoded by bb tags
    content
  end

  def get_pages
    @file_list = Array.new

    Dir.foreach('pages/') do |item|
      if item != 'index.txt' and
         item != 'robots.txt' and
         item != 'footer.txt' and
         item != '..' and
         item != '.' and
         item =~ /\.txt$/ then
        @file_list.push(item.sub(/\.txt$/, ''))
      end
    end

    @file_list
  end
end

########## routes ##########

get '/' do
  if File.exist? "pages/index.txt"
    redirect '/page/index'
  else
    "YOU NO HAVE INDEX? SERIOUSLY?"
  end
end

get '/page/:name' do
  @title ||= []
  @current_page ||= []
  @file_time ||= []

  page_name = params[:name]
  @title = page_name.capitalize # set the default title for the html page

  if page_name !~ /\.txt$/
    puts "lol you no have extension!"

    page_name += ".txt"

    # @current_page will be used to check the page
    # the user is visiting

    @current_page = page_name
  end

  page_name = "pages/#{page_name}"

  if File.exist? page_name
    @file_content = bb_convert(File.read(page_name))
    @file_time = File.new(page_name).mtime.strftime("Page last updated on %A, %d %B, %Y at %I:%M%p")

    # get the title if exists as a bb tag

    if @file_content =~ /\[title\](.+?)\[\/title\]/
      @title = $1 # set the customized title

      # remove the title tags
      @file_content = @file_content.gsub(/\[title\](.+?)\[\/title\]<br>/, "")
    end
    
    erb :page
  else
    redirect '/'
  end
end

# I had no other solutions for this route
# I know that probably it sucks, thus tell me
# if you have any suggestions

get %r{^(\/page\/|\/page)$} do
  redirect '/'
end