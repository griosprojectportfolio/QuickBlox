//
//  QMChatService.m
//  QMServices
//
//  Created by Andrey Ivanov on 02.07.14.
//  Copyright (c) 2015 Quickblox. All rights reserved.
//

#import "QMChatService.h"
#import "QBChatMessage+TextEncoding.h"
#import "NSString+GTMNSStringHTMLAdditions.h"
#import "QBChatMessage+QMCustomParameters.h"

const char *kChatCacheQueue = "com.q-municate.chatCacheQueue";

#define kChatServiceSaveToHistoryTrue @"1"
#define kQMLoadedAllMessages          @1

@interface QMChatService() <QBChatDelegate>

@property (strong, nonatomic) QBMulticastDelegate <QMChatServiceDelegate, QMChatConnectionDelegate> *multicastDelegate;
@property (weak, nonatomic) id <QMChatServiceCacheDataSource> cacheDataSource;
@property (strong, nonatomic) QMDialogsMemoryStorage *dialogsMemoryStorage;
@property (strong, nonatomic) QMMessagesMemoryStorage *messagesMemoryStorage;
@property (strong, nonatomic) QMChatAttachmentService *chatAttachmentService;
@property (strong, nonatomic, readonly) NSNumber *dateSendTimeInterval;

@property (strong, nonatomic) NSTimer *presenceTimer;

@property (weak, nonatomic)   BFTask* loadEarlierMessagesTask;
@property (strong, nonatomic) NSMutableDictionary *loadedAllMessages;

@end

@implementation QMChatService

@dynamic dateSendTimeInterval;

- (void)dealloc {
	
	NSLog(@"%@ - %@",  NSStringFromSelector(_cmd), self);
	
	[self.presenceTimer invalidate];
	[QBChat.instance removeDelegate:self];
}

#pragma mark - Configure

- (instancetype)initWithServiceManager:(id<QMServiceManagerProtocol>)serviceManager cacheDataSource:(id<QMChatServiceCacheDataSource>)cacheDataSource {
	
	self = [super initWithServiceManager:serviceManager];
	
	if (self) {
		
		self.cacheDataSource = cacheDataSource;
		
		self.presenceTimerInterval = 45.0;
		self.automaticallySendPresences = YES;
        
        self.loadedAllMessages = [NSMutableDictionary dictionary];
        
        if ([QBSession currentSession].currentUser != nil) [self loadCachedDialogsWithCompletion:nil];
    }
	
	return self;
}

- (void)serviceWillStart {
	
	self.multicastDelegate = (id<QMChatServiceDelegate, QMChatConnectionDelegate>)[[QBMulticastDelegate alloc] init];
	self.dialogsMemoryStorage = [[QMDialogsMemoryStorage alloc] init];
	self.messagesMemoryStorage = [[QMMessagesMemoryStorage alloc] init];
    self.chatAttachmentService = [[QMChatAttachmentService alloc] init];
	
	[QBChat.instance addDelegate:self];
}

#pragma mark - Load cached data

- (void)loadCachedDialogsWithCompletion:(void(^)())completion
{
    __weak __typeof(self)weakSelf = self;
	
	if ([self.cacheDataSource respondsToSelector:@selector(cachedDialogs:)]) {
        
        NSAssert([QBSession currentSession].currentUser != nil, @"Current user must be non nil!");
		
		[weakSelf.cacheDataSource cachedDialogs:^(NSArray *collection) {
			// We need only current users dialog
            NSArray* userDialogs = [collection filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%lu IN self.occupantIDs", [QBSession currentSession].currentUser.ID]];
            
			[weakSelf.dialogsMemoryStorage addChatDialogs:userDialogs andJoin:NO];
			
			if ([weakSelf.multicastDelegate respondsToSelector:@selector(chatService:didAddChatDialogsToMemoryStorage:)]) {
				[weakSelf.multicastDelegate chatService:weakSelf didAddChatDialogsToMemoryStorage:collection];
			}
            
            NSMutableSet *dialogsUsersIDs = [NSMutableSet set];
            for (QBChatDialog *dialog in userDialogs) {
                [dialogsUsersIDs addObjectsFromArray:dialog.occupantIDs];
            }
            if ([weakSelf.multicastDelegate respondsToSelector:@selector(chatService:didLoadChatDialogsFromCache:withUsers:)]) {
                [weakSelf.multicastDelegate chatService:weakSelf didLoadChatDialogsFromCache:userDialogs withUsers:dialogsUsersIDs.copy];
            }
            
            if (completion) {
                completion();
            }
		}];
	}
}

- (void)loadCachedMessagesWithDialogID:(NSString *)dialogID compleion:(void(^)())completion {
	
	if ([self.cacheDataSource respondsToSelector:@selector(cachedMessagesWithDialogID:block:)]) {
		
		__weak __typeof(self)weakSelf = self;
		[self.cacheDataSource cachedMessagesWithDialogID:dialogID block:^(NSArray *collection) {
			
			if (collection.count > 0) {
				
				[weakSelf.messagesMemoryStorage addMessages:collection forDialogID:dialogID];
				
				if ([weakSelf.multicastDelegate respondsToSelector:@selector(chatService:didAddMessagesToMemoryStorage:forDialogID:)]) {
					[weakSelf.multicastDelegate chatService:weakSelf didAddMessagesToMemoryStorage:collection forDialogID:dialogID];
				}
			}
            
            if (completion) {
                completion();
            }
		}];
	}
}

#pragma mark - Add / Remove Multicast delegate

- (void)addDelegate:(id<QMChatServiceDelegate, QMChatConnectionDelegate>)delegate {
	
	[self.multicastDelegate addDelegate:delegate];
}

- (void)removeDelegate:(id<QMChatServiceDelegate, QMChatConnectionDelegate>)delegate{
	
	[self.multicastDelegate removeDelegate:delegate];
}

#pragma mark - QBChatDelegate

- (void)chatDidLogin {
	
	if (self.automaticallySendPresences){
		[self startSendPresence];
	}
    
    [QBChat.instance setCarbonsEnabled:YES];
    
    if ([self.multicastDelegate respondsToSelector:@selector(chatServiceChatDidLogin)]) {
        [self.multicastDelegate chatServiceChatDidLogin];
    }
}

- (void)chatDidNotLoginWithError:(NSError *)error {
    if ([self.multicastDelegate respondsToSelector:@selector(chatServiceChatDidNotLoginWithError:)]) {
        [self.multicastDelegate chatServiceChatDidNotLoginWithError:error];
    }
}

- (void)chatDidFailWithStreamError:(NSError *)error {
	
	[self stopSendPresence];
    
    if ([self.multicastDelegate respondsToSelector:@selector(chatServiceChatDidFailWithStreamError:)]) {
        [self.multicastDelegate chatServiceChatDidFailWithStreamError:error];
    }
}

- (void)chatDidConnect
{
    if ([self.multicastDelegate respondsToSelector:@selector(chatServiceChatDidConnect:)]) {
        [self.multicastDelegate chatServiceChatDidConnect:self];
    }
}

- (void)chatDidAccidentallyDisconnect
{
    if ([self.multicastDelegate respondsToSelector:@selector(chatServiceChatDidAccidentallyDisconnect:)]) {
        [self.multicastDelegate chatServiceChatDidAccidentallyDisconnect:self];
    }
}

- (void)chatDidReconnect
{
    if ([self.multicastDelegate respondsToSelector:@selector(chatServiceChatDidReconnect:)]) {
        [self.multicastDelegate chatServiceChatDidReconnect:self];
    }
}

#pragma mark Handle messages (QBChatDelegate)

- (void)chatRoomDidReceiveMessage:(QBChatMessage *)message fromDialogID:(NSString *)dialogID
{
    [self handleChatMessage:message];
}

- (void)chatDidReceiveMessage:(QBChatMessage *)message
{
	[self handleChatMessage:message];
}

- (void)chatDidReceiveSystemMessage:(QBChatMessage *)message
{
    [self handleSystemMessage:message];
}

- (void)chatDidReadMessageWithID:(NSString *)messageID dialogID:(NSString *)dialogID readerID:(NSUInteger)readerID
{
    NSParameterAssert(dialogID != nil);
    NSParameterAssert(messageID != nil);
    
    QBChatMessage* message = [self.messagesMemoryStorage messageWithID:messageID fromDialogID:dialogID];
    
    if (message != nil) {
        if (message.readIDs == nil) {
            message.readIDs = [NSArray array];
        }
        
        if (![message.readIDs containsObject:@(readerID)]) {
            message.readIDs = [message.readIDs arrayByAddingObject:@(readerID)];
            
            [self.messagesMemoryStorage updateMessage:message];
            
            if ([self.multicastDelegate respondsToSelector:@selector(chatService:didUpdateMessage:forDialogID:)]) {
                [self.multicastDelegate chatService:self didUpdateMessage:message forDialogID:dialogID];
            }            
        }
    }
}

- (void)chatDidDeliverMessageWithID:(NSString *)messageID dialogID:(NSString *)dialogID toUserID:(NSUInteger)userID
{
    NSParameterAssert(dialogID != nil);
    NSParameterAssert(messageID != nil);

    QBChatMessage* message = [self.messagesMemoryStorage messageWithID:messageID fromDialogID:dialogID];
    
    if (message != nil) {
        if (message.deliveredIDs == nil) {
            message.deliveredIDs = [NSArray array];
        }
        
        if (![message.deliveredIDs containsObject:@(userID)]) {
            message.deliveredIDs = [message.deliveredIDs arrayByAddingObject:@(userID)];
            
            [self.messagesMemoryStorage updateMessage:message];
            
            if ([self.multicastDelegate respondsToSelector:@selector(chatService:didUpdateMessage:forDialogID:)]) {
                [self.multicastDelegate chatService:self didUpdateMessage:message forDialogID:dialogID];
            }
        }
    }
}

#pragma mark - Chat Login/Logout

- (void)connectWithCompletionBlock:(QBChatCompletionBlock)completion {
    
    BOOL isAuthorized = self.serviceManager.isAuthorized;
    NSAssert(isAuthorized, @"User must be authorized");
    
    QBUUser *user = self.serviceManager.currentUser;
    NSAssert(user != nil, @"User must be already allocated!");
    
    if ([QBChat instance].isConnected) {
        if(completion){
            completion(nil);
        }
    }
    else {
        [QBSettings setAutoReconnectEnabled:YES];
        [[QBChat instance] connectWithUser:user completion:completion];
    }
}

- (void)disconnectWithCompletionBlock:(QBChatCompletionBlock)completion {
    
    [self stopSendPresence];
    [[QBChat instance] disconnectWithCompletionBlock:completion];
}

#pragma mark - Presence

- (void)startSendPresence {
	
	[self sendPresence:nil];
	
	self.presenceTimer =
	[NSTimer scheduledTimerWithTimeInterval:self.presenceTimerInterval
									 target:self
								   selector:@selector(sendPresence:)
								   userInfo:nil
									repeats:YES];
}

- (void)sendPresence:(NSTimer *)timer {
	
	[QBChat.instance sendPresence];
}

- (void)stopSendPresence {
	
	[self.presenceTimer invalidate];
	self.presenceTimer = nil;
}

#pragma mark - Handle Chat messages

- (void)handleSystemMessage:(QBChatMessage *)message {
    
    if (message.messageType == QMMessageTypeCreateGroupDialog) {
        __weak __typeof(self)weakSelf = self;
        
        [self messagesWithChatDialogID:message.dialogID completion:^(QBResponse *response, NSArray *messages) {
            //
            __typeof(weakSelf)strongSelf = weakSelf;
            QBChatDialog *dialogToAdd = message.dialog;
            
            if (messages.count > 0) {
                QBChatMessage *lastMessage = [messages lastObject];
                dialogToAdd.lastMessageText = [lastMessage encodedText];
                dialogToAdd.lastMessageDate = lastMessage.dateSent;
                dialogToAdd.updatedAt       = lastMessage.dateSent;
                dialogToAdd.unreadMessagesCount++;
            }
            
            [strongSelf.dialogsMemoryStorage addChatDialog:dialogToAdd andJoin:YES completion:^(QBChatDialog *addedDialog, NSError *error) {
                //
                if ([strongSelf.multicastDelegate respondsToSelector:@selector(chatService:didAddChatDialogToMemoryStorage:)]) {
                    [strongSelf.multicastDelegate chatService:strongSelf didAddChatDialogToMemoryStorage:addedDialog];
                }
                // calling multicast delegate to show notification
                if (messages.count > 0) {
                    if ([strongSelf.multicastDelegate respondsToSelector:@selector(chatService:didAddMessageToMemoryStorage:forDialogID:)]) {
                        [strongSelf.multicastDelegate chatService:strongSelf didAddMessageToMemoryStorage:messages.lastObject forDialogID:addedDialog.ID];
                    }
                }
            }];
        }];
    }
}

- (void)handleChatMessage:(QBChatMessage *)message {
	
    if (!message.dialogID) {
        
        NSLog(@"Need update this case");
        
        return;
    }
    
    QBChatDialog *chatDialogToUpdate = [self.dialogsMemoryStorage chatDialogWithID:message.dialogID];
	
	if (message.messageType == QMMessageTypeText) {
        BOOL shouldSaveDialog = NO;
        
		//Update chat dialog in memory storage
        if (!chatDialogToUpdate)
        {
            chatDialogToUpdate = [[QBChatDialog alloc] initWithDialogID:message.dialogID type:QBChatDialogTypePrivate];
            chatDialogToUpdate.occupantIDs = @[@([self.serviceManager currentUser].ID), @(message.senderID)];
            
            shouldSaveDialog = YES;
        }
        
		chatDialogToUpdate.lastMessageText = message.encodedText;
		chatDialogToUpdate.lastMessageDate = message.dateSent;
        chatDialogToUpdate.updatedAt = message.dateSent;
        
        if (message.senderID != [QBSession currentSession].currentUser.ID) {
            chatDialogToUpdate.unreadMessagesCount++;
        }
        
        if (shouldSaveDialog) {
            [self.dialogsMemoryStorage addChatDialog:chatDialogToUpdate andJoin:NO completion:nil];
            
            if ([self.multicastDelegate respondsToSelector:@selector(chatService:didAddChatDialogToMemoryStorage:)]) {
                [self.multicastDelegate chatService:self didAddChatDialogToMemoryStorage:chatDialogToUpdate];
            }
        }
        else {
            if ([self.multicastDelegate respondsToSelector:@selector(chatService:didUpdateChatDialogInMemoryStorage:)]) {
                [self.multicastDelegate chatService:self didUpdateChatDialogInMemoryStorage:chatDialogToUpdate];
            }
        }
	}
	else if (message.messageType == QMMessageTypeUpdateGroupDialog) {

        if (chatDialogToUpdate) {
            
            // old custom parameters handling
            if (message.dialog != nil) {
                
                if ([chatDialogToUpdate.updatedAt compare:message.dialog.updatedAt] == NSOrderedAscending) {
                    
                    if (message.dialog.name != nil) {
                        chatDialogToUpdate.name = message.dialog.name;
                    }
                    if (message.dialog.photo != nil) {
                        chatDialogToUpdate.photo = message.dialog.photo;
                    }
                    if ([message.dialog.occupantIDs count] > 0) {
                        chatDialogToUpdate.occupantIDs = message.dialog.occupantIDs;
                    }
                }
            }
            
            // new custom parameters handling
            if (message.dialogUpdatedAt != nil && [chatDialogToUpdate.updatedAt compare:message.dialogUpdatedAt] == NSOrderedAscending) {
                
                switch (message.dialogUpdateType) {
                    case QMDialogUpdateTypeName:
                        chatDialogToUpdate.name = message.dialogName;
                        break;
                        
                    case QMDialogUpdateTypePhoto:
                        chatDialogToUpdate.photo = message.dialogPhoto;
                        break;
                        
                    case QMDialogUpdateTypeOccupants:
                        chatDialogToUpdate.occupantIDs = message.currentOccupantsIDs;
                        break;
                        
                    default:
                        break;
                }
                
                chatDialogToUpdate.updatedAt = message.dialogUpdatedAt;
            }
            
            chatDialogToUpdate.lastMessageText = message.encodedText;
            
            if (message.senderID != [QBSession currentSession].currentUser.ID) {
                chatDialogToUpdate.unreadMessagesCount++;
            }
            
            if ([self.multicastDelegate respondsToSelector:@selector(chatService:didUpdateChatDialogInMemoryStorage:)]) {
                [self.multicastDelegate chatService:self didUpdateChatDialogInMemoryStorage:chatDialogToUpdate];
            }
        }
	}
    else if (message.messageType == QMMessageTypeContactRequest || message.messageType == QMMessageTypeAcceptContactRequest || message.messageType == QMMessageTypeRejectContactRequest || message.messageType == QMMessageTypeDeleteContactRequest) {

        if (chatDialogToUpdate != nil) {
            chatDialogToUpdate.lastMessageText = message.encodedText;
            chatDialogToUpdate.lastMessageDate = message.dateSent;
            chatDialogToUpdate.updatedAt = message.dateSent;
            chatDialogToUpdate.unreadMessagesCount++;
            
            if ([self.multicastDelegate respondsToSelector:@selector(chatService:didUpdateChatDialogInMemoryStorage:)]) {
                [self.multicastDelegate chatService:self didUpdateChatDialogInMemoryStorage:chatDialogToUpdate];
            }
        }
        else {
            chatDialogToUpdate = [[QBChatDialog alloc] initWithDialogID:message.dialogID type:QBChatDialogTypePrivate];
            chatDialogToUpdate.occupantIDs = @[@([self.serviceManager currentUser].ID), @(message.senderID)];
            chatDialogToUpdate.lastMessageText = message.encodedText;
            chatDialogToUpdate.lastMessageDate = message.dateSent;
            chatDialogToUpdate.updatedAt = message.dateSent;
            chatDialogToUpdate.unreadMessagesCount++;
            
            [self.dialogsMemoryStorage addChatDialog:chatDialogToUpdate andJoin:NO completion:nil];
            
            if ([self.multicastDelegate respondsToSelector:@selector(chatService:didAddChatDialogToMemoryStorage:)]) {
                [self.multicastDelegate chatService:self didAddChatDialogToMemoryStorage:chatDialogToUpdate];
            }
        }
	}
	
	if ([message.saveToHistory isEqualToString:kChatServiceSaveToHistoryTrue]) {
		
		[self.messagesMemoryStorage addMessage:message forDialogID:message.dialogID];
		
		if ([self.multicastDelegate respondsToSelector:@selector(chatService:didAddMessageToMemoryStorage:forDialogID:)]) {
			[self.multicastDelegate chatService:self didAddMessageToMemoryStorage:message forDialogID:message.dialogID];
		}
	}
    
    if (message.isNotificatonMessage && chatDialogToUpdate != nil) {
        if ([self.multicastDelegate respondsToSelector:@selector(chatService:didReceiveNotificationMessage:createDialog:)]) {
            [self.multicastDelegate chatService:self didReceiveNotificationMessage:message createDialog:chatDialogToUpdate];
        }
    }
}

- (void)joinToGroupDialog:(QBChatDialog *)dialog
               failed:(void (^)(NSError *))failed {
    
    NSParameterAssert(dialog.type != QBChatDialogTypePrivate);
    
    if (dialog.isJoined) {
        return;
    }
    
    NSString *dialogID = dialog.ID;
    
    [dialog setOnJoinFailed:^(NSError *error) {
        
        if (error.code == 201 || error.code == 404 || error.code == 407) {
            
            [self.dialogsMemoryStorage deleteChatDialogWithID:dialogID];
            
            if ([self.multicastDelegate respondsToSelector:@selector(chatService:didDeleteChatDialogWithIDFromMemoryStorage:)]) {
                [self.multicastDelegate chatService:self didDeleteChatDialogWithIDFromMemoryStorage:dialogID];
            }
        }
        
        if (failed) {
            failed(error);
        }
        
    }];
    
    [dialog join];
}

- (void)joinToGroupDialog:(QBChatDialog *)dialog completion:(QBChatCompletionBlock)completion {
    
    NSParameterAssert(dialog.type != QBChatDialogTypePrivate);
    
    if (dialog.isJoined) {
        return;
    }
    
    NSString *dialogID = dialog.ID;
    
    [dialog joinWithCompletionBlock:^(NSError *error) {
        //
        if (error != nil) {
            if (error.code == 201 || error.code == 404 || error.code == 407) {
                
                [self.dialogsMemoryStorage deleteChatDialogWithID:dialogID];
                
                if ([self.multicastDelegate respondsToSelector:@selector(chatService:didDeleteChatDialogWithIDFromMemoryStorage:)]) {
                    [self.multicastDelegate chatService:self didDeleteChatDialogWithIDFromMemoryStorage:dialogID];
                }
            }

            if (completion) completion(error);
        }
        else {
            if (completion) completion(nil);
        }
    }];
}


#pragma mark - Dialog history

- (void)allDialogsWithPageLimit:(NSUInteger)limit
				extendedRequest:(NSDictionary *)extendedRequest
				iterationBlock:(void(^)(QBResponse *response, NSArray *dialogObjects, NSSet *dialogsUsersIDs, BOOL *stop))interationBlock
					 completion:(void(^)(QBResponse *response))completion {
	
	__weak __typeof(self)weakSelf = self;
	
	__block QBResponsePage *responsePage = [QBResponsePage responsePageWithLimit:limit];
	__block BOOL cancel = NO;
	
	__block dispatch_block_t t_request;
	
	dispatch_block_t request = [^{
        
        if (![weakSelf.serviceManager isAuthorized]) {
            if (completion) {
                completion(nil);
            }
            return;
        }
        
		[QBRequest dialogsForPage:responsePage extendedRequest:extendedRequest successBlock:^(QBResponse *response, NSArray *dialogObjects, NSSet *dialogsUsersIDs, QBResponsePage *page) {
            
			[weakSelf.dialogsMemoryStorage addChatDialogs:dialogObjects andJoin:YES];
			
			if ([weakSelf.multicastDelegate respondsToSelector:@selector(chatService:didAddChatDialogsToMemoryStorage:)]) {
				[weakSelf.multicastDelegate chatService:weakSelf didAddChatDialogsToMemoryStorage:dialogObjects];
			}
			
			responsePage.skip += dialogObjects.count;
			
			if (page.totalEntries <= responsePage.skip) {
				cancel = YES;
			}
			
			interationBlock(response, dialogObjects, dialogsUsersIDs, &cancel);
            
            if (!cancel) {
				t_request();
			} else {
                if (completion) {
					completion(response);
				}
			}
			
		} errorBlock:^(QBResponse *response) {

			[weakSelf.serviceManager handleErrorResponse:response];
			
			if (completion) {
				completion(response);
			}
		}];
		
	} copy];
	
	t_request = request;
	request();
}

#pragma mark - Create Private/Group dialog

- (void)createPrivateChatDialogWithOpponentID:(NSUInteger)opponentID
                                 completion:(void(^)(QBResponse *response, QBChatDialog *createdDialo))completion {
    
    QBChatDialog *dialog = [self.dialogsMemoryStorage privateChatDialogWithOpponentID:opponentID];
    
    if (!dialog) {
        
        QBChatDialog *chatDialog = [[QBChatDialog alloc] initWithDialogID:nil type:QBChatDialogTypePrivate];
        chatDialog.occupantIDs = @[@(opponentID)];
        
        __weak __typeof(self)weakSelf = self;
        
        [QBRequest createDialog:chatDialog successBlock:^(QBResponse *response, QBChatDialog *createdDialog) {
            
            [weakSelf.dialogsMemoryStorage addChatDialog:createdDialog andJoin:NO completion:nil];
            
            //Notify about create new dialog
            
            if ([weakSelf.multicastDelegate respondsToSelector:@selector(chatService:didAddChatDialogToMemoryStorage:)]) {
                [weakSelf.multicastDelegate chatService:weakSelf didAddChatDialogToMemoryStorage:createdDialog];
            }
            
            if (completion) {
                completion(response, createdDialog);
            }
            
            
        } errorBlock:^(QBResponse *response) {
            
            [weakSelf.serviceManager handleErrorResponse:response];
            
            if (completion) {
                completion(response, nil);
            }
        }];
    }
    else {
        
        if (completion) {
            completion(nil, dialog);
        }
    }
}

- (void)createPrivateChatDialogWithOpponent:(QBUUser *)opponent
								 completion:(void(^)(QBResponse *response, QBChatDialog *createdDialo))completion {
	
    [self createPrivateChatDialogWithOpponentID:opponent.ID completion:completion];
}

- (void)createGroupChatDialogWithName:(NSString *)name photo:(NSString *)photo occupants:(NSArray *)occupants
						   completion:(void(^)(QBResponse *response, QBChatDialog *createdDialog))completion {
	
	NSMutableSet *occupantIDs = [NSMutableSet set];
	
	for (QBUUser *user in occupants) {
		NSAssert([user isKindOfClass:[QBUUser class]], @"occupants must be an array of QBUUser instances");
		[occupantIDs addObject:@(user.ID)];
	}
	
	QBChatDialog *chatDialog = [[QBChatDialog alloc] initWithDialogID:nil type:QBChatDialogTypeGroup];
	chatDialog.name = name;
	chatDialog.photo = photo;
	chatDialog.occupantIDs = occupantIDs.allObjects;
	
	__weak __typeof(self)weakSelf = self;
	[QBRequest createDialog:chatDialog successBlock:^(QBResponse *response, QBChatDialog *createdDialog) {

        [weakSelf.dialogsMemoryStorage addChatDialog:createdDialog andJoin:YES completion:^(QBChatDialog *addedDialog, NSError *error) {
            if ([weakSelf.multicastDelegate respondsToSelector:@selector(chatService:didAddChatDialogToMemoryStorage:)]) {
                [weakSelf.multicastDelegate chatService:weakSelf didAddChatDialogToMemoryStorage:addedDialog];
            }
            
            if (completion) {
                completion(response, addedDialog);
            }
        }];
		
	} errorBlock:^(QBResponse *response) {
		
		[weakSelf.serviceManager handleErrorResponse:response];
		
		if (completion) {
			completion(response, nil);
		}
	}];
}

#pragma mark - Edit dialog methods

- (void)changeDialogName:(NSString *)dialogName forChatDialog:(QBChatDialog *)chatDialog
			  completion:(void(^)(QBResponse *response, QBChatDialog *updatedDialog))completion {
	
	chatDialog.name = dialogName;
	
	__weak __typeof(self)weakSelf = self;
	[QBRequest updateDialog:chatDialog successBlock:^(QBResponse *response, QBChatDialog *updatedDialog) {
        
        [weakSelf.dialogsMemoryStorage addChatDialog:updatedDialog andJoin:YES completion:^(QBChatDialog *addedDialog, NSError *error) {
            if (completion) {
                completion(response, addedDialog);
            }
        }];
		
	} errorBlock:^(QBResponse *response) {
		
		[weakSelf.serviceManager handleErrorResponse:response];
		
		if (completion) {
			completion(response, nil);
		}
	}];
}

- (void)changeDialogAvatar:(NSString *)avatarPublicUrl forChatDialog:(QBChatDialog *)chatDialog completion:(void(^)(QBResponse *response, QBChatDialog *updatedDialog))completion {

    NSAssert(avatarPublicUrl != nil, @"avatarPublicUrl can't be nil");
    NSAssert(chatDialog != nil, @"Dialog can't be nil");
    
    chatDialog.photo = avatarPublicUrl;
    
    __weak __typeof(self)weakSelf = self;
    [QBRequest updateDialog:chatDialog successBlock:^(QBResponse *response, QBChatDialog *dialog) {
        //
        [weakSelf.dialogsMemoryStorage addChatDialog:dialog andJoin:YES completion:^(QBChatDialog *addedDialog, NSError *error) {
            if (completion) completion(response, addedDialog);
        }];
    } errorBlock:^(QBResponse *response) {
        //
        [weakSelf.serviceManager handleErrorResponse:response];
        
        if (completion) completion(response,nil);
    }];
}

- (void)joinOccupantsWithIDs:(NSArray *)ids toChatDialog:(QBChatDialog *)chatDialog
				  completion:(void(^)(QBResponse *response, QBChatDialog *updatedDialog))completion {
	
	__weak __typeof(self)weakSelf = self;
    
    chatDialog.pushOccupantsIDs = ids;
	
	[QBRequest updateDialog:chatDialog successBlock:^(QBResponse *response, QBChatDialog *updatedDialog) {

        [weakSelf.dialogsMemoryStorage addChatDialog:updatedDialog andJoin:YES completion:^(QBChatDialog *addedDialog, NSError *error) {
            if (completion) {
                completion(response, addedDialog);
            }
        }];
		
	} errorBlock:^(QBResponse *response) {
		
		[weakSelf.serviceManager handleErrorResponse:response];
		
		if (completion) {
			completion(response, nil);
		}
	}];
}

- (void)deleteDialogWithID:(NSString *)dialogId completion:(void (^)(QBResponse *))completion {
	
    NSParameterAssert(dialogId);
    
    __weak __typeof(self)weakSelf = self;
    
    [QBRequest deleteDialogsWithIDs:[NSSet setWithObject:dialogId] forAllUsers:NO successBlock:^(QBResponse *response, NSArray *deletedObjectsIDs, NSArray *notFoundObjectsIDs, NSArray *wrongPermissionsObjectsIDs) {
        //
        [weakSelf.dialogsMemoryStorage deleteChatDialogWithID:dialogId];
        [weakSelf.messagesMemoryStorage deleteMessagesWithDialogID:dialogId];
        
        if ([weakSelf.multicastDelegate respondsToSelector:@selector(chatService:didDeleteChatDialogWithIDFromMemoryStorage:)]) {
            [weakSelf.multicastDelegate chatService:weakSelf didDeleteChatDialogWithIDFromMemoryStorage:dialogId];
        }
        
        if (completion) {
            completion(response);
        }
    } errorBlock:^(QBResponse *response) {
        //
        if (response.status == QBResponseStatusCodeNotFound) {
            [weakSelf.dialogsMemoryStorage deleteChatDialogWithID:dialogId];
            
            if ([weakSelf.multicastDelegate respondsToSelector:@selector(chatService:didDeleteChatDialogWithIDFromMemoryStorage:)]) {
                [weakSelf.multicastDelegate chatService:weakSelf didDeleteChatDialogWithIDFromMemoryStorage:dialogId];
            }
        }
        else {
            [weakSelf.serviceManager handleErrorResponse:response];
        }
        
        if (completion) {
            completion(response);
        }
    }];
}

#pragma mark - Messages histroy

- (void)messagesWithChatDialogID:(NSString *)chatDialogID completion:(void(^)(QBResponse *response, NSArray *messages))completion {
	
    dispatch_group_t messagesLoadGroup = dispatch_group_create();
    if ([[self.messagesMemoryStorage messagesWithDialogID:chatDialogID] count] == 0) {
        
        // loading messages from cache
        dispatch_group_enter(messagesLoadGroup);
        [self loadCachedMessagesWithDialogID:chatDialogID compleion:^{
            //
            dispatch_group_leave(messagesLoadGroup);
        }];
    }
    
    @weakify(self);
    dispatch_group_notify(messagesLoadGroup, dispatch_get_main_queue(), ^{
        //
        @strongify(self);
        
        QBResponsePage *page = [QBResponsePage responsePageWithLimit:self.chatMessagesPerPage];
        NSMutableDictionary *parameters = [@{@"sort_desc" : @"date_sent"} mutableCopy];
        QBChatMessage *lastMessage = [self.messagesMemoryStorage lastMessageFromDialogID:chatDialogID];
        if (lastMessage != nil) {
            parameters[@"date_sent[gt]"] = @([lastMessage.dateSent timeIntervalSince1970]);
        }
        
        [QBRequest messagesWithDialogID:chatDialogID
                        extendedRequest:parameters
                                forPage:page
                           successBlock:^(QBResponse *response, NSArray *messages, QBResponsePage *page) {
                               NSArray* sortedMessages = [[messages reverseObjectEnumerator] allObjects];
                               
                               if ([sortedMessages count] > 0) {
                                   
                                   if (lastMessage == nil) {
                                       [self.messagesMemoryStorage replaceMessages:sortedMessages forDialogID:chatDialogID];
                                   } else {
                                       [self.messagesMemoryStorage addMessages:sortedMessages forDialogID:chatDialogID];
                                   }
                                   
                                   if ([self.multicastDelegate respondsToSelector:@selector(chatService:didAddMessagesToMemoryStorage:forDialogID:)]) {
                                       [self.multicastDelegate chatService:self didAddMessagesToMemoryStorage:sortedMessages forDialogID:chatDialogID];
                                   }
                               }
                               
                               if (completion) {
                                   completion(response, sortedMessages);
                               }
                           } errorBlock:^(QBResponse *response) {
                               // case where we may have deleted dialog from another device
                               if( response.status != QBResponseStatusCodeNotFound ) {
                                   [self.serviceManager handleErrorResponse:response];
                               }
                               
                               if (completion) {
                                   completion(response, nil);
                               }
                           }];
    });
}

- (BFTask *)loadEarlierMessagesWithChatDialogID:(NSString *)chatDialogID {
    
    if ([self.loadedAllMessages[chatDialogID] isEqualToNumber: kQMLoadedAllMessages]) return [BFTask taskWithResult:@[]];
    
    if (self.loadEarlierMessagesTask == nil) {
        BFTaskCompletionSource* source = [BFTaskCompletionSource taskCompletionSource];
        
        QBChatMessage *oldestMessage = [self.messagesMemoryStorage oldestMessageForDialogID:chatDialogID];
        
        if (oldestMessage == nil) return [BFTask taskWithResult:@[]];
        
        NSString *oldestMessageDate = [NSString stringWithFormat:@"%ld", (long)[oldestMessage.dateSent timeIntervalSince1970]];
        
        QBResponsePage *page = [QBResponsePage responsePageWithLimit:self.chatMessagesPerPage];
        
        NSMutableDictionary* parameters = [@{
                                             @"date_sent[lt]" : oldestMessageDate,
                                             @"sort_desc"     : @"date_sent"
                                             } mutableCopy];
        
        
        @weakify(self);
        [QBRequest messagesWithDialogID:chatDialogID extendedRequest:parameters forPage:page successBlock:^(QBResponse *response, NSArray *messages, QBResponsePage *page) {
            @strongify(self);
            
            if ([messages count] < self.chatMessagesPerPage) self.loadedAllMessages[chatDialogID] = kQMLoadedAllMessages;
            
            if ([messages count] > 0) {
                
                [self.messagesMemoryStorage addMessages:messages forDialogID:chatDialogID];
                
                if ([self.multicastDelegate respondsToSelector:@selector(chatService:didAddMessagesToMemoryStorage:forDialogID:)]) {
                    [self.multicastDelegate chatService:self didAddMessagesToMemoryStorage:messages forDialogID:chatDialogID];
                }
            }
            
            [source setResult:[[messages reverseObjectEnumerator] allObjects]];
            
        } errorBlock:^(QBResponse *response) {
            @strongify(self);
            
            // case where we may have deleted dialog from another device
            if( response.status != QBResponseStatusCodeNotFound ) {
                [self.serviceManager handleErrorResponse:response];
            }
            
            [source setError:response.error.error];
        }];
        
        self.loadEarlierMessagesTask = source.task;
        return self.loadEarlierMessagesTask;
    }
    
    return [BFTask taskWithResult:@[]];
}

- (void)earlierMessagesWithChatDialogID:(NSString *)chatDialogID completion:(void(^)(QBResponse *response, NSArray *messages))completion {
    
    if ([self.messagesMemoryStorage isEmptyForDialogID:chatDialogID]) {
        
        [self messagesWithChatDialogID:chatDialogID completion:completion];
        
        return;
    }
    
    QBChatMessage *oldestMessage = [self.messagesMemoryStorage oldestMessageForDialogID:chatDialogID];
    NSString *oldestMessageDate = [NSString stringWithFormat:@"%ld", (long)[oldestMessage.dateSent timeIntervalSince1970]];
    QBResponsePage *page = [QBResponsePage responsePageWithLimit:self.chatMessagesPerPage];
    
    __weak __typeof(self) weakSelf = self;
    
    [QBRequest messagesWithDialogID:chatDialogID extendedRequest:@{@"date_sent[lt]": oldestMessageDate, @"sort_desc" : @"date_sent"} forPage:page successBlock:^(QBResponse *response, NSArray *messages, QBResponsePage *page) {
        
        if ([messages count] > 0) {
        
            [weakSelf.messagesMemoryStorage addMessages:messages forDialogID:chatDialogID];
            
            if ([weakSelf.multicastDelegate respondsToSelector:@selector(chatService:didAddMessagesToMemoryStorage:forDialogID:)]) {
                [weakSelf.multicastDelegate chatService:weakSelf didAddMessagesToMemoryStorage:messages forDialogID:chatDialogID];
            }
        }
        
        if (completion) {
            completion(response, messages);
        }
        
    } errorBlock:^(QBResponse *response) {
        
        // case where we may have deleted dialog from another device
        if( response.status != QBResponseStatusCodeNotFound ) {
            [weakSelf.serviceManager handleErrorResponse:response];
        }
        
        
        if (completion) {
            completion(response, nil);
        }
        
    }];
}

#pragma mark - Fetch dialogs

- (void)fetchDialogWithID:(NSString *)dialogID completion:(void (^)(QBChatDialog *dialog))completion
{
    // checking memory storage for dialog with specific id
    QBChatDialog *dialogFromMemoryStorage = [self.dialogsMemoryStorage chatDialogWithID:dialogID];
    if (dialogFromMemoryStorage != nil) {
        if (completion) {
            completion(dialogFromMemoryStorage);
        }
        return;
    }
    
    // checking cache for dialog with specific id
    if ([self.cacheDataSource respondsToSelector:@selector(cachedDialogWithID:completion:)]) {
        NSAssert([QBSession currentSession].currentUser != nil, @"Current user must be non nil!");
        
        [self.cacheDataSource cachedDialogWithID:dialogID completion:^(QBChatDialog *dialog) {
            if (completion) completion(dialog);
        }];
    }
    else {
        if (completion) {
            completion(nil);
        }
    }
}

- (void)loadDialogWithID:(NSString *)dialogID completion:(void (^)(QBChatDialog *loadedDialog))completion {
    __weak __typeof(self)weakSelf = self;
    QBResponsePage *responsePage = [QBResponsePage responsePageWithLimit:1 skip:0];
    NSMutableDictionary *extendedRequest = @{@"_id":dialogID}.mutableCopy;
    [QBRequest dialogsForPage:responsePage extendedRequest:extendedRequest successBlock:^(QBResponse *response, NSArray *dialogObjects, NSSet *dialogsUsersIDs, QBResponsePage *page) {
        if ([dialogObjects firstObject] != nil) {
            [weakSelf.dialogsMemoryStorage addChatDialog:[dialogObjects firstObject] andJoin:YES completion:nil];
            if ([weakSelf.multicastDelegate respondsToSelector:@selector(chatService:didAddChatDialogToMemoryStorage:)]) {
                [weakSelf.multicastDelegate chatService:weakSelf didAddChatDialogToMemoryStorage:[dialogObjects firstObject]];
            }
        }
        if (completion) {
            completion([dialogObjects firstObject]);
        }
    } errorBlock:^(QBResponse *response) {
        if (completion) {
            completion(nil);
        }
    }];
}

- (void)fetchDialogsUpdatedFromDate:(NSDate *)date
                       andPageLimit:(NSUInteger)limit
                     iterationBlock:(void(^)(QBResponse *response, NSArray *dialogObjects, NSSet *dialogsUsersIDs, BOOL *stop))iteration
                    completionBlock:(void (^)(QBResponse *response))completion
{
    NSTimeInterval timeInterval = [date timeIntervalSince1970];
    NSMutableDictionary *extendedRequest = @{@"updated_at[gt]":@(timeInterval)}.mutableCopy;
    
    [self allDialogsWithPageLimit:limit extendedRequest:extendedRequest iterationBlock:^(QBResponse *response, NSArray *dialogObjects, NSSet *dialogsUsersIDs, BOOL *stop) {
        //
        if (iteration) iteration(response,dialogObjects,dialogsUsersIDs,stop);
    } completion:^(QBResponse *response) {
        //
        if (completion) completion(response);
    }];
}

#pragma mark - Send messages

- (void)sendMessage:(QBChatMessage *)message
               type:(QMMessageType)type
           toDialog:(QBChatDialog *)dialog
      saveToHistory:(BOOL)saveToHistory
      saveToStorage:(BOOL)saveToStorage
         completion:(QBChatCompletionBlock)completion
{
    message.dateSent = [NSDate date];
    message.text = [message.text gtm_stringByEscapingForHTML];
    
    //Save to history
    if (saveToHistory) {
        message.saveToHistory = kChatServiceSaveToHistoryTrue;
    }
    //Set message type
    if (type != QMMessageTypeText) {
        message.messageType = type;
    }
    
    QBUUser *currentUser = self.serviceManager.currentUser;
    
    if (dialog.type == QBChatDialogTypePrivate) {
        message.recipientID = dialog.recipientID;
        message.markable = YES;
    }
    
    message.senderID = currentUser.ID;
    message.dialogID = dialog.ID;
    
    [dialog sendMessage:message completionBlock:^(NSError *error) {
        //
        if (error == nil && saveToStorage) {
            [self.messagesMemoryStorage addMessage:message forDialogID:dialog.ID];
            
            if ([self.multicastDelegate respondsToSelector:@selector(chatService:didAddMessageToMemoryStorage:forDialogID:)]) {
                [self.multicastDelegate chatService:self didAddMessageToMemoryStorage:message forDialogID:dialog.ID];
            }
            
            dialog.lastMessageText = message.encodedText;
            dialog.lastMessageDate = message.dateSent;
            dialog.updatedAt = message.dateSent;
            
            if ([self.multicastDelegate respondsToSelector:@selector(chatService:didUpdateChatDialogInMemoryStorage:)]) {
                [self.multicastDelegate chatService:self didUpdateChatDialogInMemoryStorage:dialog];
            }
        }
        
        if (completion) completion(error);
    }];
}

- (void)sendMessage:(QBChatMessage *)message
         toDialogID:(NSString *)dialogID
      saveToHistory:(BOOL)saveToHistory
      saveToStorage:(BOOL)saveToStorage
         completion:(QBChatCompletionBlock)completion
{
    NSCParameterAssert(dialogID);
    QBChatDialog *dialog = [self.dialogsMemoryStorage chatDialogWithID:dialogID];
    NSAssert(dialog != nil, @"Dialog have to be in memory cache!");
    
    [self sendMessage:message toDialog:dialog saveToHistory:saveToHistory saveToStorage:saveToStorage completion:completion];
}

- (void)sendMessage:(QBChatMessage *)message
           toDialog:(QBChatDialog *)dialog
      saveToHistory:(BOOL)saveToHistory
      saveToStorage:(BOOL)saveToStorage
         completion:(QBChatCompletionBlock)completion
{
    NSAssert(message.messageType == QMMessageTypeText, @"You can only send text messages with this method.");
    
    [self sendMessage:message type:QMMessageTypeText toDialog:dialog saveToHistory:saveToHistory saveToStorage:saveToStorage completion:completion];
}

- (void)sendAttachmentMessage:(QBChatMessage *)attachmentMessage
                     toDialog:(QBChatDialog *)dialog
          withAttachmentImage:(UIImage *)image
                   completion:(QBChatCompletionBlock)completion
{
    
    [self.messagesMemoryStorage addMessage:attachmentMessage forDialogID:dialog.ID];
    if ([self.multicastDelegate respondsToSelector:@selector(chatService:didAddMessageToMemoryStorage:forDialogID:)]) {
        
        [self.multicastDelegate chatService:self didAddMessageToMemoryStorage:attachmentMessage forDialogID:dialog.ID];
        
    }
    
    [self.chatAttachmentService uploadAndSendAttachmentMessage:attachmentMessage toDialog:dialog withChatService:self withAttachedImage:image completion:completion];
}

#pragma mark - mark as delivered

- (void)markMessageAsDelivered:(QBChatMessage *)message completion:(QBChatCompletionBlock)completion {
    [self markMessagesAsDelivered:@[message] completion:completion];
}

- (void)markMessagesAsDelivered:(NSArray *)messages completion:(QBChatCompletionBlock)completion {
    
    dispatch_group_t deliveredGroup = dispatch_group_create();
    
    for (QBChatMessage *message in messages) {

        if (![message.deliveredIDs containsObject:@([QBSession currentSession].currentUser.ID)]) {
            message.markable = YES;
            __weak __typeof(self)weakSelf = self;
            dispatch_group_enter(deliveredGroup);
            [[QBChat instance] markAsDelivered:message completion:^(NSError *error) {
                //
                if (error == nil) {
                    __typeof(weakSelf)strongSelf = weakSelf;
                    
                    // updating message in memory storage
                    [strongSelf.messagesMemoryStorage addMessage:message forDialogID:message.dialogID];
                    // calling multicast delegate
                    if ([strongSelf.multicastDelegate respondsToSelector:@selector(chatService:didUpdateMessage:forDialogID:)]) {
                        [strongSelf.multicastDelegate chatService:strongSelf didUpdateMessage:message forDialogID:message.dialogID];
                    }
                }
                dispatch_group_leave(deliveredGroup);
            }];
        }
    }
    
    dispatch_group_notify(deliveredGroup, dispatch_get_main_queue(), ^{
        //
        if (completion) {
            completion(nil);
        }
    });

}

#pragma mark - read messages

- (void)readMessage:(QBChatMessage *)message completion:(QBChatCompletionBlock)completion {
    NSAssert(message.dialogID != nil, @"Message must have a dialog ID!");
    
    [self readMessages:@[message] forDialogID:message.dialogID completion:completion];
}

- (void)readMessages:(NSArray *)messages forDialogID:(NSString *)dialogID completion:(QBChatCompletionBlock)completion {
    NSAssert(dialogID != nil, @"dialogID can't be nil");
    
    dispatch_group_t readGroup = dispatch_group_create();
    
    QBChatDialog *chatDialogToUpdate = [self.dialogsMemoryStorage chatDialogWithID:dialogID];

    for (QBChatMessage *message in messages) {
        NSAssert([message.dialogID isEqualToString:dialogID], @"Message is from incorrect dialog.");
        
        if (![message.readIDs containsObject:@([QBSession currentSession].currentUser.ID)]) {
            message.markable = YES;
            __weak __typeof(self)weakSelf = self;
            dispatch_group_enter(readGroup);
            [[QBChat instance] readMessage:message completion:^(NSError *error) {
                //
                if (error == nil) {
                    __typeof(weakSelf)strongSelf = weakSelf;
                    
                    if (chatDialogToUpdate.unreadMessagesCount > 0) {
                        chatDialogToUpdate.unreadMessagesCount--;
                    }
                    // updating message in memory storage
                    [strongSelf.messagesMemoryStorage addMessage:message forDialogID:message.dialogID];
                    // calling multicast delegate
                    if ([strongSelf.multicastDelegate respondsToSelector:@selector(chatService:didUpdateMessage:forDialogID:)]) {
                        [strongSelf.multicastDelegate chatService:strongSelf didUpdateMessage:message forDialogID:dialogID];
                    }
                }
                dispatch_group_leave(readGroup);
            }];
        }
    }
    
    dispatch_group_notify(readGroup, dispatch_get_main_queue(), ^{
        //
        if ([self.multicastDelegate respondsToSelector:@selector(chatService:didUpdateChatDialogInMemoryStorage:)]) {
            [self.multicastDelegate chatService:self didUpdateChatDialogInMemoryStorage:chatDialogToUpdate];
        }
        if (completion) {
            completion(nil);
        }
    });
}

#pragma mark - QMMemoryStorageProtocol

- (void)free {
	
    [self.loadedAllMessages removeAllObjects];
	[self.messagesMemoryStorage free];
	[self.dialogsMemoryStorage free];
}

#pragma mark - System messages

- (void)sendSystemMessageAboutAddingToDialog:(QBChatDialog *)chatDialog
                                  toUsersIDs:(NSArray *)usersIDs
                                  completion:(QBChatCompletionBlock)completion
{
    dispatch_group_t notifyGroup = dispatch_group_create();
    
    for (NSNumber *occupantID in usersIDs) {
        
        if (self.serviceManager.currentUser.ID == [occupantID integerValue]) {
            continue;
        }
        
        QBChatMessage *privateMessage = [self systemMessageWithRecipientID:[occupantID integerValue] parameters:nil];
        privateMessage.messageType = QMMessageTypeCreateGroupDialog;
        [privateMessage updateCustomParametersWithDialog:chatDialog];
        
        dispatch_group_enter(notifyGroup);
        [[QBChat instance] sendSystemMessage:privateMessage completion:^(NSError *error) {
            //
            dispatch_group_leave(notifyGroup);
        }];
    }
    
    dispatch_group_notify(notifyGroup, dispatch_get_main_queue(), ^{
        //
        if (completion) completion(nil);
    });
}

- (void)sendMessageAboutUpdateDialog:(QBChatDialog *)updatedDialog
                withNotificationText:(NSString *)notificationText
                    customParameters:(NSDictionary *)customParameters
                          completion:(QBChatCompletionBlock)completion
{
    NSParameterAssert(updatedDialog);
    
    QBChatMessage *message = [QBChatMessage message];
    message.text = notificationText;
    
    [message updateCustomParametersWithDialog:updatedDialog];
    
    if (customParameters)
    {
        [message.customParameters addEntriesFromDictionary:customParameters];
    }
    
    [self sendMessage:message type:QMMessageTypeUpdateGroupDialog toDialog:updatedDialog saveToHistory:YES saveToStorage:YES completion:completion];
}

- (void)sendMessageAboutAcceptingContactRequest:(BOOL)accept
                                   toOpponentID:(NSUInteger)opponentID
                                     completion:(QBChatCompletionBlock)completion
{
    QBChatMessage *message = [QBChatMessage message];
    message.text = @"Contact request";
    
    QMMessageType messageType = accept ? QMMessageTypeAcceptContactRequest : QMMessageTypeRejectContactRequest;
    
    QBChatDialog *p2pDialog = [self.dialogsMemoryStorage privateChatDialogWithOpponentID:opponentID];
    NSParameterAssert(p2pDialog);
    
    [self sendMessage:message type:messageType toDialog:p2pDialog saveToHistory:YES saveToStorage:YES completion:completion];
}

#pragma mark - Notification messages

- (void)sendNotificationMessageAboutAddingOccupants:(NSArray *)occupantsIDs
                                           toDialog:(QBChatDialog *)chatDialog
                                         completion:(QBChatCompletionBlock)completion
{
    QBChatMessage *notificationMessage = [self notificationMessageAboutUpdateDialogWithType:QMDialogUpdateTypeOccupants andDialogUpdatedAt:chatDialog.updatedAt];
    notificationMessage.addedOccupantsIDs = occupantsIDs;
    notificationMessage.currentOccupantsIDs = chatDialog.occupantIDs;
    
    [self sendMessage:notificationMessage type:QMMessageTypeUpdateGroupDialog toDialog:chatDialog saveToHistory:YES saveToStorage:YES completion:completion];
}

- (void)sendNotificationMessageAboutLeavingDialog:(QBChatDialog *)chatDialog
                                       completion:(QBChatCompletionBlock)completion
{
    QBChatMessage *notificationMessage = [self notificationMessageAboutUpdateDialogWithType:QMDialogUpdateTypeOccupants andDialogUpdatedAt:[NSDate date]];
    notificationMessage.deletedOccupantsIDs = @[@(self.serviceManager.currentUser.ID)];
    
    NSMutableArray *occupantsWithoutCurrentUser = [NSMutableArray arrayWithArray:chatDialog.occupantIDs];
    [occupantsWithoutCurrentUser removeObject:@(self.serviceManager.currentUser.ID)];
    
    notificationMessage.currentOccupantsIDs = [occupantsWithoutCurrentUser copy];
    
    [self sendMessage:notificationMessage type:QMMessageTypeUpdateGroupDialog toDialog:chatDialog saveToHistory:YES saveToStorage:YES completion:completion];
}

- (void)sendNotificationMessageAboutChangingDialogPhoto:(QBChatDialog *)chatDialog
                                             completion:(QBChatCompletionBlock)completion
{
    QBChatMessage *notificationMessage = [self notificationMessageAboutUpdateDialogWithType:QMDialogUpdateTypePhoto andDialogUpdatedAt:chatDialog.updatedAt];
    notificationMessage.dialogPhoto = chatDialog.photo;
    
    [self sendMessage:notificationMessage type:QMMessageTypeUpdateGroupDialog toDialog:chatDialog saveToHistory:YES saveToStorage:YES completion:completion];
}

- (void)sendNotificationMessageAboutChangingDialogName:(QBChatDialog *)chatDialog
                                            completion:(QBChatCompletionBlock)completion
{
    QBChatMessage *notificationMessage = [self notificationMessageAboutUpdateDialogWithType:QMDialogUpdateTypeName andDialogUpdatedAt:chatDialog.updatedAt];
    notificationMessage.dialogName = chatDialog.name;
    
    [self sendMessage:notificationMessage type:QMMessageTypeUpdateGroupDialog toDialog:chatDialog saveToHistory:YES saveToStorage:YES completion:completion];
}

#pragma mark Utilites

- (QBChatMessage *)privateMessageWithRecipientID:(NSUInteger)recipientID text:(NSString *)text save:(BOOL)save {
	
	QBChatMessage *message = [QBChatMessage message];
	message.recipientID = recipientID;
	message.senderID = self.serviceManager.currentUser.ID;
    message.text = text;
    message.dateSent = [NSDate date];
	
	if (save) {
		message.saveToHistory = kChatServiceSaveToHistoryTrue;
	}
	
	return message;
}

- (QBChatMessage *)systemMessageWithRecipientID:(NSUInteger)recipientID parameters:(NSDictionary *)paramters {
    
    QBChatMessage *message = [QBChatMessage message];
    message.recipientID = recipientID;
    message.senderID = self.serviceManager.currentUser.ID;
    
    if (paramters) {
        [message.customParameters addEntriesFromDictionary:paramters];
    }
    
    return message;
}

- (QBChatMessage *)notificationMessageAboutUpdateDialogWithType:(QMDialogUpdateType)dialogUpdateType
                                             andDialogUpdatedAt:(NSDate *)dialogUpdatedAt
{
    
    QBChatMessage *notificationMessage = [QBChatMessage message];
    notificationMessage.senderID = self.serviceManager.currentUser.ID;
    notificationMessage.text = @"Notification message";
    notificationMessage.dialogUpdateType = dialogUpdateType;
    notificationMessage.dialogUpdatedAt = dialogUpdatedAt;
    
    return notificationMessage;
}

@end
