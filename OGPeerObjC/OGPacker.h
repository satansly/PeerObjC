//
//  OGPacker.h
//  Pods
//
//  Created by Omar Hussain on 2/12/16.
//
//

#import <Foundation/Foundation.h>
/**
 *  @brief Packer class to pack data for transmission on data channel with binary or binary-utf8 serialization schemes
 */
@interface OGPacker : NSObject
/**
 *  @brief Get packed buffered data
 *
 *  @return Packed and buffered ready for transmission on data channel
 */
-(NSData *)getBuffer;
/**
 *  @brief Packs the given value in a buffer with informational bytes
 *
 *  @param value Value that needs packing to be sent on data channel
 */
-(void)pack:(id)value;
@end
