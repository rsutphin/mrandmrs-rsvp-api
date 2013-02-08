class InvitationsController < ApplicationController
  def show
    invitation = Invitation.find(params[:id])
    render :json => invitation
  end

  def update
    invitation = InvitationSerializer.from_json(params)

    if invitation.id != params['id']
      response.status = 422
      render :json => {
        "errors" => [
          "Updates for invitation #{invitation.id} must be sent to its resource, #{invitation_path(invitation.id)}."
        ]
      }
      return
    end

    invitation.save
  end
end
