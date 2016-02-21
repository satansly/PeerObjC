//
//  OGMediaConnection.m
//  OGPeerObjectiveC
//
//  Created by Omar Hussain on 2/9/16.
//  Copyright © 2016 ohgarage. All rights reserved.
//

#import "OGMediaConnection.h"
#import "OGCommon.h"
#import "OGUtil.h"
#import "OGNegotiator.h"
#import "OGMessage.h"
#import <EventEmitter/EventEmitter.h>
#import <AVFoundation/AVFoundation.h>

@interface OGMediaConnectionOptions ()

@end
@implementation OGMediaConnectionOptions
@synthesize connectionId,constraints,metadata,payload;
+(instancetype)defaultConnectionOptions {
    OGMediaConnectionOptions * options = [[OGMediaConnectionOptions alloc] init];
    options.metadata = @{};
    return options;
}

@end
@interface OGMediaConnection ()


@end
@implementation OGMediaConnection
-(instancetype)initWithPeer:(NSString *)peer provider:(OGPeer *)provider {
    
    self = [self initWithPeer:peer provider:provider options:[OGMediaConnectionOptions defaultConnectionOptions]];
    if (self) {
        
    }
    return self;
}
-(instancetype)initWithPeer:(NSString *)peer provider:(OGPeer *)provider options:(id<OGConnectionOptions>)options {
    self = [super init];
    if(self) {
        _options = options;
        _open = false;
        _type = OGConnectionTypeMedia;
        _peer = peer;
        _provider = provider;
        _metadata = _options.metadata;
        
        _identifier = (_options.connectionId) ? _options.connectionId :[NSString stringWithFormat:@"%@%@",[OGMediaConnection identifierPrefix],[[OGUtil util] randomToken]];
        if(!_options.payload) {
            __weak typeof(self) weakSelf = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf initialize];
            });
        }
    }
    return self;
}
-(void)initialize {
    OGNegotiatorOptions * options = [[OGNegotiatorOptions alloc] init];
    if(_options.payload)
        options.originator = NO;
    else
        options.originator = YES;
    
    options.payload = _options.payload;
    
    _negotiator = [[OGNegotiator alloc] initWithOptions:options];
    if (!_localStream) {
        [_negotiator startConnection:self options:options];
    }
    
}
-(void)addStream:(RTCMediaStream *)remoteStream {
    DDLogDebug(@"Receiving stream %@", [remoteStream description]);
    
    if (remoteStream.videoTracks.count > 0 || remoteStream.audioTracks.count > 0) {
        self.remoteStream = remoteStream;
    }
    if(!self.remoteStream)
        [super emit:@"open" data:self];
    [self emit:@"stream" data:remoteStream]; // Should we call this `open`?
    [self perform:@selector(connection:onAddedRemoteStream:) withArgs:@[self,remoteStream]];
    
    
}

-(void)addLocalTrack:(RTCMediaStreamTrack *)track {
    if([track isKindOfClass:[RTCVideoTrack class]]) {
        [self.localStream addVideoTrack:(RTCVideoTrack *)track];
        [self perform:@selector(connection:onAddedLocalVideoTrack:) withArgs:@[self, _localStream]];
    }else{
        [self.localStream addAudioTrack:(RTCAudioTrack *)track];
        [self perform:@selector(connection:onAddedLocalAudioTrack:) withArgs:@[self, _localStream]];
    }
}



- (void)removeStream:(RTCMediaStream *)stream {
    [self emit:@"removed_stream" data:stream];
    [self perform:@selector(connection:onRemovedRemoteStream:) withArgs:@[self,stream]];
}
-(void)setLocalStream:(RTCMediaStream *)localStream {
    _localStream = localStream;
    [self emit:@"local_stream" data:localStream];
    [self perform:@selector(connection:onAddedLocalStream:) withArgs:@[self,localStream]];
}
-(void)handleMessage:(OGMessage *)message {
    OGMessagePayload * payload = message.payload;
    
    switch (message.type) {
        case OGMessageTypeAnswer:
            // Forward to negotiator
            [_negotiator handleSDP:message.type connection:self sdp:payload.sdp];
            _open = true;
            break;
        case OGMessageTypeCandidate:
            [_negotiator handleCandidate:self ice:payload.candidate];
            break;
        default:
            DDLogWarn(@"Unrecognized message type: %ld from peer: %@", (long)message.type, self.peer);
            break;
    }
}

- (void)answer:(OGStreamType )streamtype {
    if (_localStream ) {
        DDLogWarn(@"Local stream already exists on this MediaConnection. Are you answering a call twice?");
        return;
    }else{
        
    }
    ((OGMediaConnectionOptions *)_options).type = streamtype;
    ((OGMediaConnectionOptions *)_options).direction = AVCaptureDevicePositionFront;
    OGNegotiatorOptions * options = [[OGNegotiatorOptions alloc] init];
    //options.pc =
    
    if(_options.payload)
        options.originator = NO;
    else
        options.originator = YES;
    
    options.payload = _options.payload;
    _negotiator = [[OGNegotiator alloc] initWithOptions:options];
    [_negotiator startConnection:self options:options];
    
    // Retrieve lost messages stored because PeerConnection not set up.
    NSArray * messages = [_provider getMessages:self.identifier];
    for (int i = 0; i < messages.count; i++) {
        [self handleMessage:messages[i]];
    }
    _open = true;
};

/**
 * Exposed functionality for users.
 */


+(NSString *)identifierPrefix {
    static NSString * prefix = @"mc_";
    return prefix;
}

-(void)deleteLocalAudioTracks {
    if (_localStream != nil) {
        [self removeAudioTracks:_localStream];
        [self cleanupStreams];
    }
    
    
}
-(void)deleteLocalVideoTracks {
    if (_localStream != nil) {
        [self removeVideoTracks:_localStream];
        [self cleanupStreams];
    }
}


-(void)enableAudio {
    [self addLocalTrack:[_negotiator addAudioTrack]];
}
-(void)enableVideo {
    [self addLocalTrack:[_negotiator addVideoTrack:((OGMediaConnectionOptions *)_options).direction]];
}
-(void)disableAudio {
    [self deleteLocalAudioTracks];
}
-(void)disableVideo {
    [self deleteLocalVideoTracks];
}
-(void)removeAudioTracks:(RTCMediaStream *)stream {
    for(RTCAudioTrack * audioTrack in stream.audioTracks) {
        [stream removeAudioTrack:audioTrack];
        [self perform:@selector(connection:onRemovedLocalAudioTrack:) withArgs:@[self,stream]];
        [self emit:@"removed_local_audio_track" data:audioTrack];
        
    }
    
}
-(void)removeVideoTracks:(RTCMediaStream *)stream {
    for(RTCVideoTrack * videoTrack in stream.videoTracks) {
        [stream removeVideoTrack:videoTrack];
        [self perform:@selector(connection:onRemovedLocalVideoTrack:) withArgs:@[self,stream]];
        [self emit:@"removed_local_video_track" data:videoTrack];
        
    }
    
}
-(void)cleanupStreams {
    if(_localStream.videoTracks.count == 0 && _localStream.audioTracks.count == 0) {
        [self perform:@selector(connection:onRemovedLocalStream:) withArgs:@[self,_localStream]];
        _localStream = nil;
    }
    if(_remoteStream.videoTracks.count == 0 && _remoteStream.audioTracks.count == 0) {
        [self perform:@selector(connection:onRemovedRemoteStream:) withArgs:@[self,_remoteStream]];
        _remoteStream = nil;
    }
}
-(void)close {
    [self deleteLocalVideoTracks];
    [self deleteLocalAudioTracks];
    [super close];
}
@end
