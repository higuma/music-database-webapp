require 'json'

DATA_FILE = 'lib/tasks/data.json'
def read_json
  open DATA_FILE do |f|
    JSON.parse f.read
  end
end

namespace :data do
  desc 'Populate test data'
  task populate: :environment do
    read_json.each do |album|
      title = album['title']
      puts "#{album['artist']} - #{title}"
      unless title
        puts "FATAL: INVALID DATA (NO TITLE)"
        exit
      end

      artist = Artist.find_or_create_by name: album['artist']
      release = artist.releases.find_by title: album['title']
      puts ">> Possibly duplicated release: #{title}" if release
      release = artist.releases.create title: album['title'] unless release
      release.year = album['year']
      release.save
      album['tracks'].each do |num, tr|
        num = num.to_i
        track = release.tracks.find_by number: num
        puts ">> Possibly duplicated track: #{track.title}" if track
        track = release.tracks.create number: num unless track
        track.title = tr[0]
        tr[1] =~ /(\d+):(\d+)/
        track.minutes = $1.to_i if $1
        track.seconds = $2.to_i if $2
        track.save
      end
    end
  end
end
