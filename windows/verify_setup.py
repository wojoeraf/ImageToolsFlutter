#!/usr/bin/env python3
"""
Verification script to check if the TurboJPEG integration setup is correct.
"""

import os
import sys
from pathlib import Path

def check_file_exists(file_path, description):
    """Check if a file exists and print status."""
    if os.path.exists(file_path):
        print(f"✓ {description}: {file_path}")
        return True
    else:
        print(f"✗ {description}: {file_path} (NOT FOUND)")
        return False

def check_cmake_content():
    """Check if CMakeLists.txt has the required content."""
    cmake_file = "CMakeLists.txt"
    if not os.path.exists(cmake_file):
        print(f"✗ CMakeLists.txt not found")
        return False
    
    with open(cmake_file, 'r') as f:
        content = f.read()
    
    checks = [
        ("JPEG wrapper target", "add_library(jpeg_decoder_wrapper SHARED"),
        ("TurboJPEG linking", "target_link_libraries(jpeg_decoder_wrapper"),
        ("DLL installation", "install(TARGETS jpeg_decoder_wrapper"),
        ("TurboJPEG DLL installation", "turbojpeg.dll"),
    ]
    
    all_good = True
    for description, pattern in checks:
        if pattern in content:
            print(f"✓ CMakeLists.txt contains {description}")
        else:
            print(f"✗ CMakeLists.txt missing {description}")
            all_good = False
    
    return all_good

def check_dart_content():
    """Check if the Dart FFI file has the required enhancements."""
    dart_file = "../lib/services/decode_jpeg_ffi.dart"
    if not os.path.exists(dart_file):
        print(f"✗ Dart FFI file not found: {dart_file}")
        return False
    
    with open(dart_file, 'r') as f:
        content = f.read()
    
    checks = [
        ("Robust DLL loading", "_loadLibrary()"),
        ("TurboJPEG test function", "test_turbojpeg"),
        ("Path package import", "package:path/path.dart"),
        ("Integration test function", "testTurboJpegIntegration"),
    ]
    
    all_good = True
    for description, pattern in checks:
        if pattern in content:
            print(f"✓ Dart file contains {description}")
        else:
            print(f"✗ Dart file missing {description}")
            all_good = False
    
    return all_good

def main():
    """Main verification function."""
    print("=== TurboJPEG Integration Verification ===\n")
    
    # Change to windows directory
    script_dir = Path(__file__).parent
    os.chdir(script_dir)
    
    print("1. Checking required files:")
    files_ok = True
    files_ok &= check_file_exists("turbojpeg.dll", "TurboJPEG DLL")
    files_ok &= check_file_exists("turbojpeg.h", "TurboJPEG header")
    files_ok &= check_file_exists("lib/turbojpeg.lib", "TurboJPEG library")
    files_ok &= check_file_exists("jpeg_decoder_wrapper.c", "JPEG wrapper source")
    files_ok &= check_file_exists("CMakeLists.txt", "CMake configuration")
    files_ok &= check_file_exists("build_wrapper.bat", "Build script")
    files_ok &= check_file_exists("check_dependencies.ps1", "Dependency checker")
    
    print("\n2. Checking CMakeLists.txt content:")
    cmake_ok = check_cmake_content()
    
    print("\n3. Checking Dart FFI enhancements:")
    dart_ok = check_dart_content()
    
    print("\n=== Summary ===")
    if files_ok and cmake_ok and dart_ok:
        print("✓ All checks passed! The TurboJPEG integration should work correctly.")
        print("\nNext steps:")
        print("1. Build the project using CMake or the build script")
        print("2. Run the Dart test to verify TurboJPEG is working")
        return 0
    else:
        print("✗ Some checks failed. Please review the issues above.")
        return 1

if __name__ == "__main__":
    sys.exit(main())