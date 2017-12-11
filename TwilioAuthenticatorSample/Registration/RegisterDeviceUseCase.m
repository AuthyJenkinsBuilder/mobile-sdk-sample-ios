//
//  RegisterDeviceUseCase.m
//  TwilioAuthenticatorSample
//
//  Created by Adriana Pineda on 2/20/17.
//  Copyright © 2017 Authy. All rights reserved.
//

#import "RegisterDeviceUseCase.h"

#define CONTENT_TYPE @"application/x-www-form-urlencoded"

@implementation RegisterDeviceUseCase

- (void)getRegistrationTokenForUserID:(NSString *)userId andBackendURL:(NSString *)backendURL completion:(void(^) (RegistrationResponse *registrationResponse))completion {

    NSString *urlString = [backendURL stringByAppendingString:@"/registration"];
    NSURL *url = [NSURL URLWithString:urlString];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];

    NSString *body = [NSString stringWithFormat:@"user_id=%@", userId];
    NSData *bodyAsNSData = [body dataUsingEncoding:NSASCIIStringEncoding];

    [request setHTTPBody:bodyAsNSData];

    NSString *length = [NSString stringWithFormat:@"%lu", (unsigned long)bodyAsNSData.length];
    [request setValue:length forHTTPHeaderField:@"Content-Length"];
    [request setValue:CONTENT_TYPE forHTTPHeaderField: @"Content-Type"];

    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
        RegistrationResponse *registrationResponse = [[RegistrationResponse alloc] init];

        if (data == nil) {
            registrationResponse.messageError = [NSString stringWithFormat:@"Request could not be made: %@", connectionError.localizedDescription];
            completion(registrationResponse);
            return;
        }

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
        if ([httpResponse statusCode] != 200) {
            NSString *error = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            registrationResponse.messageError = [NSString stringWithFormat:@"Request could not be made: %@", error];
            completion(registrationResponse);
            return;
        }

        NSError *error = nil;
        NSDictionary *currentResponseAsDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];

        NSString *registrationToken = [currentResponseAsDict objectForKey:@"registration_token"];
        if (registrationToken) {
            registrationResponse.registrationToken = registrationToken;
        }

        NSString *message = [currentResponseAsDict objectForKey:@"message"];
        if (message && ![message isEqualToString:@""]) {
            registrationResponse.messageError = message;
        }

        completion(registrationResponse);

    }];

}

@end
