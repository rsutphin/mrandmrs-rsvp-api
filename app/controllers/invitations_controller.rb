class InvitationsController < ApplicationController
  def show
    invitation = Invitation.find(params[:id])
    render :json => invitation
  end

  def update
    invitation = InvitationSerializer.from_json(params)
    invitation.save
  end
end
