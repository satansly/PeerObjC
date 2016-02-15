//
//  OGPackingUtils.m
//  Pods
//
//  Created by Omar Hussain on 2/13/16.
//
//

#import "OGPackingUtils.h"

@implementation OGPackingUtils


+(NSUInteger)utf8Length:(NSString *)str {
    //if (str.length > 600) {
    // Blob method faster for large strings
    
    return [str dataUsingEncoding:NSUTF8StringEncoding].length;
    /*} else {
     NSMutableString *asciiCharacters = [NSMutableString string];
     for (NSInteger i = 32; i < 127; i++)  {
     [asciiCharacters appendFormat:@"%c", i];
     }
     
     NSCharacterSet *nonAsciiCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:asciiCharacters] invertedSet];
     
     
     
     return [str stringByTrimmingCharactersInSet:nonAsciiCharacterSet].length;//[str .replace(/[^\u0000-\u007F]/g, _utf8Replace).length;
     }*/
}

@end
