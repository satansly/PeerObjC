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

@interface OGMediaConnectionOptions ()
@end
@implementation OGMediaConnectionOptions
+(instancetype)defaultConnectionOptions {
    OGMediaConnectionOptions * options = [[OGMediaConnectionOptions alloc] init];
    options.metadata = @{};
    return options;
}

@end
@implementation OGMediaConnection
-(instancetype)initWithPeer:(NSString *)peer provider:(OGPeer *)provider {
    
    self = [self initWithPeer:peer provider:provider options:[OGMediaConnectionOptions defaultConnectionOptions]];
    if (self) {
        
        
        
        _open = false;
        _type = OGConnectionTypeMedia;
        _peer = peer;
        _provider = provider;
        _metadata = _options.metadata;
        _localStream = _options.stream;
        
        _identifier = (_options.connectionId) ? _options.connectionId :[NSString stringWithFormat:@"%@%@",[OGMediaConnection identifierPrefix],[[OGUtil util] randomToken]];
        
        OGNegotiatorOptions * options = [[OGNegotiatorOptions alloc] init];
        options.originator = YES;
        
        
        _negotiator = [[OGNegotiator alloc] init];
        if (_localStream) {
            [_negotiator startConnection:self options:options];
        }
        
        
        
    }
    return self;
}
-(instancetype)initWithPeer:(NSString *)peer provider:(OGPeer *)provider options:(OGDataConnectionOptions *)options {
    self = [super init];
    if(self) {
        
    }
    return self;
}

-(void)addStream:(RTCMediaStream *)remoteStream {
    //util.log('Receiving stream', remoteStream);
    
    _remoteStream = remoteStream;
    [self emit:@"stream" data:remoteStream]; // Should we call this `open`?
    
};

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

-(void)answer:(RTCMediaStream *)stream {
    if (_localStream) {
        //util.warn('Local stream already exists on this MediaConnection. Are you answering a call twice?');
        return;
    }
    
    _options.stream = stream;
    
    _localStream = stream;
    
    [_negotiator startConnection:self options:_options.payload];
    
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
@end
