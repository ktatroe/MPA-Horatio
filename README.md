# Horatio

## Introduction

Horatio is a library of patterns, protocols, and classes typical for the "skeleton" of a modern app. This includes:

1. Operations queue with conditions, observers, and improved error handling (based on Apple’s "Advanced NSOperations" sample code).
2. HTTP requests for standard REST services.
3. An injection container.
4. A feature availability system for global or per-subject behaviors.

By implementing concrete implementations of various protocols, you can quickly implement complex, testable network apps.

Horatio relies on the Advanced NSOperations sample code from Apple.

This document contains the following sections:

1. [Requirements](#requirements)
2. [Setup](#setup)
3. [Documentation](#documentation)
4. [Troubleshooting](#troubleshooting)
5. [Contributing](#contributing)
6. [Contributor License](#contributorlicense)
7. [Contact](#contact)
8. [Future Work](#future)

<a id="requirements"></a> 
## 1. Requirements

Horatio is delivered as Swift 2.3 source files. Due to Swift’s current
lack of ABI-compatibility, there is no framework delivery for it at the
moment.

Horatio requires compilation against iOS SDK 9.0 or higher.

<a id="setup"></a>
## 2. Setup

### 2.1 Download the source

1. Download the latest [MPA-Horatio](https://github.com/ktatroe/MPA-Network.git) framework, provided as source files.

### 2.2 Copy the SDK into your projects directory in Finder

Typically, 3rd-party libraries reside inside a folder in your Xcode
project (for example purposes, we assume your folder is called
"Vendor"). Create a folder and copy the SDK source files into it (the
Demo source files are not part of the main SDK, but could be copied into
your app as a starting point for various behaviors and patterns beyond
that which is provided by the SDK itself).

### 2.4 Add the SDK to the project in Xcode

> We recommend to use Xcode's group-feature to create a group for
> 3rd-party-libraries similar to the structure of our files on disk. For
> example, similar to the file structure in 2.2 above, our projects have
> a group called `Vendor`.
  
1. Make sure the `Project Navigator` is visible (⌘+1).
2. Drag & drop `Horatio` from your `Finder` to the `Vendor` group in `Xcode` using the `Project Navigator` on the left side.
3. An overlay will appear. Select `Create groups` and set the checkmark for your target. Then click `Finish`.

<a id="modifycode"></a>
### 2.4 Modify Code 

1. Open your `AppDelegate.swift` file.
2. Search for the method 

  ```swift
  application(application: UIApplication, didFinishLaunchingWithOptions launchOptions:[NSObject: AnyObject]?) -> Bool
  ```

4. Add the following lines to setup and start the Application Insights SDK:

  ```swift
  Container.register(OperationQueue.self) { _ in OperationQueue() }
  ```

In addition, register Services, Bridges, Feeds, etc. Typically, you'll
provide a startup manager class to handle the startup sequence.

<a id="documentation"></a>
## 3. Documentation

Documentation for Horatio can be found on (TBD).

<a id="troubleshooting"></a>
## 5.Troubleshooting

### iTunes Connect rejection

  Make sure none of the following files are added to any target:

  - `CalendarCondition.swift` (except if your app asks for permission to access the user’s calendar)
  - `CloudCondition.swift` (except if your app includes the CloudKit entitlement and at least one CloudKit container)
  - `HealthCondition.swift` (except if your app includes the HealthKit entitlement)
  - `PassbookCondition.swift` (except if your app uses Passbook API)
  - `PhotosCondition.swift` (except if your app asks for permission to access the user’s Photos data)
  - `UserNotificationCondition.swift` (except if your app includes the Push entitlement and has a valid APNS certificate for its bundle)

<a id="contributing"></a>
## 5. Contributing

We're looking forward to your contributions via pull requests.

**Development environment**

* Mac running the latest version of OS X
* Get the latest Xcode from the Mac App Store

<a id="contributorlicense"></a>
## 6. Contributor License

You must sign a Contributor License Agreement (TDB).

<a id="contact"></a>
## 7. Contact

If you have further questions or are running into trouble that cannot be
resolved by any of the steps here, feel free to open a Github issue
here, contact us at [support@mudpotapps.com](mailto:support@mudpotapps.com).

<a id="future"></a>
## 8. Future Work

Finishing the demo app; moving the Startup Sequence, Environments, and
Persistent Store code from the Demo into the library.

Provide experimental version in Swift 3.0.
