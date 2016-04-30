require 'rails_helper'

RSpec.describe Exchanges::AnnouncementsController do
  let(:announcement) { FactoryGirl.create(:announcement) }
  let(:user) { FactoryGirl.create(:user) }

  describe "GET index" do
    it "should redirect when login without hbx_staff" do
      sign_in user
      get :index
      expect(response).to have_http_status(:redirect)
      expect(flash[:error]).to eq "You must be an HBX staff member"
    end

    context "with hbx_staff" do
      context "without filter" do
        before :each do
          allow(user).to receive(:has_hbx_staff_role?).and_return true
          sign_in user
          get :index
        end

        it "renders index" do
          expect(response).to have_http_status(:success)
          expect(response).to render_template("exchanges/announcements/index")
        end

        it "get current announcements" do
          expect(assigns(:announcements)).to eq Announcement.current
        end
      end

      context "with filter" do
        before :each do
          allow(user).to receive(:has_hbx_staff_role?).and_return true
          sign_in user
          get :index, filter: 'all'
        end

        it "get all announcements" do
          expect(assigns(:announcements)).to eq Announcement.all
        end
      end
    end
  end

  describe "POST create" do
    let(:announcement_params) { {announcement: {content: 'msg', start_date: '2016-3-1', end_date: '2016-10-1', audiences: ['Employer']}} }

    it "should redirect when login without hbx_staff" do
      sign_in user
      post :create, announcement_params
      expect(response).to have_http_status(:redirect)
      expect(flash[:error]).to eq "You must be an HBX staff member"
    end

    context "with hbx_staff" do
      before :each do
        allow(user).to receive(:has_hbx_staff_role?).and_return true
        sign_in user
        post :create, announcement_params
      end

      it "should redirect" do
        expect(response).to have_http_status(:redirect)
      end

      it "should get successful notice" do
        expect(flash[:notice]).to eq "Create Announcement Successful."
      end
    end
  end

  describe "DELETE destroy" do
    it "should redirect when login without hbx_staff" do
      sign_in user
      delete :destroy, id: announcement.id
      expect(response).to have_http_status(:redirect)
      expect(flash[:error]).to eq "You must be an HBX staff member"
    end

    context "with hbx_staff" do
      before :each do
        allow(user).to receive(:has_hbx_staff_role?).and_return true
        sign_in user
        delete :destroy, id: announcement.id
      end

      it "should redirect" do
        expect(response).to have_http_status(:redirect)
      end

      it "should get successful notice" do
        expect(flash[:notice]).to eq "Destroy Announcement Successful."
      end
    end
  end
end
