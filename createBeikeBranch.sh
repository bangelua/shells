#!/bin/sh
# 功能: 为贝壳平台组负责的七个仓库批量创建新的迭代版本分支, 更新分支版本号, 并提交代码到 gerrit.
# 使用方法:
# 方法一: sh createBeikeBranch.sh
# 根据引导提示输入新版本号和老版本号, 格式如 2.8.0, 版本号中不要带 dev- 的前缀, 脚本会自动处理.
# 指定老版本号的作用是, 将基于老版本号的分支来创建新版本号的分支.
#
# 方法二: sh createBeikeBranch.sh -n {新版本号} -o {老版本号}, 如:
# sh createBeikeBranch.sh -n 2.9.0 -o 2.8.0
#
# 以上命令可在任意贝壳仓库目录内运行, 请确保你有将新建分支 push 到 remote 的权限.
#
export PATH

#准备阶段, 切到最近的分支, 并检查本地分支是否是干净的, 校验分支.
function prepare()
{
	echo "checking $1 ..."
	cd "$PROJECTS_PATH/$1"
	if [ $? -ne 0 ]; then
		echo "未找到 $1 仓库目录, 请确保所有仓库与宿主 beike_main_project 在同一个目录下"
		exit 1
	fi
	isMainProject=$(pwd | grep beike_main_project)
	BRANCH_PREX="dev-"

	if [ -n "$(git status --porcelain)" ]; then
		echo "$1 中有尚未保存的代码, 请保存代码后重试"
		exit 1
	fi

	#切换到最近的版本分支并更新代码
	LAST_BRANCH=$BRANCH_PREX$OLD_VERSION
	CURRENT_BRANCH=`git branch | grep "*" | awk '{print $2}'`
	if [[ $LAST_BRANCH != $CURRENT_BRANCH ]]; then
		git checkout $LAST_BRANCH
		if [ $? -ne 0 ]; then
			echo "切换分支失败, 请检查 $1 仓库中的分支 $LAST_BRANCH 是否存在."
			exit 1
		fi
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
	isMainProject=$(pwd | grep beike_main_project)

	BRANCH_PREX="dev-"

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
        	sed -i '' "s/PROJ_VERSION=.*/PROJ_VERSION=$NEW_VERSION.0-SNAPSHOT/g" $file/gradle.properties
        	isMavenLib="_"
        fi
    done

	FIRST_V=` echo $NEW_VERSION | cut -d '.' -f 1 `
	MID_V=` echo $NEW_VERSION | cut -d '.' -f 2 `
    if [[ $isMainProject != "" ]]; then
    	#更新 ng 中的插件版本配置
    	sed -i '' "s/dev-$OLD_VERSION/dev-$NEW_VERSION/g" plugin_config.json
		sed -i '' "s/dev-$OLD_VERSION/dev-$NEW_VERSION/g" diffluence_config.json

		#更新 versionCode
		MID_V_LEN=`echo $MID_V | awk '{print length($0)}'`
		if [ $MID_V_LEN -eq 1 ]; then
			VERSION_CODE=$FIRST_V"0"$MID_V"0999"
		else
			VERSION_CODE=$FIRST_V$MID_V"0999"
		fi
		sed -i '' "s/versionCode =.*$/versionCode = $VERSION_CODE/g" build.gradle
		#更新 versionName
		sed -i '' "s/versionName =.*$/versionName = \"$NEW_VERSION\"/g" build.gradle
	fi

	# 提交代码
	if [ -n "$(git status --porcelain)" ]; then
		git add . && git commit -m "[Change]: [$NEW_VERSION]-[更新分支版本号]autoUpdateVersion"
		sh review || exit 1
	fi
}
#create branch funciton end

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
	read -p "请输入要创建的贝壳新分支的版本号: " NEW_VERSION
fi

if [[ ! "$NEW_VERSION" =~ ^([0-9]{1,3}.){2}[0-9]{1,3}$ ]]; then
	echo "$NEW_VERSION 不是合法的版本号, 格式应该类似: 2.8.0"
	exit 1
fi

if [ -z "$OLD_VERSION" ]; then
	read -p "请输入要基于哪个版本号的分支来创建新分支: " OLD_VERSION
fi

if [[ ! "$OLD_VERSION" =~ ^([0-9]{1,3}.){2}[0-9]{1,3}$ ]]; then
	echo "$OLD_VERSION 不是合法的版本号, 格式应该类似: 2.8.0"
	exit 1
fi

#get host project parent path
PROJECTS_PATH=`pwd`
while [ ! -d "$PROJECTS_PATH/beike_main_project" ]
do
	PROJECTS_PATH="$(dirname $PROJECTS_PATH)"
	if [ $PROJECTS_PATH = "/" ]; then
		break;
	fi
done

if [[ ! -d "$PROJECTS_PATH/beike_main_project" ]]; then
	echo "请在任意贝壳 project 目录内执行此脚本."
	exit 1
fi
cd $PROJECTS_PATH

#贝壳 project 数组
project_array=(
	shared_uilib bk_android_bkbase \
	bk_android_platc bk_android_secondhouse \
	bk_identify_plugin bk_android_sharedbiz bk_android_wallet \
	beike_main_project)

for project in ${project_array[*]}
	do
		prepare $project
	done

for project in ${project_array[*]}
	do
		echo "start create branch for $project...\n"
		createBranch $project
		echo "end create branch for $project~~~\n"
	done

echo "执行成功, 新版本分支已创建, 请在 gerrit 上 review 代码~~~"
