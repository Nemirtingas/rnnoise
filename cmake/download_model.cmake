# Download and extract RNNoise model (script mode compatible)

if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/model_version")
    message(FATAL_ERROR "Missing model_version file")
endif()

file(READ "${CMAKE_CURRENT_SOURCE_DIR}/model_version" MODEL_HASH)
string(STRIP "${MODEL_HASH}" MODEL_HASH)
string(TOLOWER "${MODEL_HASH}" MODEL_HASH)

set(MODEL_FILENAME "rnnoise_data-${MODEL_HASH}.tar.gz")
set(MODEL_URL "https://media.xiph.org/rnnoise/models/${MODEL_FILENAME}")
set(MODEL_PATH "${CMAKE_CURRENT_SOURCE_DIR}/${MODEL_FILENAME}")
set(EXTRACT_MARKER "${CMAKE_CURRENT_SOURCE_DIR}/.extracted_${MODEL_HASH}")

# Download
if(NOT EXISTS "${MODEL_PATH}")
    message(STATUS "Downloading ${MODEL_URL}")
    file(DOWNLOAD "${MODEL_URL}" "${MODEL_PATH}" SHOW_PROGRESS STATUS st)
    list(GET st 0 code)
    list(GET st 1 msg)
    if(NOT code EQUAL 0)
        message(FATAL_ERROR "Download failed: ${msg}")
    endif()
endif()

# Verify hash
file(SHA256 "${MODEL_PATH}" ACTUAL_HASH)
string(TOLOWER "${ACTUAL_HASH}" ACTUAL_HASH)

if(NOT ACTUAL_HASH STREQUAL MODEL_HASH)
    file(REMOVE "${MODEL_PATH}")
    message(FATAL_ERROR "SHA256 mismatch (expected ${MODEL_HASH}, got ${ACTUAL_HASH})")
endif()

# Extract once
if(NOT EXISTS "${EXTRACT_MARKER}")
    message(STATUS "Extracting...")
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E tar xzf "${MODEL_PATH}"
        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
        RESULT_VARIABLE res
    )
    if(NOT res EQUAL 0)
        message(FATAL_ERROR "Extraction failed")
    endif()

    file(WRITE "${EXTRACT_MARKER}" "ok")
endif()