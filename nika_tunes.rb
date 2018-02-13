require 'uri'
require 'logger'

require 'sonos'
require 'rspotify'
require 'dotenv'

Dotenv.load
$logger = Logger.new(STDOUT)

def log(msg, &block)
  start_time = Time.now
  $logger.info(msg)
  result = block.call
  end_time = Time.now
  $logger.info("done. Took #{end_time-start_time} seconds")

  result
end

class Jukebox
  attr_reader :spotify

  def initialize(speaker_name, spotify)
    @speaker_name = speaker_name
    @spotify = spotify
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
  def play_spotify_playlist(user, id)
    uris = log("Loading playlist \"#{user} - #{id}\" from spotify") do
      spotify.playlist_uris(user, id)
    end
    play_spotify_uris(uris)
  end

  # Search for a track on Spotify by title and play it on the Sonos speaker
  def play_spotify_track(title)
    uri = log("Loading track \"#{title}\" from spotify") do
      spotify.track_uri(title)
    end
    play_spotify_uris([uri])
  end

  private
  def speaker
    return @speaker if @speaker

    @speaker = log("Finding speaker \"#{@speaker_name}\"...") do
      system = Sonos::System.new
      system.speakers.find{|speaker| speaker.name == @speaker_name}
    end
  end

  def sonos_uri_from_spotify_uri(spotify_uri)
    safe_spotify_uri = URI.encode(spotify_uri + "?sid=12&flags=8224&sn=2", ":&")

    "x-sonos-spotify:" + safe_spotify_uri
  end
end

# Provides a slightly simpler interface to Spotify than RSpotify. Now with
# caching!
class Spotify
  def initialize
    @track_cache = {}
    @playlist_cache = {}
  end

  # You should initialize with this factory method to ensure that we can make
  # authenticated queries to Spotify
  def self.authenticate!
    log 'Authenticating with Spotify...' do
      client_id = ENV.fetch("SPOTIFY_CLIENT_ID")
      client_secret = ENV.fetch("SPOTIFY_CLIENT_SECRET")
      RSpotify.authenticate(client_id, client_secret)
    end

    new
  end

  def track_uri(title)
    return @track_cache[title] if @track_cache[title]

    track = RSpotify::Track.search(title).first
    artist = track.artists.map(&:name).join(" & ")
    $logger.info "Found #{artist} - #{track.name} from the album \"#{track.album.name}\""

    @track_cache[title] = track.uri
  end

  def playlist_uris(user, id)
    key = [user, id].join(':')
    return @playlist_cache[key] if @playlist_cache[key]

    playlist = RSpotify::Playlist.find("zdwiggins", "4m2vrzVCUjvrHzaW00Skli")
    @playlist_cache[key] = playlist.tracks.map(&:uri)
  end

  # Ensure we only initialize using .authenticate
  private_class_method :new
end

speaker_name = ENV.fetch("SPEAKER_NAME")
spotify = Spotify.authenticate!
jukebox = Jukebox.new(speaker_name, spotify)

# Bedtime music
jukebox.play_spotify_playlist("zdwiggins", "4m2vrzVCUjvrHzaW00Skli")

loop do
  print 'Title: '
  title = gets.chomp
  jukebox.play_spotify_track(title)
end

