//
//  OGNegotiator.h
//  OGPeerObjectiveC
//
//  Created by Omar Hussain on 2/9/16.
//  Copyright © 2016 ohgarage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OGCommon.h"
#import "OGConnection.h"
#import "RTCPeerConnection.h"
/**
 *  @brief Options associated with a negotiator object at the time of initalizing
 */
@interface OGNegotiatorOptions : NSObject
/**
 *  @brief Local stream reference
 */
@property (nonatomic, assign) RTCMediaStream * localStream;
/**
 *  @brief Is current negotiator originator
 */
@property (nonatomic, assign) BOOL originator;
/**
 *  @brief Payload received in offer message
 */
@property (nonatomic, strong) OGMessagePayload * payload;
@end

/**
 *  @brief Negotiator object negotiates connection with peer
 */
@interface OGNegotiator : NSObject
/**
 *  @brief Options used to initialized negotiator
 */
@property (nonatomic,strong) OGNegotiatorOptions * options;
/**
 *  @brief Initialized negotiator with given options
 *
 *  @param options Options object
 *
 *  @return Initialized negotiator
 */
-(instancetype)initWithOptions:(OGNegotiatorOptions *)options;
/**
 *  @brief Starts peer connection with provided options and connection
 *
 *  @param connection Connection object
 *  @param options    Options object
 *
 *  @return The peer connection object
 */
-(RTCPeerConnection *)startConnection:(OGConnection *)connection options:(OGNegotiatorOptions *)options;
/**
 *  @brief Identifier prefix for negotiator
 *
 *  @return String prefix for peer connection object
 */
+(NSString *)identifierPrefix;

/**
 *  @brief Get an existing or create and return a peer connection
 *
 *  @param connection Connection object
 *  @param options    Options object
 *
 *  @return A peer connection object
 */
-(RTCPeerConnection *)getPeerConnection:(OGConnection *)connection options:(OGNegotiatorOptions *)options;
/**
 *  @brief Starts an existing peer connection or creates one
 *
 *  @param connection Connection object
 *
 *  @return A peer connection object
 */
- (RTCPeerConnection *)startPeerConnection:(OGConnection *)connection;
/**
 *  @brief Handles a session description message of given type for given connection
 *
 *  @param type       Type of message
 *  @param connection Connection object
 *  @param sdp        Session description object
 */
- (void)handleSDP:(OGMessageType)type connection:(OGConnection *)connection sdp:(RTCSessionDescription *)sdp;
/**
 *  @brief Makes offer to given connection
 *
 *  @param connection Connection object
 */
- (void)makeOffer:(OGConnection *)connection;
/**
 *  @brief Handles candidate message for given connection
 *
 *  @param connection Connection object
 *  @param candidate  Candidate object
 */
- (void)handleCandidate:(OGConnection *)connection ice:(RTCICECandidate *)candidate;
/**
 *  @brief Makes answer to send for given connection
 *
 *  @param connection Connection object
 */
- (void)makeAnswer:(OGConnection *)connection;
/**
 *  @brief Cleans up peer connection
 *
 *  @param connection Connection object
 */
-(void)cleanup:(OGConnection *)connection;

/**
 *  @brief Returns an initialized audio track
 *
 *  @return Initialized audio track
 */
-(RTCAudioTrack *)addAudioTrack;
/**
 *  @brief Returns an initialized video track
 *
 *  @param position Camera position
 *
 *  @return Initialized video track
 */
-(RTCVideoTrack *)addVideoTrack:(AVCaptureDevicePosition)position;
@end
