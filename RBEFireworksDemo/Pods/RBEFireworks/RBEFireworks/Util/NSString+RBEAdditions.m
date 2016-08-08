//
//  NSString+RBEAdditions.m
//  RBENetWork
//
//  Created by Robbie on 15/11/19.
//  Copyright © 2015年 Robbie. All rights reserved.
//

#import "NSString+RBEAdditions.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (RBEAdditions)

+ (NSString *)rbe_Base64EncodedStringFromString:(NSString *)string {
    NSData *stringData = [string dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64EncodedStr = [stringData base64EncodedStringWithOptions:(NSDataBase64EncodingOptions)0];
    
    return base64EncodedStr;
}

+ (NSString *)rbe_URLEncodedStringFromString:(NSString *)string {
    return [string stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
}

+ (NSString *)rbe_URLParametersStringFromParameters:(NSDictionary *)parameters {
    NSMutableString *urlParametersString = [[NSMutableString alloc] initWithString:@""];
    if (parameters && parameters.count > 0) {
        for (NSString *key in parameters) {
            NSString *value = parameters[key];
            value = [NSString stringWithFormat:@"%@",value];
            value = [NSString rbe_URLEncodedStringFromString:value];
            [urlParametersString appendFormat:@"&%@=%@", key, value];
        }
    }
    return urlParametersString;
}

+ (NSString *)rbe_URLWithOriginURL:(NSString *)originURL appendParameters:(NSDictionary *)parameters {
    NSString *filtedURL = originURL;
    NSString *paraURL = [self rbe_URLParametersStringFromParameters:parameters];
    if (paraURL && paraURL.length > 0) {
        if ([originURL rangeOfString:@"?"].location != NSNotFound) {
            filtedURL = [filtedURL stringByAppendingString:paraURL];
        } else {
            filtedURL = [filtedURL stringByAppendingFormat:@"?%@", [paraURL substringFromIndex:1]];
        }
        return filtedURL;
    } else {
        return originURL;
    }
}

+ (NSString *)rbe_md5StringFromString:(NSString *)string {
    const char *str = [string UTF8String];
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (uint32_t)strlen(str), r);
    return [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
}

@end
