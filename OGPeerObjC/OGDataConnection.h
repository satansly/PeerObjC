//
//  OGDataConnection.h
//  OGPeerObjectiveC
//
//  Created by Omar Hussain on 2/9/16.
//  Copyright © 2016 ohgarage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OGCommon.h"
#import "OGConnection.h"
#import "RTCDataChannel.h"
#import "RTCPeerConnection.h"


@class OGPeer;
@class OGDataConnection;

@protocol OGDataConnectionDelegate<OGConnectionDelegate>
- (void)connection:(OGDataConnection *)connection onData:(id)data;
@end

/**
 *  @brief Options associated with a data connection object at the time of initalizing
 */
@interface OGDataConnectionOptions : NSObject<OGConnectionOptions>
/**
 *  @brief Label for connection
 */
@property (nonatomic, strong) NSString * label;
/**
 *  @brief Serialization for connection
 */
@property (nonatomic, assign) OGSerialization serialization;
/**
 *  @brief Is true if connection is reliable
 */
@property (nonatomic, assign) BOOL reliable;
@end

/**
 *  @brief Connection object to perform messages/arbitrary data exchange
 */
@interface OGDataConnection : OGConnection
/**
 *  @brief Data channel associated with connection to perform exchange of messages/arbitrary data
 */
@property (nonatomic, strong) RTCDataChannel * dataChannel;
/**
 *  @brief True if connection is reliable
 */
@property (nonatomic, assign) BOOL reliable;
/**
 *  @brief Buffer size to use for data chunking
 */
@property (nonatomic, strong) NSNumber * bufferSize;
/**
 *  @brief Sets to connection data channel and prepares for exchanges
 *
 *  @param dataChannel Data channel object
 */
- (void)initialize:(RTCDataChannel *)dataChannel;
/**
 *  @brief Sends arbitrary data over data channel
 *
 *  @param data Arbitrary data
 */
- (void)send:(id)data;
@end
