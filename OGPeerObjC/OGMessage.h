//
//  OGMessage.h
//  OGPeerObjectiveC
//
//  Created by Omar Hussain on 2/11/16.
//  Copyright © 2016 ohgarage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OGCommon.h"
#import "RTCSessionDescription.h"
#import "RTCICECandidate.h"

@class OGConnection;
/**
 *  @brief Message payload exchanged during negotiation
 */
@interface OGMessagePayload : NSObject
/**
 *  @brief Session description object
 */
@property (nonatomic, strong) RTCSessionDescription * sdp;
/**
 *  @brief Type of connection @see OGConnectionType
 */
@property (nonatomic, assign) OGConnectionType type;
/**
 *  @brief Type of stream being sent/received
 */
@property (nonatomic, assign) OGStreamType streamType;
/**
 *  @brief Label for connection in negotiation
 */
@property (nonatomic, strong) NSString * label;
/**
 *  @brief Connection identifier for connection under negotiation
 */
@property (nonatomic, strong) NSString * connectionId;
/**
 *  @brief Is connection reliable. Specific to data connections
 */
@property (nonatomic, assign) BOOL reliable;
/**
 *  @brief Serialization scheme for data to be transmission over data connection
 */
@property (nonatomic, assign) OGSerialization serialization;
/**
 *  @brief Any arbitrary metadata to be exchanged during negotiation
 */
@property (nonatomic, strong) NSDictionary * metadata;

/**
 *  @brief Name of browser at client
 */
@property (nonatomic, strong) NSString * browser;
/**
 *  @brief Candidate message
 */
@property (nonatomic, strong) RTCICECandidate * candidate;
/**
 *  @brief Message
 */
@property (nonatomic, strong) NSString * msg;
/**
 *  @brief Initialized instance of message payload with provided dictionary
 *
 *  @param dict Dictionary with message keys/values set
 *
 *  @return Instance of initialized payload object
 */
-(instancetype)initWithDictionary:(NSDictionary *)dict;
/**
 *  @brief Returns payload as a stream of binary
 *
 *  @return JSON object from payload as blob
 */
-(NSData *)JSONData;
/**
 *  @brief Returns dictionary representation of message payload
 *
 *  @return Dictionary representation of message payload
 */
-(NSDictionary *)dictionary;
@end

/**
 *  @brief Message object exchanged during connection negotiation
 */
@interface OGMessage : NSObject
/**
 *  @brief Source identifier of the message sender
 */
@property (nonatomic, strong) NSString * source;
/**
 *  @brief Type of message
 */
@property (nonatomic, assign) OGMessageType type;
/**
 *  @brief Destination identifer of message receiver
 */
@property (nonatomic, strong) NSString * destination;
/**
 *  @brief Payload object of the message
 */
@property (nonatomic, strong) OGMessagePayload * payload;
/**
 *  @brief Initialized instance of message with provided dictionary
 *
 *  @param dict Dictionary with message keys/values set and to be sent/received
 *
 *  @return Instance of initialized message object
 */
-(instancetype)initWithDictionary:(NSDictionary *)dict;
/**
 *  @brief Returns message as a stream of binary
 *
 *  @return JSON object from message as blob
 */
-(NSData *)JSONData;
/**
 *  @brief Returns dictionary representation of message
 *
 *  @return Dictionary representation of message
 */
-(NSDictionary *)dictionary;
@end

@interface OGMessage (Negotiator)
/**
 *  @brief Prepares an offer message with provided connection object
 *
 *  @param connection connection object
 *
 *  @return Prepared offer message ready to be sent to peer
 */
+(OGMessage *)offerWithConnection:(OGConnection *)connection;
/**
 *  @brief Prepares an answer message with provided connection object
 *
 *  @param connection connection object
 *
 *  @return Prepared answer message ready to be sent to peer
 */
+(OGMessage *)answerWithConnection:(OGConnection *)connection;
/**
 *  @brief Prepares a candidate message with provided connection object
 *
 *  @param connection connection object
 *
 *  @return Prepared candidate message ready to be sent to peer
 */
+(OGMessage *)candidateWithConnection:(OGConnection *)connection candidate:(RTCICECandidate *)candidate;
/**
 *  @brief Prepares a leave message with provided connection object
 *
 *  @param connection connection object
 *
 *  @return Prepared leave message ready to be sent to peer
 */
+(OGMessage *)leaveWithConnection:(OGConnection *)connection;
@end



