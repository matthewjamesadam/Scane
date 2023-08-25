#!/usr/bin/swift

//
//  processDeps.swift
//  Scane
//
//  Created by Matt Adam on 2021-12-30.
//

import Foundation

struct DepLib {
    let name: String
    let version: String
    let libName: String
    let dylibName: String
    let shas: [String:String]
}

// List of all dependencies we pull from homebrew
let saneLib = DepLib(
    name: "sane-backends",
    version: "1.2.1_1",
    libName: "libsane",
    dylibName: "libsane.dylib",
    shas: [
        "arm64":  "816f955ec13f1767fa9bf3e721a3fb55a06bd17482c3db58fca4dab8c1a0ea44", // arm64_big_sur
        "x86_64": "68a5dadc176006ccaac9957884dfa582bde20c846e0567201efb381e5cc190af", // big_sur
])

let usbLib = DepLib(
    name: "libusb",
    version: "1.0.26",
    libName: "libusb",
    dylibName: "libusb-1.0.dylib",
    shas: [
        "arm64":  "d9121e56c7dbfad640c9f8e3c3cc621d88404dc1047a4a7b7c82fe06193bca1f", // arm64_big_sur
        "x86_64": "963720057ac56afd38f8d4f801f036231f08f5cf7db36cb470814cbc1b38e49c", // big_sur
])

let pngLib = DepLib(
    name: "libpng",
    version: "1.6.40",
    libName: "libpng",
    dylibName: "libpng.dylib",
    shas: [
        "arm64":  "bd0c0853926df0f1118b4b7f700ee7594cad881604fd76e711eeef1231700f50", // arm64_big_sur
        "x86_64": "c4f83c1860a79daac87a140dce046a16bafae60f064c4f5b6d25d568db2bf695", // big_sur
])

let tiffLib = DepLib(
    name: "libtiff",
    version: "4.5.1",
    libName: "libtiff",
    dylibName: "libtiff.dylib",
    shas: [
        "arm64":  "760ba837679b14af360309108cdc3e682ddfed4c969ac1cec744927a7fcab67e", // arm64_big_sur
        "x86_64": "18bd9c73f730afa03c4c5dd3c9b23d810a827e32464d325beafd1499161e47ab", // big_sur
])

let jpegLib = DepLib(
    name: "jpeg-turbo",
    version: "3.0.0",
    libName: "libjpeg",
    dylibName: "libjpeg.dylib",
    shas: [
        "arm64":  "8365422894438d22ff64db9387c6445ca5c9cbdecda15da0ef018c7fe355eda1", // arm64_big_sur
        "x86_64": "4ced360a9d7c567dc49ae6dc6370ed92edbeb0ed6917c40bc56aa3ba73e51ce5", // big_sur
])


let depLibs = [ saneLib, usbLib, pngLib, tiffLib, jpegLib ]

guard let buildProductsDir = ProcessInfo.processInfo.environment["BUILT_PRODUCTS_DIR"],
      let frameworksFolderPath = ProcessInfo.processInfo.environment["FRAMEWORKS_FOLDER_PATH"],
      let sharedSupportFolderPath = ProcessInfo.processInfo.environment["SHARED_SUPPORT_FOLDER_PATH"],
      let srcRoot = ProcessInfo.processInfo.environment["SRCROOT"] else
{
    print("Build output folders are not in the environment")
    exit(1)
}

let buildProductsUrl = URL(fileURLWithPath: buildProductsDir, isDirectory: true)
let frameworksFolder = buildProductsUrl.appendingPathComponents(frameworksFolderPath)
let sharedSupportFolder = buildProductsUrl.appendingPathComponents(sharedSupportFolderPath)

let etcFolder = sharedSupportFolder.appendingPathComponents("sane.d")

let srcRootFolder = URL(fileURLWithPath: srcRoot, isDirectory: true)

let fileMgr = FileManager.default
let tmpFolder = fileMgr.temporaryDirectory.appendingPathComponents("ScaneDeps")

let depsFolder = srcRootFolder.appendingPathComponents("SaneKit", "deps")

let libFolder = depsFolder.appendingPathComponents("lib")
let includeFolder = depsFolder.appendingPathComponents("include")

extension URL {
    func appendingPathComponents(_ args: String...) -> URL {
        var url = self
        for arg in args {
            url = url.appendingPathComponent(arg)
        }
        return url
    }
}

// Helpers for running processes
struct RunOutput {
    let status: Int32
    let output: [String]
}

enum RunError: Error {
    case error(RunOutput)
}

@discardableResult
func run(_ args: String...) throws -> RunOutput {
    try run(args)
}

@discardableResult
func run(_ args: [String]) throws -> RunOutput {
    
    let task = Process()
    let pipe = Pipe()
    
    task.standardOutput = pipe
    task.standardError = pipe
    
    task.launchPath = "/usr/bin/env"
    task.arguments = args
    task.launch()
    task.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)!.components(separatedBy: .newlines)
    let runOutput = RunOutput(status: task.terminationStatus, output: output)

    if task.terminationStatus != 0 {
        throw RunError.error(runOutput)
    }
    
    return runOutput
}

// Get clean name for a dependency
func cleanDepName(depName: String) -> String {
    for depLib in depLibs {
        if depName.contains(depLib.libName) {
            return depLib.dylibName
        }
    }

    return depName
}

// Clean a single dependency for a single library
func cleanLibDep(lib: URL, depPath: String, depFolderPath: String) throws {
    let depUrl = URL(fileURLWithPath: depPath)
    let depName = cleanDepName(depName: depUrl.lastPathComponent)

    if lib.lastPathComponent == depName {
        try run("install_name_tool", "-id", "@rpath/\(depName)", lib.path)
    }
    else {
        try run("install_name_tool", "-change", depPath, "\(depFolderPath)/\(depName)", lib.path)
    }
}

// Clean all dependencies for a single library
func cleanLibDeps(lib: URL, depFolderPath: String) throws {
    let otoolOutput = try run("otool", "-L", "-X", lib.path)

    try otoolOutput.output.forEach { depString in
        if let range = depString.range(of: #"^\s*\S+"#, options: .regularExpression) {
            let path = depString[range].description.trimmingCharacters(in: .whitespacesAndNewlines)

            if path.contains("@@HOMEBREW_PREFIX@@") {
                try cleanLibDep(lib: lib, depPath: path, depFolderPath: depFolderPath)
            }
        }
    }
    
    try run("codesign", "--force", "--sign", "-", "--timestamp=none", lib.path)
}

func clearFolder(url: URL) throws {
    try? fileMgr.removeItem(at: url)
    try fileMgr.createDirectory(at: url, withIntermediateDirectories: true)
}

func createLib(lib: DepLib) throws {

    // Fetch libs
    try lib.shas.forEach({ arch, sha in
        print("Fetching \(lib.name) \(arch)...")

        let rootPath = "\(lib.name)-\(arch)"
        let tarPath = tmpFolder.appendingPathComponent("\(rootPath).tar.gz")
        let libPath = tmpFolder.appendingPathComponent(rootPath)

        try? fileMgr.removeItem(at: tarPath)
        try? fileMgr.removeItem(at: libPath)
        try fileMgr.createDirectory(at: libPath, withIntermediateDirectories: true)

        try run("curl", "-L", "-H", "Authorization: Bearer QQ==", "-f", "-o", tarPath.path, "https://ghcr.io/v2/homebrew/core/\(lib.name)/blobs/sha256:\(sha)")
        try run("tar", "-xzvf", tarPath.path, "-C", libPath.path)
    })

    // Create merged universal library
    print("Creating \(lib.dylibName)...")
    var lipoArgs = ["lipo", "-create"]
    lib.shas.forEach({ arch, _ in
        let srcPath = tmpFolder.appendingPathComponents("\(lib.name)-\(arch)", lib.name, lib.version, "lib", lib.dylibName)
        lipoArgs.append(contentsOf: ["-arch", arch, srcPath.path])
    })
    
    let destPath = libFolder.appendingPathComponent(lib.dylibName)
    lipoArgs.append(contentsOf: ["-output", destPath.path])
    
    try run(lipoArgs)
    
    try cleanLibDeps(lib: destPath, depFolderPath: "@loader_path")
}

func getSaneLibFolder(arch: String) -> URL {
    return tmpFolder.appendingPathComponents("\(saneLib.name)-\(arch)", saneLib.name, saneLib.version, "lib", "sane")
}

func creeateSaneLib(libName: String) throws {

    // Create merged universal library
    print("Creating \(libName)...")
    var lipoArgs = ["lipo", "-create"]
    saneLib.shas.forEach({ arch, _ in
        let srcPath = getSaneLibFolder(arch: arch).appendingPathComponents(libName)
        lipoArgs.append(contentsOf: ["-arch", arch, srcPath.path])
    })
    
    let destPath = libFolder.appendingPathComponents("sane", libName)
    lipoArgs.append(contentsOf: ["-output", destPath.path])
    
    try run(lipoArgs)
    
    try cleanLibDeps(lib: destPath, depFolderPath: "@loader_path/..")
}

func embedLibs() throws {

    print("Downloading and processing dependencies from homebrew...")

    // Set up a clean state
    try clearFolder(url: tmpFolder)
    try clearFolder(url: depsFolder)
    try fileMgr.createDirectory(at: libFolder.appendingPathComponents("sane"), withIntermediateDirectories: true)
    try fileMgr.createDirectory(at: includeFolder, withIntermediateDirectories: true)
    try fileMgr.createDirectory(at: frameworksFolder.appendingPathComponents("sane"), withIntermediateDirectories: true)
    try fileMgr.createDirectory(at: etcFolder, withIntermediateDirectories: true)

    // Create root dylibs
    for depLib in depLibs {
        try createLib(lib: depLib)
    }

    // Create sane dylibs
    let saneLibPath = getSaneLibFolder(arch: "arm64")
    let paths = try FileManager.default.contentsOfDirectory(at: saneLibPath, includingPropertiesForKeys: nil)
    try paths.filter({$0.path.contains(".1.so")}).forEach { path in
        try creeateSaneLib(libName: path.lastPathComponent)
    }

    // Copy /etc
    print("Copying /etc files...")
    let srcEtcFolder = tmpFolder.appendingPathComponents("\(saneLib.name)-arm64", saneLib.name, saneLib.version, "etc", "sane.d")
    try run("rsync", "-rtvh", "\(srcEtcFolder.path)/", "\(etcFolder.path)/")

    // Copy /lib -- from derived data into frameworks output
    print("Copying /lib files...")
    try run ("rsync", "-rtvh", "\(libFolder.path)/", "\(frameworksFolder.path)/")

    // Copy /include
    print("Copying /include files...")
    let srcIncludeFolder = tmpFolder.appendingPathComponents("\(saneLib.name)-arm64", saneLib.name, saneLib.version, "include", "sane")
    let destIncludeFolder = includeFolder
    try fileMgr.createDirectory(at: destIncludeFolder, withIntermediateDirectories: true)
    try run("rsync", "-rtvh", "\(srcIncludeFolder.path)/", "\(destIncludeFolder.path)/")
}

try embedLibs()
