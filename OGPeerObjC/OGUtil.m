//
//  OGUtils.m
//  OGPeerObjectiveC
//
//  Created by Omar Hussain on 2/10/16.
//  Copyright © 2016 ohgarage. All rights reserved.
//

#import "OGUtil.h"
#import "OGPeer.h"
#import "RTCPeerConnection.h"
#import "RTCPeerConnectionFactory.h"
#import "RTCMediaConstraints.h"
#import "RTCPair.h"
#import "NSString+Extensions.h"

@implementation OGUtilSupports

+(OGUtilSupports *)supports {
    OGUtilSupports * supports = [[OGUtilSupports alloc] init];
    
    supports.data = YES;
    supports.audioVideo = YES;
    
    supports.binaryBlob = NO;
    supports.sctp = NO;
    supports.onnegotiationneeded = YES;
    
    RTCPeerConnectionFactory * factory = [[RTCPeerConnectionFactory alloc] init];
    
    RTCPeerConnection * pc;
    RTCDataChannel * dc;
    @try {
        NSArray *optionalConstraints = @[
                                         [[RTCPair alloc] initWithKey:@"DtlsSrtpKeyAgreement" value:@"true"]
                                         ,[[RTCPair alloc] initWithKey:@"RtpDataChannels" value:@"true"]
                                         ];
        RTCMediaConstraints* constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:nil optionalConstraints:optionalConstraints];
        pc = [factory peerConnectionWithICEServers:[[OGPeerConfig defaultConfig] iceServers] constraints:constraints delegate:nil];
    } @catch (NSException * e) {
        supports.data = false;
        supports.audioVideo = false;
    }
    
    if (supports.data) {
        @try {
            if(pc) {
                dc = [pc createDataChannelWithLabel:@"_PEERJSTEST" config:nil];
                if(dc.state == kRTCDataChannelStateOpen)
                    [dc close];
            }
        } @catch (NSException * e) {
            supports.data = false;
        }
    }
    if(pc.signalingState == RTCSignalingStable)
        [pc close];
    
    if (supports.data) {
        // Binary test
        @try {
            //dc.binaryType = 'blob';
            supports.binaryBlob = YES;
        } @catch (NSException * e) {
        }
        NSArray *optionalConstraints = @[
                                         [[RTCPair alloc] initWithKey:@"DtlsSrtpKeyAgreement" value:@"true"]
                                         ];
        // Reliable test.
        RTCMediaConstraints* constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:nil optionalConstraints:optionalConstraints];
        RTCPeerConnection * reliablePC = [factory peerConnectionWithICEServers:[[OGPeerConfig defaultConfig] iceServers] constraints:constraints delegate:nil];
        @try {
            RTCDataChannel * reliableDC = [reliablePC createDataChannelWithLabel:@"_PEERJSRELIABLETEST" config:nil];
            supports.sctp = reliableDC.isReliable;
            if(reliableDC.state == kRTCDataChannelStateOpen)
                [reliableDC close];
        } @catch (NSException * e) {
        }
        if(reliablePC.signalingState == RTCSignalingStable)
            [reliablePC close];
    }
    
    // FIXME: not really the best check...
    if (supports.audioVideo) {
        supports.audioVideo = [pc addStream:nil];
    }
    
    // FIXME: this is not great because in theory it doesn't work for
    // av-only browsers (?).
    if (!supports.onnegotiationneeded && supports.data) {
        // sync default check.
        NSArray *optionalConstraints = @[
                                         [[RTCPair alloc] initWithKey:@"DtlsSrtpKeyAgreement" value:@"true"]
                                         ,[[RTCPair alloc] initWithKey:@"RtpDataChannels" value:@"true"]
                                         ];
        
        RTCMediaConstraints* constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:nil optionalConstraints:optionalConstraints];
        RTCPeerConnection * negotiationPC = [factory peerConnectionWithICEServers:[[OGPeerConfig defaultConfig] iceServers] constraints:constraints delegate:nil];
        supports.onnegotiationneeded = YES;
        RTCDataChannel * negotiationChannel = [negotiationPC createDataChannelWithLabel:@"_PEERJSNEGOTIATIONTEST" config:nil];
        if(negotiationChannel.state == kRTCDataChannelStateOpen)
            [negotiationChannel close];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if(negotiationPC.signalingState == RTCSignalingStable)
                [negotiationPC close];
        });
    }
    
    
    
    return supports;
    
}

@end
@interface OGChunk ()
@property (nonatomic, assign) int peerData;
@end
@implementation OGChunk


@end
@implementation OGUtil

+(instancetype)util {
    OGUtil * util = [[OGUtil alloc] init];
    util.supports = [OGUtilSupports supports];
    return util;
}
-(NSString *)randomToken {
    NSString * token = [self randomStringWithMaxLength:36];
    DDLogDebug(@"Random Token : %@",token);
    return token;
}
-(NSString *)randomStringWithMaxLength:(NSInteger)len {
    NSInteger length = [self randomBetween:len max:len];
    unichar letter[length];
    for (int i = 0; i < length; i++) {
        letter[i] = [self randomBetween:65 max:90];
    }
    NSString * randString = [[[NSString alloc] initWithCharacters:letter length:length] lowercaseString];
    DDLogDebug(@"Random String : %@ of length: %ldld",randString,(long)len);
    return randString;
}
- (NSInteger)randomBetween:(NSInteger)min max:(NSInteger)max
{
    return (arc4random_uniform((u_int32_t)max) % (max - min + 1)) + min;
}
- (BOOL)validateIdentifier:(NSString *)identifier {
    DDLogDebug(@"Validating identifier %@",identifier);
    if(!identifier) {
        DDLogDebug(@"Nil identifier. Is valid.");
        return YES;
    }else{
        NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:@"^[A-Za-z0-9]+(?:[ _-][A-Za-z0-9]+)*$" options:NSRegularExpressionCaseInsensitive error:nil];
        NSUInteger matches = [regex numberOfMatchesInString:identifier options:NSMatchingReportCompletion range:NSMakeRange(0, identifier.length)];
        
        BOOL isvalid = (matches > 0);
        if(isvalid)
            DDLogDebug(@"Valid identifier %@",identifier);
        else
            DDLogDebug(@"Invalid identifier %@",identifier);
        return isvalid;
    }
    
}
- (BOOL)validateKey:(NSString *)key {
    if(!key) {
        DDLogDebug(@"Nil key. Is valid.");
        return YES;
    }else{
        NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:@"^[A-Za-z0-9]+(?:[ _-][A-Za-z0-9]+)*$" options:NSRegularExpressionCaseInsensitive error:nil];
        NSUInteger matches =  [regex numberOfMatchesInString:key options:NSMatchingReportCompletion range:NSMakeRange(0, key.length)];
        BOOL isvalid = (matches > 0);
        if(isvalid)
            DDLogDebug(@"Valid key %@",key);
        else
            DDLogDebug(@"Invalid key %@",key);
        return isvalid;
    }
}

-(NSArray<NSData *> *)chunk:(NSData *)data {
    DDLogDebug(@"Chunking data. Data length %lud",(unsigned long)data.length);
    NSMutableArray * chunks = [NSMutableArray array];
    NSUInteger size = data.length;
    int start = 0;
    int index = 0;
    double total = ceil(size/[[self chunkedMTU] doubleValue]);
    DDLogDebug(@"Total chunks %f",total);
    while (start < size) {
        int end = MIN(size, start + [[self chunkedMTU] doubleValue]);
        NSData * b = [data subdataWithRange:NSMakeRange(0, [[self chunkedMTU] integerValue])];
        
        OGChunk * chunk = [[OGChunk alloc] init];
        chunk.peerData = _dataCount;
        chunk.n = index;
        chunk.data =  b;
        chunk.total = total;
        [chunks addObject:chunk];
        
        start = end;
        index += 1;
    }
    _dataCount += 1;
    return chunks;
}

- (NSString *)blobToBinaryString:(NSString *)data {
    
    NSString * string = [NSString stringWithUTF8String:[[data dataUsingEncoding:NSUTF8StringEncoding ] bytes]];
    return [string binaryString];
}
-(NSString *)host {
    return @"0.peerjs.com";
}
-(NSNumber *)port {
    return @(9000);
}
-(NSNumber *)chunkedMTU {
    return @(16300);
}
-(NSString *)stringFromConnectionType:(OGConnectionType)type {
    switch (type) {
        case OGConnectionTypeData:
            return @"data";
            break;
        case OGConnectionTypeMedia:
            return @"media";
        default:
            break;
    }
    return nil;
}
-(OGConnectionType)connectionTypeFromString:(NSString *)type {
    if([type isEqualToString:@"data"]) {
        return OGConnectionTypeData;
    }else{
        return OGConnectionTypeMedia;
    }
}
-(NSString *)stringFromSerialization:(OGSerialization)serialization {
    switch (serialization) {
        case OGSerializationBinary: {
            return @"binary";
            break;
        }
        case OGSerializationBinaryUTF8: {
            return @"binary-utf8";
            break;
        }
        case OGSerializationJSON: {
            return @"json";
            break;
        }
        case OGSerializationNone: {
            return @"none";
            break;
        }
    }
    return nil;
}
-(OGSerialization)serializationFromString:(NSString *)serialization {
    if([serialization isEqualToString:@"binary"]) {
        return OGSerializationBinary;
    }else if([serialization isEqualToString:@"binary-utf8"]) {
        return OGSerializationBinaryUTF8;
    }else if([serialization isEqualToString:@"json"]) {
        return OGSerializationJSON;
    }else{
        return OGSerializationNone;
    }
}

-(OGMessageType)messageTypeFromString:(NSString *)type {
    if([type isEqualToString:@"OFFER"]) {
        return OGMessageTypeOffer;
    }else if([type isEqualToString:@"ANSWER"]) {
        return OGMessageTypeAnswer;
    }else if([type isEqualToString:@"BYE"]) {
        return OGMessageTypeBye;
    }else if([type isEqualToString:@"OPEN"]) {
        return OGMessageTypeOpen;
    }else if([type isEqualToString:@"LEAVE"]) {
        return OGMessageTypeLeave;
    }else if([type isEqualToString:@"ERROR"]) {
        return OGMessageTypeError;
    }else if([type isEqualToString:@"ID-TAKEN"]) {
        return OGMessageTypeIdTaken;
    }else if([type isEqualToString:@"INVALID-KEY"]) {
        return OGMessageTypeInvalidKey;
    }else if([type isEqualToString:@"EXPIRE"]) {
        return OGMessageTypeExpire;
    }else{
        return OGMessageTypeCandidate;
    }
}
-(NSString *)stringFromMessageType:(OGMessageType)type {
    switch (type) {
        case OGMessageTypeCandidate: {
            return @"CANDIDATE";
        }
        case OGMessageTypeOffer: {
            return @"OFFER";
        }
        case OGMessageTypeAnswer: {
            return @"ANSWER";
        }
        case OGMessageTypeBye: {
            return @"BYE";
        }
        case OGMessageTypeOpen: {
            return @"OPEN";
        }
        case OGMessageTypeError: {
            return @"ERROR";
        }
        case OGMessageTypeLeave: {
            return @"LEAVE";
        }
        case OGMessageTypeExpire: {
            return @"EXPIRE";
        }
        case OGMessageTypeIdTaken: {
            return @"ID-TAKEN";
        }
        case OGMessageTypeInvalidKey: {
            return @"INVALID-KEY";
        }
    }
    return nil;
}
-(OGStreamType)streamTypeFromString:(NSString *)type {
    if([type isEqualToString:@"both"]) {
        return OGStreamTypeBoth;
    }else if([type isEqualToString:@"video"]) {
        return OGStreamTypeVideo;
    }else{
        return OGStreamTypeAudio;
    }
}
-(NSString *)stringFromStreamType:(OGStreamType)type {
    switch (type) {
        case OGStreamTypeBoth: {
            return @"both";
        }
        case OGStreamTypeAudio: {
            return @"audio";
        }
        case OGStreamTypeVideo: {
            return @"video";
        }
    }
}
@end
