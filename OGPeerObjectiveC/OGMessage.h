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

@interface OGMessagePayload : NSObject
@property (nonatomic, strong) RTCSessionDescription * sdp;
@property (nonatomic, assign) OGConnectionType type;
@property (nonatomic, strong) NSString * label;
@property (nonatomic, strong) NSString * connectionId;
@property (nonatomic, assign) BOOL reliable;
@property (nonatomic, assign) OGSerialization serialization;
@property (nonatomic, strong) NSDictionary * metadata;
@property (nonatomic, strong) NSString * browser;
@property (nonatomic, strong) RTCICECandidate * candidate;
@property (nonatomic, strong) NSString * msg;

-(instancetype)initWithDictionary:(NSDictionary *)dict;
-(NSData *)JSONData;
@end
@interface OGMessage : NSObject
@property (nonatomic, strong) NSString * source;
@property (nonatomic, assign) OGMessageType type;
@property (nonatomic, strong) NSString * destination;
@property (nonatomic, strong) OGMessagePayload * payload;

-(instancetype)initWithDictionary:(NSDictionary *)dict;
-(NSData *)JSONData;
@end



