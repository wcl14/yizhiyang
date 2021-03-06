export USER=`whoami`
system=`uname -s`
if [ $system == Linux ]; then
	shopt -s checkwinsize
	alias ls='ls --color'
else
	CLICOLOR=1 #for mac and BSD
	export LSCOLORS=gxfxcxdxbxegedabagacad
	if [ `which gls`_ == _ ]; then
		alias ls='ls -G'
	else
		alias ls='gls --color'
	fi
fi
HAWQ_SRC=~/dev/hawq
HORNET_SRC=~/dev/hornet

alias vi=vim
alias grep='grep --color'
alias psql="psql -P pager=off -v ON_ERROR_STOP=1 -v \"file_format=FORMAT 'orc'\""
alias mysql='mysql -h 127.0.0.1 -P 4000 -u root -D tpch'
alias catalog-dumper='~/dev/hornet/kv/build/examples/catalog-dumper'
export LANG=en_US
export LC_ALL=en_US.utf-8

ulimit -c 10000000000
export PGDATABASE=postgres

export CC=`which clang`
export CXX=`which clang++`
export DEPENDENCY_PATH=/opt/dependency/package
export DYLD_FALLBACK_LIBRARY_PATH=$DEPENDENCY_PATH/lib
export JAVA_LIBRARY_PATH=/opt/dependency/package/lib/:/usr/local/lib

export CPATH=$DEPENDENCY_PATH/include
export LIBRARY_PATH=$DEPENDENCY_PATH/lib

export GOPATH=~/dev/goprojects
export PATH=$HOME/yizhiyang/bin:$HOME/yizhiyang/usr/bin:/usr/local/sbin/:$GOPATH/bin/:$PATH

instrument() {
	instruments -l $1 -t Time\ Profiler -p `hawq-qe 2`
}
format-code() {
	git diff head --name-only| xargs clang-format -i -style=google
	git diff head --name-only| xargs cpplint.py
}
find-latest() {
	find . -iname $1 |xargs ls -ltr
}

lldb-latest() {
	if [ -n "$1" ]; then
		lldb -c `ls -rt /cores/core.$1.* | tail -n 1`
	else
		lldb -c /cores/`ls -rt /cores | tail -n 1`
	fi
}
alias lldb-recent='lldb -c /cores/`ls -rt /cores| tail -n 2| head -n 1`'
alias vi-latest='vi `ls -1t|head -1`'
alias cutf="tr -s ' '| cut -d ' ' -f "

alias log-tpch='cd ~/dev/hawq/src/test/feature/tpchtest'
alias log-segment='cd ~/hawq-data-directory/segmentdd/pg_log'
alias log-master='cd ~/hawq-data-directory/masterdd/pg_log'
alias log-hdfs='cd /usr/local/Cellar/hadoop/3.1.0/libexec/logs/'

alias vi-tpch='vi ~/dev/hawq/src/test/feature/tpchtest/tpchorc_newqe.xml'
alias oushu='source /usr/local/hawq/greenplum_path.sh && unset DYLD_LIBRARY_PATH'
alias apache-hawq='source /usr/local/apache-hawq/greenplum_path.sh'

alias server='ssh root@192.168.1.190'
alias aws1='lava ssh `ls -1 ~/.lava/machines/| grep "\-1"`'
alias aws2='lava ssh `ls -1 ~/.lava/machines/| grep "\-2"`'
alias aws3='lava ssh `ls -1 ~/.lava/machines/| grep "\-3"`'

alias spark-start='/usr/local/Cellar/apache-spark/2.2.0/libexec/sbin/start-master.sh && /usr/local/Cellar/apache-spark/2.2.0/libexec/sbin/start-slave spark://localhost:7077'
alias spark-sql='cd /tmp && spark-sql --driver-java-options "-Dlog4j.configuration=file:///usr/local/Cellar/apache-spark/2.2.0/bin/log4j.properties"'

alias apache-diff='git diff oushu/wcy-merge-apache'
alias apache-checkout='git checkout oushu/wcy-merge-apache'
alias fix='cp ~/FindSSL.cmake ./depends/libhdfs3/CMake/FindSSL.cmake && find . -name hawq_type_mapping.h| xargs rm'


#-------------------------------------------------------------------------------
#
# lava and ci
#
#-------------------------------------------------------------------------------
ci-get() {
	if [ -n "$1" ]; then
		lava scp -r \
		ciserver:/home/ec2-user/jenkins_home/.lava/machines/$1 \
		~/.lava/machines
	fi
	find ~/.lava -name *.json |xargs sed -i '' "s|/var/jenkins_home/|$HOME/|g"
	find ~/.lava -name *.json |xargs sed -i '' "s|/Users/[^/]*/|$HOME/|g"
}
ci-upload-lib() {
		local lib_path=~/dev-linux/dependency/package/lib
		case $2 in
		dbcommon)
			lava scp $lib_path/libdbcommon.so $1:/tmp/
		;;
		univplan)
			lava scp $lib_path/libunivplan.so $1:/tmp/
		;;
		interconnect)
			lava scp $lib_path/libinterconnect.so $1:/tmp/
		;;
		kv-client)
			lava scp $lib_path/libkv-client.so $1:/tmp/
		;;
		storage)
			lava scp $lib_path/libstorage.so $1:/tmp/
		;;
		executor)
			lava scp $lib_path/libexecutor.so $1:/tmp/
		;;
		kv-server)
			lava scp $lib_path/libkv-server.so $1:/tmp/
		;;
		*)
			lava scp $lib_path/libdbcommon.so $1:/tmp/
			lava scp $lib_path/libunivplan.so $1:/tmp/
			lava scp $lib_path/libinterconnect.so $1:/tmp/
			lava scp $lib_path/libkv-client.so $1:/tmp/
			lava scp $lib_path/libstorage.so $1:/tmp/
			lava scp $lib_path/libexecutor.so $1:/tmp/
			lava scp $lib_path/libkv-server.so $1:/tmp/
		esac
}
lava-clean() {
	nodes=`lava ls| grep Error| tr -s ' '| cut -d ' ' -f 1`
	for node in $nodes
	do
		echo $node
		find ~/.lava -name $node| xargs rm -rf
	done
}


#-------------------------------------------------------------------------------
#
#   magma
#
#-------------------------------------------------------------------------------
s-server() {
	cd $HORNET_SRC/kv/build && make -j8 simple_server && cd -
	rm -rf /tmp/rocksdata/*
	mkdir -p /tmp/rocksdata
	$HORNET_SRC/kv/build/examples/simple_server \
               -node node1 -listen 0.0.0.0:38324 \
               -locations file:///tmp/rocksdata 2>&1 |
		tee /tmp/server.log
}
s-client() {
	cd $HORNET_SRC/kv/build && make -j8 simple_client && cd -
	$HORNET_SRC/kv/build/examples/simple_client
}

#-------------------------------------------------------------------------------
#
# tidb/cockroach
#
#-------------------------------------------------------------------------------
tidb-start() {
	pd-server --data-dir=$HOME/tidb-data/pd --log-file=$HOME/tidb-data/pd.log &
	sleep 2
	tikv-server --pd="127.0.0.1:2379" --data-dir=$HOME/tidb-data/tikv --log-file=$HOME/tidb-data/tikv.log &
	sleep 2
	tidb-server --store=tikv --path="127.0.0.1:2379" --log-file=$HOME/tidb-data/tidb.log &
}
tidb-stop() {
	killall tidb-server
	killall tikv-server
	killall pd-server
}
cockroachdb-start() {
	cockroach start --store=$HOME/cockroach-data --insecure &
}
cockroachdb-stop() {
	killall cockroach
}



#-------------------------------------------------------------------------------
#
#   Hawq 
#
#-------------------------------------------------------------------------------
alias hawqps="ps -eo pid,ppid,start,%cpu,command|sort -k3,2|grep -E '([^ ]*[p]ostgres[ :]|[m]agma_server |[p]sql )'"
hawq-qe() {
	if [ -n "$1" ]; then
		ps -ef| grep [p]ostgres.*con.*seg| tr -s ' '| cut -d ' ' -f 3| 
		sort|head -n $1|tail -n 1
	else
		ps -ef| grep [p]ostgres.*con.*seg| tr -s ' '| cut -d ' ' -f 3|
		sort
	fi
}
hawq-qd() {
	ps -ef| grep [p]ostgres.*con.*cmd | tr -s ' '| cut -d ' ' -f 3
}
magma-clean() {
	killall -9 magma_server
	rm -rf /magma/magma_master/*
	rm -rf /magma/magma_segment/*
}
hawq-clean() {
	ps -ef|grep [p]ostgres|tr -s ' '| cut -d ' ' -f3|xargs kill -9
	rm -rf ~/hawq-*
	hdfs dfs -rmr /hawq_default*
	if [ $system == Linux ]; then
		rm -rf /data*/hawq/gsmaster/*
		rm -rf /data*/hawq/gssegment/*
		rm -rf /data1/hawq/master/*
		rm -rf /data2/hawq/segment/*
		rm -rf /data*/hawq/tmp/master/*
		rm -rf /data*/hawq/tmp/segment/*
		sudo -u hdfs hdfs dfs -rm -f -r /hawq_data
		sudo -u hdfs hdfs dfs -mkdir /hawq_data
		sudo -u hdfs hdfs dfs -chown gpadmin /hawq_data
	fi
}
hawq-init() {
	# rm -rf /cores/*
	magma-clean
	hawq-clean
	if [ $system == Darwin ]; then
		cp ~/yizhiyang/config/hawq-site.xml /usr/local/hawq/etc
	fi
	hawq init cluster -a
	hawq-setup-feature-test
}
magma-join() {
	rm -rf /magma/magma_segment1/*
	rm -rf /magma/magma_segment2/*
	rm -rf /magma/magma_segment3/*
	rm -rf /magma/magma_log1/*
	rm -rf /magma/magma_log2/*
	rm -rf /magma/magma_log3/*
	/opt/dependency/package/bin/magma_server \
		--listen=0.0.0.0:400010 \
		--join=0.0.0.0:40005 \
		--locations=file:///magma/magma_segment1 \
		--clusterhosts=/tmp/magma_host1 \
		--logdir=/magma/magma_log1 \
		--node=node1 &
	/opt/dependency/package/bin/magma_server \
		--listen=0.0.0.0:400015 \
		--join=0.0.0.0:40005 \
		--locations=file:///magma/magma_segment2 \
		--clusterhosts=/tmp/magma_host2 \
		--logdir=/magma/magma_log2 \
		--node=node2 &
	/opt/dependency/package/bin/magma_server \
		--listen=0.0.0.0:400020 \
		--join=0.0.0.0:40005 \
		--locations=file:///magma/magma_segment3 \
		--clusterhosts=/tmp/magma_host3 \
		--logdir=/magma/magma_log3 \
		--node=node3 &
}
magma-start() {
	source /usr/local/hawq/greenplum_path.sh; nohup /usr/local/hawq/bin/magma.sh start 0.0.0.0:50002 file:///magma/magma_segment /usr/local/hawq/etc/magma_hosts_segment ~/hawq-data-directory/segmentdd/pg_log
}
hawq-stop() {
	ps -ef|grep [p]ostgres|tr -s ' '| cut -d ' ' -f3|xargs kill -9
	killall magma_server
}
hawq-restart () {
	if [ "$#" -eq 1 ]; then
		val=$1;
		echo "set QE num to $1";
		hawq-config hawq_rm_nvseg_perquery_perseg_limit $val;
		hawq-config default_hash_table_bucket_number $val;
	fi;
	hawq-stop
	hawq start cluster -a -M immediate
}
hawq-install() {
	cd ~/dev/hawq
	make -j8 install && hawq-restart
	cd -
}
hawq-setup-feature-test () {
	TEST_DB_NAME="hawq_feature_test_db";
	# psql -c "drop database if exists $TEST_DB_NAME;";
	psql -d postgres -c "create database $TEST_DB_NAME;";
	psql -c "alter database $TEST_DB_NAME set lc_messages to 'C';";
	psql -c "alter database $TEST_DB_NAME set lc_monetary to 'C';";
	psql -c "alter database $TEST_DB_NAME set lc_numeric to 'C';";
	psql -c "alter database $TEST_DB_NAME set lc_time to 'C';";
	psql -c "alter database $TEST_DB_NAME set timezone_abbreviations to 'Default';";
	psql -c "alter database $TEST_DB_NAME set timezone to 'PST8PDT';";
	psql -c "alter database $TEST_DB_NAME set datestyle to 'postgres,MDY';";
}
hawq-test () {
	cd $HAWQ_SRC;
	make -j8 feature-test > /dev/null;
	TEST_DB_NAME="hawq_feature_test_db";
	export PGDATABASE=$TEST_DB_NAME;
	if [ -n "$1" ]; then
		$HAWQ_SRC/src/test/feature/feature-test --gtest_filter=$1;
	else
		$HAWQ_SRC/src/test/feature/feature-test --gtest_filter=TestNewExec*;
	fi
	cd -
	export PGDATABASE=postgres;
}
hornet-test() {
	unset DYLD_LIBRARY_PATH
	if [ -n "$1" ]; then
		make -j8 unit && test/unit/unit --gtest_filter=$1;
	else
		make -j8 unittest
	fi
}
hawq-rebuild () {
	cd $HAWQ_SRC/
	make distclean
	./configure --with-perl --with-python --enable-debug --enable-cassert
	make -j8 install
	cd -
}
hawq-performance() {
	rm $HAWQ_SRC/src/test/feature/tpchtest/baseline/tpch_orc_newqe_1g_perf.result
	hawq-test TestTPCH.TestORC_NewQE
	cat $HAWQ_SRC/src/test/feature/tpchtest/baseline/tpch_orc_newqe_1g_perf.result
}



#-------------------------------------------------------------------------------
#
#  Hornet 
#
#-------------------------------------------------------------------------------
kv-install() {
	cd $HORNET_SRC/kv/build && ../bootstrap --enable-client --enable-debug \
	&& make -j8 install && \
	cd - && \
	cd $HORNET_SRC/kv/build && ../bootstrap --enable-server --enable-debug \
	&& make -j8 install && \
	# make simple_server && \
	cd -
}
kv-unittest() {
	kv-install && \
	cd $HORNET_SRC/kv/build && ../bootstrap --enable-client --enable-debug \
	&& make -j8 unittest && \
	cd - && \
	cd $HORNET_SRC/kv/build && ../bootstrap --enable-server --enable-debug \
	&& make -j8 unittest && \
	cd -
}
hornet-debug() {
	cd ~/dev/hornet && make incremental && cd -
}
hornet-release() {
	cd ~/dev/release/hornet && make incremental && cd -
}
hornet-coverage() {
	cd ~/dev/coverage/hornet && make incremental && cd -
}

#-------------------------------------------------------------------------------
#
#   Docker on Hawq
#
#-------------------------------------------------------------------------------
linux-start ()
{
docker run -d \
	-v /Users/$USER/yizhiyang:/home/gpadmin/yizhiyang \
	-v /Users/$USER/dev-linux/dependency:/opt/dependency \
	-v /Users/$USER/dev-linux/hawq:/home/gpadmin/dev/hawq \
	-v /Users/$USER/dev-linux/hornet-release:/home/gpadmin/dev/release/hornet \
	-v /Users/$USER/dev-linux/hornet-debug:/home/gpadmin/dev/hornet \
	-v /Users/$USER/dev/hornet:/home/gpadmin/hornet \
	-v /Users/$USER/dev-linux/thirdparty:/home/gpadmin/dev/thirdparty \
	-v /Users/$USER/dev-linux/libhdfs3:/home/gpadmin/dev/libhdfs3 \
	--privileged=true hub.oushu.io/hawq:yizhiyang
}
linux-login () {
	docker exec -e I_AM_DOCKER=1 -it \
	$(docker ps| grep yizhiyang| cut -d ' ' -f1| tail -n 1) /bin/bash
}
docker-clean() {
	sudo docker ps -a|cut -d ' ' -f 1|xargs sudo docker stop
	sudo docker ps -a|grep Exit|cut -d ' ' -f 1|xargs sudo docker rm
	sudo docker images|grep none|tr -s ' '|cut -d ' ' -f 3|xargs sudo docker rmi
}


#-------------------------------------------------------------------------------
#
#   Basic
#
#-------------------------------------------------------------------------------
# Avoid duplicates
export HISTCONTROL=ignoredups:erasedups  
# When the shell exits, append to the history file instead of overwriting it
shopt -s histappend
# After each command, append to the history file and reread it
# export PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a; history -c; history -r"

if [ $system == Linux ]; then
	export PS1='[\t] \[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\n\$'
else
	export PS1='[\t] \[\033[01;33m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\n\$'
fi
# disable in docker for performance
#I_AM_DOCKER=1
if [ -f ~/yizhiyang/config/git-completion.bash -a -z "${I_AM_DOCKER+x}" ]
then
	# source ~/yizhiyang/config/git-completion.bash
	source ~/yizhiyang/config/git-prompt.sh
	GIT_PS1_SHOWDIRTYSTATE=true
	GIT_PS1_SHOWUNTRACKEDFILES=true
	GIT_PS1_SHOWUPSTREAM="verbose name"
	if [ $system == Linux ]; then
		export PS1='[\t] \[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] `__git_ps1 " (%s)"`\n\$'
	else
		export PS1='[\t] \[\033[01;33m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] `__git_ps1 " (%s)"`\n\$'
	fi
fi

export LS_COLORS="rs=0:di=38;5;27:ln=38;5;51:mh=44;38;5;15:pi=40;38;5;11:so=38;5;13:do=38;5;5:bd=48;5;232;38;5;11:cd=48;5;232;38;5;3:or=48;5;232;38;5;9:mi=05;48;5;232;38;5;15:su=48;5;196;38;5;15:sg=48;5;11;38;5;16:ca=48;5;196;38;5;226:tw=48;5;10;38;5;16:ow=48;5;10;38;5;21:st=48;5;21;38;5;15:ex=38;5;34:*.tar=38;5;9:*.tgz=38;5;9:*.arc=38;5;9:*.arj=38;5;9:*.taz=38;5;9:*.lha=38;5;9:*.lz4=38;5;9:*.lzh=38;5;9:*.lzma=38;5;9:*.tlz=38;5;9:*.txz=38;5;9:*.tzo=38;5;9:*.t7z=38;5;9:*.zip=38;5;9:*.z=38;5;9:*.Z=38;5;9:*.dz=38;5;9:*.gz=38;5;9:*.lrz=38;5;9:*.lz=38;5;9:*.lzo=38;5;9:*.xz=38;5;9:*.bz2=38;5;9:*.bz=38;5;9:*.tbz=38;5;9:*.tbz2=38;5;9:*.tz=38;5;9:*.deb=38;5;9:*.rpm=38;5;9:*.jar=38;5;9:*.war=38;5;9:*.ear=38;5;9:*.sar=38;5;9:*.rar=38;5;9:*.alz=38;5;9:*.ace=38;5;9:*.zoo=38;5;9:*.cpio=38;5;9:*.7z=38;5;9:*.rz=38;5;9:*.cab=38;5;9:*.jpg=38;5;13:*.jpeg=38;5;13:*.gif=38;5;13:*.bmp=38;5;13:*.pbm=38;5;13:*.pgm=38;5;13:*.ppm=38;5;13:*.tga=38;5;13:*.xbm=38;5;13:*.xpm=38;5;13:*.tif=38;5;13:*.tiff=38;5;13:*.png=38;5;13:*.svg=38;5;13:*.svgz=38;5;13:*.mng=38;5;13:*.pcx=38;5;13:*.mov=38;5;13:*.mpg=38;5;13:*.mpeg=38;5;13:*.m2v=38;5;13:*.mkv=38;5;13:*.webm=38;5;13:*.ogm=38;5;13:*.mp4=38;5;13:*.m4v=38;5;13:*.mp4v=38;5;13:*.vob=38;5;13:*.qt=38;5;13:*.nuv=38;5;13:*.wmv=38;5;13:*.asf=38;5;13:*.rm=38;5;13:*.rmvb=38;5;13:*.flc=38;5;13:*.avi=38;5;13:*.fli=38;5;13:*.flv=38;5;13:*.gl=38;5;13:*.dl=38;5;13:*.xcf=38;5;13:*.xwd=38;5;13:*.yuv=38;5;13:*.cgm=38;5;13:*.emf=38;5;13:*.axv=38;5;13:*.anx=38;5;13:*.ogv=38;5;13:*.ogx=38;5;13:*.aac=38;5;45:*.au=38;5;45:*.flac=38;5;45:*.mid=38;5;45:*.midi=38;5;45:*.mka=38;5;45:*.mp3=38;5;45:*.mpc=38;5;45:*.ogg=38;5;45:*.ra=38;5;45:*.wav=38;5;45:*.axa=38;5;45:*.oga=38;5;45:*.spx=38;5;45:*.xspf=38;5;45:"

test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

export PATH="$HOME/.cargo/bin:$PATH"
source /usr/local/hawq/greenplum_path.sh
