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

    if invitation.valid? && invitation.guests.all? { |g| g.valid? }
      invitation.save
      render :json => { 'ok' => true }
    else
      response.status = 422

      error_response = {}
      if inv_e = error_pod(invitation)
        error_response['invitation'] = inv_e
      end
      guest_es = invitation.guests.collect { |g| error_pod(g) }.compact
      unless guest_es.empty?
        error_response['guests'] = guest_es
      end

      render :json => error_response
    end
  end

  private

  def high_level_errors_entity(*errors)
    {
      "errors" => errors
    }
  end

  def error_pod(model)
    if model.errors.empty?
      nil
    else
      { "id" => model.id, "errors" => model.errors.as_json }
    end
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
    if invitation.id.upcase != params['id'].upcase
      response.status = 422
      render :json => high_level_errors_entity(
        "Updates for invitation #{invitation.id} must be sent to its resource, #{invitation_path(invitation.id)}.")
      false
    else
      true
    end
  end
end
