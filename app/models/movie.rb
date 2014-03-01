class Movie < ActiveRecord::Base
	has_and_belongs_to_many :directors
	has_and_belongs_to_many :genres
	has_and_belongs_to_many :countries
  has_and_belongs_to_many :trackers
  has_many :seeds

  scope :preto, -> {where('torrent_hash is null')}
  scope :vermelho, -> {where('count = 0')}
  scope :amarelo, -> {where('count = 0')}

  validates_uniqueness_of :nome
  #default_scope -> { order(:ano) }

  def torrent
    # only for development
    require "#{Rails.root.to_s}/lib/torrent_info"
    file = Rails.root.join("public/torrents/#{self.id}.torrent")
    TorrentInfo.new file
  end

  before_save :urlize
  def urlize
    self.urlized = self.nome.urlize
  end

end
