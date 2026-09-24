@echo off

:: Windows Intel MPI variant: ParaMEDMEM. There is no MPI compiler wrapper
:: FindMPI can interrogate on Windows (and MPI_<lang>_LIBRARIES is a result
:: variable it overwrites), so describe the conda impi-devel layout with the
:: FindMPI hint variables.
:: 64-bit ids in the MPI variant, as on Linux: code_aster's coupling passes
:: DataArrayInt64 global ids to ParaMESH.setCellGlobal/setNodeGlobal
set "ON_MPI=OFF"
set "IDS64=OFF"
set "MPI_OPTIONS="
if "%mpi%"=="impi" (
    set "ON_MPI=ON"
    set "IDS64=ON"
    set "MPI_OPTIONS=-D MPI_C_HEADER_DIR=%LIBRARY_INC% -D MPI_CXX_HEADER_DIR=%LIBRARY_INC% -D MPI_C_LIB_NAMES=impi -D MPI_CXX_LIB_NAMES=impi -D MPI_impi_LIBRARY=%LIBRARY_LIB%/impi.lib -D MPI_CXX_SKIP_MPICXX=ON"
)

cmake -B build -G "Ninja" . ^
    -Wno-dev ^
    -D CMAKE_BUILD_TYPE="Release" ^
    -D PYTHON_ROOT_DIR="%PREFIX%" ^
    -D CMAKE_CXX_FLAGS="/bigobj /wd4661 /wd4244 /EHsc" ^
    -D PYTHON_EXECUTABLE:FILEPATH="%PYTHON%" ^
    -D CONFIGURATION_ROOT_DIR="%SRC_DIR%/deps/config" ^
    -D SALOME_CMAKE_DEBUG=ON ^
    -D SALOME_USE_MPI=%ON_MPI% ^
    -D MEDCOUPLING_BUILD_STATIC=OFF ^
    -D MEDCOUPLING_BUILD_TESTS=OFF ^
    -D MEDCOUPLING_BUILD_DOC=OFF ^
    -D MEDCOUPLING_USE_64BIT_IDS=%IDS64% ^
    -D MEDCOUPLING_USE_MPI=%ON_MPI% ^
    -D MEDCOUPLING_MEDLOADER_USE_XDR=OFF ^
    -D MEDCOUPLING_INSTALL_PYTHON=%SP_DIR% ^
    -D XDR_INCLUDE_DIRS="" ^
    -D MEDCOUPLING_ENABLE_PYTHON=ON ^
    -D MEDCOUPLING_ENABLE_PARTITIONER=ON ^
    -D MEDCOUPLING_PARTITIONER_PARMETIS=OFF ^
    -D MEDCOUPLING_PARTITIONER_METIS=OFF ^
    -D MEDCOUPLING_PARTITIONER_SCOTCH=OFF ^
    -D MEDCOUPLING_PARTITIONER_PTSCOTCH=OFF ^
    %MPI_OPTIONS% ^
    %CMAKE_ARGS%

:: "if errorlevel 1" misses negative exit codes (a failed link through
:: cmake -E vs_link_dll returns -1)
if %ERRORLEVEL% neq 0 exit 1
cmake --build build --target install
if %ERRORLEVEL% neq 0 exit 1

:: Move dll files from %PREFIX%/Library/Lib to %PREFIX%/Library/Bin
:: This is needed for the python bindings to work

cd %LIBRARY_LIB%
move *.dll %LIBRARY_BIN%
