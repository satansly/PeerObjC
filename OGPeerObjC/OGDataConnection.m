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
#import "NSString+Extensions.h"
#import "OGPacker.h"
#import "OGUnpacker.h"

@interface OGDataConnectionOptions ()
@property (nonatomic, assign) BOOL sctp;
@end
@implementation OGDataConnectionOptions
@synthesize constraints, connectionId,metadata,payload;

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
@property (nonatomic, strong) NSMutableData * buffer;
@property (nonatomic, assign) BOOL buffering;
@property (nonatomic, strong) NSMutableDictionary * chunkedData;

@end

@implementation OGDataConnection

-(instancetype)initWithPeer:(NSString *)peer provider:(OGPeer *)provider {
    
    self = [self initWithPeer:peer provider:provider options:[OGDataConnectionOptions defaultConnectionOptions]];
    if (self) {
        
        
        
        
    }
    return self;
}
-(instancetype)initWithPeer:(NSString *)peer provider:(OGPeer *)provider options:(id<OGConnectionOptions>)options {
    self = [super init];
    if(self) {
        _open =NO;
        _type = OGConnectionTypeData;
        _peer = peer;
        _provider = provider;
        _options = options;
        _identifier = (_options.connectionId) ? _options.connectionId :[NSString stringWithFormat:@"%@%@",[OGDataConnection identifierPrefix],[[OGUtil util] randomToken]];
        OGDataConnectionOptions * doptions = (OGDataConnectionOptions *)options;
        _label = (doptions.label) ? doptions.label : _identifier;
        _metadata = options.metadata;
        _serialization = doptions.serialization;
        _reliable = doptions.reliable;
        
        // Data channel buffering.
        _buffer = [NSMutableData data];
        _buffering = false;
        
        // For storing large data.
        _chunkedData = [NSMutableDictionary dictionary];
        OGNegotiatorOptions * options = [[OGNegotiatorOptions alloc] init];
        //options.pc =
        if(_options.payload)
            options.originator = NO;
        else
            options.originator = YES;
        options.payload = _options.payload;
        //options.sdp;
        //options.pc;
        
        _negotiator = [[OGNegotiator alloc] initWithOptions:options];
        
        [_negotiator startConnection:self options:options];
        
    }
    return self;
}

- (void)initialize:(RTCDataChannel *)dc {
    DDLogDebug(@"Initializing data channel %@ for connection: %@",dc.label, _identifier);
    
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
            DDLogDebug(@"Data channel connection success");
            _open = YES;
            [super emit:@"open"];
            [self perform:@selector(connectionOnOpen:) withArgs:@[self]];
            
        }
            break;
        case kRTCDataChannelStateClosed: {
            DDLogDebug(@"DataChannel closed for: %@", self.peer);
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
    id data;
    if (self.serialization == OGSerializationBinary || self.serialization == OGSerializationBinaryUTF8) {
        OGUnpacker * unpacker = [[OGUnpacker alloc] initWithData:buffer.data];
        data = [unpacker unpack];
    } else if (self.serialization == OGSerializationJSON) {
        NSError * error;
        data = [NSJSONSerialization JSONObjectWithData:buffer.data options:NSJSONReadingAllowFragments error:&error];
        if(error)
            [self emit:@"error" data:error];
    }else{
        data = buffer.data;
    }
    if ([data isKindOfClass:[NSDictionary class]] && data[@"__peerData"]) {
        NSDictionary * dict = (NSDictionary *)data;
        int ident = [dict[@"__peerData"] intValue];
        NSMutableDictionary * chunkInfo = (_chunkedData[@(ident)]) ? _chunkedData[@(ident)] :[NSMutableDictionary dictionaryWithDictionary:@{@"data": [NSMutableData data], @"count" : @0, @"total": dict[@"total"]}];
        
        [chunkInfo[@"data"] appendData:data[@"data"]];
        chunkInfo[@"count"] = @([chunkInfo[@"count"] intValue] + 1);
        
        if ([chunkInfo[@"total"] intValue] == [chunkInfo[@"count"] intValue]) {
            // Clean up before making the recursive call to `_handleDataMessage`.
            [_chunkedData removeObjectForKey:@(ident)];
            
            // We've received all the chunks--time to construct the complete data.
            data = [[NSData alloc] initWithData:chunkInfo[@"data"]];
            RTCDataBuffer * buffer = [[RTCDataBuffer alloc] initWithData:data isBinary:YES];
            [self handleDataMessage:buffer];
        }
        _chunkedData[@(ident)] = chunkInfo;
        return;
    }
    
    if(data) {
        [self emit:@"data" data:data];
        [self perform:@selector(connection:onData:) withArgs:@[self,data]];
    }
}

/**
 * Exposed functionality for users.
 */



/** Allows user to send data. */
- (void)send:(id)data {
    if (!self.open) {
        [self emit:@"error" data:[NSError errorWithLocalizedDescription:@"Connection is not open. You should listen for the `open` event before sending messages."]];
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
        OGPacker * packer = [[OGPacker alloc] init];
        [packer pack:data];
        rawdata = [packer getBuffer];
        
    } else {
        if([data isKindOfClass:[NSString class]]) {
            NSString * dataStr = (NSString *)data;
            rawdata = [dataStr dataUsingEncoding:NSUTF8StringEncoding];
            
        }else{
            rawdata = (NSData *)data;
        }
    }
    [self trySend:rawdata];
}


// Returns true if the send succeeds.
- (void)trySend:(NSData *)data {
    @try {
        //BOOL isBinary = (self.serialization == OGSerializationBinary || self.serialization == OGSerializationBinaryUTF8) ? YES : NO;
        [_dataChannel sendData:[[RTCDataBuffer alloc] initWithData:data isBinary:YES]];
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
            DDLogWarn(@"Unrecognized message type: %ld from peer: %@", (long)message.type, self.peer);
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
