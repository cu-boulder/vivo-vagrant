#!/bin/bash
#
#
#Install VIVO.
#
#

export DEBIAN_FRONTEND=noninteractive
#Exit on first error
set -e
#Print shell commands
set -o verbose

#
# -- Setup global variables and directories
#
#VIVO install location
APPDIR=/usr/local/vivo
TEMPLATEBASE=fis-vivo-base
#Data directory - Solr index and VIVO application files will be stored here.
DATADIR=${APPDIR}/${TEMPLATEBASE}/vdata
PROVDIR=/home/vagrant/provision
#Tomcat webapp dir
WEBAPPDIR=/var/lib/tomcat7/webapps
#Database
VIVO_DATABASE=vivo17dev

#Make app directory
mkdir -p $APPDIR
#Make data directory
#PART OF TEMPLATE#mkdir -p $DATADIR
#Make config directory
#PART OF TEMPLATE#mkdir -p $DATADIR/config
#Make log directory
#mkdir -p $DATADIR/logs

createDatabase() {
    #create VIVO mysql database
    mysql -uroot -pvivo -e "CREATE DATABASE IF NOT EXISTS $VIVO_DATABASE DEFAULT CHARACTER SET utf8;"
}

cloneVIVOTemplate(){
    #VIVO will be installed in APPDIR.  You might want to put this
    #in a shared folder so that the files can be edited from the
    #host machine.  Building VIVO via the shared file
    #system can be very slow, at least with Windows.  See
    #http://docs.vagrantup.com/v2/synced-folders/nfs.html

    #Remove existing app directory if present.
    rm -rf $APPDIR && mkdir -p $APPDIR

    #Setup permissions and switch to app dir.
    chown -R vagrant:tomcat7 $APPDIR
    cd $APPDIR

    #Checkout three tiered build template from Github
    git clone https://github.com/cu-boulder/vivo-template.git ${TEMPLATEBASE}
    git submodule init
    git submodule update
# Part of template    cd VIVO/
# Part of template    git checkout maint-rel-1.9
# Part of template    cd ../Vitro
# Part of template    git checkout maint-rel-1.9
# Part of template    cd ..
    return $TRUE
}


removeRDFFiles(){
    #In development, you might want to remove these ontology and data files
    #since they slow down Tomcat restarts considerably.
    rm VIVO/rdf/tbox/filegraph/geo-political.owl
    rm VIVO/rdf/abox/filegraph/continents.n3
    rm VIVO/rdf/abox/filegraph/us-states.rdf
    rm VIVO/rdf/abox/filegraph/geopolitical.abox.ver1.1-11-18-11.owl
    return $TRUE
}


setLogAlias() {
    #Alias for viewing VIVO log
    VLOG="alias vlog='less +F $DATADIR/logs/vivo.all.log'"
    BASHRC=/home/vagrant/.bashrc

    if grep "$VLOG" $BASHRC > /dev/null
    then
       echo "log alias exists"
    else
       (echo;  echo $VLOG)>> $BASHRC
       echo "log alias created"
    fi
    return $TRUE
}


setupTomcat(){
    cd
    #Change permissions
    dirs=( $DATADIR $WEBAPPDIR/vivo )
    for dir in "${dirs[@]}"
    do
      chown -R vagrant:tomcat7 $dir
      chmod -R g+rws $dir
    done

    #Add redirect to /vivo in tomcat root
    rm -f $WEBAPPDIR/ROOT/index.html
    cp $PROVDIR/vivo/index.jsp $WEBAPPDIR/ROOT/index.jsp

    return $TRUE
}

installVIVO(){
#DRE    cd /home/vagrant/
#DRE    rm -rf vivo
#DRE    mkdir vivo
#DRE    cd vivo
#DRE    wget https://github.com/vivo-project/VIVO/releases/download/rel-1.9.2/vivo-1.9.2.tar.gz -O vivo.tar.gz
#DRE    tar -xvf vivo.tar.gz
    #Copy runtime properties into data directory
    cp $PROVDIR/vivo/runtime.properties $DATADIR/.
    #Copy applicationSetup.n3 from Vitro into data directory
    cp $PROVDIR/vivo/applicationSetup.n3 $DATADIR/config/.
    #Copy log4j config to config directory
    cp $PROVDIR/vivo/log4j.properties webapp/src/main/webResources/WEB-INF/classes/.
    cp $PROVDIR/vivo/settings.xml .
    mvn install -s settings.xml
    chown -R vagrant:tomcat7 ../
    return $TRUE
}


#Stop tomcat
/etc/init.d/tomcat7 stop

# add vagrant to tomcat7 group
usermod -a -G tomcat7 vagrant

# create VIVO SDB database
createDatabase

#Clone the VIVO 3 tier template
cloneVIVOTemplate

# install the app
installVIVO

#Adjust tomcat permissions
setupTomcat

#Set a log alias
setLogAlias

#Start Tomcat
/etc/init.d/tomcat7 start

echo VIVO installed.

exit

