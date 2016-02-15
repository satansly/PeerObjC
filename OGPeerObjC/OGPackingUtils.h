//
//  OGPackingUtils.h
//  Pods
//
//  Created by Omar Hussain on 2/13/16.
//
//

#import <Foundation/Foundation.h>

@interface OGPackingUtils : NSObject
/**
 *  @brief Gets utf8 length of string
 *
 *  @param str String receiver for which length needs calculation
 *
 *  @return Utf-8 length of string receiver
 */
+(NSUInteger)utf8Length:(NSString *)str;
@end
