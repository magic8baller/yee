class Api::V1::SessionsController < ApplicationController
  
  def create
    # User has clicked "login" button - assemble get request to Spotify to have
    # user authorize application
    query_params = {    
      client_id: ENV["CLIENT_ID"],
      response_type: "code",
      redirect_uri: ENV["REDIRECT_URI"],
      scope: "user-library-read user-read-recently-played playlist-read-private ",
      show_dialog: true
    }

    url = "https://accounts.spotify.com/authorize/"
    # redirects user"s browser to Spotify"s authorization page, which details
    # scopes my app is requesting
    redirect_to "#{url}?#{query_params.to_query}"
  end

end
