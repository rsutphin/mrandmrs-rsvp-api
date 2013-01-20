class GuestSerializer < ActiveModel::Serializer
  attributes :id, :name, :email_address, :attending, :entree_choice
end
