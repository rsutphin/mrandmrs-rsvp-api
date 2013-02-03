require 'spec_helper'

describe 'routing to invitations' do
  it 'routes GET /invitations/:id to invitations#show for code' do
    { :get => 'invitations/ER100' }.should route_to(
      :controller => 'invitations',
      :action => 'show',
      :id => 'ER100'
    )
  end

  it 'routes PUT /invitations/:id to invitations#update for code' do
    { :put => 'invitations/ER200' }.should route_to(
      :controller => 'invitations',
      :action => 'update',
      :id => 'ER200'
    )
  end

  it 'does not expose a list of invitations' do
    expect(:get => '/invitations').not_to be_routable
  end

  it 'does not permit deleting an invitation' do
    expect(:delete => '/invitations/foo').not_to be_routable
  end

  it 'does not permit adding a new invitation' do
    expect(:post => '/invitations').not_to be_routable
  end
end
