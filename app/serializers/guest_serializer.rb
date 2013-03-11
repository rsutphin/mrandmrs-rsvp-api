class GuestSerializer < ActiveModel::Serializer
  attributes :id, :name, :email_address, :attending, :entree_choice,
    :invited_to_rehearsal_dinner, :attending_rehearsal_dinner

  class << self
    ##
    # @return [Guest]
    def from_json(json_hash)
      Guest.new.tap do |g|
        # This should probably use self.schema, but that method in
        # active_model_serializers is currently ActiveRecord-specific.
        self._attributes.values.each do |a|
          setter = "#{a}="
          if g.respond_to?(setter)
            g.send(setter, json_hash[a.to_s])
          end
        end
      end
    end
  end
end
