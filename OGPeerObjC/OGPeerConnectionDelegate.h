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

/**
 *  @brief Delegate handles peer connection delegate methods and notifies necessary objects
 */
@interface OGPeerConnectionDelegate : NSObject<RTCPeerConnectionDelegate>
/**
 *  @brief Connection under negotiation
 */
@property (nonatomic, strong) OGConnection * connection;
/**
 *  @brief Negotiator currently negotiating the connection
 */
@property (nonatomic, assign) OGNegotiator * negotiator;
/**
 *  @brief Initializes delegate object which will notify negotiator and connection of changes in session
 *
 *  @param connection Connection under negotiation
 *  @param negotiator Negotiator currently negotiating the connection
 *
 *  @return Initialized delegate object
 */
-(instancetype)initWithConnection:(OGConnection *)connection negotiator:(OGNegotiator *)negotiator;
@end
