//
//  OGDataConnection.m
//  OGPeerObjectiveC
//
//  Created by Omar Hussain on 2/9/16.
//  Copyright © 2016 ohgarage. All rights reserved.
//

#import "OGDataConnection.h"
#import "OGNegotiator.h"
#import "OGUtil.h"
#import "OGMessage.h"

@interface OGDataConnectionOptions ()
@property (nonatomic, assign) BOOL sctp;
@end
@implementation OGDataConnectionOptions

+(instancetype)defaultConnectionOptions {
    OGDataConnectionOptions * options = [[OGDataConnectionOptions alloc] init];
    options.label = @"PEERJSDATACONNECTION";
    options.serialization = OGSerializationBinary;
    options.reliable = NO;
    options.metadata = @{};
    options.sctp = NO;
    return options;
}

@end

@interface OGDataConnection ()<RTCDataChannelDelegate>
@property (nonatomic, strong) OGDataConnectionOptions * options;
@property (nonatomic, strong) NSMutableData * buffer;
@property (nonatomic, assign) BOOL buffering;
@property (nonatomic, strong) NSMutableData * chunkedData;

@end

@implementation OGDataConnection

-(instancetype)initWithPeer:(NSString *)peer provider:(OGPeer *)provider {
    
    self = [self initWithPeer:peer provider:provider options:[OGDataConnectionOptions defaultConnectionOptions]];
    if (self) {
        _open =NO;
        _type = OGConnectionTypeData;
        _peer = peer;
        _provider = provider;
        
        _identifier = (_options.connectionId) ? _options.connectionId :[NSString stringWithFormat:@"%@%@",[OGDataConnection identifierPrefix],[[OGUtil util] randomToken]];
        
        _label = (_options.label) ? _options.label : _identifier;
        _metadata = _options.metadata;
        _serialization = _options.serialization;
        _reliable = _options.reliable;
        
        // Data channel buffering.
        _buffer = [NSMutableData data];
        _buffering = false;
        
        // For storing large data.
        _chunkedData = [NSMutableData data];
        
        OGNegotiatorOptions * options = [[OGNegotiatorOptions alloc] init];
        //if(_options._payload)
        //options.originator = NO;
        //else
        //options.originator = YES;
        //options.sdp;
        //options.pc;
        
        _negotiator = [[OGNegotiator alloc] init];
        [_negotiator startConnection:self options:options];
        
        
        
    }
    return self;
}
-(instancetype)initWithPeer:(NSString *)peer provider:(OGPeer *)provider options:(OGDataConnectionOptions *)options {
    self = [super init];
    if(self) {
        
    }
    return self;
}

- (void)initialize:(RTCDataChannel *)dc {
    self.dataChannel = dc;
    [self configureDataChannel];
}

- (void)configureDataChannel {
    self.dataChannel.delegate = self;
    
}
// Called when the data channel state has changed.
- (void)channelDidChangeState:(RTCDataChannel*)channel {
    
    switch (channel.state) {
        case kRTCDataChannelStateConnecting:
            
            break;
        case kRTCDataChannelStateOpen: {
            //util.log('Data channel connection success');
            self.open = true;
            _open = YES;
            [self emit:@"open"];
            //self.emit('open');
            
        }
            break;
        case kRTCDataChannelStateClosed: {
            //util.log('DataChannel closed for:', self.peer);
            [self close];
        }
            break;
        case kRTCDataChannelStateClosing:
            break;
            
        default:
            break;
    }
}

// Called when a data buffer was successfully received.
- (void)channel:(RTCDataChannel*)channel
didReceiveMessageWithBuffer:(RTCDataBuffer*)buffer {
    [self handleDataMessage:buffer];
}

// Handles a DataChannel message.
- (void)handleDataMessage:(RTCDataBuffer *)buffer {
    OGUtil * util = [OGUtil util];
    id data;
    if (self.serialization == OGSerializationBinary || self.serialization == OGSerializationBinaryUTF8) {
        data = [NSString stringWithUTF8String:[buffer.data bytes]];
    } else if (self.serialization == OGSerializationJSON) {
        NSError * error;
        data = [NSJSONSerialization JSONObjectWithData:buffer.data options:NSJSONReadingAllowFragments error:&error];
        if(error)
            [self emit:@"error" data:error];
    }else{
        data = buffer.data;
    }
    [self emit:@"data" data:data];
}

/**
 * Exposed functionality for users.
 */

/** Allows user to close connection. */
-(void)close {
    if (!self.open) {
        return;
    }
    self.open = false;
    [_negotiator cleanup:self];
    [self emit:@"close"];
}

/** Allows user to send data. */
- (void)send:(id)data {
    if (!self.open) {
        [self emit:@"error" data:[NSError errorWithDomain:@"com.ohgarage" code:1001 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Connection is not open. You should listen for the `open` event before sending messages."]}]];
        return;
    }
    NSData * rawdata = nil;
    if (self.serialization == OGSerializationJSON) {
        NSError * error;
        rawdata = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:&error];
        if(error) {
            [self emit:@"error" data:error];
        }
    } else if (self.serialization == OGSerializationBinary || self.serialization == OGSerializationBinaryUTF8) {
        NSString * dataStr = (NSString *)data;
        rawdata = [dataStr dataUsingEncoding:NSUTF8StringEncoding];
    } else {
        rawdata = (NSData *)data;
    }
    [self trySend:rawdata];
}


// Returns true if the send succeeds.
- (void)trySend:(NSData *)data {
    @try {
        BOOL isBinary = (self.serialization == OGSerializationBinary || self.serialization == OGSerializationBinaryUTF8) ? YES : NO;
        [_dataChannel sendData:[[RTCDataBuffer alloc] initWithData:data isBinary:isBinary]];
    }
    @catch (NSException * e) {
    }
}

-(void)handleMessage:(OGMessage *)message {
    OGMessagePayload * payload = message.payload;
    
    switch (message.type) {
        case OGMessageTypeAnswer:
            //self.peerBrowser = payload[@"browser"];
            
            // Forward to negotiator
            
            [_negotiator handleSDP:message.type connection:self sdp:payload.sdp];
            break;
        case OGMessageTypeCandidate:
            [_negotiator handleCandidate:self ice:payload.candidate];
            break;
        default:
            //util.warn('Unrecognized message type:', message.type, 'from peer:', this.peer);
            break;
    }
}
+(NSString *)identifierPrefix {
    static NSString * prefix = @"dc_";
    return prefix;
}
-(NSNumber *)bufferSize {
    return @(_buffer.length);
}
@end
