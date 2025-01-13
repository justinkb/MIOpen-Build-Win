# MIOpen for Windows

Using the instructions below one can build MIOpen for Windows using the AMD HIP SDK.

## Getting Started

### Dependencies

You need to have Docker Windows Containers set up. You need to accept the license for and download AMD HIP SDK 24.Q4.
You need to clone this repository.

### Create the container

Make sure it has plenty memory for the build.

```
docker run --name miopen-build --memory 16G -it mcr.microsoft.com/windows/servercore:ltsc2022
```

Inside the container, create our working directory, then immediately exit it, leaving it stopped.
This is necessary because on Windows, we can't "docker cp" things into a running container.

```
mkdir \dev\
exit
```

### Copy over a few things

Back on the host, there's some stuff you will need to manually download and copy over.
Make sure you accept the licenses of all this stuff.
The last two directories contain (sometimes slightly patched versions of) a few missing CMake and header files from a Linux install of ROCm 6.2.3.
You can easily check out what changes were made by diffing.
From the CMake files, only some of the amd_comgr bits were patched.
From the include files, nothing needed patching. (It's actually just one missing file that was needed.)
[This commit](https://github.com/justinkb/MIOpen-Build-Win/commit/b541f855b6b79a29fc3681fc6ea78c2f66d49d96) on this repository shows you all changes.

```
docker cp .\AMD-Software-PRO-Edition-24.Q4-Win10-Win11-For-HIP.exe miopen-build:\dev
docker cp .\rocm-includes\ miopen-build:\dev
docker cp .\rocm-cmake\ miopen-build:\dev
```

### Start the container again

We are ready to enter back into the container.

```
docker start miopen-build
docker attach miopen-build
```

### Download some development tools

We need to download Visual Studio build tools, a Perl distribution and Git LFS.

```
cd \dev\
curl -SL --output vs_buildtools.exe https://aka.ms/vs/17/release/vs_Community.exe
curl -SL --output perl.zip https://github.com/StrawberryPerl/Perl-Dist-Strawberry/releases/download/SP_54001_64bit_UCRT/strawberry-perl-5.40.0.1-64bit-portable.zip
curl -SL --output git-lfs-windows.exe https://github.com/git-lfs/git-lfs/releases/download/v3.6.0/git-lfs-windows-v3.6.0.exe
```

Next step is installing these tools, as well as the HIP SDK. We install the Perl distribution later, because we can extract the zip file faster that way.

```
start /w vs_buildtools.exe --quiet --wait --norestart --nocache ^
    --add Microsoft.VisualStudio.Workload.NativeDesktop;includeRecommended ^
    --remove Microsoft.VisualStudio.Component.Windows10SDK.18362 ^
    --remove Microsoft.VisualStudio.Component.Windows10SDK.19041 ^
    --remove Microsoft.VisualStudio.Component.Windows10SDK.20348 ^
    --add Microsoft.VisualStudio.Component.Git
set PATH=C:\Program Files\Git\mingw64\bin;%PATH%
start /w git-lfs-windows.exe /silent
set PATH=C:\Program Files\Git LFS;%PATH%
git lfs install
start /w AMD-Software-PRO-Edition-24.Q4-Win10-Win11-For-HIP.exe -install
```

### Download and bootstrap vcpkg and boost

We will use vcpkg later in the process to install packages that are build dependencies for MIOpen.

```
git clone --depth 1 --branch 2024.12.16 https://github.com/microsoft/vcpkg.git
cd .\vcpkg\
.\bootstrap-vcpkg.bat
cd ..
git clone --depth 1 --branch boost-1.87.0 --recursive https://github.com/boostorg/boost.git boost_1_87_0
cd .\boost_1_87_0\
.\bootstrap.bat
.\b2.exe
cd ..
```

### Clone half and MIOpen repositories

We also grab the ROCm half header-only library and correct its directory structure.
Finally, we clone the MIOpen repository.

```
git clone --depth 1 --branch rocm-6.2.4 https://github.com/ROCm/half.git
mkdir .\half-pkg\include\half\
copy .\half\include\half.hpp .\half-pkg\include\half\
git clone --branch rocm-6.2.4 --recursive https://github.com/ROCm/MIOpen.git
```

## Readying the build

### Enter the PowerShell and source the VS Dev Shell stuff

```
powershell
```

Now we are in the PowerShell environment.

```
cd "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\"
.\Launch-VsDevShell.ps1 -Arch amd64
cd \dev\
```

### Make Perl available and install dependencies using vcpkg

We extract Perl using this trick, because Expand-Archive from the PowerShell Archive module is extremely slow.
We set some environment variables to ensure we use vcpkg in classic mode for ease of use.
We install sqlite3, bzip2, nlohmann_json and zstd packages with vcpkg.

```
Add-Type -Assembly "System.IO.Compression.Filesystem"
[System.IO.Compression.ZipFile]::ExtractToDirectory("c:\dev\perl.zip", "c:\dev\perl")
$env:PATH="c:\dev\vcpkg;${env:PATH}"
$env:VCPKG_ROOT="c:\dev\vcpkg"
vcpkg install sqlite3:x64-windows-release
vcpkg install bzip2:x64-windows-release
vcpkg install nlohmann-json:x64-windows-release
vcpkg install zstd:x64-windows-release
```

### Prepare the environment variables for the build

We set a variable that holds the location of the HIP SDK.
We need Perl on the PATH, provided by the portable Strawberry Perl distribution we extracted earlier.
We also need bzcat.exe on the path, so we copy it from bzip2.exe and add the tools directory of the bzip2 vcpkg.

```
$env:HIP_PATH="C:\Program Files\AMD\ROCm\6.2\"
$env:PATH+=";C:\dev\perl\c\bin;C:\dev\perl\perl\bin;C:\dev\perl\perl\site\bin"
copy .\vcpkg\packages\bzip2_x64-windows-release\tools\bzip2\bzip2.exe .\vcpkg\packages\bzip2_x64-windows-release\tools\bzip2\bzcat.exe
$env:PATH+=";C:\dev\vcpkg\packages\bzip2_x64-windows-release\tools\bzip2"
```

### Configure the build

We are ready to configure the build. Adjust the gfx1100 in the command to target your GPU.
I tried to keep every feature that would reasonably be buildable on Windows enabled.
Some stuff had to be disabled, like composable_kernel, rocMLIR, etc.

```
cd .\MIOpen\
cmake -G Ninja `
    -DCMAKE_C_COMPILER:FILEPATH="${env:HIP_PATH}bin\clang.exe" `
    -DCMAKE_CXX_COMPILER:FILEPATH="${env:HIP_PATH}bin\clang++.exe" `
    -DCMAKE_HIP_ARCHITECTURES:STRING="gfx1100" `
    -DCMAKE_BUILD_TYPE:STRING="Release" `
    -DCMAKE_PREFIX_PATH:STRING="C:\Program Files\AMD\ROCm\6.2;C:\dev\rocm-cmake;C:\dev\vcpkg\packages\sqlite3_x64-windows-release;C:\dev\vcpkg\packages\bzip2_x64-windows-release;C:\dev\vcpkg\packages\nlohmann-json_x64-windows-release;C:\dev\boost_1_87_0\stage;c:\dev\vcpkg\packages\zstd_x64-windows-release" `
    -DMIOPEN_USE_COMPOSABLEKERNEL:BOOL=FALSE `
    -DMIOPEN_USE_MLIR:BOOL=FALSE `
    -DMIOPEN_ENABLE_AI_KERNEL_TUNING:BOOL=FALSE `
    -DMIOPEN_ENABLE_AI_IMMED_MODE_FALLBACK:BOOL=FALSE `
    -DBoost_COMPILER:STRING="vc143" `
    -DHALF_INCLUDE_DIR:FILEPATH="C:\dev\half-pkg\include" `
    -DBUILD_TESTING:BOOL=FALSE `
    -DMIOPEN_BUILD_DRIVER:BOOL=FALSE `
    -S . -B build
```

### Do the build and prepare the package output

We need one more thing added to PATH to do the build, namely sqlite3.dll

```
$env:PATH+=";C:\dev\vcpkg\packages\sqlite3_x64-windows-release\bin"
```

Now we are ready for building. Adjust the -j16 parameter as fits your system.

```
cmake --build build -- -j16
```

Install the build products into a prefix

```
cd .\build\
cmake --install . --prefix ..\dist
```

### Exit the PowerShell and the container

The first exit puts us back into the cmd.exe shell.

```
exit
```

The second puts us back onto the host machine shell.

```
exit
```

### Copy over the build products on the host

```
docker cp miopen-build:\dev\MIOpen\dist c:\temp\MIOpen
```