//
//  RBEMarco.h
//  RBEFireworkPerformance
//
//  Created by Robbie on 16/8/3.
//  Copyright © 2016年 Robbie. All rights reserved.
//

#ifndef RBEMarco_h
#define RBEMarco_h

#define RBELog(format, ...) do {                                                                                                                                                 \
       fprintf(stderr, "<%s : %d> %s\n",                                          \
       [[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], \
       __LINE__, __func__);                                                       \
       (NSLog)((format), ##__VA_ARGS__);                                          \
       fprintf(stderr, "-------\n");                                              \
       } while (0)

#endif /* RBEMarco_h */
