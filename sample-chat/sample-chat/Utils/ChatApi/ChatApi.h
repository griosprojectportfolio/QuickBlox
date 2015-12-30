//
//  ShadowApi.h
//  ShadowPro
//
//  Created by GrepRuby on 25/08/15.
//  Copyright (c) 2015 GrepRuby. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AFNetworking.h"
#import "Reachability.h"

@interface ChatApi : AFHTTPSessionManager

+ (ChatApi *)sharedClient;

- (NSURLSessionTask *)callPostUrl:(NSDictionary *)aParams method:(NSString *)method
                                success:(void (^)(NSURLSessionTask *task, id responseObject))successBlock
                                failure:(void (^)(NSURLSessionTask *task, NSError *error))failureBlock;

- (NSURLSessionTask *)callGetUrl:(NSDictionary *)aParams method:(NSString *)method
                               success:(void (^)(NSURLSessionTask *task, id responseObject))successBlock
                               failure:(void (^)(NSURLSessionTask *task, NSError *error))failureBlock;

- (NSURLSessionTask *)callDeleteUrl:(NSDictionary *)aParams method:(NSString *)method
                                  success:(void (^)(NSURLSessionTask *task, id responseObject))successBlock
                                  failure:(void (^)(NSURLSessionTask *task, NSError *error))failureBlock;

- (NSURLSessionTask *)callPutUrl:(NSDictionary *)aParams method:(NSString *)method
                               success:(void (^)(NSURLSessionTask *task, id responseObject))successBlock
                               failure:(void (^)(NSURLSessionTask *task, NSError *error))failureBlock;

- (NSURLSessionTask *)callPostUrlWithHeader:(NSDictionary *)aParams method:(NSString *)method
                                          success:(void (^)(NSURLSessionTask *task, id responseObject))successBlock
                                          failure:(void (^)(NSURLSessionTask *task, NSError *error))failureBlock;

- (NSURLSessionTask *)callGetUrlWithHeader:(NSDictionary *)aParams method:(NSString *)method
                                         success:(void (^)(NSURLSessionTask *task, id responseObject))successBlock
                                         failure:(void (^)(NSURLSessionTask *task, NSError *error))failureBlock;
@end
