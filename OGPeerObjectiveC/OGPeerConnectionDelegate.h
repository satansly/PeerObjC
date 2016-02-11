//
//  OGPeerConnectionDelegate.h
//  OGPeerObjectiveC
//
//  Created by Omar Hussain on 2/10/16.
//  Copyright © 2016 ohgarage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RTCPeerConnection.h"
#import "OGPeer.h"
#import "OGConnection.h"
#import "OGNegotiator.h"

@interface OGPeerConnectionDelegate : NSObject<RTCPeerConnectionDelegate>
@property (nonatomic, strong) OGConnection * connection;
@property (nonatomic, assign) OGNegotiator * negotiator;
-(instancetype)initWithConnection:(OGConnection *)connection negotiator:(OGNegotiator *)negotiator;
@end
