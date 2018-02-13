require 'uri'
require 'logger'

require 'sonos'
require 'rspotify'
require 'dotenv'

Dotenv.load
$logger = Logger.new(STDOUT)

class Jukebox
  def initialize(speaker_name)
    @speaker_name = speaker_name
  end

  # Play a given spotify URI on the Sonos speaker
  def play_spotify_uris(spotify_uris)
    speaker.clear_queue
    spotify_uris.each do |spotify_uri|
      sonos_uri = sonos_uri_from_spotify_uri(spotify_uri)
      speaker.add_to_queue(sonos_uri)
    end
    speaker.play
  end

  # Play a given RSpotify::Playlist on the Sonos speaker
  def play_spotify_playlist(playlist)
    uris = playlist.tracks.map(&:uri)
    play_spotify_uris(uris)
  end

  # Search for a track on Spotify by title and play it on the Sonos speaker
  def play_spotify_track(title)
    $logger.info "Retrieving track \"#{title}\" from Spotify..."
    track = RSpotify::Track.search(title).first
    $logger.info 'done.'
    artist = track.artists.map(&:name).join(" & ")

    $logger.info "Found #{artist} - #{track.name} from the album \"#{track.album.name}\""
    play_spotify_uris([track.uri])
  end

  private
  def speaker
    return @speaker if @speaker

    $logger.info "Finding speaker \"#{@speaker_name}\"..."
    system = Sonos::System.new
    @speaker = system.speakers.find{|speaker| speaker.name == @speaker_name}
    $logger.info 'done'

    @speaker
  end

  def sonos_uri_from_spotify_uri(spotify_uri)
    safe_spotify_uri = URI.encode(spotify_uri + "?sid=12&flags=8224&sn=2", ":&")

    "x-sonos-spotify:" + safe_spotify_uri
  end
end

# TODO: Cache lookups to Spotify for performance reasons?
# Provides a slightly simpler interface to Spotify than RSpotify
class Spotify
  def initialize
    @playlist_cache = {}
    @track_cache = {}
  end
end

$logger.info 'Authenticating with Spotify...'
client_id = ENV.fetch("SPOTIFY_CLIENT_ID")
client_secret = ENV.fetch("SPOTIFY_CLIENT_SECRET")
RSpotify.authenticate(client_id, client_secret)
$logger.info 'done'
$logger.info 'Finding playlist on Spotify...'
playlist = RSpotify::Playlist.find("zdwiggins", "4m2vrzVCUjvrHzaW00Skli")
$logger.info 'done'

jukebox = Jukebox.new(ENV.fetch("SPEAKER_NAME"))

loop do
  print 'Title: '
  title = gets.chomp
  jukebox.play_spotify_track(title)
end

