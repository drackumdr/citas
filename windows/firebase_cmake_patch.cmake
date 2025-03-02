# This script patches the Firebase C++ SDK CMakeLists.txt to remove the deprecation warning

if(EXISTS "${CMAKE_BINARY_DIR}/x64/extracted/firebase_cpp_sdk_windows/CMakeLists.txt")
    file(READ "${CMAKE_BINARY_DIR}/x64/extracted/firebase_cpp_sdk_windows/CMakeLists.txt" FIREBASE_CMAKE_CONTENT)
    string(REGEX REPLACE "cmake_minimum_required\\(VERSION ([0-9]+\\.[0-9]+)\\)" "cmake_minimum_required(VERSION \\1...)" FIREBASE_CMAKE_CONTENT_MODIFIED "${FIREBASE_CMAKE_CONTENT}")
    file(WRITE "${CMAKE_BINARY_DIR}/x64/extracted/firebase_cpp_sdk_windows/CMakeLists.txt" "${FIREBASE_CMAKE_CONTENT_MODIFIED}")
    message(STATUS "Firebase CMake file patched to use modern version requirement syntax")
endif()
