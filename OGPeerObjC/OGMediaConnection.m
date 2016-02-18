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
    if (!_localVideoStream && !_localAudioStream) {
        [_negotiator startConnection:self options:options];
    }
    
}
-(void)addStream:(RTCMediaStream *)remoteStream {
    DDLogDebug(@"Receiving stream %@", [remoteStream description]);
    
    if (remoteStream.videoTracks.count > 0) {
        self.remoteVideoStream = remoteStream;
    }
    if (remoteStream.audioTracks.count > 0) {
        self.remoteAudioStream = remoteStream;
        
    }
    if(!(self.remoteAudioStream || self.remoteVideoStream))
        [super emit:@"open" data:self];
    [self emit:@"stream" data:remoteStream]; // Should we call this `open`?
    [self perform:@selector(connection:onAddedRemoteStream:) withArgs:@[self,remoteStream]];
    
    
};

- (void)removeStream:(RTCMediaStream *)stream {
    [self emit:@"removed_stream" data:stream];
    [self perform:@selector(connection:onRemovedRemoteStream:) withArgs:@[self,stream]];
}
-(void)setLocalAudioStream:(RTCMediaStream *)localAudioStream {
    _localAudioStream = localAudioStream;
    [self emit:@"added_local_audio_stream" data:localAudioStream];
    [self perform:@selector(connection:onAddedLocalStream:) withArgs:@[self,localAudioStream]];
}
-(void)setLocalVideoStream:(RTCMediaStream *)localVideoStream {
    _localVideoStream = localVideoStream;
    [self emit:@"added_local_video_stream" data:localVideoStream];
    [self perform:@selector(connection:onAddedLocalStream:) withArgs:@[self,localVideoStream]];
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
    if (_localAudioStream || _localVideoStream) {
        DDLogWarn(@"Local stream already exists on this MediaConnection. Are you answering a call twice?");
        return;
    }else{
        
    }
    ((OGMediaConnectionOptions *)_options).direction = AVCaptureDevicePositionBack;
    OGNegotiatorOptions * options = [[OGNegotiatorOptions alloc] init];
    //options.pc =
    if(_options.payload)
        options.originator = NO;
    else
        options.originator = YES;
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

-(void)deleteLocalAudioStream {
    if (_localAudioStream != nil) {
        [self removeTracks:_localAudioStream];
        [self emit:@"removed_local_audio_stream" data:_localAudioStream];
        [self perform:@selector(connection:onRemovedLocalStream:) withArgs:@[self,_localAudioStream]];
        _localAudioStream = nil;
    }
    
}
-(void)deleteLocalVideoStream {
    if (_localVideoStream != nil) {
        [self removeTracks:_localVideoStream];
        [self emit:@"removed_local_video_stream" data:_localVideoStream];
        [self perform:@selector(connection:onRemovedLocalStream:) withArgs:@[self,_localVideoStream]];
        _localVideoStream = nil;
    }
}
-(void)deleteRemoteAudioStream {
    if (_remoteAudioStream != nil) {
        [self removeTracks:_remoteAudioStream];
        [self emit:@"removed_remote_video_stream" data:_remoteAudioStream];
        _remoteAudioStream = nil;
        
    }
}
-(void)deleteRemoteVideoStream {
    if (_remoteVideoStream != nil) {
        [self removeTracks:_remoteVideoStream];
        [self emit:@"removed_remote_video_stream" data:_remoteVideoStream];
        _remoteVideoStream = nil;
    }
}

-(void)enableAudio {
    [_negotiator addLocalAudioStream];
}
-(void)enableVideo {
    [_negotiator addLocalVideoStream:((OGMediaConnectionOptions *)_options).direction];
}
-(void)disableAudio {
    [self deleteLocalAudioStream];
}
-(void)disableVideo {
    [self deleteLocalVideoStream];
}
-(void)removeTracks:(RTCMediaStream *)stream {
    for(RTCVideoTrack * videoTrack in stream.videoTracks) {
        [stream removeVideoTrack:videoTrack];
    }
    for(RTCAudioTrack * audioTrack in stream.audioTracks) {
        [stream removeAudioTrack:audioTrack];
    }
    
}
@end
