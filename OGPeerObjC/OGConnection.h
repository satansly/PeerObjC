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
/**
 *  @brief Options associated with a connection object at the time of initalizing
 */
@protocol OGConnectionOptions <NSObject>
/**
 *  @brief Identifier of the connection. If necessary to be handled manually
 */
@property (nonatomic, strong) NSString * connectionId;
/**
 *  @brief Arbitrary metadata associated with connection
 */
@property (nonatomic, strong) NSDictionary * metadata;
/**
 *  @brief Payload of offer message that results in creation of connection
 */
@property (nonatomic, strong) OGMessagePayload * payload;
/**
 *  @brief Constraints applicable on connection
 */
@property (nonatomic, strong) RTCMediaConstraints * constraints;
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
    id<OGConnectionOptions>  _options;
    BOOL _open;
}
/**
 *  @brief Is the connection open
 */
@property (nonatomic, assign,readonly) BOOL open;
/**
 *  @brief Identifier for connection
 */
@property (nonatomic, strong,readonly) NSString * identifier;
/**
 *  @brief Label of the connection
 */
@property (nonatomic, strong,readonly) NSString * label;
/**
 *  @brief Peer with which the connection is in progress
 */
@property (nonatomic, strong,readonly) NSString * peer;
/**
 *  @brief Type of current connection
 */
@property (nonatomic, assign,readonly) OGConnectionType type;
/**
 *  @brief Peer connection object
 */
@property (nonatomic, strong) RTCPeerConnection * peerConnection;
/**
 *  @brief Peer object managing the connection
 */
@property (nonatomic, strong,readonly) OGPeer * provider;
/**
 *  @brief Serialization type of the data connection
 */
@property (nonatomic, assign,readonly) OGSerialization serialization;
/**
 *  @brief Arbitrary metadata associated with connection
 */
@property (nonatomic, strong,readonly) NSDictionary * metadata;
/**
 *  @brief Negotiator currently negotiating the negotiation
 */
@property (nonatomic, strong,readonly) OGNegotiator * negotiator;
/**
 *  @brief Options object
 */
@property (nonatomic, strong,readonly) id<OGConnectionOptions>  options;

/**
 *  @brief Initializes connection with peer and options provided
 *
 *  @param peer     Peer with which connection is in progress
 *  @param provider Provider currently managing the connection
 *  @param options  Options used to initialize connection
 *
 *  @return Initialized instance of connection
 */
- (instancetype)initWithPeer:(NSString *)peer provider:(OGPeer *)provider options:(id<OGConnectionOptions>)options;
/**
 *  @brief Initializes connection with peer and default options
 *
 *  @param peer     Peer with which connection is in progress
 *  @param provider Provider currently managing the connection
 *
 *  @return Initialized instance of connection
 */
- (instancetype)initWithPeer:(NSString *)peer provider:(OGPeer *)provider;

/**
 *  @brief Initializes connection process
 */
-(void)initialize;

/**
 *  @brief Connection type returned as a string
 *
 *  @return Connection type as a string for negotiation messaging
 */
-(NSString *)typeAsString;
/**
 *  @brief Serialization type returned as a string
 *
 *  @return Serialization type as a string for negotiation messaging
 */
-(NSString *)serializationAsString;
/**
 *  @brief Identifier prefix discriminating types of connection
 *
 *  @return Identifier prefix discriminating types of connection
 */
+(NSString *)identifierPrefix;
/**
 *  @brief Handle negotiation message received
 *
 *  @param message Message received during negotiaton
 */
-(void)handleMessage:(OGMessage *)message;
/**
 *  @brief Closes the current connection and performs cleanup
 */
-(void)close;
@end
