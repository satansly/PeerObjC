//
//  OGMediaConnection.h
//  OGPeerObjectiveC
//
//  Created by Omar Hussain on 2/9/16.
//  Copyright © 2016 ohgarage. All rights reserved.
//

#import <Foundation/Foundation.h>
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


@interface OGMediaConnectionOptions : OGConnectionOptions
@property (nonatomic, strong) RTCMediaStream * stream;

@end


@interface OGMediaConnection : OGConnection
@property (nonatomic, assign) BOOL open;
@property (nonatomic, strong) OGMediaConnectionOptions * options;
@property (nonatomic, strong) RTCMediaStream * localStream;
@property (nonatomic, strong) RTCMediaStream * remoteStream;

- (instancetype)initWithPeer:(NSString *)peer provider:(OGPeer *)provider options:(OGMediaConnectionOptions *)options;
- (instancetype)initWithPeer:(NSString *)peer provider:(OGPeer *)provider;

- (void)answer:(RTCMediaStream *)stream;
- (void)close;
- (void)addStream:(RTCMediaStream *)stream;
@end
