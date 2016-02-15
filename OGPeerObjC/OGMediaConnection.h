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
@protocol OGMediaConnectionDelegate <NSObject>
- (void)connection:(OGMediaConnection *)connection onStream:(RTCMediaStream *)stream;
- (void)connection:(OGMediaConnection *)connection onRemoteAudioTrack:(RTCAudioTrack *)track;
- (void)connection:(OGMediaConnection *)connection onLocalAudioTrack:(RTCAudioTrack *)track;
- (void)connection:(OGMediaConnection *)connection onRemoteVideTrack:(RTCVideoTrack *)track;
- (void)connection:(OGMediaConnection *)connection onLocalVideTrack:(RTCVideoTrack *)track;
- (void)connectionOnClose:(OGMediaConnection *)connection;
- (void)connection:(OGMediaConnection *)connection onError:(NSError *)error;

@end


@interface OGMediaConnectionOptions : NSObject<OGConnectionOptions>
@property(nonatomic,assign) OGStreamType type;
@property(nonatomic,assign) AVCaptureDevicePosition direction;
@end


@interface OGMediaConnection : OGConnection
@property(nonatomic, strong) RTCVideoTrack *localVideoTrack;
@property(nonatomic, strong) RTCAudioTrack *localAudioTrack;
@property(nonatomic, strong) RTCMediaStream *localAudioStream;
@property(nonatomic, strong) RTCMediaStream *remoteAudioStream;
@property(nonatomic, strong) RTCVideoTrack *remoteVideoTrack;
@property(nonatomic, strong) RTCAudioTrack *remoteAudioTrack;
@property(nonatomic, strong) RTCMediaStream *localVideoStream;
@property(nonatomic, strong) RTCMediaStream *remoteVideoStream;



- (void)answer:(OGStreamType )streamtype;
- (void)addStream:(RTCMediaStream *)stream;
- (void)removeStream:(RTCMediaStream *)stream;
@end
