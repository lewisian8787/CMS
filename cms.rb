require "sinatra"
require "sinatra/reloader"
require "redcarpet"
#require 'bcrypt'
require "yaml"

#configuring sessions
configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

helpers do
  
  def load_user_credentials
    if ENV["RACK_ENV"] == "test"
      credentials_path = File.expand_path("../test/users.yml", __FILE__)
      # "/home/ec2-user/environment/CMS/test/data"
    else
      credentials_path = File.expand_path("../users.yml", __FILE__)
      # "/home/ec2-user/environment/CMS/data"
    end
    YAML.load_file(credentials_path)
  end
  
  def signin_status
    session[:signin_status]
  end

  def valid_credentials?
    if load_user_credentials.key?(params[:username])
      bcrypt_password = BCrypt::Password.new(load_user_credentials[params[:username]])
      bcrypt_password == params[:password]
    else
      false
    end
  end
  
  def restricted_message
    if !signin_status == true
      session[:message] = "You are not allowed to do that"
      redirect "/"
    end
  end
  
  #render markdown method
  def render_markdown(markdown_string)
      markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
      markdown.render(markdown_string)
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

get "/new_document" do
  restricted_message
  erb :new, layout: :layout
end

get "/signin" do
  erb :signin, layout: :layout
end

post "/signin_evaluation" do
  puts params.inspect
  if valid_credentials?
    session[:message] = "Welcome #{params[:username]}"
    session[:username] = params[:username]
    session[:signin_status] = true
    redirect "/"
  else
    session[:message] = "Wrong bitch"
    session[:signin_status] = false
    redirect "/signin"
  end
end

post "/signout" do
  session[:signin_status] = false
  session[:message] = "#{session[:username]} has been signed out."
  redirect "/"
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
  restricted_message
  file_path = File.join(data_path, params[:filename])
  
  @filename = params[:filename]
  @content = File.read(file_path)
  
  erb :edit
end

post "/create_new_page" do
  restricted_message
  filename = params[:filename].to_s
  
  if filename.size == 0
    session[:message] = "You must enter a name"
    status 402
    redirect "/new"
  else
    file_path = File.join(data_path, filename)
    
    File.write(file_path, "")
    
    session[:message] = "#{params[:filename]} has been created"
    redirect "/"
  end
end

post "/:filename/update" do
  restricted_message
  file_path = File.join(data_path, params[:filename])
  
  File.write(file_path, params[:content])
  

  session[:message] = "#{params[:filename]} has been updated"
  redirect "/"
end

post "/:filename/delete_file" do
  restricted_message
  file_path = File.join(data_path, params[:filename])
  
  File.delete(file_path)
  
  session[:message] = "#{params[:filename]} has been deleted"
  redirect "/"
end

#end

