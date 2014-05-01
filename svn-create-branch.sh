#!/bin/sh

check_errs()
{
  # Function. Parameter 1 is the return code
  # Para. 2 is text to display on failure.
  if [ "${1}" -ne "0" ]; then
      echo "ERROR # ${1} : ${2}"
      # as a bonus, make our script exit with the right error code.
      exit ${1}
  fi
}

check_uncommitted()
{
    UNCOMMITTED=`svn st | grep "^[UGMC\?\!AD]"`
    if [ -n "$UNCOMMITTED" ]; then
        echo "You have some uncommitted files:"
        echo "$UNCOMMITTED"
        echo -n "Are you sure you want to continue? (y or n): "
        read CONTINUE
        case $CONTINUE in
            [yY]) break ;;
            * ) exit 0 ;;
        esac
    fi
}

if [ $# != 1 ]; then
    echo "";
    echo "";
    echo "      Usage";
    echo "      svn-create-branch.sh BRANCH_NAME";
    echo "";
    echo "      BRANCH_NAME - The name of the branch to be created e.g. style-tweaks";
    echo "";
    exit 1;
fi

svn info > /dev/null 2>&1
check_errs $? "Not a working directory!"

#get SVN URL
URL=`svn info | grep "^Repository Root:" | sed s/"Repository Root: "//g`

# check branches folder exists, if it doesnt then create it
BRANCHES_DIR=`svn ls $URL | grep "^branches"`
if [ -z "$BRANCHES_DIR" ]; then
    echo "Creating branches directory"
    svn mkdir ${URL}/branches -m "created branches directory to hold all the branches"
    check_errs $? "Could not make branches directory"
fi

# check to make sure branch doesn't already exist
BRANCH_EXISTS=`svn ls ${URL}/branches | grep "^${1}/$"`
if [ -n "$BRANCH_EXISTS" ]; then
    echo "Branch already exists!"
    exit 2;
fi

# create the branch
echo "Creating branch..."
svn cp ${URL}/trunk ${URL}/branches/${1} -m "created branch ${1}"
check_errs $? "Could not create new branch"

# are we switching to the branch?
echo "Branch created!"
echo -n "Would you like to switch to the branch? (y or n): "
read yn
case $yn in
    [yY]) break ;;
    * ) exit 0 ;;
esac

check_uncommitted

# switch to the branch
echo "Switching to branch..."
svn switch ${URL}/branches/${1}
check_errs $? "There was a problem switching"

echo "Done!"
exit 0
