#!/bin/make -f


### NOTES:
### version string is fetched from git history
### when not available, specify GIT_VERSION on commnad line:
###
### ```
### export GIT_VERSION=2.x-dev
### ```

ifndef GIT_VERSION
GIT_VERSION := $(shell git describe --long --abbrev=7)
ifndef GIT_VERSION
$(error GIT_VERSION is not set)
endif
endif

### NOTES:
### to compile without jemalloc, set environment variable NOJEMALLOC=1
### to compile with gcov code coverage, set environment variable WITHGCOV=1
### to compile with ASAN, set environment variables NOJEMALLOC=1, WITHASAN=1:
###   * To perform a full ProxySQL build with ASAN then execute:
###
###     ```
###     make build_deps_debug -j$(nproc) && make debug -j$(nproc) && make build_tap_test_debug -j$(nproc)
###     ```
###
### ** to use on-demand coredump generation feature, compile code without ASAN option (WITHASAN=0).

O0=-O0
O2=-O2
O1=-O1
O3=-O3 -mtune=native
#OPTZ=$(O2)
EXTRALINK=#-pg
ALL_DEBUG=-ggdb -DDEBUG
NO_DEBUG=
DEBUG=${ALL_DEBUG}
#export DEBUG
#export OPTZ
#export EXTRALINK
export MAKE
export CURVER?=2.6.0
ifneq (,$(wildcard /etc/os-release))
	DISTRO := $(shell awk -F= '/^NAME/{print $$2}' /etc/os-release)
else
	DISTRO := Unknown
endif

NPROCS := 1
OS := $(shell uname -s)
ifeq ($(OS),Linux)
	NPROCS := $(shell nproc)
endif
ifeq ($(OS),Darwin)
	NPROCS := $(shell sysctl -n hw.ncpu)
endif

export MAKEOPT=-j ${NPROCS}

ifeq ($(wildcard /usr/lib/systemd/system), /usr/lib/systemd/system)
	SYSTEMD=1
else
	SYSTEMD=0
endif
USERCHECK := $(shell getent passwd proxysql)
GROUPCHECK := $(shell getent group proxysql)


### main targets

.PHONY: default
default: build_src

.PHONY: debug
debug: build_src_debug

.PHONY: testaurora
testaurora: build_src_testaurora
	cd test/tap && OPTZ="${O0} -ggdb -DDEBUG -DTEST_AURORA" CC=${CC} CXX=${CXX} ${MAKE}
	cd test/tap/tests && OPTZ="${O0} -ggdb -DDEBUG -DTEST_AURORA" CC=${CC} CXX=${CXX} ${MAKE} $(MAKECMDGOALS)

.PHONY: testgalera
testgalera: build_src_testgalera
	cd test/tap && OPTZ="${O0} -ggdb -DDEBUG -DTEST_GALERA" CC=${CC} CXX=${CXX} ${MAKE}
	cd test/tap/tests && OPTZ="${O0} -ggdb -DDEBUG -DTEST_GALERA" CC=${CC} CXX=${CXX} ${MAKE} $(MAKECMDGOALS)

.PHONY: testgrouprep
testgrouprep: build_src_testgrouprep

.PHONY: testreadonly
testreadonly: build_src_testreadonly

.PHONY: testreplicationlag
testreplicationlag: build_src_testreplicationlag

.PHONY: testall
testall: build_src_testall

.PHONY: clickhouse
clickhouse: build_src_clickhouse

.PHONY: debug_clickhouse
debug_clickhouse: build_src_debug_clickhouse


### helper targets

.PHONY: build_deps
build_deps:
	cd deps && OPTZ="${O2} -ggdb" CC=${CC} CXX=${CXX} ${MAKE}

.PHONY: build_lib
build_lib: build_deps
	cd lib && OPTZ="${O2} -ggdb" CC=${CC} CXX=${CXX} ${MAKE}

.PHONY: build_src
build_src: build_lib
	cd src && OPTZ="${O2} -ggdb" CC=${CC} CXX=${CXX} ${MAKE}

.PHONY: build_deps_debug
build_deps_debug:
	cd deps && OPTZ="${O0} -ggdb -DDEBUG" PROXYDEBUG=1 CC=${CC} CXX=${CXX} ${MAKE}

.PHONY: build_lib_debug
build_lib_debug: build_deps_debug
	cd lib && OPTZ="${O0} -ggdb -DDEBUG" CC=${CC} CXX=${CXX} ${MAKE}

.PHONY: build_src_testaurora
build_src_testaurora: build_lib_testaurora
	cd src && OPTZ="${O0} -ggdb -DDEBUG -DTEST_AURORA" CC=${CC} CXX=${CXX} ${MAKE}

.PHONY: build_lib_testaurora
build_lib_testaurora: build_deps_debug
	cd lib && OPTZ="${O0} -ggdb -DDEBUG -DTEST_AURORA" CC=${CC} CXX=${CXX} ${MAKE}

.PHONY: build_src_testgalera
build_src_testgalera: build_lib_testgalera
	cd src && OPTZ="${O0} -ggdb -DDEBUG -DTEST_GALERA" CC=${CC} CXX=${CXX} ${MAKE}

.PHONY: build_lib_testgalera
build_lib_testgalera: build_deps_debug
	cd lib && OPTZ="${O0} -ggdb -DDEBUG -DTEST_GALERA" CC=${CC} CXX=${CXX} ${MAKE}

.PHONY: build_src_testgrouprep
build_src_testgrouprep: build_lib_testgrouprep
	cd src && OPTZ="${O0} -ggdb -DDEBUG -DTEST_GROUPREP" CC=${CC} CXX=${CXX} ${MAKE}

.PHONY: build_lib_testgrouprep
build_lib_testgrouprep: build_deps_debug
	cd lib && OPTZ="${O0} -ggdb -DDEBUG -DTEST_GROUPREP" CC=${CC} CXX=${CXX} ${MAKE}

.PHONY: build_src_testreadonly
build_src_testreadonly: build_lib_testreadonly
	cd src && OPTZ="${O0} -ggdb -DDEBUG -DTEST_READONLY" CC=${CC} CXX=${CXX} ${MAKE}

.PHONY: build_lib_testreadonly
build_lib_testreadonly: build_deps_debug
	cd lib && OPTZ="${O0} -ggdb -DDEBUG -DTEST_READONLY" CC=${CC} CXX=${CXX} ${MAKE}

.PHONY: build_src_testreplicationlag
build_src_testreplicationlag: build_lib_testreplicationlag
	cd src && OPTZ="${O0} -ggdb -DDEBUG -DTEST_REPLICATIONLAG" CC=${CC} CXX=${CXX} ${MAKE}

.PHONY: build_lib_testreplicationlag
build_lib_testreplicationlag: build_deps_debug
	cd lib && OPTZ="${O0} -ggdb -DDEBUG -DTEST_REPLICATIONLAG" CC=${CC} CXX=${CXX} ${MAKE}

.PHONY: build_src_testall
build_src_testall: build_lib_testall
	cd src && OPTZ="${O0} -ggdb -DDEBUG -DTEST_AURORA -DTEST_GALERA -DTEST_GROUPREP -DTEST_READONLY -DTEST_REPLICATIONLAG" CC=${CC} CXX=${CXX} ${MAKE}

.PHONY: build_lib_testall
build_lib_testall: build_deps_debug
	cd lib && OPTZ="${O0} -ggdb -DDEBUG -DTEST_AURORA -DTEST_GALERA -DTEST_GROUPREP -DTEST_READONLY -DTEST_REPLICATIONLAG" CC=${CC} CXX=${CXX} ${MAKE}

.PHONY: build_tap_test
build_tap_test: build_src
	cd test/tap && OPTZ="${O0} -ggdb -DDEBUG" CC=${CC} CXX=${CXX} ${MAKE}

.PHONY: build_tap_test_debug
build_tap_test_debug: build_src_debug
	cd test/tap && OPTZ="${O0} -ggdb -DDEBUG" CC=${CC} CXX=${CXX} ${MAKE} debug

.PHONY: build_src_debug
build_src_debug: build_lib_debug
	cd src && OPTZ="${O0} -ggdb -DDEBUG" CC=${CC} CXX=${CXX} ${MAKE}

.PHONY: build_deps_clickhouse
build_deps_clickhouse:
	cd deps && OPTZ="${O2} -ggdb" PROXYSQLCLICKHOUSE=1 CC=${CC} CXX=${CXX} ${MAKE}

.PHONY: build_deps_debug_clickhouse
build_deps_debug_clickhouse:
	cd deps && OPTZ="${O0} -ggdb -DDEBUG" PROXYSQLCLICKHOUSE=1 PROXYDEBUG=1 CC=${CC} CXX=${CXX} ${MAKE}

.PHONY: build_lib_clickhouse
build_lib_clickhouse: build_deps_clickhouse
	cd lib && OPTZ="${O2} -ggdb" PROXYSQLCLICKHOUSE=1 CC=${CC} CXX=${CXX} ${MAKE}

.PHONY: build_lib_debug_clickhouse
build_lib_debug_clickhouse: build_deps_debug_clickhouse
	cd lib && OPTZ="${O0} -ggdb -DDEBUG" PROXYSQLCLICKHOUSE=1 CC=${CC} CXX=${CXX} ${MAKE}

.PHONY: build_src_clickhouse
build_src_clickhouse: build_lib_clickhouse
	cd src && OPTZ="${O2} -ggdb" PROXYSQLCLICKHOUSE=1 CC=${CC} CXX=${CXX} ${MAKE}

.PHONY: build_src_debug_clickhouse
build_src_debug_clickhouse: build_lib_debug_clickhouse
	cd src && OPTZ="${O0} -ggdb -DDEBUG" PROXYSQLCLICKHOUSE=1 CC=${CC} CXX=${CXX} ${MAKE}


### packaging targets

SYS_ARCH := $(shell uname -m)
REL_ARCH := $(subst x86_64,amd64,$(subst aarch64,arm64,$(SYS_ARCH)))
RPM_ARCH := .$(SYS_ARCH)
DEB_ARCH := _$(REL_ARCH)
REL_VERS := $(shell echo ${GIT_VERSION} | grep -Po '(?<=^v|^)[\d\.]+')
RPM_VERS := -$(REL_VERS)-1
DEB_VERS := _$(REL_VERS)

packages: $(REL_ARCH)-packages ;
almalinux: $(REL_ARCH)-almalinux ;
centos: $(REL_ARCH)-centos ;
debian: $(REL_ARCH)-debian ;
fedora: $(REL_ARCH)-fedora ;
opensuse: $(REL_ARCH)-opensuse ;
ubuntu: $(REL_ARCH)-ubuntu ;

amd64-packages: amd64-centos amd64-ubuntu amd64-debian amd64-fedora amd64-opensuse amd64-almalinux
amd64-almalinux: almalinux8 almalinux8-clang almalinux8-dbg almalinux9 almalinux9-clang almalinux9-dbg
amd64-centos: centos6 centos6-dbg centos7 centos7-dbg centos8 centos8-clang centos8-dbg centos9 centos9-clang centos9-dbg
amd64-debian: debian8 debian8-dbg debian9 debian9-dbg debian10 debian10-dbg debian11 debian11-clang debian11-dbg debian12 debian12-clang debian12-dbg
amd64-fedora: fedora27 fedora27-dbg fedora28 fedora28-dbg fedora33 fedora33-dbg fedora34 fedora34-clang fedora34-dbg fedora36 fedora36-clang fedora36-dbg fedora37 fedora37-clang fedora37-dbg fedora38 fedora38-clang fedora38-dbg fedora39 fedora39-clang fedora39-dbg
amd64-opensuse: opensuse15 opensuse15-clang opensuse15-dbg
amd64-ubuntu: ubuntu14 ubuntu14-dbg ubuntu16 ubuntu16-dbg ubuntu18 ubuntu18-dbg ubuntu20 ubuntu20-clang ubuntu20-dbg ubuntu22 ubuntu22-clang ubuntu22-dbg

arm64-packages: arm64-centos arm64-debian arm64-ubuntu arm64-fedora arm64-opensuse arm64-almalinux
arm64-almalinux: almalinux8 almalinux9
arm64-centos: centos7 centos8
arm64-debian: debian9 debian10 debian11 debian12
arm64-fedora: fedora33 fedora34 fedora36 fedora37 fedora38 fedora39
arm64-opensuse: opensuse15
arm64-ubuntu: ubuntu16 ubuntu18 ubuntu20 ubuntu22

almalinux%: build-almalinux% ;
centos%: build-centos% ;
debian%: build-debian% ;
fedora%: build-fedora% ;
opensuse%: build-opensuse% ;
ubuntu%: build-ubuntu% ;


.PHONY: build-%
.NOTPARALLEL: build-%
build-%: BLD_NAME=$(patsubst build-%,%,$@)
build-%: PKG_VERS=$(if $(filter $(shell echo ${BLD_NAME} | grep -Po '[a-z]+'),debian ubuntu),$(DEB_VERS),$(RPM_VERS))
build-%: PKG_TYPE=$(if $(filter $(shell echo $(BLD_NAME) | grep -Po '\-de?bu?g'),-dbg -debug),-dbg,)
build-%: PKG_NAME=$(firstword $(subst -, ,$(BLD_NAME)))
build-%: PKG_COMP=$(if $(filter $(shell echo $(BLD_NAME) | grep -Po '\-clang'),-clang),-clang,)
build-%: PKG_ARCH=$(if $(filter $(shell echo ${BLD_NAME} | grep -Po '[a-z]+'),debian ubuntu),$(DEB_ARCH),$(RPM_ARCH))
build-%: PKG_KIND=$(if $(filter $(shell echo ${BLD_NAME} | grep -Po '[a-z]+'),debian ubuntu),deb,rpm)
build-%: PKG_FILE=binaries/proxysql$(PKG_VERS)$(PKG_TYPE)-$(PKG_NAME)$(PKG_COMP)$(PKG_ARCH).$(PKG_KIND)
build-%:
	@echo 'building $@'
	@IMG_NAME=$(PKG_NAME) IMG_TYPE=$(subst -,_,$(PKG_TYPE)) IMG_COMP=$(subst -,_,$(PKG_COMP)) $(MAKE) $(PKG_FILE)

.NOTPARALLEL: binaries/proxysql%
binaries/proxysql%:
	@docker-compose -p $(IMG_NAME) down -v --remove-orphans
	@docker-compose -p $(IMG_NAME) up $(IMG_NAME)$(IMG_TYPE)$(IMG_COMP)_build


### clean targets

.PHONY: clean
clean:
	cd lib && ${MAKE} clean
	cd src && ${MAKE} clean
	cd test/tap && ${MAKE} clean

.PHONY: cleanall
cleanall:
	cd deps && ${MAKE} cleanall
	cd lib && ${MAKE} clean
	cd src && ${MAKE} clean
	cd test/tap && ${MAKE} clean
	rm -f binaries/*deb || true
	rm -f binaries/*rpm || true
	rm -f binaries/*id-hash || true

.PHONY: cleanbuild
cleanbuild:
	cd deps && ${MAKE} cleanall
	cd lib && ${MAKE} clean
	cd src && ${MAKE} clean


### install targets

.PHONY: install
install: src/proxysql
	install -m 0755 src/proxysql /usr/bin
	install -m 0600 etc/proxysql.cnf /etc
	if [ ! -d /var/lib/proxysql ]; then mkdir /var/lib/proxysql ; fi
ifeq ($(findstring proxysql,$(USERCHECK)),)
	@echo "Creating proxysql user and group"
	useradd -r -U -s /bin/false proxysql
endif
ifeq ($(SYSTEMD), 1)
	install -m 0644 systemd/system/proxysql.service /usr/lib/systemd/system/
	systemctl enable proxysql.service
else
	install -m 0755 etc/init.d/proxysql /etc/init.d
ifeq ($(DISTRO),"CentOS Linux")
		chkconfig --level 0123456 proxysql on
else
ifeq ($(DISTRO),"Rocky Linux")
		chkconfig --level 0123456 proxysql on
else
ifeq ($(DISTRO),"Red Hat Enterprise Linux Server")
		chkconfig --level 0123456 proxysql on
else
ifeq ($(DISTRO),"Ubuntu")
		update-rc.d proxysql defaults
else
ifeq ($(DISTRO),"Debian GNU/Linux")
		update-rc.d proxysql defaults
else
ifeq ($(DISTRO),"Unknown")
		$(warning Not sure how to install proxysql service on this OS)
endif
endif
endif
endif
endif
endif
endif

.PHONY: uninstall
uninstall:
	if [ -f /etc/proxysql.cnf ]; then rm /etc/proxysql.cnf ; fi
	if [ -f /usr/bin/proxysql ]; then rm /usr/bin/proxysql ; fi
	if [ -d /var/lib/proxysql ]; then rmdir /var/lib/proxysql 2>/dev/null || true ; fi
ifeq ($(SYSTEMD), 1)
		systemctl stop proxysql.service
		if [ -f /usr/lib/systemd/system/proxysql.service ]; then rm /usr/lib/systemd/system/proxysql.service ; fi
		find /etc/systemd -name "proxysql.service" -exec rm {} \;
		systemctl daemon-reload
else
ifeq ($(DISTRO),"CentOS Linux")
		chkconfig --level 0123456 proxysql off
		if [ -f /etc/init.d/proxysql ]; then rm /etc/init.d/proxysql ; fi
else
ifeq ($(DISTRO),"Red Hat Enterprise Linux Server")
		chkconfig --level 0123456 proxysql off
		if [ -f /etc/init.d/proxysql ]; then rm /etc/init.d/proxysql ; fi
else
ifeq ($(DISTRO),"Ubuntu")
		if [ -f /etc/init.d/proxysql ]; then rm /etc/init.d/proxysql ; fi
		update-rc.d proxysql remove
else
ifeq ($(DISTRO),"Debian GNU/Linux")
		if [ -f /etc/init.d/proxysql ]; then rm /etc/init.d/proxysql ; fi
		update-rc.d proxysql remove
else
ifeq ($(DISTRO),"Unknown")
		$(warning Not sure how to uninstall proxysql service on this OS)
endif
endif
endif
endif
endif
endif
ifneq ($(findstring proxysql,$(USERCHECK)),)
	@echo "Deleting proxysql user"
	userdel proxysql
endif
ifneq ($(findstring proxysql,$(GROUPCHECK)),)
	@echo "Deleting proxysql group"
	groupdel proxysql
endif
