#!/bin/sh
# 功能: 为掌链平台负责的五个仓库批量创建新的迭代版本分支, 更新分支版本号, 并提交代码到 gerrit.
# 使用方法:
# 方法一: sh createHomelinkBranch.sh
# 根据引导提示输入新版本号和老版本号, 格式如 9.2.0, 版本号中不要带 feature/2nd- 的前缀, 脚本会自动处理.
# 指定老版本号的作用是, 将基于老版本号的分支来创建新版本号的分支.
#
# 方法二: sh createHomelinkBranch.sh -n {新版本号} -o {老版本号}, 如:
# sh createHomelinkBranch.sh -n 9.2.6 -o 9.2.4
#
# 以上命令可在任意掌链仓库目录内运行, 请确保你有将新建分支 push 到 remote 的权限.
#
export PATH

#准备阶段, 切到最近的分支, 并检查本地分支是否是干净的
function prepare()
{
	echo "checking $1 ..."
	cd "$PROJECTS_PATH/$1"
	if [ $? -ne 0 ]; then
		echo "未找到 $1 仓库目录, 请确保所有仓库与 lianjia_homelink_project 在同一个目录下"
		exit 1
	fi
	BRANCH_PREX="feature/2nd-"

	if [ -n "$(git status --porcelain)" ]; then
		echo "$1 有尚未保存的代码, 请保存代码后重试"
		exit 1
	fi
	#切换到最近的版本分支并更新代码
	LAST_BRANCH=$BRANCH_PREX$OLD_VERSION
	CURRENT_BRANCH=`git branch | grep "*" | awk '{print $2}'`
	if [[ $LAST_BRANCH != $CURRENT_BRANCH ]]; then
		git checkout $LAST_BRANCH || exit 1
	fi

	git fetch && git pull --rebase || exit 1
	LOCAL_COMMITS=`git log --pretty=format:"%s" origin/$LAST_BRANCH..HEAD`
	if [[ $LOCAL_COMMITS != "" ]]; then
		echo "$1 中存在尚未入库的本地修改, 请解决掉再重新运行此脚本"
		exit 1
	fi
}

function createBranch()
{
	cd "$PROJECTS_PATH/$1"
	isMainProject=$(pwd | grep lianjia_homelink_project)

	BRANCH_PREX="feature/2nd-"

	#创建分支
	git rev-parse --verify origin/$BRANCH_PREX$NEW_VERSION &> /dev/null
	if [[ $? == 0 ]];then
		echo "$1 仓库已经存在分支 $BRANCH_PREX$NEW_VERSION, 忽略创建"
		git checkout $BRANCH_PREX$NEW_VERSION || exit 1
	else
		git checkout -b $BRANCH_PREX$NEW_VERSION || exit 1
		#推送新建分支到远端
		git push --set-upstream origin $BRANCH_PREX$NEW_VERSION
		if [ $? -ne 0 ]; then
			echo "创建分支失败, 请检查是否有权限将分支 push 到 remote"
			# 回滚
			git checkout -  && git branch -D $BRANCH_PREX$NEW_VERSION
			exit 1
		fi
	fi

	for file in `ls .`
    do
        if([ -d $file ] && [ -f "$file/gradle.properties" ]); then
        	#更新maven 库版本
        	sed -i '' "s/PROJ_VERSION=.*/PROJ_VERSION=$NEW_VERSION-SNAPSHOT/g" $file/gradle.properties
        	isMavenLib="_"
        fi
    done

	FIRST_V=` echo $NEW_VERSION | cut -d '.' -f 1 `
	MID_V=` echo $NEW_VERSION | cut -d '.' -f 2 `
	LAST_V=` echo $NEW_VERSION | cut -d '.' -f 3 `
    if [[ $isMainProject != "" ]]; then
    	#更新 ng 中的插件版本配置
    	sed -i '' "s/feature\/2nd-$OLD_VERSION/feature\/2nd-$NEW_VERSION/g" plugin_config.json
        sed -i '' "s/\"branch\": \"dev-.*\",/\"branch\": \"dev-$BEIKE_VERSION\",/g" plugin_config.json

        #更新 midlib 库版本号
		sed -i '' "s/ljmid.*: '$OLD_VERSION.*$/ljmid                       : '$NEW_VERSION-SNAPSHOT',/g" config.gradle
        #更新 uilib 公共库版本号
		sed -i '' "s/uilib.*-SNAPSHOT.*$/uilib                       : '$BEIKE_VERSION.0-SNAPSHOT',/g" config.gradle

		#更新 versionCode
		if [ "$MID_V" -gt 9 ]; then
			VERSION_CODE=$FIRST_V$MID_V$LAST_V"999"
		else
			VERSION_CODE=$FIRST_V"0"$MID_V$LAST_V"999"
		fi
		sed -i '' "s/versionCode =.*$/versionCode = $VERSION_CODE/g" build.gradle
		#更新 versionName
		sed -i '' "s/versionName =.*$/versionName = \"$NEW_VERSION.-1\"/g" build.gradle
	fi
	# 提交代码
	if [ -n "$(git status --porcelain)" ]; then
		git add . && git commit -m "[Change]: [$NEW_VERSION]-[更新分支版本号]autoUpdateVersion"
		sh review || exit 1
	fi
}
#create branch funciton end

function updateConfigRepo()
{
	if [[ ! -d "$PROJECTS_PATH/platc_base_deps_config/" ]]; then
		echo "未在本地找到 platc_base_deps_config 仓库，开始自动下载..."
		git clone git@git.lianjia.com:mobile_android/platc_base_deps_config.git
	fi
	echo "updateConfigRepo start..."

	echo "updateConfigRepo end"
	exit 1
}

#main
while getopts ":n:o:" opt
do
    case $opt in
        n)
        NEW_VERSION=$OPTARG
        ;;

        o)
        OLD_VERSION=$OPTARG
        ;;

        ?)
        echo "未知参数, 参数使用方法: -n {NEW_VERSION} -o {OLD_VERSION}"
        exit 1;;
    esac
done

if [ -z "$NEW_VERSION" ]; then
	read -p "请输入要创建的掌链新分支的版本号: " NEW_VERSION
fi

if [[ ! "$NEW_VERSION" =~ ^([0-9]{1,3}.){2}[0-9]{1,3}$ ]]; then
	echo "$NEW_VERSION 不是合法的版本号, 格式应该类似 9.2.0"
	exit 1
fi

if [ -z "$OLD_VERSION" ]; then
	read -p "请输入要基于哪个版本号的分支来创建新分支: " OLD_VERSION
fi

if [[ ! "$OLD_VERSION" =~ ^([0-9]{1,3}.){2}[0-9]{1,3}$ ]]; then
	echo "$OLD_VERSION 不是合法的版本号, 格式应该类似 9.2.0"
	exit 1
fi

if [ -z "$BEIKE_VERSION" ]; then
	read -p "请输入掌链迭代版本对应贝壳的版本号: " BEIKE_VERSION
fi

if [[ ! "$BEIKE_VERSION" =~ ^([0-9]{1,3}.){2}[0-9]{1,3}$ ]]; then
	echo "$BEIKE_VERSION 不是合法的版本号, 格式应该类似 2.25.0"
	exit 1
fi

#get host project parent path
PROJECTS_PATH=`pwd`
while [ ! -d "$PROJECTS_PATH/lianjia_homelink_project" ]
do
	PROJECTS_PATH="$(dirname $PROJECTS_PATH)"
	if [ $PROJECTS_PATH = "/" ]; then
		break;
	fi
done

if [[ ! -d "$PROJECTS_PATH/lianjia_homelink_project" ]]; then
	echo "请在任意掌链 project 目录内执行此脚本."
	exit 1
fi
cd $PROJECTS_PATH

updateConfigRepo

#掌链 project 数组
project_array=(lianjia_android_midlib lianjia_android_merchandise \
	lianjia_android_content lianjia_android_customer lianjia_android_secondhouse \
	lianjia_homelink_project)

for project in ${project_array[*]}
	do
		prepare $project
	done

for project in ${project_array[*]}
	do
		echo "start create branch for $project"
		createBranch $project
		echo "end create branch for $project"
	done

echo "执行成功, 新版本分支已创建, 请在 gerrit 上 review 代码~~~"
