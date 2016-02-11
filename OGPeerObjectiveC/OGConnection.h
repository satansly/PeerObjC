//
//  OGConnection.h
//  OGPeerObjectiveC
//
//  Created by Omar Hussain on 2/10/16.
//  Copyright © 2016 ohgarage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RTCPeerConnection.h"
#import "OGCommon.h"
#import "OGPeer.h"
#import <EventEmitter/EventEmitter.h>


@class OGMessagePayload;
@class OGNegotiator;
@class OGMessage;

@interface OGConnectionOptions : NSObject
@property (nonatomic, strong) NSString * connectionId;
@property (nonatomic, strong) NSDictionary * metadata;
@property (nonatomic, strong) OGMessagePayload * payload;
@end
@interface OGConnection : NSObject {
@protected
    OGConnectionType _type;
    NSString *_identifier;
    NSString *_label;
    NSDictionary *_metadata;
    RTCPeerConnection * _peerConnection;
    NSString * _peer;
    OGPeer * _provider;
    OGSerialization _serialization;
    OGNegotiator * _negotiator;
}
@property (nonatomic, strong) NSString * identifier;
@property (nonatomic, strong) NSString * label;
@property (nonatomic, strong) NSString * peer;
@property (nonatomic, assign) OGConnectionType type;
@property (nonatomic, strong) RTCPeerConnection * peerConnection;
@property (nonatomic, strong) OGPeer * provider;
@property (nonatomic, assign) OGSerialization serialization;
@property (nonatomic, strong) NSDictionary * metadata;
@property (nonatomic, strong) OGNegotiator * negotiator;

-(void)initialize;

-(NSString *)typeAsString;
-(NSString *)serializationAsString;
+(NSString *)identifierPrefix;
-(void)handleMessage:(OGMessage *)message;
-(void)close;
-(void)handleError:(NSError *)error;
@end
