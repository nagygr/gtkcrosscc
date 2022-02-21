# Cross-compiling a GTK application

## Introduction

This repository creates a Fedora-based Docker image that can be used to
cross-compile GTK application on Linux to Windows. It installs the `mingw`
toolchain and a library (`pe-utils`) that makes it possible to acquire the DLL
dependencies of the executable (similarly to how the `ldd` command lists the SO
dependencies of a Linux executable).

The result of the compilation is a `package` folder in the project root that
will contain the executable and all the DLL and config file dependencies that
are needed to run it. Then entire folder should be distributed as the executable
is dynamically linked and will not work if a system lacks the required DLLs.

The image uses CMAKE to build the application, so you will need to create a
`CMakeLists.txt` for your project. An example is included here. The basic
project file is platform agnostic so it can be used to build the project for
Linux. It is the `toolchain_mingw.cmake` that adds the `mingw` toolchain and
thus the Windows-related settings.

The process consists of three steps, the last two of which need to be performed
in the project's root directory. All of the can be done there so I suggest you
enter the project root and work there.

This project is based on the work done [here][1].

## Requirements

As mentioned earlier, the project is Docker-based, so Docker needs to be
installed and running on the system for it work. Installation is OS and
distribution dependent.

On a Linux with `systemd` start Docker by issuing:

```bash
sudo systemctl start Docker
```

The project also requires CMAKE.

GTK doesn't have to be installed on the host system, although that makes
development easier.

## Compilation

1.	Start Docker.

2.	Enter the project root.

3.	Run the following command to create the Docker image. This only needs to be
	done once on a machine (or whenever the Dockerfile changes):

	```bash
	docker build . -t cppcc
	```

	The name of the image (`cppcc`) can be changed freely.

4.	Run the following command once per project	(or whenever the Dockerfile changes):

	```bash
	docker create -v $(pwd):/home/crosscc/src --name cppcc_gtk cppcc:latest
	```

	The name (´cpcc_gtk´) can be freely changed -- please note that the names
	are used in several commands so any change shall be made in all of them
	accordingly.

5.	Issue the following command every time the project needs to be rebuilt:

	```bash
	docker start -ai cppcc_gtk
	```

6.	If there were no compilation errors, the build should be available in the
	`package` directory together with all of its dependencies.

## Appendix

### Compiling pe-utils on Arch Linux

The pe-utils project can be used to find the dynamic dependencies of a
cross-compiled Windows executable. It doesn't compile on Arch by default
though, as the path of the directory that holds the mingw dlls is different.

The following simple patch (`fix_path.patch`) solves this:

```patch
diff --git a/peldd.cc b/peldd.cc
index d8ba233..87c517b 100644
--- a/peldd.cc
+++ b/peldd.cc
@@ -258,10 +258,10 @@ struct Arguments {
   deque<string> search_path;
   bool no_default_search_path {false};
   const array<const char*, 1> mingw64_search_path = {{
-    "/usr/x86_64-w64-mingw32/sys-root/mingw/bin"
+    "/usr/x86_64-w64-mingw32/bin"
   }};
   const array<const char*, 1> mingw64_32_search_path = {{
-    "/usr/i686-w64-mingw32/sys-root/mingw/bin"
+    "/usr/i686-w64-mingw32/bin"
   }};
   unordered_set<string> whitelist;
   const array<const char*, 36> default_whitelist = {{
```

In order to compile the project, issue the commands below:

```bash
git clone https://github.com/gsauthof/pe-util
cd pe-util
git submodule update --init
git apply fix_path.patch
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
```

The executable will be available at: `build/peldd`. You can use it by issueing:

```bash
peldd -t --ignore-errors <path-to-exe>
```

[1]: https://github.com/etrombly/rust-crosscompile.git
