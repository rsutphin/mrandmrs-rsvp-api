class Guest
  ##
  # @return [Invitation] the invitation under which this person is invited.
  attr_accessor :invitation

  ##
  # @return [String] the person's invited name.
  attr_accessor :name

  ##
  # @return [String,nil] the person's e-mail address, if known.
  attr_accessor :email_address

  ##
  # @return [Boolean,nil] whether this guest will attend. `nil` means "don't
  #   know" or "not responded yet".
  attr_accessor :attending

  ##
  # @return [String,nil] entree choice.
  attr_accessor :entree_choice

  ##
  # Provides the generated ID for this record.
  def id
    name.gsub(' ', '').downcase
  end
end
