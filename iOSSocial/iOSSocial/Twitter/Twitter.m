//
//  Twitter.m
//  iOSSocial
//
//  Created by Christopher White on 7/22/11.
//  Copyright 2011 Mad Races, Inc. All rights reserved.
//

#import "Twitter.h"
#import "iOSSLog.h"
#import "LocalTwitterUser.h"
#import "LocalTwitterUserLegacy.h"
#import <Accounts/Accounts.h>

@interface Twitter ()

@property(nonatomic, readwrite, assign)     BOOL primary;
@property(nonatomic, retain)                ACAccountStore *accountStore;
@property(nonatomic, copy)                  AuthorizationHandler authorizationHandler;

@end

static Twitter *twitterService = nil;

@implementation Twitter

@synthesize name;
@synthesize logoImage;
@synthesize primary;
@synthesize accountStore;
@synthesize authorizationHandler;

+ (id<iOSSocialServiceProtocol>)sharedService;
{
    @synchronized(self) {
        if(twitterService == nil) {
            twitterService = [[super allocWithZone:NULL] init];
        }
    }
    return twitterService;
}

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        if ([ACAccountStore class]) {
            self.accountStore = [[ACAccountStore alloc] init];
        }
    }
    
    return self;
}

- (void)assignOAuthParams:(NSDictionary*)params asPrimary:(BOOL)isPrimary
{
    [super assignOAuthParams:params];
    
    self.primary = isPrimary;
    
    [[iOSSocialServicesStore sharedServiceStore] registerService:self];
}

- (NSString*)name
{
    return @"Twitter";
}

- (UIImage*)logoImage
{
    NSURL *logoURL = [[NSBundle mainBundle] URLForResource:@"twitter-logo" withExtension:@"png"];
    UIImage *theLogoImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:logoURL]];
    return theLogoImage;
}

- (NSString*)serviceKeychainItemName
{
    return self.keychainItemName;
}

- (void)setAccountStoreAccounts {
    ACAccountType *accountType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    NSArray *twitterAccounts = [self.accountStore accountsWithAccountType:accountType];
    if (!twitterAccounts.count) {
        if (self.authorizationHandler) {
            NSError *error = [NSError errorWithDomain:@"Twitter" code:1 userInfo:nil];
            self.authorizationHandler(nil, nil, error);
            self.authorizationHandler = nil;
        }
    } else {
        if (self.authorizationHandler) {
            ACAccount *account = [twitterAccounts objectAtIndex:0];
            
            NSDictionary *userDictionary = [NSDictionary dictionaryWithObject:account.username forKey:@"username"];
            NSDictionary *userInfoDictionary = [NSDictionary dictionaryWithObject:userDictionary forKey:@"user"];

            self.authorizationHandler(account, userInfoDictionary, nil);
            self.authorizationHandler = nil;
        }
    }
}

- (id)checkAuthenticationForKeychainItemName:(NSString*)theKeychainItemName
{
    if (![ACAccountStore class]) {
        return [super checkAuthenticationForKeychainItemName:theKeychainItemName];
    }
    
    ACAccount *account = nil;
    if (theKeychainItemName) {
        account = [self.accountStore accountWithIdentifier:theKeychainItemName];
    }
    
    return account;
}

- (void)authorizeFromViewController:(UIViewController *)vc 
                            forAuth:(id)theAuth 
                andKeychainItemName:(NSString *)theKeychainItemName 
                    andCookieDomain:(NSString *)cookieDomain 
              withCompletionHandler:(AuthorizationHandler)completionHandler 
{
    self.authorizationHandler = completionHandler;
    
    if ([ACAccountStore class]) {

        ACAccountType *accountType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        
        [self.accountStore requestAccessToAccountsWithType:accountType withCompletionHandler:
         ^(BOOL granted, NSError *error) {
             if (error) {
                 if (self.authorizationHandler) {
                     self.authorizationHandler(nil, nil, error);
                     self.authorizationHandler = nil;
                 }
             } else {
                 if (granted) {
                     dispatch_async(dispatch_get_main_queue(), ^{
                         [self setAccountStoreAccounts];
                     });
                 } else {
                     if (self.authorizationHandler) {
                         NSError *error = [NSError errorWithDomain:@"Twitter" code:2 userInfo:nil];
                         self.authorizationHandler(nil, nil, error);
                         self.authorizationHandler = nil;
                     }
                 }
             }
         }];
    } else {
        [super authorizeFromViewController:vc forAuth:theAuth andKeychainItemName:theKeychainItemName andCookieDomain:cookieDomain withCompletionHandler:completionHandler];
    }
}

- (id<iOSSocialLocalUserProtocol>)localUser
{
    if (![ACAccountStore class]) {
        return [[LocalTwitterUserLegacy alloc] init];
    }
    
    return [LocalTwitterUser localTwitterUser];
}

- (id<iOSSocialLocalUserProtocol>)localUserWithDictionary:(NSDictionary*)dictionary
{
    if (![ACAccountStore class]) {
        return [[LocalTwitterUserLegacy alloc] initWithDictionary:dictionary];
    } 
    
    LocalTwitterUser *theUser = [[LocalTwitterUser alloc] initWithDictionary:dictionary];
    [LocalTwitterUser setLocalTwitterUser:theUser];
    return theUser;
}

- (id<iOSSocialLocalUserProtocol>)localUserWithIdentifier:(NSString*)identifier
{
    if (![ACAccountStore class]) {
        return [[LocalTwitterUserLegacy alloc] initWithIdentifier:identifier];
    }
    
    LocalTwitterUser *theUser = [[LocalTwitterUser alloc] initWithIdentifier:identifier];
    [LocalTwitterUser setLocalTwitterUser:theUser];
    return theUser;
}

@end
