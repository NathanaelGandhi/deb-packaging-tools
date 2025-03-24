cmake_minimum_required(VERSION 3.10)

# Define the project name
project(helloworld)

# Add an executable target
add_executable(helloworld main.cpp)

# Specify where to install the binary
install(TARGETS helloworld DESTINATION bin)
