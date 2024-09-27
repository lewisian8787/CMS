require "sinatra"
require "sinatra/reloader"
require "redcarpet"

#configuring sessions
configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

#render markdown method
def render_markdown(markdown_string)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    markdown.render(markdown_string)
end

# new method to establish the correct path based on the current environment (determine if its in test or not)
def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
    # "/home/ec2-user/environment/CMS/test/data"
  else
    File.expand_path("../data", __FILE__)
    # "/home/ec2-user/environment/CMS/data"
  end
end

#method to load the content of the file at path requested
def load_file_content(path)
  content = File.read(path)
  case File.extname(path)
  when ".txt"
    headers["Content-Type"] = "text/plain"
    content
  when ".md"
    erb render_markdown(content)
  end
end

# Displays the index of files
get "/" do
  pattern = File.join(data_path, "*")
  # "/home/ec2-user/environment/CMS/data/*"
  @files = Dir.glob(pattern).map do |path|
    # Dir.glob returns an array of all paths in the directory (about/history/changes)
    File.basename(path)
    # Returns just the file name of a given path (about.md/changes.txt/history.txt) destructively creating a new array in @files
  end
  # @files = [about.md, changes.txt, history.txt]
  
  erb :index
end

get "/new" do 
  erb :new, layout: :layout
end

get "/:filename" do
  #return a string to the file the page is currently rendering
  file_path = File.join(data_path, params[:filename])
  
  #simlpified way of searching for the complete file path above (includes path and basename)
  if File.exist?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect "/"
  end
end

get "/:filename/edit" do
  file_path = File.join(data_path, params[:filename])
  
  @filename = params[:filename]
  @content = File.read(file_path)
  
  erb :edit
end

# post "/create" do
  
#   filename = params[:filename].to_s
  
#   if filename.size == 0
#     session[:message] = "You must enter a name"
#     status 402
#     redirect "/new"
#   else
#     file_path = File.join(data_path, filename)
    
#     File.write(file_path, "")
    
#     session[:message] = "#{params[:filename]} has been created"
#     redirect "/"
#   end
# end

# cms.rb
get "/new" do
  erb :new
end

post "/create" do
  filename = params[:filename].to_s

  if filename.size == 0
    session[:message] = "A name is required."
    status 422
    erb :new
  else
    file_path = File.join(data_path, filename)

    File.write(file_path, "")
    session[:message] = "#{params[:filename]} has been created."

    redirect "/"
  end
end

post "/:filename" do
  file_path = File.join(data_path, params[:filename])
  
  File.write(file_path, params[:content])
  

  session[:message] = "#{params[:filename]} has been updated"
  redirect "/"
end

