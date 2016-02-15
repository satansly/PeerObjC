//
//  OGCommon.h
//  OGPeerObjectiveC
//
//  Created by Omar Hussain on 2/10/16.
//  Copyright © 2016 ohgarage. All rights reserved.
//

#ifndef OGCommon_h
#define OGCommon_h

/**
 *  @brief Stream type received or to be transmitted over established media connection
 */
typedef NS_ENUM (NSInteger, OGStreamType) {
    /**
     *  Both audio and video streams
     */
    OGStreamTypeBoth,
    /**
     *  Only audio stream
     */
    OGStreamTypeAudio,
    /**
     *  Only video stream
     */
    OGStreamTypeVideo
};


/**
 *  @brief Type of connection being established
 */
typedef NS_ENUM (NSInteger, OGConnectionType) {
    /**
     *  Data connection for arbitrary data transmission
     */
    OGConnectionTypeData,
    /**
     *  Media connection for video and audio streams transmission
     */
    OGConnectionTypeMedia
};

/**
 *  @brief Serialization type for data connection
 */
typedef NS_ENUM (NSInteger, OGSerialization) {
    /**
     *  No serialization given or explicitly none
     */
    OGSerializationNone,
    /**
     *  Binary serialization
     */
    OGSerializationBinary,
    /**
     *  Binary utf-8 serialization
     */
    OGSerializationBinaryUTF8,
    /**
     *  JSON data plain serialization
     */
    OGSerializationJSON
};

/**
 *  @brief type of message
 */
typedef NS_ENUM (NSInteger, OGMessageType) {
    /**
     *  Candidate message
     */
    OGMessageTypeCandidate,
    /**
     *  Offer message
     */
    OGMessageTypeOffer,
    /**
     *  Answer message
     */
    OGMessageTypeAnswer,
    /**
     *  Bye message
     */
    OGMessageTypeBye,
    /**
     *  Open message
     */
    OGMessageTypeOpen,
    /**
     *  Error message
     */
    OGMessageTypeError,
    /**
     *  Id-taken message
     */
    OGMessageTypeIdTaken,
    /**
     *  Invalid-key message
     */
    OGMessageTypeInvalidKey,
    /**
     *  Leave message
     */
    OGMessageTypeLeave,
    /**
     *  Expire message
     */
    OGMessageTypeExpire,
};
/**
 *  @brief Default STUN server uri
 *
 *  @return Default STUN server uri
 */
#define DEFAULT_STUN_SERVER @"stun:stun.l.google.com:19302"
#endif /* OGCommon_h */
