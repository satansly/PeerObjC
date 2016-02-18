//
//  OGSessionDescriptionDelegate.m
//  OGPeerObjectiveC
//
//  Created by Omar Hussain on 2/10/16.
//  Copyright © 2016 ohgarage. All rights reserved.
//

#import "OGSessionDescriptionDelegate.h"
#import "OGUtil.h"



@interface OGSessionDescriptionDelegate ()
@property (nonatomic, strong) RTCSessionDescription * sdp;
@end
@implementation OGSessionDescriptionDelegate
-(instancetype)initWithConnection:(OGConnection *)connection negotiator:(OGNegotiator *)negotiator {
    self = [super init];
    if(self) {
        NSAssert(connection != nil, @"Connection cannot be nil");
        NSAssert(negotiator != nil, @"Negotiator cannot be nil");
        _connection = connection;
        _negotiator = negotiator;
    }
    return self;
}
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didCreateSessionDescription:(RTCSessionDescription *)sdp
                 error:(NSError *)error {
    
    if(_didCreateSessionDescription) {
        _sdp = sdp;
        _didCreateSessionDescription(peerConnection, sdp, error);
    }
    if(!error) {
        DDLogDebug(@"Did create session description for connection: %@",_connection.identifier);
        DDLogDebug(@"Setting local session description for connection: %@",_connection.identifier);
        [peerConnection setLocalDescriptionWithDelegate:self sessionDescription:sdp];
    }else{
        DDLogError(@"Could not create session description. Error %@",[error localizedDescription]);
    }
    
}

// Called when setting a local or remote description.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didSetSessionDescriptionWithError:(NSError *)error {
    if(_didSetSessionDescription)
        _didSetSessionDescription(peerConnection,(_sdp) ? _sdp : peerConnection.remoteDescription, error);
    
    if(!error) {
        DDLogDebug(@"Did set session description for connection: %@",_connection.identifier);
    }else{
        DDLogError(@"Could not set session description. Error %@",[error localizedDescription]);
    }
    
}

@end
