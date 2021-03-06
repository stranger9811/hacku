class DemoController < ApplicationController
    def home
      @oauth_url = MiniFB.oauth_url('199535680199935', # your Facebook App ID (NOT API_KEY)
                                    "http://rocky-ravine-5583.herokuapp.com/demo/index", # redirect url
                                    :scope=>MiniFB.scopes.join(","))
    
    end
    def mail
      email_list = params[:email_id].split(",")
      for email in email_list
          url = "https://sendgrid.com/api/mail.send.json"

          response = HTTParty.post url, :body => {
            "api_user" => "stranger9811",
            "api_key" => "password",
            "to" => email,
            "from" => cookies[:user_email],
            "subject" => "Test Mail",
            "text" => "You are invited to party."
          }
      end
    
    end
    
    def main
      require 'google/api_client'
      
      itunes_limit=2
      artist_limit=2
      music_limit="3"
      developer_key = "4IzaSyBLkCKyf8cM6Hzxe3r19kmmR0gh7MTidHA"
      api_service = "youtube"
      api_version = "v3"

      client = Google::APIClient.new(:key => developer_key,
                                     :authorization => nil)
      youtube = client.discovered_api(api_service, api_version)
      @id_list=[]
      for i in params
        x=i[0].split(" ")
        if x[0]=="user_comming"
          @id_list.push(x[1])
        end
      end
      @music_list=Hash.new()
     # @username_list=Hash.new()
      for id in @id_list  
        data=$graph.get_object(id+"?fields=music.limit("+music_limit+")")  
        music_data = data["music"]
            
        songs=[]
            
        if music_data
           music_names = music_data["data"]
                
           for current_song in music_names
             songs.push(current_song["name"])
           end
         
         end
         @music_list[id]=songs
         #@username_list[id]=data["username"]
        
      end
      
      @top_song_list=Hash.new(0)
      for id in @id_list
        for song in @music_list[id]                         #add only invited friends
          @top_song_list[song]+=1
        end
      end

      @top_song_list =  @top_song_list.sort_by {|a,b| b}
      @top_song_list = @top_song_list.reverse
      @songs=[]
      i=0
     
      for album in @top_song_list
        @songs.push(album[0])
        i+=1
        if i>=artist_limit
          break
        end
      end
      
      @top_song_list=@songs
      puts @top_song_list
      @music_database=[]
      itunes = ITunes::Client.new
      
      for song_single in @top_song_list
        
        song_list = itunes.music(song_single, :limit => itunes_limit)
        song_list=song_list.results
    
        for song_loop in song_list                   # don't take all songs
          
          music=Hash.new()
          music["title"] = song_loop.track_name
          music["itunes_track_id"]   =song_loop.track_id
          music["artist"]  = song_single
          if song_loop.collection_name
            music["album"] = song_loop.collection_name
          else
            music["album"] = ""
          end
           
          opts = Trollop::options do
            opt :q, 'Search term', :type => String, :default => "#{music["title"]} #{music["artist"]}"
            opt :maxResults, 'Max results', :type => :int, :default => 1
          end



          opts[:part] = 'id,snippet'
          search_response = client.execute!(
            :api_method => youtube.search.list,
            :parameters => opts
          )

          video_id=""

          search_response.data.items.each do |search_result|
            case search_result.id.kind
              when 'youtube#video'
                video_id=search_result.id.videoId
   
            end
          end
          if video_id!=""
            music["youtube_id"] = video_id
            @music_database.push(music)
          end
        end
      end
      
      #sending facebook invitation
      #for id_single in @id_list
      if "ass"=="a"
        require 'xmpp4r_facebook'
        app_id = "572817559525702"
        app_secret="e2591c4efec061263b0b42a7f9509c37"
        id = $user["id"]+'@chat.facebook.com'
        to = id_single+'@chat.facebook.com'
        puts id,to
        body = "hello"
        subject = 'hello'
        message = Jabber::Message.new to, body
        message.subject = subject
        puts message
        client = Jabber::Client.new Jabber::JID.new(id)
        client.connect
        client.auth_sasl(Jabber::SASL::XFacebookPlatform.new(client, app_id, $access_token, app_secret), nil)
        client.send message
        puts "message sent"
        client.close
      end
      
      #adding to database
      for i in @music_database 
        s = Song.new 
        s.party_id = $party.id
        s.itunes_track_id = i["itunes_track_id"] 
        s.artist = i["artist"]
        s.votes = 0
        s.title = i["title"]
        s.youtube_id = i["youtube_id"]
        s.album=i["album"]
        s.save
      end

      redirect_to :controller => 'song' , :action => 'list' , :party_id=>$party.id
      
    end
    def index
        #access_token_hash = MiniFB.oauth_access_token('204212613074016', "http://rocky-ravine-5583.herokuapp.com",  'b4653e6a3fecb75fc9909336f44b25a6', params[:code])
        #$access_token = access_token_hash["access_token"]
        friend_limit="20"
        $access_token = "CAACEdEose0cBAK8SVne4yHAV6Y1gpmNcX1KNlcsZCG9zsjy8GADHnbjwOPEVcwnP03TF3jIQANCATloZA38jCrFZBGQjUxFunNiqciPRPPFsF27mXhI6E1MzpYvMCGEeB7pw77lVbclVTln0hAQ8YSwJ3eoCSDgwqV44cSgZAIZCklSJFmP8eqTXnmvQPFeUQGOi5MVbOYgZDZD"
        $graph=Koala::Facebook::API.new($access_token)
        $user=$graph.get_object("me")
        $party=Party.create(:party_admin=>$user["name"])
        cookies[:party_id]=$party.id
        cookies[:user_email] = $user["username"]+"@sendgrid.me"
       
        @name_list=Hash.new
        @id_list=[]
        @profile_pic_list=Hash.new()

        profile_pic = $graph.get_object("me/friends?fields=picture,name&limit="+friend_limit)
        

        for friend in profile_pic
          @profile_pic_list[friend["id"]]=friend["picture"]["data"]["url"]
          @id_list.push(friend["id"])
          @name_list[friend["id"]]=friend["name"]
        end
        @name_list =  @name_list.sort_by {|a,b| b}
    end
end
