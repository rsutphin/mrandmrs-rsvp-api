class InvitationSerializer < ActiveModel::Serializer
  embed :ids, :include => true

  attributes :id, :response_comments, :hotel

  has_many :guests

  class << self
    ##
    # N.b., the implementations here and in {GuestSerializer} are _not_ generic.
    # They make different assumptions about the structure of the incoming JSON
    # that are suitable to their separate uses.
    #
    # @return [Invitation]
    def from_json(json_hash)
      all_guests = (json_hash['guests'] || []).
        collect { |json_guest| GuestSerializer.from_json(json_guest) }

      invitation = Invitation.new.tap do |i|
        # This should probably use self.schema, but that method in
        # active_model_serializers is currently ActiveRecord-specific.
        self._attributes.values.each do |a|
          setter = "#{a}="
          if i.respond_to?(setter)
            i.send(setter, json_hash['invitation'][a.to_s])
          end
        end
      end

      invitation_guest_ids = json_hash['invitation']['guests'] || []
      invitation.guests = invitation_guest_ids.collect { |gid| all_guests.find { |g| g.id == gid } }
      invitation.guests.each  { |g| g.invitation = invitation }

      invitation
    end
  end
end
