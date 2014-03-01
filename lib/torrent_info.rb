#!ruby
# encoding: UTF-8
# author: Rafael Polo
# created_at 13.out.2009
# updated_at 21.fev.2014

# TorrentInfo v0.6
# + SomBarato, BaixoGavea, MakingOff

require 'digest/sha1'
require 'open-uri'
require 'json'
require 'timeout'

class TorrentInfo

  def initialize(path)
    return nil unless File.exists?(path)
    begin
      @torrent = File.bdecode(path)
    rescue BEncode::DecodeError => e
      puts "#{e}".red
      # binding.pry if Rails.env.development? # debug
      return nil
    end
    return nil unless valid?
  end

  def valid?
    (@torrent && @torrent["info"]) ? true : false
  end

  def name
    @torrent['info']['name'].strip
  end

  def hash
    Digest::SHA1.hexdigest(@torrent["info"].bencode)
  end

  def announce_list
    list = []
    if @torrent['announce-list']
      @torrent['announce-list'].each do |announce|
        list << announce[0].strip if announce[0]
      end
    else
      list << @torrent['announce']
    end
    list << 'udp://tracker.openbittorrent.com:80/announce'
    list << 'udp://tracker.publicbt.com:80/announce'
    list << 'udp://tracker.istole.it:80/announce'
    list.uniq
  end

  def size
    total_size = 0
    if @torrent['info'] && files = @torrent['info']['files']
      files.each do |file|
        total_size += file['length']
      end
    end
    total_size
  end

  def magnet_link
    params = {}
    params[:xt] = "urn:btih:" << hash
    params[:dn] = CGI.escape(@torrent["info"]["name"])
    params[:tr] = announce_list
    magnet_uri  = "magnet:?xt=#{params.delete(:xt)}"
    magnet_uri << "&" << Rack::Utils.build_query(params)
    magnet_uri
  end

  def get_seeds_count
    peers = []
    announce_list.each do |t|
      if tracker = valid_tracker(t)
        begin
          handler = Torckapi.tracker(t)
          tracker_peers = []
          timeout(8) do
            response = handler.announce(hash)
            response.peers.each do |p|
              tracker_peers << p[0]
            end
            tracker.update(last_alive_at: DateTime.now)
          end
        rescue Exception => e
          puts "#{t} => #{e}".red
          tracker.update(last_error_at: DateTime.now)
        else
          puts "#{t} => #{tracker_peers.count}".green if tracker_peers.count > 0
        end
        peers << tracker_peers
      end
    end
    uniq_peers = peers.flatten.uniq.size
    puts "#{name} => #{uniq_peers} peers".yellow
    uniq_peers
  end

  def valid_tracker t
    # URL válida?
    return false if !t || !(t =~ /^#{URI::regexp}$/)
    tracker = Tracker.find_or_create_by(url: t)
    # primeira vez? salve
    return Tracker.find_or_create_by(url: t) if tracker == nil
    # só valide se tracker estiver vivo na última semana
    tracker.last_alive_at && (tracker.last_alive_at > 1.week.ago) ? tracker : false
  end

end
