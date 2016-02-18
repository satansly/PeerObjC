//
//  OGUtils.h
//  OGPeerObjectiveC
//
//  Created by Omar Hussain on 2/10/16.
//  Copyright © 2016 ohgarage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OGCommon.h"




/**
 *  @brief Adds chunking capability of large objects
 */
@interface OGChunk : NSObject
/**
 *  @brief N-th chunk in the series
 */
@property (nonatomic, assign) int n;
/**
 *  @brief Binary data associated with n-th chunk
 */
@property (nonatomic, strong) NSData * data;
/**
 *  @brief Total number of chunks
 */
@property (nonatomic, assign) int total;
@end

/**
 *  @brief Utility class for miscellenaous tasks
 */
@interface OGUtil : NSObject
/**
 *  @brief Current browser(or client). In this case it is the iOS client
 */
@property (nonatomic, strong) NSString * browser;
/**
 *  @brief Logging level.
 */
@property (nonatomic, assign) int logLevel;
/**
 *  @brief Data transmitted count
 */
@property (nonatomic, assign) int dataCount;

/**
 *  @brief Shared instance for convenient access to methods and properties
 *
 *  @return Shared instance of utils
 */
+(OGUtil *)util;
/**
 *  @brief Default host, when none is provided. Currently 0.peerjs.com
 *
 *  @return Default host of peerjs server
 */
-(NSString *)host;
/**
 *  @brief Default port, when none is provided. Currently 9000
 *
 *  @return Default port of peerjs server
 */
-(NSNumber *)port;
/**
 *  @brief Default chunk size. Currently 16300
 *
 *  @return Default chunk size
 */
-(NSNumber *)chunkedMTU;
/**
 *  @brief Generates random token
 *
 *  @return Generates random 36 character token
 */
-(NSString *)randomToken;
/**
 *  @brief Generates random string of given length
 *
 *  @param len Length of string to be generated
 *
 *  @return Generates random string of given length
 */
-(NSString *)randomStringWithMaxLength:(NSInteger)len;
/**
 *  @brief Sets logging level
 *
 *  @param level Level of loggin required
 */
-(void)setLogLevel:(int)level;

/**
 *  @brief Validates given identifier has allowed characters
 *
 *  @param identifier Identifier being validated
 *
 *  @return A yes or no based on validation of identifiers
 */
-(BOOL)validateIdentifier:(NSString *)identifier;

/**
 *  @brief Validates given key has allowed characters
 *
 *  @param key Key being validated
 *
 *  @return A yes or no based on validation of key
 */
-(BOOL)validateKey:(NSString *)key;

/**
 *  @brief UTF-8 encoded string from data
 *
 *  @param data Encoded data
 *
 *  @return String encoded in UTF-8
 */
- (NSString *)blobToBinaryString:(NSString *)data;

/**
 *  @brief String representation of the connection type
 *
 *  @param type Connection type
 *
 *  @return String representation of the connection type
 */
-(NSString *)stringFromConnectionType:(OGConnectionType)type;
/**
 *  @brief Enum represetation of connection type
 *
 *  @param type Connection type string
 *
 *  @return Enum representation of connection type
 */
-(OGConnectionType)connectionTypeFromString:(NSString *)type;

/**
 *  @brief String representation of serialization type
 *
 *  @param serialization Serialization type enum
 *
 *  @return String representation of serialziation type
 */
-(NSString *)stringFromSerialization:(OGSerialization)serialization;

/**
 *  @brief Enum representation of serialization type
 *
 *  @param serialization Serialization type string
 *
 *  @return Enum representation of  serialization type
 */
-(OGSerialization)serializationFromString:(NSString *)serialization;

/**
 *  @brief String representation of message type
 *
 *  @param type Message type enum
 *
 *  @return String representation of message type
 */
-(NSString *)stringFromMessageType:(OGMessageType)type;

/**
 *  @brief Enum represetation of message type
 *
 *  @param type Message type string
 *
 *  @return Enum represetation of message type
 */
-(OGMessageType)messageTypeFromString:(NSString *)type;

/**
 *  @brief String representation of stream type
 *
 *  @param type Stream type enum
 *
 *  @return String representation of stream type
 */
-(OGStreamType)streamTypeFromString:(NSString *)type;
/**
 *  @brief Enum representation of stream type
 *
 *  @param type Stream type string
 *
 *  @return Enum representation of stream type
 */
-(NSString *)stringFromStreamType:(OGStreamType)type;

@end
