class Rekeyer
  attr_reader :store

  CHARS = %w(2 3 4 6 7 8 9 a b c d e f h k r t w x y z)
  LENGTH = 6

  def initialize(store)
    @store = store
  end

  ##
  # Steps through the model sheets in the given store and replaces each distinct
  # RSVP ID value with a new randomly generated value.
  def rekey!
    [Guest.sheet_name, Invitation.sheet_name].each do |sheet_name|
      sheet = store.get_sheet(sheet_name)
      sheet.each do |row|
        row['RSVP ID'] = new_key(row['RSVP ID'])
      end
      store.replace_sheet(sheet_name, sheet)
    end
    $stderr.puts "Replaced #{new_keys.size} RSVP IDs"
  end

  private

  def new_keys
    @new_keys ||= {}
  end

  def new_key(old_key)
    new_keys[old_key] ||= generate_key
  end

  def prng
    @prng ||= Random.new
  end

  def generate_key
    to_chars(
      prng.rand(CHARS.size ** LENGTH),
      LENGTH
    ).upcase
  end

  def to_chars(i, size)
    converted = ''
    while i > 0
      converted << CHARS[i % CHARS.size]
      i /= CHARS.size
    end
    ("%#{size}s" % converted).gsub(' ', CHARS[0])
  end
end
