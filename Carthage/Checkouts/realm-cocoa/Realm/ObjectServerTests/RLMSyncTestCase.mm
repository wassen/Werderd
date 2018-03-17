////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMSyncTestCase.h"

#import <XCTest/XCTest.h>
#import <Realm/Realm.h>

#import "RLMRealm_Dynamic.h"
#import "RLMRealm_Private.hpp"
#import "RLMRealmConfiguration_Private.h"
#import "RLMSyncManager+ObjectServerTests.h"
#import "RLMSyncSessionRefreshHandle+ObjectServerTests.h"
#import "RLMSyncConfiguration_Private.h"
#import "RLMUtil.hpp"

#import "sync/sync_manager.hpp"
#import "sync/sync_session.hpp"
#import "sync/sync_user.hpp"

// Set this to 1 if you intend to start up a ROS instance manually to test against.
#define PROVIDING_OWN_ROS 0

// Set this to 1 if you want the test ROS instance to log its debug messages to console.
#define LOG_ROS_OUTPUT 0

// Set this to 1 for extremely verbose trace logging from ROS
#define LOG_ROS_TRACE 0

#define NODE_PATH @"/usr/local/bin/node"

#if PROVIDING_OWN_ROS
// Define the admin token as an Objective-C string here if you wish to run tests requiring it.
// #define OWN_ROS_ADMIN_TOKEN @"token_goes_here"
#endif

#if !TARGET_OS_MAC
#error These tests can only be run on a macOS host.
#endif

@interface RLMSyncManager ()
+ (void)_setCustomBundleID:(NSString *)customBundleID;
- (instancetype)initWithCustomRootDirectory:(NSURL *)rootDirectory;
@end

@interface RLMSyncTestCase ()
@property (nonatomic) NSTask *task;
@end

@interface RLMSyncCredentials ()
+ (instancetype)credentialsWithDebugUserID:(NSString *)userID isAdmin:(BOOL)isAdmin;
@end

@interface RLMSyncSession ()
- (BOOL)waitForUploadCompletionOnQueue:(dispatch_queue_t)queue callback:(void(^)(NSError *))callback;
- (BOOL)waitForDownloadCompletionOnQueue:(dispatch_queue_t)queue callback:(void(^)(NSError *))callback;
@end

@interface RLMSyncUser()
- (std::shared_ptr<realm::SyncUser>)_syncUser;
@end

@implementation SyncObject
@end

@implementation HugeSyncObject

+ (instancetype)object  {
    const NSInteger fakeDataSize = 1000000;
    HugeSyncObject *object = [[self alloc] init];
    char fakeData[fakeDataSize];
    memset(fakeData, sizeof(fakeData), 16);
    object.dataProp = [NSData dataWithBytes:fakeData length:sizeof(fakeData)];
    return object;
}

@end

static NSTask *s_task;
static RLMSyncManager *s_managerForTest;

static NSURL *syncDirectoryForChildProcess() {
    NSString *path = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES)[0];
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *bundleIdentifier = bundle.bundleIdentifier ?: bundle.executablePath.lastPathComponent;
    path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-child", bundleIdentifier]];
    [[NSFileManager defaultManager] createDirectoryAtPath:path
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
    return [NSURL fileURLWithPath:path isDirectory:YES];
}

@interface RealmObjectServer : NSObject
@property (nonatomic, readonly) NSURL *serverDataRoot;

+ (instancetype)sharedServer;

- (void)launch;
@end

@implementation RealmObjectServer {
    NSTask *_task;
    NSURL *_serverDataRoot;
}
+ (instancetype)sharedServer {
    static RealmObjectServer *instance = [RealmObjectServer new];
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _serverDataRoot = [[[[[NSURL fileURLWithPath:@(__FILE__)]
                             URLByDeletingLastPathComponent]
                            URLByDeletingLastPathComponent]
                           URLByDeletingLastPathComponent]
                           URLByAppendingPathComponent:@"test-ros-instance/"];
    }
    return self;
}

- (void)launch {
#if !PROVIDING_OWN_ROS
    if (_task) {
        return;
    }

    // Kill any old running processes from a previous run
    // Make sure this argument list matches the one used to launch below
    [[NSTask launchedTaskWithLaunchPath:@"/usr/bin/pkill"
                              arguments:@[@"-f", @"ros/bin/ros", @"start"]] waitUntilExit];

    NSFileManager *fileManager = NSFileManager.defaultManager;

    NSURL *target = [self.serverDataRoot URLByAppendingPathComponent:@"ros/bin/ros"];
    if (![fileManager fileExistsAtPath:target.path]) {
        NSLog(@"The Realm Object Server isn't installed. You need to run 'build.sh download-object-server'"
              @" prior to running these tests.");
        abort();
    }

    [fileManager removeItemAtURL:[self.serverDataRoot URLByAppendingPathComponent:@"data"] error:nil];
    [fileManager removeItemAtURL:[self.serverDataRoot URLByAppendingPathComponent:@"realm-object-server"] error:nil];

    NSPipe *pipe = [NSPipe pipe];
    auto buffer = [[NSMutableData alloc] init];
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    __block BOOL inUseError = NO;
    pipe.fileHandleForReading.readabilityHandler = ^(NSFileHandle *file) {
        [buffer appendData:[file availableData]];
        const auto bytes = static_cast<const char *>(buffer.bytes);
        if (strstr(bytes, "Realm Object Server has started and is listening")) {
            dispatch_semaphore_signal(sema);
        }
        else if (strstr(bytes, "Error: listen EADDRINUSE")) {
            inUseError = YES;
            dispatch_semaphore_signal(sema);
        }

        const char *newline;
        auto start = bytes;
        auto end = start + buffer.length;
        while ((newline = std::find(start, end, '\n')) != end) {
#if LOG_ROS_OUTPUT
            if (newline > start + 1) {
                NSLog(@"ROS: %.*s", int(newline - start), start);
            }
#endif
            start = newline + 1;
        }

        // Remove everything up to the last newline, leaving any data not newline-terminated in the buffer
        [buffer replaceBytesInRange:{0, static_cast<NSUInteger>(start - bytes)} withBytes:nullptr length:0];
    };

    _task = [[NSTask alloc] init];
    _task.currentDirectoryPath = self.serverDataRoot.path;
    _task.launchPath = NODE_PATH;
    // Warning: if the way the ROS is launched is changed, remember to also update
    // the regex in build.sh's kill_object_server() function.
    _task.arguments = @[target.path, @"start", @"--auth", @"debug,password"
                        #if LOG_ROS_TRACE
                            , @"--loglevel", @"trace"
                        #endif
                        ];
    // Need to set the environment variables to bypass the mandatory email prompt.
    // ROS_SUPERAGENT_RETRY_DELAY is a workaround for <https://github.com/realm/realm-object-server-private/issues/950>.
    _task.environment = @{@"ROS_TOS_EMAIL_ADDRESS": @"ci@realm.io",
                          @"DOCKER_DATA_PATH": @"/tmp",
                          @"REALM_DISABLE_SYNC_TO_DISK": @"true",
                          @"ROS_SUPERAGENT_RETRY_DELAY": @"0" };

    _task.standardOutput = pipe;
    _task.standardError = pipe;

    [_task launch];

    long wait_result = dispatch_semaphore_wait(sema, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)));
    if (inUseError) {
        NSLog(@"Server tried to start up, but the port was already in use (probably already running).");
        abort();
    }
    if (wait_result != 0) {
        NSLog(@"Server did not start up within the allotted timeout interval.");
        abort();
    }
#endif // !PROVIDING_OWN_ROS
}
@end

@implementation RLMSyncTestCase

+ (RLMSyncManager *)managerForCurrentTest {
    return s_managerForTest;
}

#pragma mark - Helper methods

- (BOOL)isPartial {
    return NO;
}

+ (NSURL *)authServerURL {
    return [NSURL URLWithString:@"http://127.0.0.1:9080"];
}

+ (RLMSyncCredentials *)basicCredentialsWithName:(NSString *)name register:(BOOL)shouldRegister {
    return [RLMSyncCredentials credentialsWithUsername:name
                                              password:@"a"
                                              register:shouldRegister];
}

+ (NSURL *)onDiskPathForSyncedRealm:(RLMRealm *)realm {
    return [NSURL fileURLWithPath:@(realm->_realm->config().path.data())];
}

- (void)addSyncObjectsToRealm:(RLMRealm *)realm descriptions:(NSArray<NSString *> *)descriptions {
    [realm beginWriteTransaction];
    for (NSString *desc in descriptions) {
        [SyncObject createInRealm:realm withValue:@[desc]];
    }
    [realm commitWriteTransaction];
}

- (void)waitForDownloadsForUser:(RLMSyncUser *)user
                         realms:(NSArray<RLMRealm *> *)realms
                      realmURLs:(NSArray<NSURL *> *)realmURLs
                 expectedCounts:(NSArray<NSNumber *> *)counts {
    NSAssert(realms.count == counts.count && realms.count == realmURLs.count,
             @"Test logic error: all array arguments must be the same size.");
    for (NSUInteger i = 0; i < realms.count; i++) {
        [self waitForDownloadsForUser:user url:realmURLs[i] expectation:nil error:nil];
        [realms[i] refresh];
        CHECK_COUNT([counts[i] integerValue], SyncObject, realms[i]);
    }
}

- (RLMRealm *)openRealmForURL:(NSURL *)url user:(RLMSyncUser *)user {
    return [self openRealmForURL:url user:user immediatelyBlock:nil];
}

- (RLMRealm *)openRealmForURL:(NSURL *)url user:(RLMSyncUser *)user immediatelyBlock:(void(^)(void))block {
    return [self openRealmForURL:url
                            user:user
                   encryptionKey:nil
                      stopPolicy:RLMSyncStopPolicyAfterChangesUploaded
                immediatelyBlock:block];
}

- (RLMRealm *)openRealmForURL:(NSURL *)url
                         user:(RLMSyncUser *)user
                encryptionKey:(nullable NSData *)encryptionKey
                   stopPolicy:(RLMSyncStopPolicy)stopPolicy
             immediatelyBlock:(nullable void(^)(void))block {
    const NSTimeInterval timeout = 4;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    RLMSyncManager.sharedManager.sessionCompletionNotifier = ^(NSError *error) {
        if (error) {
            XCTFail(@"Received an asynchronous error when trying to open Realm at '%@' for user '%@': %@ (process: %@)",
                    url, user.identity, error, self.isParent ? @"parent" : @"child");
        }
        dispatch_semaphore_signal(sema);
    };

    RLMRealm *realm = [self immediatelyOpenRealmForURL:url user:user encryptionKey:encryptionKey stopPolicy:stopPolicy];
    if (block) {
        block();
    }
    // Wait for login to succeed or fail.
    XCTAssert(dispatch_semaphore_wait(sema, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC))) == 0,
              @"Timed out while trying to asynchronously open Realm for URL: %@", url);
    return realm;
}

- (RLMRealm *)openRealmWithConfiguration:(RLMRealmConfiguration *)configuration {
    return [self openRealmWithConfiguration:configuration immediatelyBlock:nullptr];
}

- (RLMRealm *)openRealmWithConfiguration:(RLMRealmConfiguration *)configuration
             immediatelyBlock:(nullable void(^)(void))block {
    const NSTimeInterval timeout = 4;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    RLMSyncConfiguration *syncConfig = configuration.syncConfiguration;
    RLMSyncManager.sharedManager.sessionCompletionNotifier = ^(NSError *error) {
        if (error) {
            XCTFail(@"Received an asynchronous error when trying to open Realm at '%@' for user '%@': %@ (process: %@)",
                    syncConfig.realmURL, syncConfig.user.identity, error, self.isParent ? @"parent" : @"child");
        }
        dispatch_semaphore_signal(sema);
    };

    RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration error:nullptr];
    if (block) {
        block();
    }
    // Wait for login to succeed or fail.
    XCTAssert(dispatch_semaphore_wait(sema, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC))) == 0,
              @"Timed out while trying to asynchronously open Realm for URL: %@", syncConfig.realmURL);
    return realm;
}
- (RLMRealm *)immediatelyOpenRealmForURL:(NSURL *)url user:(RLMSyncUser *)user {
    return [self immediatelyOpenRealmForURL:url
                                       user:user
                              encryptionKey:nil
                                 stopPolicy:RLMSyncStopPolicyAfterChangesUploaded];
}

- (RLMRealm *)immediatelyOpenRealmForURL:(NSURL *)url
                                    user:(RLMSyncUser *)user
                           encryptionKey:(NSData *)encryptionKey
                              stopPolicy:(RLMSyncStopPolicy)stopPolicy {
    auto syncConfig = [[RLMSyncConfiguration alloc] initWithUser:user realmURL:url];
    syncConfig.stopPolicy = stopPolicy;
    syncConfig.isPartial = [self isPartial];

    auto c = [RLMRealmConfiguration defaultConfiguration];
    c.encryptionKey = encryptionKey;
    c.syncConfiguration = syncConfig;
    return [RLMRealm realmWithConfiguration:c error:nil];
}

- (RLMSyncUser *)logInUserForCredentials:(RLMSyncCredentials *)credentials
                                  server:(NSURL *)url {
    NSString *process = self.isParent ? @"parent" : @"child";
    __block RLMSyncUser *theUser = nil;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Should log in the user properly"];
    [RLMSyncUser logInWithCredentials:credentials
                        authServerURL:url
                         onCompletion:^(RLMSyncUser *user, NSError *error) {
                             XCTAssertTrue(NSThread.isMainThread);
                             XCTAssertNil(error,
                                          @"Error when trying to log in a user: %@ (process: %@)",
                                          error, process);
                             XCTAssertNotNil(user);
                             theUser = user;
                             [expectation fulfill];
                         }];
    [self waitForExpectationsWithTimeout:4.0 handler:nil];
    XCTAssertTrue(theUser.state == RLMSyncUserStateActive,
                  @"User should have been valid, but wasn't. (process: %@)", process);
    return theUser;
}

- (RLMSyncUser *)createAdminUserForURL:(NSURL *)url username:(NSString *)username {
    return [self logInUserForCredentials:[RLMSyncCredentials credentialsWithDebugUserID:username isAdmin:YES]
                                  server:url];
}

- (NSString *)adminToken {
#if PROVIDING_OWN_ROS
#ifdef OWN_ROS_ADMIN_TOKEN
    return OWN_ROS_ADMIN_TOKEN;
#else
    NSAssert(NO, @"Cannot run admin token related tests unless you define OWN_ROS_ADMIN_TOKEN.");
    return nil;
#endif
#else
    NSURL *target = [RealmObjectServer.sharedServer.serverDataRoot
                     URLByAppendingPathComponent:@"/data/keys/admin.json"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:[target path]]) {
        XCTFail(@"Could not find the JSON file containing the admin token.");
        return nil;
    }
    NSData *raw = [NSData dataWithContentsOfURL:target];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:raw options:0 error:nil];
    NSString *token = json[@"ADMIN_TOKEN"];
    if ([token length] == 0) {
        XCTFail(@"Could not successfully extract the token.");
    }
    return token;
#endif
}

- (void)waitForDownloadsForRealm:(RLMRealm *)realm {
    [self waitForDownloadsForRealm:realm error:nil];
}

- (void)waitForUploadsForRealm:(RLMRealm *)realm {
    [self waitForUploadsForRealm:realm error:nil];
}

- (void)waitForDownloadsForUser:(RLMSyncUser *)user
                            url:(NSURL *)url
                    expectation:(XCTestExpectation *)expectation
                          error:(NSError **)error {
    RLMSyncSession *session = [user sessionForURL:url];
    NSAssert(session, @"Cannot call with invalid URL");
    XCTestExpectation *ex = expectation ?: [self expectationWithDescription:@"Wait for download completion"];
    __block NSError *theError = nil;
    BOOL queued = [session waitForDownloadCompletionOnQueue:nil callback:^(NSError *err) {
        theError = err;
        [ex fulfill];
    }];
    if (!queued) {
        XCTFail(@"Download waiter did not queue; session was invalid or errored out.");
        return;
    }
    [self waitForExpectations:@[ex] timeout:20.0];
    if (error) {
        *error = theError;
    }
}

- (void)waitForUploadsForRealm:(RLMRealm *)realm error:(NSError **)error {
    RLMSyncSession *session = [RLMSyncSession sessionForRealm:realm];
    NSAssert(session, @"Cannot call with invalid Realm");
    XCTestExpectation *ex = [self expectationWithDescription:@"Wait for upload completion"];
    __block NSError *completionError;
    BOOL queued = [session waitForUploadCompletionOnQueue:nil callback:^(NSError *error) {
        completionError = error;
        [ex fulfill];
    }];
    if (!queued) {
        XCTFail(@"Upload waiter did not queue; session was invalid or errored out.");
        return;
    }
    [self waitForExpectations:@[ex] timeout:2.0];
    if (error)
        *error = completionError;
}

- (void)waitForDownloadsForRealm:(RLMRealm *)realm error:(NSError **)error {
    RLMSyncSession *session = [RLMSyncSession sessionForRealm:realm];
    NSAssert(session, @"Cannot call with invalid Realm");
    XCTestExpectation *ex = [self expectationWithDescription:@"Wait for download completion"];
    __block NSError *completionError;
    BOOL queued = [session waitForDownloadCompletionOnQueue:nil callback:^(NSError *error) {
        completionError = error;
        [ex fulfill];
    }];
    if (!queued) {
        XCTFail(@"Download waiter did not queue; session was invalid or errored out.");
        return;
    }
    [self waitForExpectations:@[ex] timeout:2.0];
    if (error)
        *error = completionError;
}

- (void)manuallySetRefreshTokenForUser:(RLMSyncUser *)user value:(NSString *)tokenValue {
    [user _syncUser]->update_refresh_token(tokenValue.UTF8String);
}

// FIXME: remove this API once the new token system is implemented.
- (void)primeSyncManagerWithSemaphore:(dispatch_semaphore_t)semaphore {
    if (semaphore == nil) {
        [[RLMSyncManager sharedManager] setSessionCompletionNotifier:^(__unused NSError *error){ }];
        return;
    }
    [[RLMSyncManager sharedManager] setSessionCompletionNotifier:^(NSError *error) {
        XCTAssertNil(error, @"Session completion block returned with an error: %@", error);
        dispatch_semaphore_signal(semaphore);
    }];
}

#pragma mark - XCUnitTest Lifecycle

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
    NSURL *clientDataRoot;
    if (self.isParent) {
        [RealmObjectServer.sharedServer launch];
        clientDataRoot = [NSURL fileURLWithPath:RLMDefaultDirectoryForBundleIdentifier(nil)];
    }
    else {
        clientDataRoot = syncDirectoryForChildProcess();
    }
    NSError *error;
    [NSFileManager.defaultManager removeItemAtURL:clientDataRoot error:&error];
    [NSFileManager.defaultManager createDirectoryAtURL:clientDataRoot
                           withIntermediateDirectories:YES attributes:nil error:&error];
    s_managerForTest = [[RLMSyncManager alloc] initWithCustomRootDirectory:clientDataRoot];
    [RLMSyncManager sharedManager].logLevel = RLMSyncLogLevelOff;
}

- (void)tearDown {
    [s_managerForTest prepareForDestruction];
    s_managerForTest = nil;
    [RLMSyncSessionRefreshHandle calculateFireDateUsingTestLogic:NO blockOnRefreshCompletion:nil];

    [super tearDown];
}

@end
