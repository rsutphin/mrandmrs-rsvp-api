class InvitationSerializer < ActiveModel::Serializer
  embed :ids, :include => true

  attributes :id, :response_comments, :hotel

  has_many :guests
end
