//
//  OGUtils.h
//  OGPeerObjectiveC
//
//  Created by Omar Hussain on 2/10/16.
//  Copyright © 2016 ohgarage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OGCommon.h"



@interface OGUtilSupports : NSObject
@property (nonatomic, assign) BOOL audioVideo;
@property (nonatomic, assign) BOOL data;
@property (nonatomic, assign) BOOL binaryBlob;
@property (nonatomic, assign) BOOL binary;
@property (nonatomic, assign) BOOL reliable;
@property (nonatomic, assign) BOOL sctp;
@property (nonatomic, assign) BOOL onnegotiationneeded;

+(OGUtilSupports *)supports;
@end

@interface OGChunk : NSObject
@property (nonatomic, assign) int n;
@property (nonatomic, strong) NSData * data;
@property (nonatomic, assign) int total;
@end

@interface OGUtil : NSObject
@property (nonatomic, strong) NSString * browser;
@property (nonatomic, strong) OGUtilSupports * supports;
@property (nonatomic, assign) int logLevel;
@property (nonatomic, assign) int dataCount;

+(OGUtil *)util;
-(NSString *)host;
-(NSNumber *)port;
-(NSNumber *)chunkedMTU;
-(NSString *)randomToken;
-(NSString *)randomStringWithMaxLength:(NSInteger)len;
-(void)setLogLevel:(int)level;
-(void)printWithPrefix:(NSString *)prefix;
-(void)print;
-(BOOL)validateIdentifier:(NSString *)identifier;
-(BOOL)validateKey:(NSString *)key;
- (NSString *)blobToBinaryString:(NSString *)data;

-(NSString *)stringFromConnectionType:(OGConnectionType)type;
-(OGConnectionType)connectionTypeFromString:(NSString *)type;

-(NSString *)stringFromSerialization:(OGSerialization)serialization;
-(OGSerialization)serializationFromString:(NSString *)serialization;

-(NSString *)stringFromMessageType:(OGMessageType)type;
-(OGMessageType)messageTypeFromString:(NSString *)type;


@end
