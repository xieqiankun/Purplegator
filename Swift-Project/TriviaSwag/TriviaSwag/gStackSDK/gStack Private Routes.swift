//
//  Private Routes.swift
//  gStackSDK
//
//  Created by Qiankun Xie on 3/23/16.
//  Copyright (c) 2015 Purple Gator. All rights reserved.
//

import Foundation

public class gStackPrizeWinner : NSObject {
    public var prize: String?
    public var displayName: String?
    public var avatar: String?
    public var image: String?
    public var color: String?
    public var date: NSDate?
    public var isTournament: Bool?
    public var tournament: gStackTournament?
}

//Make sure gstack func should use gStackMakeRequest and gStackProcessResponse
//qstack works
public func gStackFetchTournaments(completion: (error: NSError?, tournaments: Array<gStackTournament>?) -> Void) {
    gStackMakeRequest(true, route: "gettournaments", type: "getUserTournaments", payload: [String : AnyObject](), completion: {
        data, response, error in
        gStackProcessResponse(error, data: data, completion: { (error, payload) in
            
            if error == nil {
                if let _payload = payload as? [[String: AnyObject]] {
                    var returnTournaments = Array<gStackTournament>()
                    
                    for tournament in _payload {
                        returnTournaments.append(gStackTournament(tournament: tournament))
                    }
                    
                    //gStackCachedTournaments = returnTournaments
                    // Post notification for successfully fetch the tournaments
                    //NSNotificationCenter.defaultCenter().postNotificationName(gStackFetchTournamentsNotificationName, object: nil)
                    completion(error: nil, tournaments: returnTournaments)
                    gStackCacheDataManager.sharedInstance.setTournaments(returnTournaments)
                } else {
                    completion(error: error, tournaments: nil)
                }
                
            } else {
                completion(error: error, tournaments: nil)
            }
        })
    })
}

public func gStackSetCurrentUserInfo(displayName: String, avator: String){
    gStackAvator = avator
    gStackDisplayName = displayName
    
}

public func gStackClearCurrentUserInfo(){
    gStackAvator = ""
    gStackDisplayName = "Guest"
    
}

//qstack works
public func gStackStartGameForTournament(tournament: gStackTournament, completion: (error: NSError?, game: gStackGame?) -> Void) {
    if tournament.uuid == nil {
        tournament.uuid = ""
    }
    let requestDictionary = ["teams":[["displayName":gStackDisplayName, "channel": gStackPusherChannel!, "avatar": gStackAvator]],"gameMode":["type":"tournament","uuid":tournament.uuid!]]
    gStackMakeRequest(true, route: "startgame", type: "clientStartGame", payload: requestDictionary, completion: {
        data, reply, error in
        gStackProcessResponse(error, data: data ,completion: {
            _error, _ in
            if _error != nil {
                completion(error: _error, game: nil)
            } else {
                completion(error: nil, game: gStackGame.sharedGame)
            }
        })
    })
}


//qstack
public func gStackFetchLeaderboardForTournament(tournament: gStackTournament, completion: (error: NSError?, leaderboard: gStackTournamentLeaderboard?) -> Void) {
    if tournament.uuid == nil {
        let error = NSError(domain: "tournament uuid is missing", code: 2222, userInfo: nil)
        completion(error: error, leaderboard: nil)
    } else {
        var payload: [String: String]!
        if let userName = triviaCurrentUser?.displayName {
            payload = ["uuid":tournament.uuid!, "displayName":userName]
        } else {
            payload = ["uuid":tournament.uuid!]
        }
        gStackMakeRequest(true, route: "gettournaments", type: "clientGetTournamentLeaderboard", payload: payload, completion: {
            data, response, error in
            gStackProcessResponse(error, data: data, completion: {
                _error, _payload in
                if _error != nil {
                    completion(error: _error, leaderboard: nil)
                } else if let payload = _payload as? Dictionary<String,AnyObject> {
                    var leaderboard: gStackTournamentLeaderboard?
                    if let leaderboardPayload = payload["leaderboard"] as? [[String: AnyObject]] {
                        leaderboard = gStackTournamentLeaderboard(array: leaderboardPayload)
                    }
                    if let rank = payload["rank"] as? Int{
                        if leaderboard != nil {
                            leaderboard?.rank = rank
                        }
                    }
                    //store the leaderboard locally
                    if let id = tournament.uuid, let l = leaderboard {
                        gStackCacheDataManager.sharedInstance.setLeaderboard(id, leaderboard: l)
                    }
                    completion(error: nil, leaderboard: leaderboard)
                    
                } else {
                    completion(error: gStackMissingPayloadError, leaderboard: nil)
                }
            })
        })
    }
}

//qstack
public func gStackSubmitQuestion(question: gStackQuestion, completion: (error: NSError?) -> Void) {
    gStackMakeRequest(true, route: "submitquestion", type: "submitQuestion", payload: question.submitDictionary(), completion: {
        data, response, error in
        gStackProcessResponse(error, data: data, completion: {
            _error, _ in
            completion(error: _error)
        })
    })
}




//NOT USE FOR NOW


//qstack
public func gStackDeleteChallenge(challenge: gStackAsyncChallengeMessage, completion: (error: NSError?, updatedInbox: triviaUserInbox?) -> Void) {
    triviaDeleteCommunique(challenge, completion: completion)
}


//qstack
public func gStackMarkChallengeRead(challenge: gStackAsyncChallengeMessage, completion: (error: NSError?, updatedInbox: triviaUserInbox?) -> Void) {
    triviaMarkCommuniqueRead(challenge, completion: completion)
}


//qstack
public func gStackFlagQuestion(question: gStackQuestion, completion: (error: NSError?) -> Void) {
    makeRequest(true, route: "flagquestion", type: "flagQuestion", payload: question.flagDictionary(), completion: {
        data, response, error in
        processResponse(error, data: data, completion: {
            _error, _ in
            completion(error: _error)
        })
    })
}

//qstack
public func gStackUpVoteQuestion(tournament: gStackTournament, question: gStackGameQuestion, completion: (error: NSError?) -> Void) {
    if tournament.questions?._zone == nil || question.question == nil {
        let error = NSError(domain: "zone or questionBody is missing", code: 2222, userInfo: nil)
        completion(error: error)
    } else {
        makeRequest(true, route: "flagquestion", type: "upVoteQuestion", payload: ["zone":tournament.questions!._zone!,"question":question.question!], completion: {
            data, response, error in
            processResponse(error, data: data, completion: {
                _error, _ in
                completion(error: _error)
            })
        })
    }
}

//qstack
public func gStackDownVoteQuestion(tournament: gStackTournament, question: gStackGameQuestion, completion: (error: NSError?) -> Void) {
    if tournament.questions?._zone == nil || question.question == nil {
        let error = NSError(domain: "zone or questionBody is missing", code: 2222, userInfo: nil)
        completion(error: error)
    } else {
        makeRequest(true, route: "flagquestion", type: "downVoteQuestion", payload: ["zone":tournament.questions!._zone!,"question":question.question!], completion: {
            data, response, error in
            processResponse(error, data: data, completion: {
                _error, _ in
                completion(error: _error)
            })
        })
    }
}



//qstack
public func gStackDeclineAsyncChallenge(challenge: gStackAsyncChallengeMessage, completion: (error: NSError?) -> Void) {
    if challenge._id == nil {
        let error = NSError(domain: "challenge id is missing", code: 2222, userInfo: nil)
        completion(error: error)
    } else {
        makeRequest(true, route: "declineAsyncChallenge", type: "clientDeclineAsyncChallenge", payload: ["challengeId":challenge._id!], completion: {
            data, response, error in
            processResponse(error, data: data, completion: {
                _error, _ in
                completion(error: _error)
            })
        })
    }
}

//qstack
public func gStackGetOpenAsyncChallenges(completion: (error: NSError?, games: Array<gStackAsyncChallengeGame>?) -> Void) {
    makeRequest(true, route: "getOpenAsyncChallenges", type: "clientGetOpenAsyncChallenges", payload: true, completion: {
        data, response, error in
        processResponse(error, data: data, completion: {
            _error, _payload in
            if _error != nil {
                completion(error: _error, games: nil)
            } else if let payload = _payload as? Dictionary<String,AnyObject> {
                if let gamesDictionary = payload["games"] as? Array<Dictionary<String,AnyObject>> {
                    var games = Array<gStackAsyncChallengeGame>()
                    for game in gamesDictionary {
                        games.append(gStackAsyncChallengeGame(dictionary: game))
                    }
                    completion(error: nil, games: games)
                } else {
                    let missingError = NSError(domain: "Missing games", code: 1111, userInfo: nil)
                    completion(error: missingError, games: nil)
                }
            } else {
                completion(error: gStackMissingPayloadError, games: nil)
            }
        })
    })
}

