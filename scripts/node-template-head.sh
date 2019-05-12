#!/usr/bin/env bash
set -e
export TERM=xterm

COLOR_WHITE=$(tput setaf 7);
COLOR_MAGENTA=$(tput setaf 5);
FONT_BOLD=$(tput bold);
FONT_NORMAL=$(tput sgr0);

echo
echo -e "$COLOR_WHITE $FONT_BOLD Substrate Node Template HEAD Setup $FONT_NORMAL";

name=$1
author=$2

if [[ "$name" == "" || "$name" == "-"* ]]
then
  echo "  Usage: node-template-head <NAME> <AUTHOR>"
  echo
  exit 1
fi
if [[ "$author" == "" || "$author" == "-"* ]]
then
  echo "  Usage: node-template-head <NAME> <AUTHOR>"
  echo
  exit 1
fi

lname="$(echo $name | tr '[:upper:]' '[:lower:]')"
dirname="${lname// /-}"

if [ -d "$dirname" ]; then
  echo "  Directory '$name' already exists!"
  echo
  exit 1
fi

echo "* Building new node template with name '$name' for current revision in folder '$dirname'"

PROJECT_ROOT=`git rev-parse --show-toplevel`
PATH_TO_ARCHIVE=$(pwd)/node-new.tar.gz

cd $PROJECT_ROOT/scripts/node-template-release/
cargo run $PROJECT_ROOT/node-template $PATH_TO_ARCHIVE

# extract the archive
tar xzf $PATH_TO_ARCHIVE 

mv substrate-node-template $dirname

pushd $dirname > /dev/null

echo "${FONT_BOLD}Customizing project...${FONT_NORMAL}"
function replace {
	find_this="$1"
	shift
	replace_with="$1"
	shift
	IFS=$'\n'
	TEMP=$(mktemp -d "${TMPDIR:-/tmp}/.XXXXXXXXXXXX")
	rmdir $TEMP
	for item in `find . -type f`
	do
		sed "s/$find_this/$replace_with/g" "$item" > $TEMP
		cat $TEMP > "$item"
	done
	rm -f $TEMP
}
replace "Template Node" "${name}"
replace node-template "${lname//[_ ]/-}"
replace node_template "${lname//[- ]/_}"
replace Anonymous "$author"

echo "${FONT_BOLD}Initializing WebAssembly build environment...${FONT_NORMAL}"
./scripts/init.sh  > /dev/null 2>&1
./scripts/build.sh > /dev/null 2>&1

echo "${FONT_BOLD}Building node...${FONT_NORMAL}"
cargo build --release

echo
echo "${FONT_BOLD}Chain client created in ${dirname}${FONT_NORMAL}."
echo "To start a dev chain, run:"
echo "$ $dirname/target/release/${lname//[_ ]/-} --dev"
echo

popd > /dev/null

