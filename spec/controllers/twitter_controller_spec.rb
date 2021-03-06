require 'spec_helper'

describe TwitterController do

  describe 'POST #retweet' do
    context 'with a signed in user' do
      let(:user){ create(:user)}
      let(:twitter_app){ social_app = create(:twitter_app,:user => user) }
      before(:each) do
        sign_in user
      end

      it 'retweets posted tweet_id' do
        SocialDash::Clients::TwitterClient.any_instance.should_receive(:retweet).with(111)
        post :retweet ,:tweet_id => '111',:id => twitter_app.id
      end

      it 'renders json of retweeted tweet_id' do
        SocialDash::Clients::TwitterClient.any_instance.stub(:retweet).and_return({:test => 1})
        post :retweet , :tweet_id => '111',:id => twitter_app.id
        response.body.should eq({:test => 1}.to_json)
      end

    end
  end

  describe 'POST #reply' do
    context 'with a signed in user' do
      let(:user){ create(:user)}
      let(:twitter_app){ social_app = create(:twitter_app,:user => user) }
      before(:each) do
        sign_in user
      end

      it 'retweets posted tweet_id' do
        SocialDash::Clients::TwitterClient.any_instance.should_receive(:reply).with('blah',111)
        post :reply, :reply => {:in_reply_to_id => '111',:text => 'blah'}, :id => twitter_app.id
      end

      it 'renders json of retweeted tweet_id' do
        SocialDash::Clients::TwitterClient.any_instance.stub(:reply).and_return({:id => 1})
        post :reply, :reply => {:in_reply_to_id => '111',:text => 'blah'}, :id => twitter_app.id
        response.body.should eq({:id => 1}.to_json)
      end
    end
  end

  describe 'POST #update_settings' do
    context 'with a signed in user' do
      let(:user){ create(:user)}
      let(:twitter_app){ create(:twitter_app,:user => user) }
      before(:each) do
        sign_in user
      end

      it 'update settings of social_app' do
        SocialApp.any_instance.should_receive(:update_settings).with({'key' => 'value'})
        post :update_settings ,:settings => {'key' => 'value'},:id => twitter_app.id
      end

      it 'redirect to show page' do
        twitter_app.stub(:update_settings).with({'key' => 'value'})
        post :update_settings ,:settings => {'key' => 'value'},:id => twitter_app.id
        response.should redirect_to(social_app_path(twitter_app))
      end

    end
  end

  describe 'GET #search_results' do
    context 'with a signed in user' do
      let(:user){ create(:user)}
      let(:twitter_app){ create(:twitter_app,:user => user) }
      before(:each) do
        sign_in user
        SocialDash::Clients::TwitterClient.any_instance.stub(:search_results).and_return([1,2])
      end

      it 'assigns social app' do
        get :search_results, :id => twitter_app.id
        assigns(:social_app).should eq(twitter_app)
      end

      it 'assigns search results' do
        get :search_results, :id => twitter_app.id
        assigns(:search_results).should eq([1,2])
      end

      it 'renders search_results page' do
        get :search_results, :id => twitter_app.id
        response.should render_template 'social_apps/twitter/search_results'
      end

    end
  end
  describe 'POST #block' do
    context 'with a signed in user' do
      context 'when target user exists' do
        let(:user){ create(:user)}
        let(:twitter_app){ create(:twitter_app,:user => user) }
        before(:each) do
          sign_in user
        end
        it 'should block user' do
          twitter_results = [{:screen_name => 'bob'}]
          SocialDash::Clients::TwitterClient.any_instance.should_receive(:block).with('bob').and_return(twitter_results)
          post :block, :id => twitter_app.id, :user => {:screen_name => 'bob'}
        end
        it 'should render json of blocked user' do
          twitter_results = [{:screen_name => 'bob'}]
          SocialDash::Clients::TwitterClient.any_instance.should_receive(:block).with('bob').and_return(twitter_results)
          post :block, :id => twitter_app.id, :user => {:screen_name => 'bob'}
          response.body.should eq(twitter_results.to_json)
        end
      end
      context 'when target user does not exist' do
        let(:user){ create(:user)}
        let(:twitter_app){ create(:twitter_app,:user => user) }
        before(:each) do
          sign_in user
        end
        it 'should render 404' do
          SocialDash::Clients::TwitterClient.any_instance.should_receive(:block).with('bob').and_return(nil)
          post :block, :id => twitter_app.id, :user => {:screen_name => 'bob'}
          response.body.should eq({:error => 'User Not found'}.to_json)
          response.response_code.should eq(404)
        end
      end
    end
  end
  describe 'GET #blocking' do
    context 'with a signed in user' do
      let(:user){ create(:user)}
      let(:twitter_app){ create(:twitter_app,:user => user) }
      before(:each) do
        sign_in user
        SocialDash::Clients::TwitterClient.any_instance.stub(:blocking).and_return([1,2])
      end

      it 'assigns social app' do
        get :blocking, :id => twitter_app.id
        assigns(:social_app).should eq(twitter_app)
      end

      it 'assigns list of blocked users' do
        get :blocking, :id => twitter_app.id
        assigns(:blocked_users).should eq([1,2])
      end

      it 'renders blocking page' do
        get :blocking, :id => twitter_app.id
        response.should render_template 'social_apps/twitter/blocking'
      end

    end
  end
end
