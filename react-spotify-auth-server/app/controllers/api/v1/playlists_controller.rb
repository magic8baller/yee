class Api::V1::PlaylistsController < ApplicationController

  def show
    @user = User.find(params[:user_id])
    playlists = @user.playlists

    header = {
      Authorization: "Bearer #{@user.access_token}"
    }

    # the below process compares a user's spotify playlists with the playlists in my database.
    # if a user has deleted a playlist on Spotify that was created by this app, we need to delete that record
    # so that wer'e not trying to display a playlist in the frontend that no longer exists.

    #fetch a current user's spotify playlists, then parse them
    users_playlists_response = RestClient.get("https://api.spotify.com/v1/me/playlists?limit=50", header)
    parsed_users_playlists = JSON.parse(users_playlists_response.body)

    # create an array of just playlist id's to compare agianst the database
    spotify_playlist_ids = parsed_users_playlists['items'].map { |playlist| playlist['id'] }

    # iterate over the playlists in my database, destroy record if it is not included in the array of Spotify playlist id's
    playlists.each do |playlist|
      if !spotify_playlist_ids.include?(playlist.spotify_id)
        Playlist.destroy(playlist.id)
      end
    end

    #in case any playlists have been destroyed, ask the database for a user's playlists again
    updated_playlists = @user.playlists

    render json: {playlists: updated_playlists}
  end

  def create
    @user = User.find(params[:user_id])

    header = {
      "Authorization" => "Bearer #{@user.access_token}",
      "Content-Type" => "application/json"
    }

    body = {
      name: params[:playlist_name]
    }
      #create and return new epmty playlist
      api_url = "https://api.spotify.com/v1/users/#{@user.username}/playlists"
      api_response = RestClient.post(api_url, body.to_json, header)
      new_playlist = JSON.parse(api_response.body)

      #create new playlist in rails database
      playlist = Playlist.create(spotify_id: new_playlist["id"], user_id: @user.id)

      #split track uris to send to Spotify api
      track_body = {
        uris: params[:track_ids].split(',')
      }

      # add tracks to new empty playlist
      tracks_api_url = "https://api.spotify.com/v1/users/#{@user.username}/playlists/#{new_playlist["id"]}/tracks"
      tracks_api_response = RestClient.post(tracks_api_url, track_body.to_json, header)
      parsed_tracks_api_response = JSON.parse(tracks_api_response.body)

      #return new playlist to frontend
      render json: {playlist: playlist}
  end

end
