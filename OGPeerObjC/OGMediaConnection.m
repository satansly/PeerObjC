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
    //util.log('Receiving stream', remoteStream);
    
    if (remoteStream.videoTracks.count > 0) {
        self.remoteVideoStream = remoteStream;
        
    }
    if (remoteStream.audioTracks.count > 0) {
        self.remoteAudioStream = remoteStream;
        
    }
    [self emit:@"stream" data:remoteStream]; // Should we call this `open`?
    
};

- (void)removeStream:(RTCMediaStream *)stream {
    [self emit:@"removed_stream" data:stream]; // Should we call this `open`?
}
-(void)setLocalAudioStream:(RTCMediaStream *)localAudioStream {
    _localAudioStream = localAudioStream;
    [self emit:@"local_audio_stream" data:localAudioStream];
    
}
-(void)setLocalVideoStream:(RTCMediaStream *)localVideoStream {
    _localVideoStream = localVideoStream;
    [self emit:@"local_video_stream" data:localVideoStream];
    
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
            //util.warn('Unrecognized message type:', message.type, 'from peer:', this.peer);
            break;
    }
}

- (void)answer:(OGStreamType )streamtype {
    if (_localAudioStream || _localVideoStream) {
        //util.warn('Local stream already exists on this MediaConnection. Are you answering a call twice?');
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

/** Allows user to close connection. */
-(void)close {
    if (!_open) {
        return;
    }
    _open = false;
    [_negotiator cleanup:self];
    [self emit:@"close"];
    
};
+(NSString *)identifierPrefix {
    static NSString * prefix = @"mc_";
    return prefix;
}

-(void)deleteLocalAudioStream {
    if (_localAudioStream != nil && _localAudioTrack != nil)
        [_localAudioStream removeAudioTrack:_localAudioTrack];
}
-(void)deleteLocalVideoStream {
    if (_localVideoStream != nil && _localVideoTrack != nil)
        [_localVideoStream removeVideoTrack:_localVideoTrack];
}
-(void)deleteRemoteAudioStream {
    if (_remoteAudioStream != nil && _remoteAudioTrack != nil)
        [_remoteAudioStream removeAudioTrack:_remoteAudioTrack];
}
-(void)deleteRemoteVideoStream {
    if (_remoteVideoStream != nil && _remoteVideoTrack != nil)
        [_remoteVideoStream removeVideoTrack:_remoteVideoTrack];
}
@end
