cmake_minimum_required(VERSION 3.15)

project(rnnoise LANGUAGES C)

# =========================================================
# Optional model download step
# =========================================================
include(cmake/download_model.cmake OPTIONAL)

# =========================================================
# Options
# =========================================================
option(RNNOISE_ASSERTIONS "Enable assertions" OFF)
option(RNNOISE_EXAMPLES "Build examples" ON)
option(RNNOISE_DNN_DEBUG_FLOAT "DNN float mode" OFF)
option(RNNOISE_X86_RTCD "Enable x86 RTCD" OFF)
option(RNNOISE_DOC "Build docs" OFF)
option(RNNOISE_LITTLE "Use little data" ON)
option(RNNOISE_DYNAMIC_RUNTIME "Link against dynamic runtime (Windows)" ON)

set(IS_X86 FALSE)

if(CMAKE_SYSTEM_PROCESSOR MATCHES "^(x86_64|AMD64|i[3-6]86)$")
    set(IS_X86 TRUE)
endif()

# =========================================================
# Library target
# =========================================================
add_library(rnnoise)

set_target_properties(rnnoise PROPERTIES
    C_STANDARD 11
    C_STANDARD_REQUIRED ON
    VERSION "0.0.0"
    SOVERSION 4
)

# =========================================================
# Sources (core)
# =========================================================
set(RNNOISE_SOURCES
    src/denoise.c
    src/rnn.c
    src/pitch.c
    src/kiss_fft.c
    src/celt_lpc.c
    src/nnet.c
    src/nnet_default.c
    src/parse_lpcnet_weights.c
    src/rnnoise_tables.c
)

target_sources(rnnoise PRIVATE ${RNNOISE_SOURCES})

# =========================================================
# X86 RTCD sources + SIMD flags
# =========================================================
if(RNNOISE_X86_RTCD AND IS_X86)
    target_sources(rnnoise PRIVATE
        src/x86/x86_dnn_map.c
        src/x86/x86cpu.c
        src/x86/nnet_sse4_1.c
        src/x86/nnet_avx2.c
    )

    set_source_files_properties(
         src/x86/nnet_sse4_1.c
         PROPERTIES
             COMPILE_OPTIONS
			     "$<$<C_COMPILER_ID:MSVC>:/arch:AVX2>;$<$<NOT:$<C_COMPILER_ID:MSVC>>:-msse4.1>"
     )
     
     set_source_files_properties(
         src/x86/nnet_avx2.c
         PROPERTIES
             COMPILE_OPTIONS
                 "$<$<C_COMPILER_ID:MSVC>:/arch:AVX2>;$<$<NOT:$<C_COMPILER_ID:MSVC>>:-mavx;-mfma;-mavx2>"
     )
endif()

if(RNNOISE_LITTLE)
    target_sources(rnnoise PRIVATE
        src/rnnoise_data_little.c
    )
else()
    target_sources(rnnoise PRIVATE
	    src/rnnoise_data.c
    )
endif()

# =========================================================
# Includes
# =========================================================
target_include_directories(rnnoise PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
    $<INSTALL_INTERFACE:include>
)

# =========================================================
# Compile definitions (MODERN TARGET-BASED)
# =========================================================
target_compile_definitions(rnnoise PRIVATE
    RNNOISE_BUILD

    # Assertions
    $<$<BOOL:${RNNOISE_ASSERTIONS}>:OP_ENABLE_ASSERTIONS=1>

    # Disable debug float if OFF
    $<$<NOT:$<BOOL:${RNNOISE_DNN_DEBUG_FLOAT}>>:DISABLE_DEBUG_FLOAT=1>

    # RTCD
    $<$<AND:${IS_X86},$<BOOL:${RNNOISE_X86_RTCD}>>:RNN_ENABLE_X86_RTCD=1>
    $<$<AND:${IS_X86},$<BOOL:${RNNOISE_X86_RTCD}>>:CPU_INFO_BY_ASM=1>

    # Windows compatibility
    $<$<PLATFORM_ID:Windows>:_WIN32_WINNT=0x0501>
)

# =========================================================
# Compiler warnings
# =========================================================
target_compile_options(rnnoise PRIVATE
    $<$<C_COMPILER_ID:MSVC>:/W4>

    $<$<NOT:$<C_COMPILER_ID:MSVC>>:-Wall>
    $<$<NOT:$<C_COMPILER_ID:MSVC>>:-Wextra>
    $<$<NOT:$<C_COMPILER_ID:MSVC>>:-pedantic>
    $<$<NOT:$<C_COMPILER_ID:MSVC>>:-Wno-sign-compare>
    $<$<NOT:$<C_COMPILER_ID:MSVC>>:-Wno-parentheses>
    $<$<NOT:$<C_COMPILER_ID:MSVC>>:-Wno-long-long>
)

# =========================================================
# Visibility (shared library hygiene)
# =========================================================
set_target_properties(rnnoise PROPERTIES
  MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>$<$<BOOL:${RNNOISE_DYNAMIC_RUNTIME}>:DLL>"
  POSITION_INDEPENDENT_CODE ON
  C_VISIBILITY_PRESET hidden
  CXX_VISIBILITY_PRESET hidden
  VISIBILITY_INLINES_HIDDEN ON
)

# =========================================================
# Math library (libm)
# =========================================================
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    target_link_libraries(rnnoise PRIVATE m)
endif()

# =========================================================
# Examples
# =========================================================
if(RNNOISE_EXAMPLES)
    add_executable(rnnoise_demo examples/rnnoise_demo.c)
    target_link_libraries(rnnoise_demo PRIVATE rnnoise)
endif()

# =========================================================
# Installation
# =========================================================
install(TARGETS rnnoise
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
)

install(FILES include/rnnoise.h
    DESTINATION include
)