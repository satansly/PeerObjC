//
//  OGPacker.m
//  Pods
//
//  Created by Omar Hussain on 2/12/16.
//
//

#import "OGPacker.h"
#import "OGPackingUtils.h"
@interface OGPacker ()
@property (nonatomic, strong) NSMutableData * data;
@end
@implementation OGPacker
-(instancetype)init {
    self = [super init];
    if(self) {
        _data = [NSMutableData data];
        
    }
    return self;
}

-(NSData *)getBuffer {
    return _data;
}
-(void)append:(char)val {
    DDLogError(@"Append data to buffer");
    [_data appendBytes:&val length:sizeof(val)];
}
-(void)pack:(id)value {
    DDLogDebug(@"Packing value %@",[value description]);
    if ([value isKindOfClass:[NSString class]]) {
        NSString * str = (NSString *)value;
        [self pack_string:str];
    } else if ([value isKindOfClass:[NSNumber class]]) {
        if (strcmp([value objCType], @encode(int)) == 0) {
            long val = ((NSNumber *)value).longValue;
            [self pack_integer: val];
        } else if(strcmp([value objCType], @encode(double)) == 0) {
            int val = ((NSNumber *)value).doubleValue;
            [self pack_double:val];
        } else if(strcmp([value objCType], @encode(BOOL)) == 0) {
            BOOL val = ((NSNumber *)value).boolValue;
            if (val == true) {
                DDLogDebug(@"Boolean true packed");
                [self append:0xc3];
            } else if (val == false) {
                DDLogDebug(@"Boolean false packed");
                [self append:0xc2];
            }
        }
    } else if ([value isKindOfClass:[NSObject class]]) {
        if (value == nil) {
            DDLogWarn(@"Nil value being packed");
            [self append:0xc0];
        } else {
            if ([value isKindOfClass:[NSArray class]]) {
                [self pack_array:value];
            } else if ([value isKindOfClass:[NSData class]]) {
                [self pack_bin:value];
            } else if (strcmp([value objCType], @encode(char [])) == 0) {
                char * arr;
                NSValue * val = (NSValue *)value;
                [val getValue:&arr];
                NSData* dat = [NSData dataWithBytes:arr length:sizeof(arr)];
                [self pack_bin:dat];
            } else if ([value isKindOfClass:[NSDictionary class]]) {
                [self pack_object:value];
            } else if ([value isKindOfClass:[NSDate class]]) {
                [self pack_string:[value description]];
            } else {
                DDLogError(@"Type not yet supported");
                @throw  [NSError errorWithLocalizedDescription:@"Type not yet supported"];
            }
        }
    } else {
        DDLogError(@"Type not yet supported");
        @throw  [NSError errorWithLocalizedDescription:@"Type not yet supported"];
    }
    
}


-(void)pack_bin:(NSData *)blob {
    DDLogDebug(@"Packing binary blob");
    NSUInteger length = blob.length;
    if (length <= 0x0f) {
        [self pack_uint8:0xa0 + length];
    } else if (length <= 0xffff) {
        [self append:0xda];
        [self pack_uint16:length];
    } else if (length <= 0xffffffff) {
        [self append:0xdb];
        [self pack_uint32:(UInt32)length];
    } else{
        DDLogError(@"Invalid length");
        @throw  [NSError errorWithLocalizedDescription:@"Invalid length"];
    }
    [self.data appendData:blob];
}

-(void)pack_string:(NSString *)str {
    DDLogDebug(@"Packing string. %@",str);
    NSUInteger length = [OGPackingUtils utf8Length:str];
    
    if (length <= 0x0f) {
        [self pack_uint8:0xb0 + length];
    } else if (length <= 0xffff) {
        [self append:0xd8];
        [self pack_uint16:length];
    } else if (length <= 0xffffffff) {
        [self append:0xd9];
        [self pack_uint32:(UInt32)length];
    } else{
        DDLogError(@"Invalid length");
        @throw  [NSError errorWithLocalizedDescription:@"Invalid length"];
    }
    [self.data appendData:[str dataUsingEncoding:NSUTF8StringEncoding]];
}

-(void)pack_array:(NSArray *)ary {
    DDLogDebug(@"Packing array. %@",[ary description]);
    NSUInteger length = ary.count;
    if (length <= 0x0f) {
        [self pack_uint8:0x90 + length];
    } else if (length <= 0xffff) {
        [self append:0xdc];
        [self pack_uint16:length];
    } else if (length <= 0xffffffff) {
        [self append:0xdd];
        [self pack_uint32:(UInt32)length];
    } else{
        DDLogError(@"");
        @throw  [NSError errorWithLocalizedDescription:@"Invalid length"];
    }
    for(int i = 0; i < length; i++) {
        DDLogDebug(@"Packing element at index %d",i);
        [self pack:ary[i]];
    }
}

-(void)pack_integer:(int64_t)num {
    DDLogDebug(@"Packing integer %lld",num);
    if ( -0x20 <= num && num <= 0x7f) {
        DDLogDebug(@"Packing byte %d",(uint)num);
        [self append:num & 0xff];
    } else if (0x00 <= num && num <= 0xff) {
        [self append:0xcc];
        [self pack_uint8:(UInt8)num];
    } else if (-0x80 <= num && num <= 0x7f) {
        [self append:0xd0];
        [self pack_int8:(int8_t)num];
    } else if ( 0x0000 <= num && num <= 0xffff) {
        [self append:0xcd];
        [self pack_uint16:(UInt16)num];
    } else if (-0x8000 <= num && num <= 0x7fff) {
        [self append:0xd1];
        [self pack_int16:(int16_t)num];
    } else if ( 0x00000000 <= num && num <= 0xffffffff) {
        [self append:0xce];
        [self pack_uint32:(UInt32)num];
    } else if (-0x80000000 <= num && num <= 0x7fffffff) {
        [self append:0xd2];
        [self pack_int32:(int32_t)num];
    } else if (-0x8000000000000000 <= num && num <= 0x7FFFFFFFFFFFFFFF) {
        [self append:0xd3];
        [self pack_int64:(int64_t)num];
    } else if (0x0000000000000000 <= num && num <= 0xFFFFFFFFFFFFFFFF) {
        [self append:0xcf];
        [self pack_uint64:(UInt64)num];
    } else{
        DDLogError(@"Invalid integer");
        @throw  [NSError errorWithLocalizedDescription:@"Invalid integer"];
    }
}

-(void)pack_double:(double)num {
    DDLogDebug(@"Packing double %f",num);
    int sign = 0;
    if (num < 0) {
        sign = 1;
        num = -num;
    }
    double exp  = floor(log(num) / log(2));
    double frac0 = num / pow(2, exp) - 1;
    double frac1 = floor(frac0 * pow(2, 52));
    double b32   = pow(2, 32);
    uint h32 = (sign << 31) | ((uint)(exp+1023) << 20) | ((uint)(frac1 / b32) & 0x0fffff);
    uint l32 = ((uint)frac1 % (uint)b32);
    [self append:0xcb];
    [self pack_int32:h32];
    [self pack_int32:l32];
}

-(void)pack_object:(NSDictionary *)obj {
    DDLogDebug(@"Packing dictionary. %@",[obj description]);
    NSArray * keys = obj.allKeys;
    uint length = (uint)keys.count;
    if (length <= 0x0f) {
        [self pack_uint8:0x80 + length];
    } else if (length <= 0xffff) {
        [self append:0xde];
        [self pack_uint16:length];
    } else if (length <= 0xffffffff) {
        [self append:0xdf];
        [self pack_uint32:length];
    } else{
        DDLogError(@"Invalid length");
        @throw  [NSError errorWithLocalizedDescription:@"Invalid length"];
    }
    for(id key in obj.allKeys) {
        DDLogDebug(@"Packing key %@",[key description]);
        [self pack:key];
        DDLogDebug(@"Packing value %@",[obj[key] description]);
        [self pack:obj[key]];
        
    }
}

-(void)pack_uint8:(UInt8)num {
    DDLogDebug(@"Packing unsigned 8-bit integer %d",(UInt8)num);
    [self append:num];
}

-(void)pack_uint16:(UInt16)num {
    DDLogDebug(@"Packing unsigned 16-bit integer %d",(UInt16)num);
    [self append:num >> 8];
    [self append:num & 0xff];
}

-(void)pack_uint32:(UInt32)num {
    DDLogDebug(@"Packing unsigned 32-bit integer %d",(UInt32)num);
    UInt32 n = num & 0xffffffff;
    [self append:(UInt32)(n & 0xff000000) >> 24];
    [self append:(n & 0x00ff0000) >> 16];
    [self append:(n & 0x0000ff00) >>  8];
    [self append:(n & 0x000000ff)];
}

-(void)pack_uint64:(UInt64)num {
    DDLogDebug(@"Packing unsigned 64-bit integer %lld",(UInt64)num);
    UInt64 high = num / pow(2, 32);
    UInt64 low  = num % (UInt64)pow(2, 32);
    [self append:(high & 0xff000000) >> 24];
    [self append:(high & 0x00ff0000) >> 16];
    [self append:(high & 0x0000ff00) >>  8];
    [self append:(high & 0x000000ff)];
    [self append:(low  & 0xff000000) >> 24];
    [self append:(low  & 0x00ff0000) >> 16];
    [self append:(low  & 0x0000ff00) >>  8];
    [self append:(low  & 0x000000ff)];
}

-(void)pack_int8:(int8_t)num {
    DDLogDebug(@"Packing 8-bit integer %d",(int8_t)num);
    [self append:num & 0xff];
}

-(void)pack_int16:(int16_t)num {
    DDLogDebug(@"Packing 16-bit integer %d",(int16_t)num);
    [self append:(num & 0xff00) >> 8];
    [self append:num & 0xff];
}

-(void)pack_int32:(int32_t)num {
    DDLogDebug(@"Packing 32-bit integer %d",(int32_t)num);
    [self append:(num >> 24) & 0xff];
    [self append:(num & 0x00ff0000) >> 16];
    [self append:(num & 0x0000ff00) >> 8];
    [self append:(num & 0x000000ff)];
}

-(void)pack_int64:(int64_t)num {
    DDLogDebug(@"Packing 64-bit integer %lld",(int64_t)num);
    int64_t high = floor(num / pow(2, 32));
    int64_t low  = num % (int64_t)pow(2, 32);
    [self append:(high & 0xff000000) >> 24];
    [self append:(high & 0x00ff0000) >> 16];
    [self append:(high & 0x0000ff00) >>  8];
    [self append:(high & 0x000000ff)];
    [self append:(low  & 0xff000000) >> 24];
    [self append:(low  & 0x00ff0000) >> 16];
    [self append:(low  & 0x0000ff00) >>  8];
    [self append:(low  & 0x000000ff)];
}
@end
