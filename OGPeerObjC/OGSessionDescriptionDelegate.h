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
/**
 *  @brief Completion block invoked on creation of a session description
 *
 *  @param pc    Peer connecion object
 *  @param sdp   Newly created session description object
 *  @param error Error if there was a failure when creating session description
 */
typedef void (^DidCreateSessionDescriptionBlock)(RTCPeerConnection * pc, RTCSessionDescription * sdp, NSError * error);
typedef void (^DidSetSessionDescriptionBlock)(RTCPeerConnection * pc, RTCSessionDescription * sdp, NSError * error);

/**
 *  @brief Handles delegate methods of session creation and/or setting and returns in a block
 */
@interface OGSessionDescriptionDelegate : NSObject<RTCSessionDescriptionDelegate>
/**
 *  @brief Connection object under negotiation
 */
@property (nonatomic, strong) OGConnection * connection;
/**
 *  @brief Negotiator object currently negotiating the session
 */
@property (nonatomic, assign) OGNegotiator * negotiator;
/**
 *  @brief Completion block called upon creation of session description
 */
@property (nonatomic, strong) DidCreateSessionDescriptionBlock didCreateSessionDescription;
/**
 *  @brief Completion block called upon setting the session descripiton
 */
@property (nonatomic, strong) DidSetSessionDescriptionBlock didSetSessionDescription;
/**
 *  @brief Initializes delegate object ready to handle Session description delegates and return in blocks
 *
 *  @param connection Connection object under negotiation
 *  @param negotiator Negotiator object currently negotiating the session
 *
 *  @return Initialized instance of delegate object
 */
-(instancetype)initWithConnection:(OGConnection *)connection negotiator:(OGNegotiator *)negotiator;

@end
