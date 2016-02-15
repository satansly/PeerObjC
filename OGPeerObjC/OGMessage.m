//
//  OGMessage.m
//  OGPeerObjectiveC
//
//  Created by Omar Hussain on 2/11/16.
//  Copyright © 2016 ohgarage. All rights reserved.
//

#import "OGMessage.h"
#import "OGUtil.h"
#import "OGConnection.h"

@interface OGMessagePayload ()
@property (nonatomic, strong) NSMutableDictionary * innerDictionary;
@end
@implementation OGMessagePayload

-(instancetype)init {
    self = [super init];
    if(self) {
        _innerDictionary = [NSMutableDictionary dictionary];
    }
    return self;
}
-(instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if(self) {
        NSAssert(dict != nil, @"Provided dictionary is nil");
        _innerDictionary = [NSMutableDictionary dictionaryWithDictionary:dict];
    }
    return self;
}
-(NSData *)JSONData {
    NSError * error;
    NSData * data = [NSJSONSerialization dataWithJSONObject:_innerDictionary options:NSJSONWritingPrettyPrinted error:&error];
    DDLogError(@"Error occurred when coverting dictionary to JSON. %@",[error localizedDescription]);
    NSAssert(error == nil, @"Error occurred when coverting dictionary to JSON. %@",[error localizedDescription]);
    return data;
}
-(NSString *)msg {
    return _innerDictionary[@"msg"];
}
-(void)setMsg:(NSString *)msg {
    _innerDictionary[@"msg"] = msg;
}
-(OGStreamType)streamType {
    return [[OGUtil util] streamTypeFromString:_innerDictionary[@"streamtype"]];
}
-(void)setStreamType:(OGStreamType)type {
    _innerDictionary[@"streamtype"] = [[OGUtil util] stringFromStreamType:type];
}
-(RTCSessionDescription *)sdp {
    return [[RTCSessionDescription alloc] initWithType: _innerDictionary[@"sdp"][@"type"] sdp: _innerDictionary[@"sdp"][@"sdp"]];
}
-(void)setSdp:(RTCSessionDescription *)sdp {
    _innerDictionary[@"sdp"] = @{@"type" : sdp.type, @"sdp":sdp.description};
}
-(OGConnectionType)type {
    return [[OGUtil util] connectionTypeFromString:_innerDictionary[@"type"]];
}
-(void)setType:(OGConnectionType)type {
    _innerDictionary[@"type"] = [[OGUtil util] stringFromConnectionType:type];
}
-(NSString *)label {
    return _innerDictionary[@"label"];
}
-(void)setLabel:(NSString *)label {
    _innerDictionary[@"label"] = label;
}

-(NSString *)connectionId {
    return _innerDictionary[@"connectionId"];
}
-(void)setConnectionId:(NSString *)connectionId {
    _innerDictionary[@"connectionId"] = connectionId;
}
-(BOOL)reliable {
    return [_innerDictionary[@"reliable"] boolValue];
}
-(void)setReliable:(BOOL)reliable {
    _innerDictionary[@"reliable"] = @(reliable);
}
-(OGSerialization)serialization {
    return [[OGUtil util] serializationFromString:_innerDictionary[@"serialization"]];
}
-(void)setSerialization:(OGSerialization)serialization {
    _innerDictionary[@"serialization"] = [[OGUtil util] stringFromSerialization:serialization];
}
-(NSDictionary *)metadata {
    return _innerDictionary[@"metdata"];
}
-(void)setMetadata:(NSDictionary *)metadata {
    _innerDictionary[@"metadata"] = metadata;
}
-(NSString *)browser {
    return _innerDictionary[@"browser"];
}
-(void)setBrowser:(NSString *)browser {
    _innerDictionary[@"browser"] = browser;
}
-(RTCICECandidate *)candidate {
    NSDictionary *candidateObj = _innerDictionary[@"candidate"];
    return [[RTCICECandidate alloc] initWithMid: candidateObj[@"sdpMid"] index:[candidateObj[@"sdpMLineIndex"] integerValue] sdp: candidateObj[@"sdp"]];
}
-(void)setCandidate:(RTCICECandidate *)candidate {
    NSDictionary *candidateObj = @{@"sdpMLineIndex": @(candidate.sdpMLineIndex),
                                   @"sdpMid": candidate.sdpMid,
                                   @"candidate": candidate.sdp};
    _innerDictionary[@"candidate"] = candidateObj;
}
-(NSDictionary *)dictionary {
    return _innerDictionary;
}

@end

@interface OGMessage ()
@property (nonatomic, strong) NSMutableDictionary * innerDictionary;
@end
@implementation OGMessage
-(instancetype)init {
    self = [super init];
    if(self) {
        _innerDictionary = [NSMutableDictionary dictionary];
    }
    return self;
}

-(instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if(self) {
        _innerDictionary = [NSMutableDictionary dictionaryWithDictionary:dict];
    }
    return self;
}
-(NSString *)source {
    return _innerDictionary[@"src"];
}
-(void)setSource:(NSString *)source {
    _innerDictionary[@"src"] = source;
}
-(OGMessageType)type {
    return [[OGUtil util] messageTypeFromString:_innerDictionary[@"type"]];
}
-(void)setType:(OGMessageType)type {
    _innerDictionary[@"type"] = [[OGUtil util] stringFromMessageType:type];
}
-(NSString *)destination {
    return _innerDictionary[@"dst"];
}
-(void)setDestination:(NSString *)destination {
    _innerDictionary[@"dst"] = destination;
}
-(OGMessagePayload *)payload {
    return [[OGMessagePayload alloc] initWithDictionary:_innerDictionary[@"payload"]];
}
-(void)setPayload:(OGMessagePayload *)payload {
    _innerDictionary[@"payload"] = [NSJSONSerialization JSONObjectWithData:[payload JSONData] options:NSJSONReadingAllowFragments error:nil];
}
-(NSDictionary *)dictionary {
    return _innerDictionary;
}
-(NSData *)JSONData {
    NSError * error;
    NSData * data = [NSJSONSerialization dataWithJSONObject:_innerDictionary options:NSJSONWritingPrettyPrinted error:&error];
    DDLogError(@"Error occurred when coverting dictionary to JSON. %@",[error localizedDescription]);
    NSAssert(error == nil, @"Error occurred when coverting dictionary to JSON. %@",[error localizedDescription]);
    return data;
}
@end
@implementation OGMessage (Negotiator)

+(OGMessage *)offerWithConnection:(OGConnection *)connection {
    NSAssert(connection != nil, @"Connection cannot be nil");
    OGUtil * util = [OGUtil util];
    OGMessagePayload * payload = [[OGMessagePayload alloc] init];
    payload.browser = util.browser;
    payload.serialization = connection.serialization;
    payload.type = connection.type;
    payload.reliable = NO;
    payload.connectionId = connection.identifier;
    payload.metadata = connection.metadata;
    payload.sdp = connection.peerConnection.localDescription;
    
    OGMessage * message = [[OGMessage alloc] init];
    message.type = OGMessageTypeOffer;
    message.source = connection.provider.identifier;
    message.destination = connection.peer;
    message.payload = payload;
    
    return message;
}

+(OGMessage *)answerWithConnection:(OGConnection *)connection {
    NSAssert(connection != nil, @"Connection cannot be nil");
    OGUtil * util = [OGUtil util];
    OGMessagePayload * payload = [[OGMessagePayload alloc] init];
    payload.browser = util.browser;
    payload.serialization = connection.serialization;
    payload.type = connection.type;
    payload.reliable = NO;
    payload.connectionId = connection.identifier;
    payload.metadata = connection.metadata;
    payload.sdp = connection.peerConnection.localDescription;
    
    OGMessage * message = [[OGMessage alloc] init];
    message.type = OGMessageTypeAnswer;
    message.source = connection.provider.identifier;
    message.destination = connection.peer;
    message.payload = payload;
    
    return message;
    
}
+(OGMessage *)candidateWithConnection:(OGConnection *)connection candidate:(RTCICECandidate *)candidate {
    NSAssert(connection != nil, @"Connection cannot be nil");
    NSAssert(candidate != nil, @"Candidate cannot be nil");
    OGMessagePayload * payload = [[OGMessagePayload alloc] init];
    payload.type = connection.type;
    payload.connectionId = connection.identifier;
    payload.candidate = candidate;
    
    OGMessage * message = [[OGMessage alloc] init];
    message.type = OGMessageTypeCandidate;
    message.source = connection.provider.identifier;
    message.destination = connection.peer;
    message.payload = payload;
    
    return message;
    
    
    
}
+(OGMessage *)leaveWithConnection:(OGConnection *)connection {
    NSAssert(connection != nil, @"Connection cannot be nil");
    OGMessage * message = [[OGMessage alloc] init];
    message.type = OGMessageTypeCandidate;
    message.source = connection.provider.identifier;
    message.destination = connection.peer;
    
    return message;
    
    
    
}

@end
