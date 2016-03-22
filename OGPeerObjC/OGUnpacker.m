//
//  OGUnpacker.m
//  Pods
//
//  Created by Omar Hussain on 2/13/16.
//
//

#import "OGUnpacker.h"

@interface OGUnpacker ()
@property (nonatomic, assign) int index;
@property (nonatomic, strong) NSData * dataBuffer;
@property (nonatomic, assign) char * dataView;
@property (nonatomic, assign) NSUInteger length;
@end
@implementation OGUnpacker
-(instancetype)initWithData:(NSData *)data {
    self = [super init];
    if(self) {
        NSAssert(data != nil, @"Provided buffer was nil");
        _index = 0;
        _dataBuffer = data;
        _dataView = (char *)[_dataBuffer bytes];
        _length = _dataBuffer.length;
        
    }
    return self;
}

-(id)unpack {
    DDLogDebug(@"Unpacking has begun");
    UInt8 type = [self unpack_uint8];
    if (type < 0x80) {
        long positive_fixnum = type;
        DDLogDebug(@"Unpacked positive long %ld",positive_fixnum);
        return @(positive_fixnum);
    } else if ((type ^ 0xe0) < 0x20) {
        long negative_fixnum = (type ^ 0xe0) - 0x20;
        DDLogDebug(@"Unpacked negative long %ld",negative_fixnum);
        return @(negative_fixnum);
    }
    int size;
    if ((size = type ^ 0xa0) <= 0x0f) {
        return [self unpack_raw:size];
    } else if ((size = type ^ 0xb0) <= 0x0f) {
        return [self unpack_string:size];
    } else if ((size = type ^ 0x90) <= 0x0f) {
        return [self unpack_array:size];
    } else if ((size = type ^ 0x80) <= 0x0f) {
        return [self unpack_map:size ];
    }
    switch(type) {
        case 0xc0: {
            DDLogWarn(@"Unpacked a nil");
            return nil;
        }
            //case 0xc1:
            //return undefined;
        case 0xc2: {
            DDLogDebug(@"Unpacked boolean false");
            return @(false);
        }
        case 0xc3: {
            DDLogDebug(@"Unpacked boolean true");
            return @(true);
        }
        case 0xca:
            return @([self unpack_float]);
        case 0xcb:
            return @([self unpack_double]);
        case 0xcc:
            return @([self unpack_uint8]);
        case 0xcd:
            return @([self unpack_uint16]);
        case 0xce:
            return @([self unpack_uint32]);
        case 0xcf:
            return @([self unpack_uint64]);
        case 0xd0:
            return @([self unpack_int8 ]);
        case 0xd1:
            return @([self unpack_int16 ]);
        case 0xd2:
            return @([self unpack_int32 ]);
        case 0xd3:
            return @([self unpack_int64 ]);
            //case 0xd4:
            //    return undefined;
            //case 0xd5:
            //    return undefined;
            //case 0xd6:
            //    return undefined;
            //case 0xd7:
            //    return undefined;
        case 0xd8:
            
            size = [self unpack_uint16];
            return [self unpack_string:size];
        case 0xd9:
            size = [self unpack_uint32];
            return [self unpack_string:size];
        case 0xda:
            size = [self unpack_uint16];
            return [self unpack_raw:size];
        case 0xdb:
            size = [self unpack_uint32];
            return [self unpack_raw:size];
        case 0xdc:
            size = [self unpack_uint16];
            return [self unpack_array:size];
        case 0xdd:
            size = [self unpack_uint32];
            return [self unpack_array:size];
        case 0xde:
            size = [self unpack_uint16];
            return [self unpack_map:size];
        case 0xdf:
            size = [self unpack_uint32];
            return [self unpack_map:size];
    }
    return nil;
}

-(UInt8)unpack_uint8 {
    uint byte = _dataView[_index] & 0xff;
    _index++;
    DDLogDebug(@"Unpacked unsigned 8-bit integer %d",byte);
    return byte;
};

-(UInt16)unpack_uint16 {
    int bytes[2];
    //[[self read:2] getValue:&bytes];
    [self read:2 buff:bytes];
    UInt16 uint16 =
    ((bytes[0] & 0xff) * 256) + (bytes[1] & 0xff);
    _index += 2;
    DDLogDebug(@"Unpacked unsigned 16-bit integer %d",uint16);
    return uint16;
}

-(UInt32)unpack_uint32 {
    int bytes[4];
    //[[self read:4] getValue:&bytes];
    [self read:4 buff:bytes];
    UInt32 uint32 =
    ((bytes[0]  * 256 +
      bytes[1]) * 256 +
     bytes[2]) * 256 +
    bytes[3];
    _index += 4;
    DDLogDebug(@"Unpacked unsigned 32-bit integer %d",(unsigned int)uint32);
    return uint32;
}

-(UInt64)unpack_uint64 {
    int bytes[8];
    //[[self read:8] getValue:&bytes];
    [self read:8 buff:bytes];
    UInt64 uint64 =
    ((((((bytes[0]  * 256 +
          bytes[1]) * 256 +
         bytes[2]) * 256 +
        bytes[3]) * 256 +
       bytes[4]) * 256 +
      bytes[5]) * 256 +
     bytes[6]) * 256 +
    bytes[7];
    _index += 8;
    DDLogDebug(@"Unpacked unsigned 64-bit integer %lld",uint64);
    return uint64;
}


-(int8_t)unpack_int8 {
    UInt8 uint8 = [self unpack_uint8];
    int8_t retVal = (uint8 < 0x80 ) ? uint8 : uint8 - (1 << 8);
    DDLogDebug(@"Unpacked 8-bit integer %d",retVal);
    return retVal;
};

-(int16_t)unpack_int16 {
    UInt16 uint16 = [self unpack_uint16];
    int16_t retVal = (uint16 < 0x8000 ) ? uint16 : uint16 - (1 << 16);
    DDLogDebug(@"Unpacked 16-bit integer %d",retVal);
    return retVal;
    
}

-(int32_t)unpack_int32 {
    UInt32 uint32 = [self unpack_uint32];
    int32_t retVal = (uint32 < pow(2, 31) ) ? uint32 :
    uint32 - pow(2, 32);
    DDLogDebug(@"Unpacked 32-bit integer %d",retVal);
    return retVal;
    
}

-(int64_t)unpack_int64 {
    UInt64 uint64 = [self unpack_uint64];
    int64_t retVal = (uint64 < pow(2, 63) ) ? uint64 :
    uint64 - pow(2, 64);
    DDLogDebug(@"Unpacked 64-bit integer %lld",retVal);
    return retVal;
    
}

-(NSData *)unpack_raw:(uint)size {
    if ( _length < _index + size) {
        DDLogError(@"BinaryPackFailure: index is out of range %d %d %lu",_index, size, (unsigned long)_length);
        @throw  [NSError errorWithLocalizedDescription:@"BinaryPackFailure: index is out of range %d %d %lu",_index, size, _length];
    }
    NSData * buf = [_dataBuffer subdataWithRange:NSMakeRange(_index, size) ];
    _index += size;
    
    //buf = util.bufferToString(buf);
    DDLogDebug(@"Unpacked blob %@",[buf description]);
    return buf;
}

-(NSString *)unpack_string:(uint)size {
    NSData * subdata = [_dataBuffer subdataWithRange:NSMakeRange( _index, size)];
    NSMutableString * str = [[NSMutableString  alloc] initWithData:subdata encoding:NSUTF8StringEncoding];
    _index += size;
    DDLogDebug(@"Unpacked string %@",str);
    return str;
}

-(NSArray *)unpack_array:(uint)size {
    NSMutableArray * objects = [NSMutableArray array];
    for(int i = 0; i < size; i++) {
        objects[i] = [self unpack];
    }
    DDLogDebug(@"Unpacked array %@",[objects description]);
    return objects;
}

-(NSDictionary *)unpack_map:(uint)size {
    NSMutableDictionary * map = [NSMutableDictionary dictionary];
    for(int i = 0; i < size; i++) {
        NSString * key  = [self unpack];
        DDLogDebug(@"Unpacked key %@",key);
        id value = [self unpack];
        DDLogDebug(@"Unpacked value %@",[value description]);
        map[key] = value;
    }
    DDLogDebug(@"Unpacked dictionary %@",[map description]);
    return map;
}

-(float)unpack_float {
    UInt32 uint32 = [self unpack_uint32];
    UInt32 sign = uint32 >> 31;
    UInt32 exp  = ((uint32 >> 23) & 0xff) - 127;
    UInt32 fraction = ( uint32 & 0x7fffff ) | 0x800000;
    float retVal = (sign == 0 ? 1 : -1) *
    fraction * pow(2, exp - 23);
    DDLogDebug(@"Unpacked float %f",retVal);
    return retVal;
    
}

-(double)unpack_double {
    UInt32 h32 = [self unpack_uint32];
    UInt32 l32 = [self unpack_uint32];
    UInt32 sign = h32 >> 31;
    UInt32 exp  = ((h32 >> 20) & 0x7ff) - 1023;
    UInt32 hfrac = ( h32 & 0xfffff ) | 0x100000;
    UInt32 frac = hfrac * pow(2, exp - 20) +
    l32   * pow(2, exp - 52);
    double retVal = (sign == 0 ? 1 : -1) * frac;
    DDLogDebug(@"Unpacked double %f",retVal);
    return retVal;
    
}

-(void)read:(uint)length buff:(int *)buf{
    
    int j = _index;
    //int sub[length];
    if (j + length <= _length) {
        for(int i = 0; i < length; j++,i++) {
            buf[i] = _dataView[j];
            NSLog(@"%i",buf[i]);//sub[i]);
        }
        //NSValue * val = [NSValue valueWithPointer:&sub];//[NSValue value:&sub withObjCType:@encode(int[])];
        //return &sub;//send;//[NSValue valueWithBytes:(__bridge const void * _Nonnull)([_dataBuffer subdataWithRange:NSMakeRange(_index, length)]) objCType:@encode(NSData)];
    } else {
        DDLogError(@"BinaryPackFailure: read index out of range");
        @throw  [NSError errorWithLocalizedDescription:@"BinaryPackFailure: read index out of range"];
        
    }
}
@end
