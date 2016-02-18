//
//  OGMediaConnection.h
//  OGPeerObjectiveC
//
//  Created by Omar Hussain on 2/9/16.
//  Copyright © 2016 ohgarage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "OGCommon.h"
#import "OGConnection.h"
#import "RTCMediaStream.h"
#import "RTCPeerConnection.h"
#import "RTCAudioTrack.h"
#import "RTCVideoTrack.h"

@class OGNegotiatorOptions;
@class OGMediaConnection;
@protocol OGMediaConnectionDelegate <OGConnectionDelegate>
- (void)connection:(OGMediaConnection *)connection onAddedRemoteStream:(RTCMediaStream *)stream;
- (void)connection:(OGMediaConnection *)connection onAddedLocalStream:(RTCMediaStream *)stream;
- (void)connection:(OGMediaConnection *)connection onRemovedRemoteStream:(RTCMediaStream *)stream;
- (void)connection:(OGMediaConnection *)connection onRemovedLocalStream:(RTCMediaStream *)stream;

- (void)connection:(OGMediaConnection *)connection onAddedLocalAudioTrack:(RTCMediaStream *)stream;
- (void)connection:(OGMediaConnection *)connection onRemovedLocalAudioTrack:(RTCMediaStream *)stream;

- (void)connection:(OGMediaConnection *)connection onAddedLocalVideoTrack:(RTCMediaStream *)stream;
- (void)connection:(OGMediaConnection *)connection onRemovedLocalVideoTrack:(RTCMediaStream *)stream;
@end

/**
 *  @brief Options object to initiate a media connection
 */
@interface OGMediaConnectionOptions : NSObject<OGConnectionOptions>
/**
 *  @brief Type of stream to initialize media connection with
 */
@property(nonatomic,assign) OGStreamType type;
/**
 *  @brief Camera direction to use
 */
@property(nonatomic,assign) AVCaptureDevicePosition direction;
@end

/**
 *  @brief Media connection to use for streaming
 */
@interface OGMediaConnection : OGConnection
/**
 *  @brief Remote audio stream
 */
@property(nonatomic, strong) RTCMediaStream *remoteStream;
/**
 *  @brief Local video stream
 */
@property(nonatomic, strong) RTCMediaStream *localStream;


/**
 *  @brief Answers the offer to connect a media call
 *
 *  @param streamtype Type of stream to reply media call with
 */
- (void)answer:(OGStreamType )streamtype;
/**
 *  @brief Adds stream
 *
 *  @param stream Stream object with audio/video tracks
 */
- (void)addStream:(RTCMediaStream *)stream;
/**
 *  @brief Removes stream
 *
 *  @param stream Stream object with audio/video tracks
 */
- (void)removeStream:(RTCMediaStream *)stream;
/**
 *  @brief Adds
 *
 *  @param track <#track description#>
 */
-(void)addLocalTrack:(RTCMediaStreamTrack *)track;
/**
 *  @brief Disable video stream to given peer
 *
 */
-(void)disableVideo;
/**
 *  @brief Disable audio stream to given peer
 *
 */
-(void)disableAudio;

/**
 *  @brief Enable video stream to given peer
 *
 */
-(void)enableVideo;
/**
 *  @brief Enable audio stream to given peer
 *
 */
-(void)enableAudio;
@end
