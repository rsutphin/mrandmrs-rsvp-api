class InvitationsController < ApplicationController
  def show
    invitation = Invitation.find(params[:id])
    if invitation
      render :json => invitation
    else
      response.status = 404
      render :json => high_level_errors_entity("There is no invitation #{params['id']}.")
    end
  end

  def update
    unless Invitation.exist?(params[:id])
      response.status = 404
      render :json => high_level_errors_entity("There is no invitation #{params['id']}. Invitations may not be created with this interface.")
      return
    end

    invitation = InvitationSerializer.from_json(params)

    if invitation.id != params['id']
      response.status = 422
      render :json => high_level_errors_entity(
        "Updates for invitation #{invitation.id} must be sent to its resource, #{invitation_path(invitation.id)}.")
      return
    end

    invitation.save
  end

  private

  def high_level_errors_entity(*errors)
    {
      "errors" => errors
    }
  end
end
