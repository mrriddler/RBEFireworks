//
//  RBEMemoryCache.m
//  RBEMemoryCache
//
//  Created by Robbie on 16/1/4.
//  Copyright © 2016年 Robbie. All rights reserved.
//

#import "RBEMemoryCache.h"
#import <UIKit/UIKit.h>
#import <pthread.h>

@interface RBELinkedHashMapNode : NSObject {
    @package
    id _key;
    id _value;
    __unsafe_unretained RBELinkedHashMapNode *_prev;
    __unsafe_unretained RBELinkedHashMapNode *_next;
}

@end

@implementation RBELinkedHashMapNode
@end

@interface RBELinkedHashMap : NSObject

- (id)findObjctForKey:(id)key;

- (void)insertObject:(id)obj forKey:(id)key;

- (void)eraseLastObject;

- (void)eraseObjectForKey:(id)key;

- (void)eraseAll;

- (NSUInteger)currentTotalUsage;

@end

@implementation RBELinkedHashMap {
    @package
    CFMutableDictionaryRef _hashMap;
    NSUInteger _totalUsage;
    RBELinkedHashMapNode *_head;
    RBELinkedHashMapNode *_tail;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _hashMap = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    }
    return self;
}

- (void)dealloc {
    CFRelease(_hashMap);
    _hashMap = nil;
}

- (id)findObjctForKey:(id)key {
    id obj = nil;
    RBELinkedHashMapNode *node = CFDictionaryGetValue(_hashMap, (__bridge const void *)key);
    if (node) {
        [self detach:node];
        [self attachToHead:node];
        obj = node->_value;
    }
    
    return obj;
}

- (void)insertObject:(id)obj forKey:(id)key {
    RBELinkedHashMapNode *node = CFDictionaryGetValue(_hashMap, (__bridge const void *)key);
    if (node) {
        node->_value = obj;
        [self detach:node];
        [self attachToHead:node];
        return;
    }
    
    RBELinkedHashMapNode *newNode = [RBELinkedHashMapNode new];
    newNode->_key = key;
    newNode->_value = obj;
    
    [self attachToHead:newNode];
    CFDictionarySetValue(_hashMap, (__bridge const void *)key, (__bridge const void *)newNode);
    _totalUsage ++;
}

- (void)eraseLastObject {
    if (!_head) {
        return;
    }
    
    RBELinkedHashMapNode *deleteNode = _tail;
    if (_head == deleteNode) {
        _head = nil;
        _tail = nil;
    }
    
    [self detach:deleteNode];
    CFDictionaryRemoveValue(_hashMap, (__bridge const void *)deleteNode->_key);
    _totalUsage --;
}

- (void)eraseObjectForKey:(id)key {
    if (!_head) {
        return;
    }
    
    RBELinkedHashMapNode *deleteNode = CFDictionaryGetValue(_hashMap, (__bridge const void *)key);
    if (deleteNode) {
        if (_head == _tail) {
            _head = nil;
            _tail = nil;
        }
        
        if (deleteNode == _head) {
            _head = _head->_next;
            _head->_prev = nil;
            deleteNode->_next = nil;
        }
        
        [self detach:deleteNode];
        CFDictionaryRemoveValue(_hashMap, (__bridge const void *)key);
        _totalUsage --;
    }
}

- (void)eraseAll {
    _totalUsage = 0;
    if (CFDictionaryGetCount(_hashMap) > 0) {
        CFDictionaryRemoveAllValues(_hashMap);
    }
}

- (void)detach:(RBELinkedHashMapNode *)node {
    if (_head == _tail || _head == node) {
        return;
    } else if (node == _tail) {
        _tail = _tail->_prev;
        _tail->_next = nil;
        node->_prev = nil;
    } else {
        node->_prev->_next = node->_next;
        node->_next->_prev = node->_prev;
    }
}

- (void)attachToHead:(RBELinkedHashMapNode *)node {
    if (_head == nil) {
        _head = node;
        _tail = node;
    } else if (_head == node) {
        return;
    } else{
        _head->_prev = node;
        node->_next = _head;
        _head = node;
    }
}

- (NSUInteger)currentTotalUsage {
    return _totalUsage;
}

@end


static NSUInteger kRBEMemoryCacheDefaultCapacity = 10;

@implementation RBEMemoryCache {
    pthread_mutex_t _mutexLock;
    dispatch_queue_t _queue;
    NSUInteger _memoryCapacity;
    RBELinkedHashMap *_linkedHashMap;
}

- (instancetype)init {
    return [self initWithMemoryCapacity:kRBEMemoryCacheDefaultCapacity];
}

- (instancetype)initWithMemoryCapacity:(NSUInteger)memoryCapacity {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAllObjects) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        _linkedHashMap = [RBELinkedHashMap new];
        _memoryCapacity = memoryCapacity;
        pthread_mutex_init(&_mutexLock, NULL);
        _queue = dispatch_queue_create("com.rbe.memory.cache", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)trimToCapacity:(NSUInteger)capacity {
    dispatch_async(_queue, ^{
        [self mutexLock];
        while ([_linkedHashMap currentTotalUsage] > capacity) {
            [_linkedHashMap eraseLastObject];
        }
        [self mutexUnLock];
    });
}

- (void)setObject:(id)object forKeyedSubscript:(id)key {
    [self mutexLock];
    [_linkedHashMap insertObject:object forKey:key];
    [self mutexUnLock];
    
    [self trimToCapacity:_memoryCapacity];
}

- (id)objectForKeyedSubscript:(id)key {
    [self mutexLock];
    id object = [_linkedHashMap findObjctForKey:key];
    [self mutexUnLock];
    
    return object;
}

- (void)removeObjectWithKey:(id)key {
    [self mutexLock];
    [_linkedHashMap eraseObjectForKey:key];
    [self mutexUnLock];
}

- (void)removeAllObjects {
    [self mutexLock];
    [_linkedHashMap eraseAll];
    [self mutexUnLock];
}

- (void)mutexLock {
    pthread_mutex_lock(&_mutexLock);
}

- (void)mutexUnLock {
    pthread_mutex_unlock(&_mutexLock);
}

@end
