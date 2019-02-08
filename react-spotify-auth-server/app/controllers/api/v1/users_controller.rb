class Api::V1::UsersController < ApplicationController
  def index
    @users = User.all
    render json: @users
  end

  def create
    body = {
      grant_type: "authorization_code",
      code: params[:code],
      redirect_uri: ENV["REDIRECT_URI"],
      client_id: ENV["CLIENT_ID"],
      client_secret: ENV["CLIENT_SECRET"]
    }
  
    auth_response = RestClient.post("https://accounts.spotify.com/api/token", body)
  
    #convert response.body to JSON for assignment
    auth_params = JSON.parse(auth_response.body)
    #assemble and send request to Spotify for user profile information
    header = {
      Authorization: "Bearer #{auth_params["access_token"]}"
    }
  
    user_response = RestClient.get("https://api.spotify.com/v1/me", header)
  
    #convert response.body to JSON for assignment
    user_params = JSON.parse(user_response.body)
  
    #Create new user based on response, or find existing user in database
    @user = User.find_or_create_by(
      id: user_params["id"],
      email: user_params["email"],
      display_name: user_params["display_name"],
      spotify_id: user_params["spotify_id"],
      spotify_url: user_params["external_urls"]["spotify"],
      href: user_params["href"],
      uri: user_params["uri"]
    )

    img_url = user_params["images"][0] ? user_params["images"][0]["url"] : nil
        
    @user.update(profile_img_url: img_url, access_token: auth_params["access_token"], refresh_token: auth_params["refresh_token"])
  
    @user.refresh_token
    # Create and send JWT Token along with user info
    payload = { user_id: @user.id }
    @token = issue_token(payload)
    render json: { jwt: @token, user: { display_name: @user.display_name, id: @user.id, spotify_id: @user.spotify_id, uri: @user.uri }
    }
  end
  
end
