module SocialDash
  module Clients

    class FacebookClient

      def initialize(social_app)
        @credentials = social_app.settings['credentials'] || {}
        @cache_key = social_app.id
        @page_id = social_app.settings['page_id']
      end

      def self.settings_for(oauth_response)
        {'credentials' => oauth_response['credentials'],'page_id' => ''}
      end

      def client
        @client ||= FbGraph::User.me(@credentials['token'])
      end

      def available_pages
        client.accounts(:type => 'page')
      end

      def page_posts
        if @page_id.blank?
          raise 'PageIdNotSet'
        else
          fetch_fql "SELECT actor_id,message,created_time,post_id,likes,comments,likes.count,permalink FROM stream WHERE source_id = #{@page_id} AND actor_id != source_id"
        end
      end

      def name_from_id(id)
        fetch_fql("SELECT name FROM user WHERE uid = #{id}").first['name']
      end

      def like!(post_id)
        post_from_id(post_id).like!({:access_token => @credentials['token']})
      end

      def comment!(post_id,comment)
        post_from_id(post_id).comment!(:access_token => @credentials['token'],
          :message => escape_single_qoutes(comment))
      end

      def user_name
        client.fetch.name
      end

      def page_name
        unless @page_id.blank?
          fetch_fql("SELECT name FROM page WHERE page_id = #{@page_id}").first['name']
        end
      end

      def block!(user_id)
        managed_page.block!([FbGraph::User.new(user_id)],:access_token => @credentials['token'])
      end

      def blocked
        managed_page.blocked(:access_token => @credentials['token'])
      end

      def managed_page
        FbGraph::Page.new(@page_id)
      end

      def page_comment_count
        if @page_id.blank?
          0
        else
          (fetch_fql "SELECT actor_id FROM stream WHERE source_id = #{@page_id} AND actor_id != source_id").count
        end
      end

      def page_like_count
        if @page_id.blank?
          0
        else
          managed_page.fetch.like_count
        end
      end

      def page_comment_count_after(timestamp)
        if @page_id.blank?
          0
        else
          (fetch_fql "SELECT actor_id FROM stream WHERE source_id = #{@page_id} AND actor_id != source_id AND created_time > #{timestamp}").count
        end
      end

      def insights_data
        {:likes => page_like_count,:comments => page_comment_count }
      end

      def delete_comment(comment_id)
        post_from_id(comment_id).destroy(:access_token => @credentials['token'])
      end

      private

      def fetch_fql(query)
        FbGraph::Query.new(query).fetch(@credentials['token'])
      end

      def post_from_id(post_id)
        FbGraph::Post.new(post_id)
      end

      def escape_single_qoutes(str)
        str.gsub(/'/, {"'" => "\'"})
      end
    end

  end
end
