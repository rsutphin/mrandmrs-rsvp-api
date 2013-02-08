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
    return unless verify_invitation_exists_before_update

    invitation = InvitationSerializer.from_json(params)

    return unless verify_invitation_matches_url(invitation)

    invitation.save
  end

  private

  def high_level_errors_entity(*errors)
    {
      "errors" => errors
    }
  end

  def verify_invitation_exists_before_update
    if Invitation.exist?(params['id'])
      true
    else
      response.status = 404
      render :json => high_level_errors_entity("There is no invitation #{params['id']}. Invitations may not be created with this interface.")
      false
    end
  end

  def verify_invitation_matches_url(invitation)
    if invitation.id != params['id']
      response.status = 422
      render :json => high_level_errors_entity(
        "Updates for invitation #{invitation.id} must be sent to its resource, #{invitation_path(invitation.id)}.")
      false
    else
      true
    end
  end
end
