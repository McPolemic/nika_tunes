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
  $logger.info("done. Took #{(end_time-start_time).to_f} seconds")

  result
end

class Jukebox
  attr_reader :spotify

  def initialize(speaker_name, spotify)
    @speaker_name = speaker_name
    @spotify = spotify
  end

  # Play a given user's playlist (id is spotify id)
  def play_spotify_playlist(user, id)
    uris = log("Loading playlist \"#{user} - #{id}\" from spotify") do
      spotify.playlist_uris(user, id)
    end
    play_spotify_uris(uris)
  end

  # Search for a track on Spotify by title and play it on the Sonos speaker
  def play_spotify_track(title)
    play_spotify_tracks([title])
  end

  # Play multiple tracks given an array of titles
  def play_spotify_tracks(titles)
    uris = titles.map do |title|
      log("Loading track \"#{title}\" from spotify") do
        spotify.track_uri(title)
      end
    end
    play_spotify_uris(uris)
  end

  private
  # Play a given spotify URI on the Sonos speaker
  def play_spotify_uris(spotify_uris)
    speaker.clear_queue

    spotify_uris.each do |spotify_uri|
      sonos_uri = sonos_uri_from_spotify_uri(spotify_uri)
      speaker.add_to_queue(sonos_uri)
    end

    speaker.play
  end

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

    playlist = RSpotify::Playlist.find(user, id)
    @playlist_cache[key] = playlist.tracks.map(&:uri)
  end

  # Ensure we only initialize using .authenticate
  private_class_method :new
end

# Reads codes from RFID tags and translates those to Jukebox actions
class CodeReader
  attr_reader :jukebox

  def initialize(jukebox)
    @jukebox = jukebox
  end

  def repl
    known_values = {
      '08931021' => Proc.new { jukebox.play_spotify_track('Remember Me') },
      '08934207' => Proc.new { jukebox.play_spotify_track('Tempest Shadow') },
      '08934206' => Proc.new { jukebox.play_spotify_track('E Dagger') },
      '09520830' => Proc.new { jukebox.play_spotify_track('Jojo Siwa') },
      '09520651' => Proc.new { jukebox.play_spotify_track('Tony Sly Liver Let Die') },
      '09535374' => Proc.new { jukebox.play_spotify_track('Cheap Thrills') },
      '09535355' => Proc.new { jukebox.play_spotify_track('Lindsey Stirling Hold My Heart') },
      '08934175' => Proc.new { jukebox.play_spotify_playlist("zdwiggins", "4m2vrzVCUjvrHzaW00Skli") },
      '08930890' => Proc.new { jukebox.play_spotify_track('Set It All Free') },
    }

    loop do
      print 'Code: '
      code = gets.chomp

      default_action = Proc.new { puts "Unknown code: #{code}" }
      known_values.fetch(code, default_action).call
    end
  end
end

speaker_name = ENV.fetch("SPEAKER_NAME")
spotify = Spotify.authenticate!
jukebox = Jukebox.new(speaker_name, spotify)

# Kick off infinite loop to read input
CodeReader.new(jukebox).repl

