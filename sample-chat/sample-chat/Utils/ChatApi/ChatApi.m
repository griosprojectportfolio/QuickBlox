//
//  ShadowApi.m
//  CallUpp
//
//  Created by GrepRuby on 25/08/15.
//  Copyright (c) 2015 GrepRuby. All rights reserved.
//

#import "ChatApi.h"

static NSString *kAppAPIBaseURLString = @"http://callshadow.herokuapp.com/api/v1/";

@implementation ChatApi

/* API Clients */
+ (ChatApi *)sharedClient {

    static ChatApi * _sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[ChatApi alloc] initWithBaseURL:[NSURL URLWithString:kAppAPIBaseURLString]];
    });
    return [ChatApi manager];
}
+ (ChatApi *)sharedAuthorizedClient{
    return nil;
}

#pragma mark - baseRequestWithHTTPMethod

- (NSURLSessionTask *)baseRequestWithHTTPMethod:(NSString *)method
                                            URLString:(NSString *)URLString
                                           parameters:(id)parameters
                                              success:(void (^)(NSURLSessionTask *operation, id responseObject))successBlock
                                              failure:(void (^)(NSURLSessionTask *operation, NSError *error))failureBlock{

    if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) {

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                        message:@"Please check your netconection."
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                              otherButtonTitles:nil];
        [alert show];
        return false;
    }else{

        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        void (^baseSuccessBlock)(NSURLSessionTask *operation, id responseObject) = ^(NSURLSessionTask *task, id responseObject) {
            NSLog(@"%@",responseObject);
            successBlock(task,responseObject);
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        };
        void (^baseFailureBlock)(NSURLSessionTask *operation, NSError *error) = ^(NSURLSessionTask *task, NSError *error) {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            NSLog(@"%@",error);
            failureBlock(task,error);
        };
            //AFHTTPSessionManager *requestOperation = [AFHTTPSessionManager manager];
        NSURLSessionTask *requestOperation;

        NSString *url = [NSString stringWithFormat:@"%@/%@",kAppAPIBaseURLString,URLString];
        if([method isEqualToString:@"GET"]){
            requestOperation = [[AFHTTPSessionManager manager] GET:url parameters:parameters progress:nil success:baseSuccessBlock failure:baseFailureBlock]; //GET:url parameters:parameters success:baseSuccessBlock failure:baseFailureBlock];
        }else if ([method isEqualToString:@"POST"]){
            requestOperation = [self POST:url parameters:parameters progress:nil success:baseSuccessBlock failure:baseFailureBlock];
        }else if ([method isEqualToString:@"PATCH"]){
            requestOperation = [self PATCH:url parameters:parameters success:baseSuccessBlock failure:baseFailureBlock];
        }else if ([method isEqualToString:@"DELETE"]){
            requestOperation = [self DELETE:url parameters:parameters success:baseSuccessBlock failure:baseFailureBlock];
        }else if ([method isEqualToString:@"PUT"]){
            requestOperation = [self PUT:url parameters:parameters success:baseSuccessBlock failure:baseFailureBlock];
        }else {
            requestOperation = nil;
        }
        return requestOperation;
    }
}

/**
 Post multipart data
 **/
- (NSURLSessionTask *)postWithMultipartData:(NSDictionary *)aParams method:(NSString *)method multiPartData:(NSArray*)arrayData
                                          success:(void (^)(NSURLSessionDataTask *task, id responseObject))successBlock
                                          failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failureBlock {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer.timeoutInterval = 210;

    return [manager POST:method parameters:aParams constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        NSLog(@"%@ %@",method, aParams);

        for (NSDictionary *dictData in arrayData) {

            NSString *strUrl = [dictData valueForKey:@"path"];
            NSData *data = [NSData dataWithContentsOfFile:strUrl];
            NSString *key = [dictData valueForKey:@"key"];
            NSString *filaname = [dictData valueForKey:@"filaname"];

            if(filaname.length == 0) {
            } else {
                NSString *type = [filaname substringFromIndex:filaname.length - 3];
                NSString *mimeType = [NSString stringWithFormat:@"audio/%@", type];
                [formData appendPartWithFileData:data
                                            name:key
                                        fileName:filaname mimeType:mimeType];
            }
        }
    }  progress:nil success:^(NSURLSessionDataTask *operation, id responseObject) {
        NSLog(@"Response: %@", responseObject);
        successBlock(operation, responseObject);
    } failure:^(NSURLSessionDataTask *operation, NSError *error) {
        NSLog(@"Error: %@ ******** %@", error, operation.response);
        failureBlock(operation, error);
    }];
}

/**
 Call post
 **/
- (NSURLSessionTask *)callPostUrl:(NSDictionary *)aParams method:(NSString *)method
                                success:(void (^)(NSURLSessionTask *task, id responseObject))successBlock
                                failure:(void (^)(NSURLSessionTask *task, NSError *error))failureBlock {

    NSString *url = [NSString stringWithFormat:@"%@", method];
    return [self baseRequestWithHTTPMethod:@"POST" URLString:url parameters:aParams success:^(NSURLSessionTask *operation, id responseObject) {
        if(successBlock){
            @try {
                NSLog(@"Create Session");
                successBlock(operation, responseObject);
            }
            @catch (NSException *exception) {
                [self processExceptionBlock:operation blockException:exception];
            }
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        if(failureBlock){
            NSLog(@"%@", operation);
            [self processFailureBlock:operation blockError:error];
            failureBlock(operation, error);
        }
    }];
}

/**
 Call post with header
 **/
- (NSURLSessionTask *)callPostUrlWithHeader:(NSDictionary *)aParams method:(NSString *)method
                                          success:(void (^)(NSURLSessionTask *task, id responseObject))successBlock
                                          failure:(void (^)(NSURLSessionTask *task, NSError *error))failureBlock {

    NSString *url = [NSString stringWithFormat:@"%@", method];
    [self.requestSerializer setValue:[[NSUserDefaults standardUserDefaults] valueForKey:@""] forHTTPHeaderField:@""];
    return [self baseRequestWithHTTPMethod:@"POST" URLString:url parameters:aParams success:^(NSURLSessionTask *operation, id responseObject) {
        if(successBlock){
            @try {
                NSLog(@"Create Session");
                successBlock(operation, responseObject);
            }
            @catch (NSException *exception) {
                [self processExceptionBlock:operation blockException:exception];
            }
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        if(failureBlock){
            NSLog(@"%@", operation);
            [self processFailureBlock:operation blockError:error];
            failureBlock(operation, error);
        }
    }];
}

/**
 Call get with header
 **/
- (NSURLSessionTask *)callGetUrlWithHeader:(NSDictionary *)aParams method:(NSString *)method
                                          success:(void (^)(NSURLSessionTask *task, id responseObject))successBlock
                                          failure:(void (^)(NSURLSessionTask *task, NSError *error))failureBlock {

    NSString *url = [NSString stringWithFormat:@"%@", method];
    [self.requestSerializer setValue:[[NSUserDefaults standardUserDefaults] valueForKey:@""] forHTTPHeaderField:@""];
    return [self baseRequestWithHTTPMethod:@"GET" URLString:url parameters:aParams success:^(NSURLSessionTask *operation, id responseObject) {
        if(successBlock){
            @try {
                NSLog(@"Create Session");
                successBlock(operation, responseObject);
            }
            @catch (NSException *exception) {
                [self processExceptionBlock:operation blockException:exception];
            }
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        if(failureBlock){
            NSLog(@"%@", operation.response);
            [self processFailureBlock:operation blockError:error];
            failureBlock(operation, error);
        }
    }];
}

/**
 Call multipart post
 **/
- (NSURLSessionTask *)callMultipartPostUrl:(NSDictionary *)aParams method:(NSString *)method  multipartArry:(NSArray*)arrayMultiPart
                                         success:(void (^)(NSURLSessionTask *task, id responseObject))successBlock
                                         failure:(void (^)(NSURLSessionTask *task, NSError *error))failureBlock {

    NSString *url = [NSString stringWithFormat:@"%@%@",kAppAPIBaseURLString, method];
    return [self baseRequestWithHTTPMethod:@"POSTMULTIPART" URLString:url parameters:aParams success:^(NSURLSessionTask *operation, id responseObject) {
        if(successBlock){
            @try {
                NSLog(@"Create Session");
                successBlock(operation, responseObject);
            }
            @catch (NSException *exception) {
                [self processExceptionBlock:operation blockException:exception];
            }
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        if(failureBlock){
            NSLog(@"%@", operation);
            [self processFailureBlock:operation blockError:error];
            failureBlock(operation, error);
        }
    }];
}

/**
 Call get
 **/
- (NSURLSessionTask *)callGetUrl:(NSDictionary *)aParams method:(NSString *)method
                               success:(void (^)(NSURLSessionTask *task, id responseObject))successBlock
                               failure:(void (^)(NSURLSessionTask *task, NSError *error))failureBlock {

    NSString *url = [NSString stringWithFormat:@"%@", method];
    return [self baseRequestWithHTTPMethod:@"GET" URLString:url parameters:aParams success:^(NSURLSessionTask *operation, id responseObject) {
        if(successBlock){
            @try {
                NSLog(@"Create Session");
                successBlock(operation, responseObject);
            }
            @catch (NSException *exception) {
                [self processExceptionBlock:operation blockException:exception];
            }
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        if(failureBlock){
            [self processFailureBlock:operation blockError:error];
            failureBlock(operation, error);
        }
    }];
}

/**
 Call delete
 **/
- (NSURLSessionTask *)callDeleteUrl:(NSDictionary *)aParams method:(NSString *)method
                                  success:(void (^)(NSURLSessionTask *task, id responseObject))successBlock
                                  failure:(void (^)(NSURLSessionTask *task, NSError *error))failureBlock {

    NSString *url = [NSString stringWithFormat:@"%@", method];
    [self.requestSerializer setValue:[[NSUserDefaults standardUserDefaults] valueForKey:@""] forHTTPHeaderField:@""];
    return [self baseRequestWithHTTPMethod:@"DELETE" URLString:url parameters:aParams success:^(NSURLSessionTask *operation, id responseObject) {
        if(successBlock){
            @try {
                NSLog(@"Create Session");
                successBlock(operation, responseObject);
            }
            @catch (NSException *exception) {
                [self processExceptionBlock:operation blockException:exception];
            }
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        if(failureBlock){
            [self processFailureBlock:operation blockError:error];
            failureBlock(operation, error);
        }
    }];
}

/**
 Call put
 **/
- (NSURLSessionTask *)callPutUrl:(NSDictionary *)aParams method:(NSString *)method
                               success:(void (^)(NSURLSessionTask *task, id responseObject))successBlock
                               failure:(void (^)(NSURLSessionTask *task, NSError *error))failureBlock {

    NSString *url = [NSString stringWithFormat:@"%@", method];
    [self.requestSerializer setValue:[[NSUserDefaults standardUserDefaults] valueForKey:@""] forHTTPHeaderField:@""];
    return [self baseRequestWithHTTPMethod:@"PUT" URLString:url parameters:aParams success:^(NSURLSessionTask *operation, id responseObject) {
        if(successBlock){
            @try {
                NSLog(@"Create Session");
                successBlock(operation, responseObject);
            }
            @catch (NSException *exception) {
                [self processExceptionBlock:operation blockException:exception];
            }
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        if(failureBlock){
            [self processFailureBlock:operation blockError:error];
            failureBlock(operation, error);
        }
    }];
}

#pragma mark- Process Exception and Failure Block

- (void)processExceptionBlock:(NSURLSessionTask*)task blockException:(NSException*) exception{
    NSLog(@"Exception : %@",((NSException*)exception));
}

- (NSError *)processFailureBlock:(NSURLSessionTask*) task blockError:(NSError*) error{
    NSLog(@"Error :%@",error);
    return nil;
}

@end
