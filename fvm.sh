# Flex Version Manager
# Implemented as a bash/zsh function
# To use, source this file from your bash/zsh profile
#
# Implemented by Chris O'Brien <chrisobr@gmail.com>
#
# Based heavily on (and with many thanks to) NVM:
# Implemented by Tim Caswell <tim@creationix.com>
# with much bash help from Matthew Ranney

# Place this script in $HOME/.fvm (or wherever you want $FVM_DIR to be)
# Add to your .bash_profile or .zshrc
#
#FVM_DIR=$HOME/.fvm
#
#if [ -s $FVM_DIR/fvm.sh ] ; then
#  source $FVM_DIR/fvm.sh
#  fvm use
#fi

ORIGINAL_FLEX_HOME=$FLEX_HOME
ORIGINAL_FLEX_SDK=$FLEX_SDK

fvm() {
	START=`pwd`
	MAJOR=3

	if [ $# -lt 1 ]; then
		fvm help
		return
	fi

	#some helper functions:

	unzip_with_progress() { #first arg is extract dir, second is zip
		width=$((${COLUMNS-$(tput cols)}-10))
		bar=$(while [[ $((--width)) -gt 0 ]]; do printf "="; done)
		barlength=${#bar}
		
		max_files=$(unzip -l $2 | tail -n 1 | awk '{print $2}') #how many files are in the zip (so we can show a percentage)
		i=0

		#using the -a flag so we extract to native text format. This avoids 'Bad Interpreter /bin/sh^M' messages,
		#and allows you to browse the frameworks easier, but it takes ages to extract
		unzip -ad $1 $2 | while read f; do
			percent="$((100*++i/max_files))%"
			n=$((barlength*i/max_files))
			printf "\r %4s [%-${barlength}s]" "$percent" "$(cutstr $bar $n)" 
		done

		echo
	}

	cutstr() {
		str=$1
		len=$2
		if [ $# -ne 2 ] || [[ $2 -eq 0 ]]; then		
			len=1
		fi

		#echo "${VERSION:0:1}" #bash only, wont work in zsh, which would be: echo "${VERSION[1,2]}"
		#so let's make it universal:

		echo $str | cut -c 1-$len
	}

	get_major() {  #takes a full version number as it's only argument and returns the first digit
		if [ `cutstr $1 3` = "4.5" ]; then
			echo "hero"
			return
		fi

		cutstr $1
	}

	#Convenience function that takes a non-full version and it tries to find a full version number that matches.
	get_version() {
		version=$1

		#if a full version string is supplied, just use that
		if [ ${#version} -gt 7 ]; then
			echo $version
		else
			#so, we get the version first from stable releases, then milestones, and if all else fails, nightlies.
			if [ ${#version} -eq 1 ]; then
				version="$version.0"
			fi

			major=$(get_major $version)

			full_version=$(fvm list-remote $major | awk -v "ver=^$version" '/Stable/, /Nightly/ { if ($1 ~ ver ) { print $1 } }' | head -n 1)

			if [[ $full_version = "" ]]; then
				#if not in the stable release, find it from anywhere (should be Milestone first, which is nice)
				full_version=$(fvm list-remote $major | awk -v "ver=^$version" '{ if ($1 ~ ver ) { print $1 } }' | head -n 1)
			fi

			echo $full_version
		fi
	}

	#return the matching zip file to download. We'll only get the open source frameworks (mpl)
	get_zip() { #takes a full version number as it's only argument
		if [ `get_major $1` = "hero" ]; then
			echo "flex_sdk_$1.zip"
			return
		fi

		echo "flex_sdk_$1_mpl.zip"
	}

	case $1 in
		"help" )
			cat <<-EOF
				Flex Version Manager

				Usage:
				  fvm help                (Show this message)
				  fvm install version     (Download and install a version)
				  fvm list                (Show all installed versions)
				  fvm list-remote [n]     (Show all versions available from adobe.com.
				                          Using \`n\` will show only version with major
				                          release number of n.)
				  fvm use version         (Set this version in the PATH)
				  fvm use                 (Use the latest stable version)
				  fvm deactivate          (Remove fvm entry from PATH)
				  fvm uninstall version   (Remove the SDK specified by version)
				  fvm clear-cache         (Clears fvms .cache directory)

				Example:
				  fvm install 3.4
				  fvm list-remote 4

				Note that fvm will expand version numbers for you. e.g.
				\`fvm install 3\` will install version 3.0.2.2113, and
				\`fvm install 4.1\` will install version 4.1.0.16076

				You can use this to make life easier if you don't need to be
				too specific
			EOF
		;;
		"install" )
			if [ $# -ne 2 ]; then
				fvm help
				return;
			fi

			# flex 3 downloads from: http://opensource.adobe.com/wiki/display/flexsdk/Download+Flex+3
			# flex 4 downloads from: http://opensource.adobe.com/wiki/display/flexsdk/Download+Flex+4
			# flex 4.5 (Hero) downloads from: http://opensource.adobe.com/wiki/display/flexsdk/Download+Flex+Hero

			# Downloads of the form: http://opensource.adobe.com/wiki/display/flexsdk/download?build=3.4.0.6955&pkgtype=2
			# (2 is for the open source sdk)
			# which translate to:
			# http://fpdownload.adobe.com/pub/flex/sdk/builds/flex'+release+'/'+pkgname+
			# e.g. http://fpdownload.adobe.com/pub/flex/sdk/builds/flex3/flex_sdk_3.4.1.10084_mpl.zip
			# no _mpl for the current Hero SDKS

			VERSION=$(get_version $2)

			if [[ $VERSION == "" ]]; then
				cat <<-EOF
					Oops. Couldn't find the version you're looking for.
					Try running \`fvm list-remote\` to see which versions are available
				EOF
				return
			fi

			ZIP=$(get_zip $VERSION)
			MAJOR=$(get_major $VERSION)

			#cache downloaded SDKs (likely not a needed feature, but nice when testing this...)
			mkdir -p "$FVM_DIR/.cache/zip"

			if [ -d "$FVM_DIR/sdks/$VERSION" ]; then
				echo "Flex SDK $VERSION is already installed"
				return
			fi

			mkdir -p "$FVM_DIR/sdks/$VERSION"

			if [ ! -s $FVM_DIR/.cache/zip/$ZIP ]; then
				curl -o $FVM_DIR/.cache/zip/$ZIP "http://fpdownload.adobe.com/pub/flex/sdk/builds/flex$MAJOR/$ZIP"
			fi

			echo "Extracting SDK. This may take a while"

			unzip_with_progress $FVM_DIR/sdks/$VERSION/ $FVM_DIR/.cache/zip/$ZIP

			for i in $FVM_DIR/sdks/$VERSION/bin/*; do chmod +x $i; done #we want to be able to run them...

			fvm use $VERSION
		;;
		"uninstall" )
			if [ $# -ne 2 ]; then
				echo "Do you want to uninstall all versions of Flex under fvm? [y/N]: "
				read answer
				if [[ $answer == "y" ]] || [[ $answer == "Y" ]]; then
					rm -rf $FVM_DIR/sdks
					echo "All SDKs uninstalled"
				fi

				return
			fi

			VERSION=$(get_version $2)

			if [ ! -d $FVM_DIR/sdks/$VERSION ]; then #not installed, so bail
				echo "SDK $VERSION is not installed"
				return
			fi

			rm -rf $FVM_DIR/sdks/$VERSION			
			echo "Removed SDK $VERSION"

			#if that was the version they were using, pick another one for them... (probs not a good idea)
			if [[ $PATH == *$FVM_DIR/sdks/$VERSION/bin* ]]; then
				fvm use
			fi
		;;
		"deactivate" )
			if [[ $PATH == *$FVM_DIR/*/bin* ]]; then
				export PATH=${PATH%$FVM_DIR/*/bin*}${PATH#*$FVM_DIR/*/bin:}
				echo "$FVM_DIR/*/bin removed from \$PATH"
			else
				echo "Could not find $FVM_DIR/*/bin in \$PATH"
			fi

			export FLEX_HOME=$ORIGINAL_FLEX_HOME
			export FLEX_SDK=$ORIGINAL_FLEX_SDK

			echo "Reset FLEX_HOME and FLEX_SDK."
		;;
		"use" )
			#just `fvm use` will pick the first sdk it finds and use that
			if [ $# -ne 2 ]; then
				for f in $FVM_DIR/sdks/*; do
					fvm use ${f##*/} > /dev/null
					return
				done
			fi

			if [[ $2 == "system" ]]; then
				fvm deactivate > /dev/null
				echo "Using system Flex SDK"
				return
			fi

			VERSION=$(get_version $2)

			if [ ! -d $FVM_DIR/sdks/$VERSION ]; then
				echo "$VERSION version is not installed yet"
				return;
			fi

			if [[ $PATH == *$FVM_DIR/sdks/*/bin* ]]; then
				PATH=${PATH%$FVM_DIR/sdks/*/bin*}$FVM_DIR/sdks/$VERSION/bin${PATH#*$FVM_DIR/sdks/*/bin}
			else
				PATH="$FVM_DIR/sdks/$VERSION/bin:$PATH"
			fi

			export PATH
			export FLEX_HOME="$FVM_DIR/sdks/$VERSION"
			export FLEX_SDK="$FVM_DIR/sdks/$VERSION"
			echo "Now using flex $VERSION"
		;;
		"list" )
			if [ $# -ne 1 ]; then
				fvm help
				return;
			fi

			for f in $FVM_DIR/sdks/*; do
				if [[ $PATH == *$f/bin* ]]; then
					echo "${f##*sdks/} *"
				else
					echo "${f##*sdks/}"
				fi
			done
		;;
		"list-remote" )
			which html2text 2>&1 > /dev/null

			if [ $? -ne 0 ]; then
				cat <<-EOF
					This system relies on html2text to process the pages from adobe.com.
					You can install using your package manager, e.g.
					(sudo) port install html2text
					(sudo) apt-get install html2text
					or see here: http://www.mbayer.de/html2text/
				EOF
				return;
			fi

			if [ $# -ne 2 ]; then
				for v in Hero 4 3; do #sdks to check against
					fvm list-remote $v
				done

				return
			else
				MAJOR=$2
				echo -e "\nFlex SDK $MAJOR"
			fi

			mkdir -p $FVM_DIR/.cache

			FLEX_LIST_CACHE=$FVM_DIR/.cache/flex_list_$MAJOR

			#if there's no list cache, or it's more than a day old, re-'parse' the website:
			if [ ! -s $FLEX_LIST_CACHE ] || find $FVM_DIR/.cache -depth 1 -ctime +1d | grep flex_list > /dev/null; then
				#some awful hackery to 'parse' their html...
				curl http://opensource.adobe.com/wiki/display/flexsdk/Download+Flex+$MAJOR 2>/dev/null \
				| html2text -ascii -nobs \
			 	| awk '/[Latest Milestone Release]|[Milestone Build]/, /Last Modified/ {
					if ( $0 ~ /^[0-9]+|Milestone|Stable|Nightly|Update/ ) {
						if ( $0 ~ /Milestone|Stable|Nightly/ ) { print ""	}

						if ( $0 ~ /Update/ ) {
							print $2
						} else if ( length($1) < 5 ) {
							printf("%s\t(%s)\n", $2, $1)
						} else {
							print $1
						}
					}
				}' |> $FLEX_LIST_CACHE

				touch $FLEX_LIST_CACHE #update the ctime
			fi

			cat $FLEX_LIST_CACHE
		;;
		"clear-cache" )
			rm -rf $FVM_DIR/.cache/*
			echo "Cache cleared"
		;;
		* )
			fvm help
		;;
	esac
}

