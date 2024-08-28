#!/bin/bash
#
if [ "$2" == "" ]; then
    echo usage: $0 \<Module\> \<Branch\> \<Workspace\> [\<BUILD_USER_ID\>] [\<D\>] [\<REASON\>]
    exit -1
else
    versionProperties=install/version.properties
    theDate=\#$(date +"%c")
    module=$1
    branch=$2
    workspace=$3
    BUILD_USER_ID=$4
    REASON=$5
	lxb=/proj/eiffel013_config/fem101/jenkins_home/bin/lxb
    CT=/usr/atria/bin/cleartool
	release_area=/home/$USER/eniq_events_releases
	pkg_dir="$PWD"
fi


function getReason {
        if [ -n "$REASON" ]; then
		REASON=`echo $REASON | sed 's/$\ /x/'`
		REASON=`echo JIRA:::$REASON | sed s/" "/,JIRA:::/g`
        else
                REASON="CI-DEV"
        fi
}

function getProductNumber {
        product=`cat $PWD/build.cfg | grep $module | grep $branch | awk -F " " '{print $3}'`
	tag_product=`echo $product | sed 's/\//_/g'`
}

function setRstate {
        revision=`cat $PWD/build.cfg | grep $module | grep " $branch " | awk -F " " '{print $4}'`

        if git tag | grep $tag_product-$revision; then
                rstate=`git tag | grep ${tag_product}-${revision} | tail -1 | sed s/.*-// | perl -nle 'sub nxt{$_=shift;$l=length$_;sprintf"%0${l}d",++$_}print $1.nxt($2) if/^(.*?)(\d+$)/';`
        else
                ammendment_level=01
                rstate=$revision$ammendment_level
       	fi
}


function getSprint {
        sprint=`cat $PWD/build.cfg | grep $module | grep $branch | awk -F " " '{print $5}'`
}

function getSprint1 {
        sprint_stats=`cat $PWD/build.cfg | grep $module | grep 15.2 | awk -F " " '{print $5}'`
}


function deliver {
	echo "Running command: /vobs/dm_eniq/tools/scripts/deliver_eniq -auto events $sprint $REASON N $BUILD_USER_ID $product NONE $pkg_dir/$pkg"
	$CT setview -exec "cd /vobs/dm_eniq/tools/scripts;./deliver_eniq -auto events $sprint $REASON N $BUILD_USER_ID $product NONE $pkg_dir/$pkg" deliver_ui
	$CT setview -exec "cd /vobs/dm_eniq/tools/scripts;./deliver_eniq -auto stats $sprint_stats $REASON N $BUILD_USER_ID $product NONE $pkg_dir/$pkg" deliver_ui
}

function getSprint1 {
        sprint_stats=`cat $PWD/build.cfg | grep $module | grep 15.2 | awk -F " " '{print $5}'`
}
getSprint
getSprint1
getProductNumber
getReason
echo "PRODUCTTAG = $tag_product"
setRstate
echo "RSTATE = $rstate "
git clean -df
git checkout $branch
git pull


echo "Building for Sprint:$sprint"
echo "Building assuremonitoring_installer_$rstate on $branch"
echo "Building rstate: $rstate"

$lxb mvn clean install

 git tag $tag_product-$rstate
 git pull
 git push --tag origin $branch
 
 cd $PWD
 mv $PWD/target/assuremonitoring_install_script.zip $PWD/assuremonitoring_install_script_$rstate.zip
 cp assuremonitoring_install_script_$rstate.zip $release_area/assuremonitoring_install_script_$rstate.zip

#if [ "${deliver}" == "Y" ] ; then
#	echo "Running delivery..."
#	getREASON
#	echo "$pkg_dir/assuremonitoring_install_script_$rstate.zip"
#	echo "Sprint: $sprint"
#	echo "BUILD_USER_ID: $BUILD_USER_ID"
#	echo "Product Number: $product"
#	echo "Running command: /vobs/dm_eniq/tools/scripts/deliver_eniq -auto events $sprint $REASON N $BUILD_USER_ID $product NONE $pkgReleaseArea/assuremonitoring_install_script_$rstate.zip"
#	$CT setview -exec "/proj/eiffel013_config/fem101/jenkins_home/bin/lxb /vobs/dm_eniq/tools/scripts/deliver_eniq -auto events $sprint $REASON N $BUILD_USER_ID $product NONE $pkg_dir/assuremonitoring_install_script_$rstate.zip" deliver_ui
#	$CT setview -exec "/proj/eiffel013_config/fem101/jenkins_home/bin/lxb /vobs/dm_eniq/tools/scripts/deliver_eniq -auto stats ${sprint_stats} ${REASON} N ${BUILD_USER_ID} ${product} NONE $pkg_dir/assuremonitoring_install_script_$rstate.zip" deliver_ui
#fi

if "${Deliver}"; then
    if [ "${DELIVERY_TYPE}" = "SPRINT" ]; then
    $CT setview -exec "/proj/eiffel013_config/fem101/jenkins_home/bin/lxb /vobs/dm_eniq/tools/scripts/deliver_eniq -auto events ${sprint} ${REASON} Y ${BUILD_USER_ID} ${product} NONE $pkg_dir/assuremonitoring_install_script_$rstate.zip" deliver_ui
    $CT setview -exec "/proj/eiffel013_config/fem101/jenkins_home/bin/lxb /vobs/dm_eniq/tools/scripts/deliver_eniq -auto stats ${sprint_stats} ${REASON} N ${BUILD_USER_ID} ${product} NONE $pkg_dir/assuremonitoring_install_script_$rstate.zip" deliver_ui
else
    $CT setview -exec "/proj/eiffel013_config/fem101/jenkins_home/bin/lxb /vobs/dm_eniq/tools/scripts/eu_deliver_eniq -EU events ${sprint} ${REASON} Y ${BUILD_USER_ID} ${product} NONE $pkg_dir/assuremonitoring_install_script_$rstate.zip" deliver_ui
    fi
else
   echo "The delivery option was not selected.."
    fi
exit $rsp
