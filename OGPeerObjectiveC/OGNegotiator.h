//
//  OGNegotiator.h
//  OGPeerObjectiveC
//
//  Created by Omar Hussain on 2/9/16.
//  Copyright © 2016 ohgarage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OGCommon.h"
#import "OGConnection.h"
#import "RTCPeerConnection.h"

@interface OGNegotiatorOptions : NSObject
@property (nonatomic, strong) RTCMediaStream * stream;
@property (nonatomic, assign) BOOL originator;
@property (nonatomic, strong) RTCSessionDescription * sdp;
@property (nonatomic, strong) RTCPeerConnection * pc;
@property (nonatomic, strong) id payload;
@end
@interface OGNegotiator : NSObject
-(RTCPeerConnection *)startConnection:(OGConnection *)connection options:(OGNegotiatorOptions *)options;
+(NSString *)identifierPrefix;

-(RTCPeerConnection *)getPeerConnection:(OGConnection *)connection options:(OGNegotiatorOptions *)options;
- (RTCPeerConnection *)startPeerConnection:(OGConnection *)connection;
- (void)handleSDP:(OGMessageType)type connection:(OGConnection *)connection sdp:(RTCSessionDescription *)sdp;
- (void)makeOffer:(OGConnection *)connection;
- (void)handleCandidate:(OGConnection *)connection ice:(RTCICECandidate *)candidate;
- (void)makeAnswer:(OGConnection *)connection;
-(void)cleanup:(OGConnection *)connection;
@end
