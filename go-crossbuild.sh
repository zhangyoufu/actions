#!/bin/sh

cd -- "$(dirname -- "$0")"

## set architecture-specific Go environment variables
## based on Dockerfile TARGETARCH / TARGETVARIANT environment variables
## for Go project cross compiling

if [ -n "${TARGETOS}" ]; then
	if [ "${TARGETOS}" != "linux" ]; then
		echo 'This script only supports Linux when building for Docker image.'
		exit 1
	fi
	export GOOS=${TARGETOS}
fi

if [ -n "${TARGETARCH}" ]; then
	# https://github.com/golang/go/blob/0f6ee42fe063a48d7825bc03097bbb714aafdb7d/test/run.go#L1599-L1613
	export GOARCH=$TARGETARCH
	case $TARGETARCH in
		386)
			# defaults to sse2 if unset
			export GO386=$TARGETVARIANT
		;;
		amd64)
			# defaults to v1 if unset
			export GOAMD64=$TARGETVARIANT
		;;
		arm)
			# https://github.com/containerd/containerd/blob/4902059cb554f4f06a8d06a12134c17117809f4e/platforms/cpuinfo.go#L113-L128
			# https://github.com/golang/go/wiki/GoArm
			case $TARGETVARIANT in
				'')
					# When the Go tools are built on an arm system,
					# the default value is set based on what the build system supports.
					# When the Go tools are not built on an arm system
					# (that is, when building a cross-compiler),
					# the default value is 7.
					# We simply hardcode to 7 here.
					export GOARM=7
				;;
				v7|v6|v5)
					# 5 defaults to softfloat
					# 6 and 7 default to hardfloat
					export GOARM=${TARGETVARIANT#v}
				;;
				*)
					echo "unknown TARGETVARIANT=$TARGETVARIANT for TARGETARCH=$TARGETARCH"
					exit 1
				;;
			esac
		;;
		arm64)
			case $TARGETVARIANT in
				'') # default value
					export GOARM64=v8.0
				;;
				v8)
					export GOARM64=v8.0
				;;
				v9)
					export GOARM64=v9.0
				;;
				*)
					echo "unknown TARGETVARIANT=$TARGETVARIANT for TARGETARCH=$TARGETARCH"
					exit 1
				;;
			esac
		;;
		mips|mipsle)
			# defaults to hardfloat if unset
			export GOMIPS=$TARGETVARIANT
		;;
		mips64|mips64le)
			# defaults to hardfloat if unset
			export GOMIPS64=$TARGETVARIANT
		;;
		ppc64|ppc64le)
			# defaults to power8 if unset
			export GOPPC64=$TARGETVARIANT
		;;
		s390x|riscv64|loong64)
			if [ -n "$TARGETVARIANT" ]; then
				echo "unknown TARGETVARIANT=$TARGETVARIANT for TARGETARCH=$TARGETARCH"
				exit 1
			fi
		;;
		*)
	esac
fi

if [ $# -ge 2 ] && [ "$1" = -C ]; then
	## -C flag must be first flag on command line
	cd -- "$2"
	shift 2
fi
go build -ldflags="-s -w" -trimpath "$@"
