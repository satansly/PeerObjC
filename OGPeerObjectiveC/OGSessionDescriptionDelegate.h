//
//  OGSessionDescriptionDelegate.h
//  OGPeerObjectiveC
//
//  Created by Omar Hussain on 2/10/16.
//  Copyright © 2016 ohgarage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RTCSessionDescriptionDelegate.h"
#import "OGConnection.h"
#import "OGNegotiator.h"

typedef void (^DidCreateSessionDescriptionBlock)(RTCPeerConnection * pc, RTCSessionDescription * sdp, NSError * error);
typedef void (^DidSetSessionDescriptionBlock)(RTCPeerConnection * pc, RTCSessionDescription * sdp, NSError * error);

@interface OGSessionDescriptionDelegate : NSObject<RTCSessionDescriptionDelegate>
@property (nonatomic, strong) OGConnection * connection;
@property (nonatomic, assign) OGNegotiator * negotiator;
@property (nonatomic, strong) DidCreateSessionDescriptionBlock didCreateSessionDescription;
@property (nonatomic, strong) DidSetSessionDescriptionBlock didSetSessionDescription;

-(instancetype)initWithConnection:(OGConnection *)connection negotiator:(OGNegotiator *)negotiator;

@end
