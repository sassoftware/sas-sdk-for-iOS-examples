#!/usr/bin/python

import sys
import os
import argparse
import shutil

class SASKitFrameworkSymlinks(object):

    # -----------------------------------------------
    def __init__(self):
        self.symlink = "SASKit.framework"

        self.framework_install_dir = "/Library/Frameworks"

        self.enterprise_framework = "SASKit.framework"          # x86_64 armv7 arm64
        self.appstore_framework   = "SASKitAppstore.framework"  # armv7 arm64
        self.debug_framework      = "SASKitDebug.framework"     # x86_64 armv7 arm64 with debug symbols

        self.use_framework = self.enterprise_framework

    def parseArgs(self):
        parser = argparse.ArgumentParser(description="Manage symlink SASKit.framework used by projects that include SASKit.  By default lists the current framework configuration.")
        parser.add_argument('-e','--enterprise', action='store_true', help="Create project symlinks to SASKit enterprise framework")
        parser.add_argument('-a','--appstore', action='store_true', help="Create project symlinks to SASKit appstore framework")
        parser.add_argument('-d','--debug', action='store_true', help="Create project symlinks to SASKit debug framework")
        parser.add_argument('-p','--path', help="When creating project symlinks, specify an alternate path to installed frameworks than the default: " + self.framework_install_dir)
        parser.add_argument('-t','--test', action='store_true', help="Test mode. Print symlink source and target without executing cmd.")
        parser.add_argument('-v','--verbose', action='store_true', help="Verbose output")

        args = parser.parse_args()
        self.set_framework_mode = False
        self.test_mode = False
        self.verbose_output = False

        if args.enterprise:
            self.use_framework = self.enterprise_framework
            self.set_framework_mode = True
        if args.appstore:
            self.use_framework = self.appstore_framework
            self.set_framework_mode = True
        if args.debug:
            self.use_framework = self.debug_framework
            self.set_framework_mode = True
        if args.test:
            self.test_mode = True
        if args.path:
            self.framework_install_dir = args.path
        if args.verbose:
            self.verbose_output = True

        self.frameworkPath = os.path.join(self.framework_install_dir, self.use_framework)

    def setLinks(self):

        if self.set_framework_mode and not os.path.exists(self.frameworkPath):
            print(self.frameworkPath + ' does not exist. Exited without creating symlinks to framework.')
            sys.exit(1)

        # Loop through directories in current path and set symlink to framework
        # for all directories having an xcodeproject
        cwd = os.getcwd()

        print("Scanning directory tree for XCode projects: " + cwd)

        for root, dirs, files in os.walk(cwd):
            for d in dirs:
                if d.endswith('.xcodeproj') and not d.endswith('_Debug.xcodeproj'):
                    targetlinkpath = os.path.join(root, self.symlink)

                    print("------------------------------------------------------------")

                    if (self.set_framework_mode):
                        if (self.test_mode):
                            print("Test mode. symlink not created. Source: " + self.frameworkPath + "   Target: " + targetlinkpath)
                        else:
                            # Remove link if it already exists at target path or new one cannot be created
                            if os.path.exists(targetlinkpath):
                                print("Replacing existing symlink: " + targetlinkpath)
                                os.unlink(targetlinkpath)

                            print("Created symlink. Source: " + self.frameworkPath + " Target: " + targetlinkpath)
                            os.symlink(self.frameworkPath , targetlinkpath)

                    # Output arch info about SASKit.framework which the project links to
                    # In test mode this prints out arch info for existing symlink
                    self.outputFrameworkInformation(d, root, targetlinkpath)


    def outputFrameworkInformation(self, projectFileName, projectDirectory, targetlinkpath ):
        print("")
        projectName = projectFileName
        if projectName.endswith('.xcodeproj'):
            projectName = projectName[:-10]
        print("Project                      : " + projectName)

        if os.path.islink(targetlinkpath):
            if os.path.exists(targetlinkpath):
                print("Real path to project symlink : " + os.path.realpath(targetlinkpath))
                print("Current project symlink      : " + targetlinkpath)
                frameworkBinary = os.path.join(targetlinkpath, "SASKit")

                if self.verbose_output:
                    print("")
                    print("lipo details:")
                    self.lipoinfocmd = "lipo -detailed_info " + frameworkBinary
                    os.system(self.lipoinfocmd)
                    print("")

                    print("otool details:")
                    self.otoolcmd = "otool -L " + frameworkBinary
                    os.system(self.otoolcmd)
                    print("")

                    print("otool debug sympbol info:")
                    self.determineIfFrameworkIsDebugOrRelease(frameworkBinary)
                    print("")

                    print("XCode project framework include info:")
                    self.parsePbxprojForFrameworkIncludeMethod(projectDirectory , projectFileName)

                    print("Swift modules directory:")
                    swiftModules = os.path.join(targetlinkpath, "Modules/SASKit.swiftmodule")
                    os.system("ls -l " + swiftModules)
                else:
                    self.lipoinfocmd = "lipo -info " + frameworkBinary
                    os.system(self.lipoinfocmd)
            else:
                print("Current project symlink      : * symlink " + targetlinkpath + " references a framework that does not exist: " + os.path.realpath(targetlinkpath))
        else:
            print("Current project symlink      : * symlink not currently set for project")

        print("")


    # Provide a utility analyze how SASKit.framework gets included in project
    #
    # This is how our internal DEBUG projects include the framework built locally in the project workspace. Not what consumers of framework would use.
    # /* SASKit.framework */ = {isa = PBXFileReference; explicitFileType = wrapper.framework; path = SASKit.framework; sourceTree = BUILT_PRODUCTS_DIR; };
    #
    # This is how a project using a pre-built framework using our SASKit.framework symlink includes framework
    # /* SASKit.framework */ = {isa = PBXFileReference; lastKnownFileType = wrapper.framework; path = SASKit.framework; sourceTree = "<group>"; };
    #
    # TODO: Add a check to see if it's included in the embedded binaries section
    def parsePbxprojForFrameworkIncludeMethod(self, projectDirectory , projectFileName):
        projectFilePath = os.path.join(projectDirectory, projectFileName)
        pbxProjectFilePath = os.path.join(projectFilePath ,"project.pbxproj")

        pbxProjectFile = open(pbxProjectFilePath)

        frameworkIncludeLine = ""
        for line in pbxProjectFile:
            if line.find("/* SASKit.framework */ = {isa = PBXFileReference; ") != -1:
                frameworkIncludeLine = line
                break

        if frameworkIncludeLine.find( "/* SASKit.framework */ = {isa = PBXFileReference; lastKnownFileType = wrapper.framework; path = SASKit.framework; sourceTree = \"<group>\"; }" ) != -1:
            print("Framework is added to project correctly: " + frameworkIncludeLine)
        else:
            print("Please verift SASKit.framework is added to project correctly: " + frameworkIncludeLine)


    # determineIfFrameworkIsDebugOrRelease() uses otool to count SAS "BIRD" symbols which are throughout
    # the portable C++ code.
    #
    # otool -Iv   produces large 8Mb file when debug symbol info is included versus < 130k file for no-symbols
    #             "BIRD" shows up as a symbol 10,000+ times in our debug framework.  Occurs 0 times in release build
    #
    # dwarfdump provided no useful info
    # dsymutil produced a lot of symbol info
    # nm -a produced a lot of symbol info
    # objdump - wouldn't run against the binary in SASKit
    def determineIfFrameworkIsDebugOrRelease(self, frameworkBinary):
        symbolFileName = "tmpSymbolDump.txt"
        dumpSymbolsCmd = "otool -Iv " + frameworkBinary + " > " + symbolFileName
        os.system(dumpSymbolsCmd)

        symbolFile = open(symbolFileName)
        BIRDSymbols = 0
        for line in symbolFile:
            if line.find("BIRD") != -1:
                BIRDSymbols += 1

        print('Number of SAS "BIRD" DEBUG symbols in library: ' + str(BIRDSymbols) )
        os.remove(symbolFileName)

def main(command_line_settings = None):
    symlinks = SASKitFrameworkSymlinks()
    symlinks.parseArgs()
    symlinks.setLinks()

if __name__ == '__main__':
    main()
    sys.exit(0)