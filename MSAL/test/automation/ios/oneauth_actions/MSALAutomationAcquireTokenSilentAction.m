//------------------------------------------------------------------------------
//
// Copyright (c) Microsoft Corporation.
// All rights reserved.
//
// This code is licensed under the MIT License.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions :
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//------------------------------------------------------------------------------

#import "MSALAutomationAcquireTokenSilentAction.h"
#import "MSIDAutomationTestRequest.h"
#import "MSALAuthority.h"
#import "MSALPublicClientApplication.h"
#import "MSIDAutomationActionConstants.h"
#import "MSIDAutomationActionManager.h"
#import "MSIDAutomationTestResult.h"
#import "MSIDAutomationErrorResult.h"
#import "MSALSilentTokenParameters.h"
#import "MSALError.h"
#import "MSALClaimsRequest.h"

#import <OneAuth/OneAuth.h>

@implementation MSALAutomationAcquireTokenSilentAction

+ (void)load
{
    [[MSIDAutomationActionManager sharedInstance] registerAction:[MSALAutomationAcquireTokenSilentAction new]];
}

- (NSString *)actionIdentifier
{
    return MSID_AUTO_ACQUIRE_TOKEN_SILENT_ACTION_IDENTIFIER;
}

- (BOOL)needsRequestParameters
{
    return YES;
}

- (void)performActionWithParameters:(MSIDAutomationTestRequest *)testRequest
                containerController:(__unused MSIDAutoViewController *)containerController
                    completionBlock:(MSIDAutoCompletionBlock)completionBlock
{
    
    // TODO:
    NSString *appVersion = @"1.27.1";
    MALAadConfiguration *aadConfiguration;
    MALMsaConfiguration *msaConfiguration;
    MALOnPremisesConfiguration *onPremConfiguration;
    MALTelemetryConfiguration *telemetryConfig;
    

    NSUUID *clientId = [[NSUUID alloc] initWithUUIDString:testRequest.clientId];

    aadConfiguration = [[MALAadConfiguration alloc] initWithClientId:clientId
                                                         redirectUri:testRequest.redirectUri
                                               defaultSignInResource:testRequest.requestResource
                                                        preferBroker:NO
                                                        capabilities:nil];

    MALAuthenticatorConfiguration *config = [[MALAuthenticatorConfiguration alloc]
        initWithAppConfiguration:[[MALAppConfiguration alloc]
                                     initWithApplicationId:@"com.microsoft.OneAuthTestApp"
                                                   appName:@"OneAuthTestApp"
                                                appVersion:appVersion
                                              languageCode:[[NSLocale currentLocale] localeIdentifier]]
                aadConfiguration:aadConfiguration
                msaConfiguration:msaConfiguration
         onPremisesConfiguration:onPremConfiguration
          telemetryConfiguration:telemetryConfig];

    if ([MALOneAuth startup:config])
    {
        [MALOneAuth setFlights:nil];
    }
    
    __auto_type authenticator = [MALOneAuth getAuthenticator];

    NSUUID *correlationId = [NSUUID new];

    MALAccount *account;
    if (testRequest.homeAccountIdentifier)
    {

        NSArray *ids = [testRequest.homeAccountIdentifier componentsSeparatedByString:@"."];
        assert(ids.count == 2);

        NSString *accountId = ids[0];
//        NSString *tenantId = ids[1];

        account = [authenticator readAccountForId:accountId];
        
    }
    
    if (!account)
    {
        // TODO:
        assert(false);
    }
    
    MALAuthParameters *params = [[MALAuthParameters alloc] initWithAuthScheme:MALAuthSchemeBearer
                                                                    authority:testRequest.configurationAuthority
                                                                       target:testRequest.requestResource
                                                                        realm:@""//tenantId
                                                           accessTokenToRenew:@""
                                                                       claims:testRequest.claims ?: @""
                                                                 capabilities:nil
                                                         additionalParameters:nil
                                                                popParameters:nil];
    
    [authenticator acquireCredentialSilentlyForAccount:account
                                            parameters:params
                                         correlationId:correlationId
                                            completion:^(MALAuthResult *authResult)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            MSIDAutomationTestResult *testResult = [self testResultWithMALAuthResult:authResult];
            completionBlock(testResult);
        });
    }];
    
//    NSError *applicationError = nil;
//    MSALPublicClientApplication *application = [self applicationWithParameters:testRequest error:nil];
//
//    if (!application)
//    {
//        MSIDAutomationTestResult *result = [self testResultWithMSALError:applicationError];
//        completionBlock(result);
//        return;
//    }
//
//    NSError *accountError = nil;
//    MSALAccount *account = [self accountWithParameters:testRequest application:application error:&accountError];
//
//    if (!account)
//    {
//        MSIDAutomationTestResult *result = nil;
//
//        if (accountError)
//        {
//            result = [self testResultWithMSALError:accountError];
//        }
//        else
//        {
//            NSError *error = MSIDCreateError(MSALErrorDomain, MSALErrorInteractionRequired, @"no account", nil, nil, nil, nil, nil, YES);
//
//            result = [[MSIDAutomationErrorResult alloc] initWithAction:self.actionIdentifier
//                                                                 error:error
//                                                        additionalInfo:nil];
//        }
//
//        completionBlock(result);
//        return;
//    }
//
//    NSOrderedSet *scopes = [NSOrderedSet msidOrderedSetFromString:testRequest.requestScopes];
//    BOOL forceRefresh = testRequest.forceRefresh;
//    NSUUID *correlationId = [NSUUID new];
//
//    MSALAuthority *silentAuthority = nil;
//
//    if (testRequest.acquireTokenAuthority)
//    {
//        // In case we want to pass a different authority to silent call, we can use "silent authority" parameter
//        silentAuthority = [MSALAuthority authorityWithURL:[NSURL URLWithString:testRequest.acquireTokenAuthority] error:nil];
//    }
//    
//    MSALClaimsRequest *claimsRequest = nil;
//    
//    if (testRequest.claims.length)
//    {
//        NSError *claimsError;
//        claimsRequest = [[MSALClaimsRequest alloc] initWithJsonString:testRequest.claims error:&claimsError];
//        if (claimsError)
//        {
//            MSIDAutomationTestResult *result = [self testResultWithMSALError:claimsError];
//            completionBlock(result);
//            return;
//        }
//    }
//    
//    MSALSilentTokenParameters *parameters = [[MSALSilentTokenParameters alloc] initWithScopes:[scopes array] account:account];
//    parameters.authority = silentAuthority;
//    parameters.forceRefresh = forceRefresh;
//    parameters.correlationId = correlationId;
//    parameters.completionBlockQueue = dispatch_get_main_queue();
//    [application acquireTokenSilentWithParameters:parameters completionBlock:^(MSALResult *result, NSError *error)
//     {
//        MSIDAutomationTestResult *testResult = [self testResultWithMSALResult:result error:error];
//        completionBlock(testResult);
//     }];
}

@end
