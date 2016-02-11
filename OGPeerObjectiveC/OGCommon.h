//
//  OGCommon.h
//  OGPeerObjectiveC
//
//  Created by Omar Hussain on 2/10/16.
//  Copyright © 2016 ohgarage. All rights reserved.
//

#ifndef OGCommon_h
#define OGCommon_h


typedef NS_ENUM (NSInteger, OGStreamType){
    OGStreamTypeAudio,
    OGStreamTypeVideo,
    OGStreamTypeBoth
};

typedef NS_ENUM (NSInteger, OGCameraDirection){
    OGCameraDirectionFront,
    OGCameraDirectionBack,
};


typedef NS_ENUM (NSInteger, OGConnectionType) {
    OGConnectionTypeData,
    OGConnectionTypeMedia
};

typedef NS_ENUM (NSInteger, OGSerialization){
    OGSerializationBinary,
    OGSerializationBinaryUTF8,
    OGSerializationJSON,
    OGSerializationNone,
};

typedef NS_ENUM (NSInteger, OGMessageType){
    OGMessageTypeCandidate,
    OGMessageTypeOffer,
    OGMessageTypeAnswer,
    OGMessageTypeBye,
    OGMessageTypeOpen,
    OGMessageTypeError,
    OGMessageTypeIdTaken,
    OGMessageTypeInvalidKey,
    OGMessageTypeLeave,
    OGMessageTypeExpire,
};

#define DEFAULT_STUN_SERVER @"stun:stun.l.google.com:19302"
#endif /* OGCommon_h */
