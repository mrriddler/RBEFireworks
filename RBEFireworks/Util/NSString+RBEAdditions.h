//
//  NSString+RBEAdditions.h
//  RBENetWork
//
//  Created by Robbie on 15/11/19.
//  Copyright © 2015年 Robbie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (RBEAdditions)

//base64Encode http header field string, to prevent unsafe character
+ (NSString *)rbe_Base64EncodedStringFromString:(NSString *)string;

//characterset endcode URL components
+ (NSString *)rbe_URLEncodedStringFromString:(NSString *)string;

//return a get method URL components by given parameters
+ (NSString *)rbe_URLParametersStringFromParameters:(NSDictionary *)parameters;

//return a get method URL by given original url and parameters
+ (NSString *)rbe_URLWithOriginURL:(NSString *)originURL appendParameters:(NSDictionary *)parameters;

//return string 's MD5
+ (NSString *)rbe_md5StringFromString:(NSString *)string;

@end
