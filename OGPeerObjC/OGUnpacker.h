//
//  OGUnpacker.h
//  Pods
//
//  Created by Omar Hussain on 2/13/16.
//
//

#import <Foundation/Foundation.h>


/**
 *  @brief Unpacks received binary or binary-utf8 serialized data
 */
@interface OGUnpacker : NSObject
/**
 *  @brief Initializes unpacker ready to unpack provided blob
 *
 *  @param data Data object that needs unpacking
 *
 *  @return Initialized instance of unpacker ready to unpack provided blob
 */
-(instancetype)initWithData:(NSData *)data;
/**
 *  @brief Begin unpacking
 *
 *  @return Returns an unpacked object
 */
-(id)unpack;
@end
