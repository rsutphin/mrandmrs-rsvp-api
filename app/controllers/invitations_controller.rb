class InvitationsController < ApplicationController
  def show
    invitation = Invitation.find(params[:id])
    render :json => invitation
  end

  def update
    
  end
end
