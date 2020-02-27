class AccountController < ApplicationController
    skip_before_action :verifyLogin, only: [:LoginUser, :CreateUser, :existingUserName]
    def CreateUser
        userName = params['userName']
        if VerifyValidUserName(userName)
            userName = userName[0] == "@" ? userName:"@".concat(userName)
            user =  UsersRecord.new
            user.userName = userName.downcase
            user.userFullName = params['userFullName']
            user.userEmail = params['userEmail']
            user.password = params['password']
            user.userId = rand(10000000...90000000)
            if user.save
                render json: user.as_json, status: :created
            else
                # render json: user.as_json, status: :internal_server_error
                # render json: user.as_json, status: :unprocessable_entity
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
        user = UsersRecord.where("userName = :userName or userEmail = :userEmail", { userName: userNameChange.downcase, userEmail: userName }).limit(1)
        if user and user.count ==1 and user[0].authenticate(password)
            #generate web token
            webToken = GenerateLoginToken user[0].userId, user[0].id
            render json: {authentication:webToken, user:user}, status: :ok
        else
            render json: {status:"error", code:404, message:"User Not Exist"}, status: :not_found
        end
    end
    #################################################################################
    # people you are following
    # followingId is the id of the user you are following
    # the person i wamt to follow must not login but must be a valid user
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
    
    def Listfollowing
        following= Following.where("userId =:userId",{userId:getUserId[0]['userId']})
        render json: {following:following}, status: :ok
    end

    def unfollowing
        followOther = params['followingId']
        Following.delete_by(userId: getUserId[0]['userId'], followingId: followOther)
        following= Following.where("userId =:userId",{userId:getUserId[0]['userId']})
        render json: {following:following}, status: :ok
    end
    ###############################################################################
    # people following you
    # followerId is the id of the user that want to follow me
    # the person that i want to follow must be a valid user - (is not compulsory that he is login)
    def CreateFollowers
        followOther = params['followingId']
        myFollowRecord = UsersRecord.find_by("userId =:userId",{userId:followOther})
        if myFollowRecord
            if Follower.where("userId= :userId and followerId= :followerId",{userId:getUserId[0]['userId'],followerId:followOther })
            .first_or_create(
                    followerId:followOther,
                    userId:getUserId[0]['userId'],
                    users_record_id:getUserId[0]['rec_id']
                )
                render json: {message:"Follower Done"}, status: :ok
            else
                render json: {status:"error", code:422, message:"Failed"}, status: :unprocessable_entity
            end
        else
            render json: {status:"error", code:422, message:"Failed"}, status: :unprocessable_entity
        end
    end

    def Listfollowers
        follower= Follower.where("userId =:userId",{userId:getUserId[0]['userId']})
        render json: {follower:follower}, status: :ok
    end
    def unfollowers
        followOther = params['followingId']
        Follower.delete_by(userId: getUserId[0]['userId'], followerId: followOther)
        follower= Follower.where("userId =:userId",{userId:getUserId[0]['userId']})
        render json: {follower:follower}, status: :ok
    end
    #######################################################################################

    def existingUserName
        user = UsersRecord.all
        # render json: user.as_json(only:[:userName,:userId]), status: :ok
        render json: user.as_json(only:[:userName]), status: :ok
        #  render json: user.as_json(only:[:userName], include:[:followings, :followers]), status: :ok
        # respond_to do |format|
        #     format.html
        #     format.json {render json: user.as_json(only:[:userName], include:[:followings, :followers]), status: :ok}
        # end
    end
    def viewProfile
        user = UsersRecord.find_by_userId(getUserId[0]['userId'])
        render json: user.as_json(include:[:followings, :followers]), status: :ok
    end
    def updateProfile
        # render plain: params['userPhone'].empty?
        user = UsersRecord.find_by_userId(getUserId[0]['userId'])
        userPhone = (params['userPhone'].present? and !params['userPhone'].empty?) ? params['userPhone'] : user.userPhone
        userBio = (params['userBio'].present? and !params['userBio'].empty?) ? params['userBio'] : user.userBio
        userLocation = (params['userLocation'].present? and !params['userLocation'].empty?) ? params['userLocation'] : user.userLocation
        userWebsite = (params['userWebsite'].present? and !params['userEmail'].empty?)  ? params['userWebsite'] : user.userWebsite
        userEmail = (params['userEmail'].present? and !params['userEmail'].empty?) ? params['userEmail'] : user.userEmail
        userFullName = (params['userFullName'].present? and !params['userFullName'].empty?) ? params['userFullName'] : user.userFullName

        user.update_attribute(:userPhone, userPhone)
        user.update_attribute(:userBio, userBio)
        user.update_attribute(:userLocation, userLocation)
        user.update_attribute(:userWebsite, userWebsite)
        user.update_attribute(:userEmail, userEmail)
        user.update_attribute(:userFullName, userFullName)

        user = UsersRecord.find_by_userId(getUserId[0]['userId'])
        # render json: params.inspect.as_json, status: :created
        render json: user.as_json, status: :created
    end
    def loadTweets
        user = UsersRecord.find_by_userId(getUserId[0]['userId'])
        render json: user.as_json(include:[:followings, :followers]), status: :ok
    end
    private def post_user_params
        params.require(:UsersRecord).permit(:userEmail, :userName, :userFullName)
    end
end
