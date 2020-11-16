# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PortalsController, dbclean: :after_each do

  let(:user) { FactoryBot.create(:user) }
  let(:person) { FactoryBot.create(:person, user: user) }

  describe 'Index' do
    let(:user) { FactoryBot.build(:user) }
    let(:person) {FactoryBot.create(:person, user: user)}

    before do
      sign_in(user)
      get :index, params: {id: person.id}
    end

    it 'should return success status' do
      expect(response).to have_http_status(:success)
    end

    it 'should assign instance variable' do
      expect(assigns(:person)).to eq person
    end

    it 'should render manage_account template' do
      expect(response).to render_template("portals/index")
    end
  end

  describe 'Index' do
    let(:user) { FactoryBot.build(:user) }
    let(:person) {FactoryBot.create(:person, user: user)}

    before do
      sign_in(user)
      get :show, params: {id: person.id}
    end

    it 'should return success status' do
      expect(response).to have_http_status(:success)
    end

    it 'should assign instance variable' do
      expect(assigns(:person)).to eq person
    end

    it 'should render manage_account template' do
      expect(response).to render_template("portals/show")
    end
  end

  describe 'New' do
    let(:user) { FactoryBot.build(:user) }
    let(:person) {FactoryBot.create(:person, user: user)}
    let!(:site) { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :dc) }

    before do
      sign_in(user)
      get :new, params: { profile_type: :benefit_sponsor, portal: nil, id: person.id}
    end

    it 'should return success status' do
      expect(response).to have_http_status(:success)
    end

    it 'should assign instance variable' do
      expect(assigns(:person)).to eq person
      expect(assigns(:profile_type)).to eq 'benefit_sponsor'
    end

    it 'should render manage_account template' do
      expect(response).to render_template("portals/new")
    end
  end

end