require "pathname"
require "json"
require "set"
require_relative "artist"
require_relative "card"
require_relative "card_set"
require_relative "card_printing"
require_relative "query"
require_relative "spelling_suggestions"

class CardDatabase
  attr_reader :sets, :cards, :blocks, :artists
  def initialize
    @sets = {}
    @blocks = Set[]
    @cards = {}
    @artists = {}
    yield(self)
  end

  def search(query)
    query = Query.new(query) unless query.is_a?(Query)
    query.search(self)
  end

  def each_printing
    @cards.each do |card_name, card|
      card.printings.each do |printing|
        yield printing
      end
    end
  end

  def printings
    @printings ||= enum_for(:each_printing).to_set
  end

  def subset(sets)
    # puts "Loading subset: #{sets}"
    self.class.send(:new) do |db|
      db.send(:load_from_subset!, self, sets)
    end
  end

  def resolve_time(time)
    return nil unless time
    return time if time.is_a?(Date)
    sets = resolve_editions(time)
    case sets.size
    when 0
      nil
    when 1
      sets.first.release_date
    else
      raise "Can't parse time #{time}"
    end
  end

  # For sets and blocks:
  # "in" is code for "Invasion", don't substring match "Innistrad" etc.
  # "Mirrodin" is name for "Mirrodin", don't substring match "Scars of Mirrodin"
  #
  # Priority:
  # * exact MCI code
  # * exact gatherer code
  # * name exact match
  # * name substring match
  def resolve_editions(edition)
    edition = edition.downcase
    matching_mci_code = Set[]
    matching_gatherer_code = Set[]
    matching_name = Set[]
    matching_name_part = Set[]

    @sets.each do |set_code, set|
      matching_mci_code      << set if set_code == edition
      matching_gatherer_code << set if set.gatherer_code.downcase == edition
      matching_name          << set if normalize_name(set.name).downcase == edition
      matching_name_part     << set if normalize_name(set.name).downcase.include?(edition)
    end
    [
      matching_mci_code,
      matching_gatherer_code,
      matching_name,
      matching_name_part
    ].find{|s| s.size > 0} || Set[]
  end

  class <<self
    private :new

    def load(path)
      # puts "Initialize #{path}"
      new do |db|
        db.send(:load_from_json!, Pathname(path))
      end
    end
  end

  def suggest_spelling(word)
    spelling_suggestions.suggest(word)
  end

  def number_of_cards
    @cards.size
  end

  def number_of_printings
    printings.size
  end

  private

  def load_from_subset!(db, sets)
    @blocks = db.blocks
    db.sets.each do |set_code, set|
      next unless sets.include?(set_code)
      @sets[set_code] = set
    end
    db.cards.each do |card_name, card|
      printings = card.printings.select do |printing|
        sets.include?(printing.set_code)
      end
      next if printings.empty?
      @cards[card_name] = card.dup
      @cards[card_name].printings = printings
    end
    # color_identity already set in parent database
  end

  def load_from_json!(path)
    color_identity_cache = {}
    multipart_cards = {}
    data = JSON.parse(path.open.read)
    data["sets"].each do |set_code, set_data|
      @sets[set_code] = CardSet.new(set_data)
      if set_data["block_code"]
        @blocks << set_data["block_code"]
        @blocks << normalize_name(set_data["block_name"])
      end
    end
    data["cards"].each do |card_name, card_data|
      next if card_data["layout"] == "token" # Do not include tokens
      normalized_name = card_name.downcase.tr("Äàáâäèéêíõöúûü", "Aaaaaeeeioouuu")
      card = @cards[normalized_name] = Card.new(card_data.reject{|k,_| k == "printings"})
      color_identity_cache[card_name] = card.partial_color_identity
      if card_data["names"]
        multipart_cards[card_name] = card_data["names"] - [card_name]
      end
      card_data["printings"].each do |set_code, printing_data|
        printing = CardPrinting.new(
          card,
          @sets[set_code],
          printing_data
        )
        card.printings << printing
        @sets[set_code].printings << printing
      end
      card.first_release_date
      card.last_release_date
    end
    fix_multipart_cards_color_identity!(color_identity_cache)
    link_multipart_cards!(multipart_cards)
    setup_artists!
  end

  def fix_multipart_cards_color_identity!(color_identity_cache)
    @cards.each do |card_name, card|
      if card.has_multiple_parts?
        card.color_identity = card.names.map{|n| color_identity_cache[n].chars }.inject(&:|).sort.join
      end
    end
  end

  def link_multipart_cards!(multipart_cards)
    multipart_cards.each do |card_name, other_names|
      card = @cards[card_name.downcase]
      other_cards = other_names.map{|name| @cards[name.downcase] }
      card.printings.each do |printing|
        printing.others = other_cards.map do |other_card|
          from_same_set = other_card.printings.select{|other_printing| other_printing.set_code == printing.set_code}
          unless from_same_set.size == 1
            raise "Can't link other side - #{card_name}"
          end
          from_same_set[0]
        end
      end
    end
  end

  def setup_artists!
    each_printing do |printing|
      artist_name = printing.artist_name
      # Presumably same artist, just keep that consistent to simplify slug code
      # We could even fix some unset artists here
      if artist_name == "JOCK"
        artist_name = "Jock"
      end
      artist_slug = artist_name.downcase.gsub(/[^a-z]+/, "_")
      @artists[artist_slug] ||= Artist.new(artist_name)
      artist = @artists[artist_slug]
      unless artist_name == artist.name
        warn "Different artists have same slug - `#{artist_name}' `#{artist.name}'"
      end
      artist.printings << printing
      printing.artist = artist
    end
  end

  # These method seem to occur in every single class out there
  def normalize_text(text)
    text.downcase.gsub(/[Ææ]/, "ae").tr("Äàáâäèéêíõöúûü’\u2212", "Aaaaaeeeioouuu'-").strip
  end

  def normalize_name(name)
    normalize_text(name).split.join(" ")
  end

  def spelling_suggestions
    @spelling_suggestions ||= begin
      ss = SpellingSuggestions.new
      @cards.keys.each do |title|
        ss << title
      end
      ss
    end
  end
end
