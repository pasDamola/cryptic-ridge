class AccountController < ApplicationController
    skip_before_action :verifyLogin, only: [:LoginUser, :CreateUser, :existingUserName]
    def CreateUser
        userName = params['userName']
        if VerifyValidUserName(userName)
            userName = userName[0] == "@" ? userName:"@".concat(userName)
            user =  UsersRecord.new
            user.username = userName.downcase
            user.userfullname = params['userFullName']
            user.useremail = params['userEmail']
            user.password = params['password']
            user.userid = rand(10000000...90000000)
            if user.save
                render json: user.as_json, status: :created
            else
                render json: {status:"error", code:422, message:"Unable To Create Account"}, status: :unprocessable_entity
            end
        else
            render json: {status:"error", code:422, message:"Invalid User Name"}, status: :unprocessable_entity
        end
    end

    def LoginUser
        userName = params['userName']
        password = params['password']
        userNameChange = userName[0] == "@" ? userName:"@".concat(userName)
        user = UsersRecord.where("username = :userName or useremail = :userEmail", { userName: userNameChange.downcase, userEmail: userName }).limit(1)
        if user.count ==1 and user[0].authenticate(password)
            #generate web token
            webToken = GenerateLoginToken user[0].userId, user[0].id
            render json: {authentication:webToken, user:user}, status: :ok
        else
            render json: {status:"error", code:404, message:"User Not Exist"}, status: :not_found
        end
    end
    #################################################################################
    # people you are following                                                      #
    # followingId is the id of the user you are following                           #
    #you become a follower to the person your are following                         #
    # the person i wamt to follow must not login but must be a valid user           #
    #################################################################################
    def CreateFollowing
        myFollowId = params['followingId']
        myFollowRecord = UsersRecord.find_by("userId =:userId",{userId:myFollowId})
        if myFollowRecord
            if Following.where("userId= :userId and followingId= :followingId",{userId:getUserId[0]['userId'],followingId:myFollowId })
            .first_or_create(
                followingId:myFollowId,
                userId:getUserId[0]['userId'],
                users_record_id:getUserId[0]['rec_id']
            )
                render json: {message:"Following"}, status: :ok
            else
                render json: {status:"error", code:422, message:"Failed to Follow"}, status: :unprocessable_entity
            end
        else
            render json: {status:"error", code:422, message:"Failed to Follow"}, status: :unprocessable_entity
        end
    end
    # people wey u dey follow
    def Listfollowing
        following= Following.where("userId =:userId",{userId:getUserId[0]['userId']})
        render json: {following:following}, status: :ok
    end
    # people wey they follow you
    def Listfollowers
        follower= Following.where("followingId =:followingId",{followingId:getUserId[0]['userId']})
        render json: {info:getUserId[0]['userId'], follower:follower}, status: :ok
    end
    def unfollowing
        followOther = params['followingId']
        Following.delete_by(userId: getUserId[0]['userId'], followingId: followOther)
        following= Following.where("userId =:userId",{userId:getUserId[0]['userId']})
        render json: {following:following}, status: :ok
    end

    #################################################################################
    # Related Profile Actions                                                       #
    # - exisiting username                                                          #
    # - view single profile                                                         #
    # - all update on user profile                                                  #
    #################################################################################
    def existingUserName
        user = UsersRecord.all
        render json: user.as_json(only:[:userName]), status: :ok
    end
    def viewProfile
        user = UsersRecord.find_by_userId(getUserId[0]['userId'])
        showUser = user.as_json
        showUser[:dp] = url_for(user.dp) 
        showUser[:coverPhoto] = url_for(user.coverPhoto)
        showUser[:followings] = user.followings.count
        showUser[:followers] = Following.where("followingId =:followingId",{followingId:getUserId[0]['userId']}).count
        render json: showUser.as_json, status: :ok
    end
    def updateProfile
        user = UsersRecord.find_by_userId(getUserId[0]['userId'])
        userPhone = !params['userPhone'].nil? ? ((params['userPhone'].present? and !params['userPhone'].empty?) ? params['userPhone'] : user.userPhone) : user.userPhone
        userBio = !params['userBio'].nil? ? ((params['userBio'].present? and !params['userBio'].empty?) ? params['userBio'] : user.userBio) : user.userBio
        userLocation = !params['userLocation'].nil? ? ((params['userLocation'].present? and !params['userLocation'].empty?) ? params['userLocation'] : user.userLocation): user.userLocation
        userWebsite = !params['userWebsite'].nil? ? ((params['userWebsite'].present? and !params['userWebsite'].empty?)  ? params['userWebsite'] : user.userWebsite) : user.userWebsite
        userEmail = !params['userEmail'].nil? ? ((params['userEmail'].present? and !params['userEmail'].empty?) ? params['userEmail'] : user.userEmail): user.userEmail
        userFullName = !params['userFullName'].nil? ? ((params['userFullName'].present? and !params['userFullName'].empty?) ? params['userFullName'] : user.userFullName) : user.userFullName
        dob = !params['dob'].nil? ? ((params['dob'].present? and !params['dob'].empty?) ? params['dob'] : user.dob): user.dob
        
        user.update_attribute(:userPhone, userPhone)
        user.update_attribute(:userBio, userBio)
        user.update_attribute(:userLocation, userLocation)
        user.update_attribute(:userWebsite, userWebsite)
        user.update_attribute(:userEmail, userEmail)
        user.update_attribute(:userFullName, userFullName)
        user.update_attribute(:dob, dob)
        # upload display pics
        if params[:dp]
            user.dp.attach(params[:dp])
        end
        # display cover photo
        if params[:coverPhoto]
            user.coverPhoto.attach(params[:coverPhoto])
        end
        render json: {updated:"Updated"}, status: :ok
    end
    def updatePassword
        user = UsersRecord.find_by_userId(getUserId[0]['userId'])
        if user and user.authenticate(params['userOldPassword'])
            user.update_attribute(:password, params['userNewPassword'])
            render json: {updated:"Updated"}, status: :ok
        else
            render json: {status:"error", code:422, message:"Failed to Update"}, status: :unprocessable_entity
        end
    end
    def CreateTweet
        tweet = Tweet.new
        user = UsersRecord.find_by_userId(getUserId[0]['userId'])
        tweetBody = !params['tweetBody'].nil? ? ((params['tweetBody'].present? and !params['tweetBody'].empty?) ? params['tweetBody'] : "") : ""
        p tweetBody
        tweet.tweetInfo = tweetBody
        tweet.users_record_id = user.id
        tweet.userId = user.userId
        if params[:tweetAttachments]
            tweet.tweetAttachments.attach(params[:tweetAttachments])
        end
        
        if tweet.save
            render json: Tweet.all.as_json, status: :ok
        else
            render json: {status:"error", code:422, message:"Failed to Update"}, status: :unprocessable_entity
        end
    end
    def loadTweets
        current_page = params[:page] ? params[:page].to_i : 1
        recPerPage = 20
        recOffset = (current_page - 1) * recPerPage
        tweetAll = []
        following= Following.where("userId =:userId",{userId:getUserId[0]['userId']})
        sam = following.to_a.map{|p| p.followingId}.push(getUserId[0]['userId'])
        tweets = Tweet.where('userId IN (?)', sam).limit(recPerPage).offset(recOffset).order(id: :desc)
        tweets.each do |singleTweet|
            eachTweet ={}
            eachTweet[:tweet] = singleTweet
            tweetAttachs = []
            singleTweet.tweetAttachments.each do |tweetFile|
                tweetAttachs.push(url_for(tweetFile))
            end
            eachTweet[:tweetAttachs] = tweetAttachs.as_json
            eachTweet[:userFullName] = singleTweet.users_record.userFullName
            eachTweet[:userName] = singleTweet.users_record.userName
            tweetAll.push(eachTweet)
        end
        render json: tweetAll.as_json, status: :ok
    end
    private def post_user_params
        params.require(:UsersRecord).permit(:userEmail, :userName, :userFullName)
    end
end
