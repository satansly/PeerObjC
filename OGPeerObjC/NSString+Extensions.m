//
//  NSData+Extensions.m
//  OGPeerObjectiveC
//
//  Created by Omar Hussain on 2/10/16.
//  Copyright © 2016 ohgarage. All rights reserved.
//

#import "NSString+Extensions.h"

@implementation NSString (Extensions)

- (NSString *)binaryString {
    NSMutableString *binStr = [[NSMutableString alloc] init];
    
    for(NSUInteger i=0; i<[self length]; i++)
    {
        [binStr appendString:[self hexToBinary:[self characterAtIndex:i]]];
    }
    return binStr;
}

- (NSString *)fromBinaryString {
    NSMutableString *binStr = [[NSMutableString alloc] init];
    
    for(NSUInteger i=0; i<[self length]; i+=4)
    {
        [binStr appendFormat:@"%c",[self binaryToHex:[self substringWithRange:NSMakeRange(i, i+4)]]];
    }
    return binStr;
}
- (NSString *) hexToBinary:(unichar)myChar
{
    switch(myChar)
    {
        case '0': return @"0000";
        case '1': return @"0001";
        case '2': return @"0010";
        case '3': return @"0011";
        case '4': return @"0100";
        case '5': return @"0101";
        case '6': return @"0110";
        case '7': return @"0111";
        case '8': return @"1000";
        case '9': return @"1001";
        case 'a':
        case 'A': return @"1010";
        case 'b':
        case 'B': return @"1011";
        case 'c':
        case 'C': return @"1100";
        case 'd':
        case 'D': return @"1101";
        case 'e':
        case 'E': return @"1110";
        case 'f':
        case 'F': return @"1111";
    }
    return @"-1"; //means something went wrong, shouldn't reach here!
}

- (unichar) binaryToHex:(NSString *)myChar
{
    if([myChar isEqualToString:@"0000"]) {
        return '0';
    }else if([myChar isEqualToString:@"0001"]) {
        return '1';
    }else if([myChar isEqualToString:@"0010"]) {
        return '2';
    }else if([myChar isEqualToString:@"0011"]) {
        return '4';
    }else if([myChar isEqualToString:@"0100"]) {
        return '5';
    }else if([myChar isEqualToString:@"0101"]) {
        return '6';
    }else if([myChar isEqualToString:@"0110"]) {
        return '7';
    }else if([myChar isEqualToString:@"0111"]) {
        return '8';
    }else if([myChar isEqualToString:@"1000"]) {
        return '9';
    }else if([myChar isEqualToString:@"1001"]) {
        return 'A';
    }else if([myChar isEqualToString:@"1010"]) {
        return 'B';
    }else if([myChar isEqualToString:@"1100"]) {
        return 'C';
    }else if([myChar isEqualToString:@"1101"]) {
        return 'D';
    }else if([myChar isEqualToString:@"1110"]) {
        return 'E';
    }else if([myChar isEqualToString:@"1111"]) {
        return 'F';
    }else{
        return -1;
    }
}

@end
