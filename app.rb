require "sinatra"
require "sinatra/activerecord"
require "sinatra/flash"
require "sendgrid-ruby"
require "./models"

include SendGrid
set :sessions, true

configure :development do
  require "sinatra/reloader"
  set :database, "sqlite3:pokemon.db"
end

configure :production do
  set :database, ENV["DATABASE_URL"]
end

get "/" do
  if session[:user_id]
    # p :user_id
    @user = User.find(session[:user_id])
    @current_user = @user.trainer_name
    @posts = Post.all

    # p @user.posts.title 
    erb :signed_in_homepage
  else
    erb :signed_out_homepage
  end
end

# displays sign in form
get "/sign-in" do
  if session[:user_id]
    flash[:warning] = "You are already logged in."
    redirect "/"
  end
  erb :sign_in
end

# responds to sign in form
post "/sign-in" do
  @user = User.find_by(trainer_name: params[:trainer_name])

  # checks to see if the user exists
  #   and also if the user password matches the password in the db
  if @user && @user.password == params[:password]
    # this line signs a user in
    session[:user_id] = @user.id

    # lets the user know that something is wrong
    flash[:info] = "#{@user.trainer_name} successfully signed in!"

    # redirects to the home page
    redirect "/"
  else
    # lets the user know that something is wrong
    flash[:warning] = "Your trainer name or password is incorrect"

    # if user does not exist or password does not match then
    #   redirect the user to the sign in page
    redirect "/sign-in"
  end
end

# displays signup form
#   with fields for relevant user information like:
#   username, password
get "/sign-up" do
  if session[:user_id]
    flash[:warning] = "You are already logged in."
    redirect "/"
  end
  
  erb :sign_up
end

post "/sign-up" do
  @user = User.find_by(trainer_name: params[:trainer_name])
  
  if User.exists?(trainer_name: params[:trainer_name])
    flash[:warning] = "Trainer Name in use."
    redirect "/sign-up"
  end

  if params[:email] == ""
    flash[:warning] = "Please input an Email."
    redirect "/sign-up"
  end 

    @user = User.create(
    trainer_name: params[:trainer_name],
    password: params[:password],
    first_name: params[:first_name],
    last_name: params[:last_name],
    email: params[:email],
    birthday: params[:birthday]
  )

  # this line does the signing in
  session[:user_id] = @user.id

  # lets the user know they have signed up
  flash[:info] = "Thanks #{@user.trainer_name} for signing up!"

  #send an email to let user know they signed up
  @email = params[:email]
  from = Email.new(email: ENV["PERSONAL_EMAIL"])
  to = Email.new(email: @email )
  subject = "Welcome to PokeJournal!"
  content = Content.new(
    type: "text/html",
    value: "Thank you " + params[:first_name] + ", for joining our Pokemon community, PokeJournal,
    a place where every Pokemon Fan is welcome! <br/> <img src ='https://m.popkey.co/3512d2/9wmyD_s-200x150.gif'/>"
  )

# create mail object with from, subject, to and content
  mail = Mail.new(from, subject, to, content)

# sets up the api key
  sg = SendGrid::API.new(
    api_key: ENV["SENDGRID_API_KEY"]
  )
  response = sg.client.mail._("send").post(request_body: mail.to_json)

  # assuming this page exists
  redirect "/"
end

# when hitting this get path via a link
#   it would reset the session user_id and redirect
#   back to the homepage
get "/sign-out" do
  # this is the line that signs a user out
  session[:user_id] = nil

  # lets the user know they have signed out
  flash[:info] = "You have been signed out"
  
  redirect "/"
end

get "/create-post" do
  if session[:user_id] == nil
    flash[:warning] = "You need to be logged in to access this section."
    redirect "/"
  end
  @user = User.find(session[:user_id])
  @current_user = @user.trainer_name
  erb :create_post
end

post "/create-post" do
  @user = User.find(session[:user_id]) 
  @post = Post.create(
    title: params[:title],
    content: params[:content],
    user_id: @user.id
  )
  # p "SESSION USER ID =>" + session[:user_id].to_s
  redirect "/"
end

get "/users" do
  @user = User.find(session[:user_id])
  @users = User.all
  @current_user = @user.trainer_name
  erb :users
end

# get "/profile/:trainer_name" do
#   @user = User.find_by(trainer_name: params[:trainer_name])
#   if User.exists?(params[:trainer_name])
#     if @user.trainer_name == params[:trainer_name]
#       #get profile
#       @user_self = User.find_by(trainer_name: params[:trainer_name])
#       erb :profile
#     else
#       #get the trainer name's page
#       @other_user = User.find_by(trainer_name: params[:trainer_name])
#       erb :profile
#     end
#   end
# end

get "/profile/:id" do
  @posts = Post.all
  @search_user = User.find(params[:id])
  
  if session[:user_id] != nil
    @user = User.find(session[:user_id])
    @current_user = @user.trainer_name
  end
  
  erb :profile
end

#post "/profile/delete_post/:id" do
 # @posts = User.all.map(&:to_s)
  # for post in @posts
  #   if post.user_id == User.find(session[:user_id]).id &&
  #     post.id == params[:id]
  #     # post.destroy
  #   end
  # end
# end

delete "/profile/delete_post/:id" do
  @post = Post.find_by_id(params[:id])
  @post.delete
  flash[:warning] = "Post deleted."
  redirect "/"
end

post "/delete/:id" do
  @posts = Post.all
  for post in @posts
    #delete all posts associated with user
    if post.user_id == User.find(session[:user_id]).id
      Post.destroy(post.id)
    end
  end
  User.destroy(session[:user_id])
  session[:user_id] = nil
  flash[:warning] = "Account Deleted."
  redirect "/"
end

post "/query" do
  if User.all.exists?(:trainer_name => params[:trainer_name]) #If trainer name matches params do next
    @query_user = User.find_by(trainer_name: params[:trainer_name])
    redirect "/profile/#{@query_user.id}"
  else
    redirect "/404"
  end
end

not_found do
  status 404
  erb :oops
end